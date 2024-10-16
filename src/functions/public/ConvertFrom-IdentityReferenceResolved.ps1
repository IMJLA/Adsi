function ConvertFrom-IdentityReferenceResolved {

    <#
        .SYNOPSIS
        Use ADSI to collect more information about the IdentityReference in NTFS Access Control Entries
        .DESCRIPTION
        Recursively retrieves group members and detailed information about them
        Use caching to reduce duplicate directory queries
        .INPUTS
        [System.Object]$IdentityReference
        .OUTPUTS
        [System.Object] The input object is returned with additional properties added:
            DirectoryEntry
            DomainDn
            DomainNetBIOS
            ObjectType
            Members (if the DirectoryEntry is a group).

        .EXAMPLE
        (Get-Acl).Access |
        Resolve-IdentityReference |
        Group-Object -Property IdentityReferenceResolved |
        ConvertFrom-IdentityReferenceResolved

        Incomplete example but it shows the chain of functions to generate the expected input for this
    #>

    [OutputType([void])]

    param (

        # The NTFS AccessControlEntry object(s), grouped by their IdentityReference property
        # TODO: Use System.Security.Principal.NTAccount instead
        [Parameter(ValueFromPipeline)]
        [string]$IdentityReference,

        # Do not get group members
        [switch]$NoGroupMembers,

        # Cache of access control entries keyed by their resolved identities
        [hashtable]$ACEsByResolvedID = ([hashtable]::Synchronized(@{})),

        # Thread-safe hashtable to use for caching directory entries and avoiding duplicate directory queries
        [hashtable]$PrincipalById = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Log messages which have not yet been written to disk
        [hashtable]$LogBuffer = ([hashtable]::Synchronized(@{})),

        # The current domain
        # Can be passed as a parameter to reduce calls to Get-CurrentDomain
        [string]$CurrentDomain = (Get-CurrentDomain)

    )

    if ($null -eq $PrincipalById[$IdentityReference]) {

        $LogParams = @{
            ThisHostname = $ThisHostname
            Type         = $DebugOutputStream
            Buffer       = $LogBuffer
            WhoAmI       = $WhoAmI
        }

        $LoggingParams = @{
            ThisHostname = $ThisHostname
            LogBuffer    = $LogBuffer
            WhoAmI       = $WhoAmI
        }

        $AccessControlEntries = $ACEsByResolvedID[$IdentityReference]

        #Write-LogMsg @LogParams -Text " # ADSI Principal cache miss for '$IdentityReference'"
        $split = $IdentityReference.Split('\')
        $DomainNetBIOS = $split[0]
        $SamAccountNameOrSid = $split[1]

        $WellKnownSidParams = @{
            IdentityReference = $SamAccountNameOrSid
            DomainsByNetbios  = $DomainsByNetbios
            DomainNetBios     = $DomainNetBIOS
        }

        $CachedWellKnownSID = Find-CachedWellKnownSID @WellKnownSidParams

        if ($CachedWellKnownSID) {

            $FakeDirectoryEntryParams = @{
                DirectoryPath = "WinNT://$DomainNetBIOS/$($CachedWellKnownSID.Name)"
                InputObject   = $CachedWellKnownSID
            }

            $DirectoryEntry = New-FakeDirectoryEntry @FakeDirectoryEntryParams

        } else {
            Write-LogMsg @LogParams -Text " # Known SID cache miss for '$IdentityReference' on '$DomainNetBIOS'"
        }

        if ($null -eq $DirectoryEntry) {


            $GetDirectoryEntryParams = @{
                DirectoryEntryCache = $DirectoryEntryCache
                DomainsByNetbios    = $DomainsByNetbios
                DomainsBySid        = $DomainsBySid
                DomainsByFqdn       = $DomainsByFqdn
                ThisFqdn            = $ThisFqdn
                CimCache            = $CimCache
                DebugOutputStream   = $DebugOutputStream
            }

            $SearchDirectoryParams = @{
                CimCache            = $CimCache
                DebugOutputStream   = $DebugOutputStream
                DirectoryEntryCache = $DirectoryEntryCache
                DomainsByNetbios    = $DomainsByNetbios
                ThisFqdn            = $ThisFqdn
            }

            if (

                $null -ne $SamAccountNameOrSid -and
                @($AccessControlEntries.AdsiProvider)[0] -eq 'LDAP'

            ) {

                Write-LogMsg @LogParams -Text " # '$IdentityReference' is a domain security principal"

                if ($DomainNetbiosCacheResult) {

                    #Write-LogMsg @LogParams -Text " # Domain NetBIOS cache hit for '$DomainNetBIOS' for '$IdentityReference'"
                    $DomainDn = $DomainNetbiosCacheResult.DistinguishedName
                    $SearchDirectoryParams['DirectoryPath'] = "LDAP://$($DomainNetbiosCacheResult.Dns)/$DomainDn"

                } else {

                    #Write-LogMsg @LogParams -Text " # Domain NetBIOS cache miss for '$DomainNetBIOS' for '$IdentityReference'"

                    if ( -not [string]::IsNullOrEmpty($DomainNetBIOS) ) {
                        #$DomainDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -DomainsByNetbios $DomainsByNetbios @LoggingParams
                    }

                    $FqdnParams = @{
                        DirectoryPath = "LDAP://$DomainNetBIOS"
                        ThisFqdn      = $ThisFqdn
                        CimCache      = $CimCache
                    }
                    $SearchDirectoryParams['DirectoryPath'] = Add-DomainFqdnToLdapPath @FqdnParams @LogParams

                }

                # Search the domain for the principal
                $SearchDirectoryParams['Filter'] = "(samaccountname=$SamAccountNameOrSid)"

                $SearchDirectoryParams['PropertiesToLoad'] = @(
                    'objectClass',
                    'objectSid',
                    'samAccountName',
                    'distinguishedName',
                    'name',
                    'grouptype',
                    'description',
                    'managedby',
                    'member',
                    'Department',
                    'Title',
                    'primaryGroupToken'
                )

                Write-LogMsg @LogParams -Text 'Search-Directory' -Expand $SearchDirectoryParams, $LoggingParams

                try {
                    $DirectoryEntry = Search-Directory @SearchDirectoryParams @LoggingParams
                } catch {

                    $LogParams['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
                    Write-LogMsg @LogParams -Text " # Did not find '$IdentityReference' in a directory search: $($_.Exception.Message.Trim())"
                    $LogParams['Type'] = $DebugOutputStream

                }

            } elseif (
                $IdentityReference.Substring(0, $IdentityReference.LastIndexOf('-') + 1) -eq $CurrentDomain.SIDString
            ) {

                Write-LogMsg @LogParams -Text " # '$IdentityReference' is an unresolved SID from the current domain"

                # Get the distinguishedName and netBIOSName of the current domain.  This also determines whether the domain is online.
                $DomainDN = $CurrentDomain.distinguishedName.Value
                $DomainFQDN = ConvertTo-Fqdn -DistinguishedName $DomainDN -ThisFqdn $ThisFqdn -CimCache $CimCache @LoggingParams
                $SearchDirectoryParams['DirectoryPath'] = "LDAP://$DomainFQDN/cn=partitions,cn=configuration,$DomainDn"
                $SearchDirectoryParams['Filter'] = "(&(objectcategory=crossref)(dnsroot=$DomainFQDN)(netbiosname=*))"
                $SearchDirectoryParams['PropertiesToLoad'] = 'netbiosname'
                Write-LogMsg @LogParams -Text 'Search-Directory' -Expand $SearchDirectoryParams, $LoggingParams
                $DomainCrossReference = Search-Directory @SearchDirectoryParams @LoggingParams

                if ($DomainCrossReference.Properties ) {

                    Write-LogMsg @LogParams -Text " # The domain '$DomainFQDN' is online for '$IdentityReference'"
                    [string]$DomainNetBIOS = $DomainCrossReference.Properties['netbiosname']

                    # TODO: The domain is online; see if any domain trusts have issues?
                    #       Determine if SID is foreign security principal?

                    # TODO: What if the foreign security principal exists but the corresponding domain trust is down?
                    # Don't want to recommend deletion of the ACE in that case.

                }
                $SidObject = [System.Security.Principal.SecurityIdentifier]::new($IdentityReference)
                $SidBytes = [byte[]]::new($SidObject.BinaryLength)
                $null = $SidObject.GetBinaryForm($SidBytes, 0)
                $ObjectSid = ConvertTo-HexStringRepresentationForLDAPFilterString -SIDByteArray $SidBytes
                $SearchDirectoryParams['DirectoryPath'] = "LDAP://$DomainFQDN/$DomainDn"
                $SearchDirectoryParams['Filter'] = "(objectsid=$ObjectSid)"
                $SearchDirectoryParams['PropertiesToLoad'] = @(
                    'objectClass',
                    'objectSid',
                    'samAccountName',
                    'distinguishedName',
                    'name',
                    'grouptype',
                    'description',
                    'managedby',
                    'member',
                    'Department',
                    'Title',
                    'primaryGroupToken'
                )

                Write-LogMsg @LogParams -Text 'Search-Directory' -Expand $SearchDirectoryParams, $LoggingParams

                try {
                    $DirectoryEntry = Search-Directory @SearchDirectoryParams @LoggingParams
                } catch {

                    $LogParams['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
                    Write-LogMsg @LogParams -Text " # Couldn't find '$IdentityReference' in a directory search: $($_.Exception.Message.Trim())"
                    $LogParams['Type'] = $DebugOutputStream

                }

            } else {

                Write-LogMsg @LogParams -Text " # '$IdentityReference' is a local security principal or unresolved SID."

                if ($null -eq $SamAccountNameOrSid) { $SamAccountNameOrSid = $IdentityReference }

                if ($SamAccountNameOrSid -like "S-1-*") {

                    if ($DomainNetBIOS -in 'APPLICATION PACKAGE AUTHORITY', 'BUILTIN', 'NT SERVICE') {

                        Write-LogMsg @LogParams -Text " # '$($IdentityReference)' is a Capability SID or Service SID which could not be resolved to a friendly name."

                        $Known = Get-KnownSid -SID $SamAccountNameOrSid

                        $FakeDirectoryEntryParams = @{
                            DirectoryPath = "WinNT://$DomainNetBIOS/$SamAccountNameOrSid"
                            InputObject   = $Known
                        }

                        $DirectoryEntry = New-FakeDirectoryEntry @FakeDirectoryEntryParams

                    } else {

                        Write-LogMsg @LogParams -Text " # '$($IdentityReference)' is an unresolved SID"

                        # The SID of the domain is the SID of the user minus the last block of numbers
                        $DomainSid = $SamAccountNameOrSid.Substring(0, $SamAccountNameOrSid.LastIndexOf("-"))

                        # Determine if SID belongs to current domain
                        if ($DomainSid -eq $CurrentDomain.SIDString) {
                            Write-LogMsg @LogParams -Text " # '$($IdentityReference)' belongs to the current domain.  Could be a deleted user.  ?possibly a foreign security principal corresponding to an offline trusted domain or deleted user in the trusted domain?"
                        } else {
                            Write-LogMsg @LogParams -Text " # '$($IdentityReference)' does not belong to the current domain. Could be a local security principal or belong to an unresolvable domain."
                        }

                        # Lookup other information about the domain using its SID as the key
                        $DomainObject = $DomainsBySID[$DomainSid]

                        if ($DomainObject) {
                            $GetDirectoryEntryParams['DirectoryPath'] = "WinNT://$($DomainObject.Dns)/Users"
                            $DomainNetBIOS = $DomainObject.Netbios
                            $DomainDN = $DomainObject.DistinguishedName
                        } else {
                            $GetDirectoryEntryParams['DirectoryPath'] = "WinNT://$DomainNetBIOS/Users"
                            $DomainDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -DomainsByNetbios $DomainsByNetbios @LoggingParams
                        }

                        Write-LogMsg @LogParams -Text "Get-DirectoryEntry" -Expand $GetDirectoryEntryParams, $LoggingParams

                        try {
                            $UsersGroup = Get-DirectoryEntry @GetDirectoryEntryParams @LoggingParams
                        } catch {
                            $LogParams['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
                            Write-LogMsg @LogParams -Text "Couldn't get '$($GetDirectoryEntryParams['DirectoryPath'])' using PSRemoting. Error: $_"
                            $LogParams['Type'] = $DebugOutputStream
                        }

                        $MembersOfUsersGroup = Get-WinNTGroupMember -DirectoryEntry $UsersGroup -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn -CimCache $CimCache @LoggingParams

                        $DirectoryEntry = $MembersOfUsersGroup |
                        Where-Object -FilterScript { ($SamAccountNameOrSid -eq $([System.Security.Principal.SecurityIdentifier]::new([byte[]]$_.Properties['objectSid'], 0))) }

                    }

                } else {

                    Write-LogMsg @LogParams -Text " # '$IdentityReference' is a local security principal"
                    $DomainNetbiosCacheResult = $DomainsByNetbios[$DomainNetBIOS]

                    if ($DomainNetbiosCacheResult) {
                        $GetDirectoryEntryParams['DirectoryPath'] = "WinNT://$($DomainNetbiosCacheResult.Dns)/$SamAccountNameOrSid"
                    } else {
                        $GetDirectoryEntryParams['DirectoryPath'] = "WinNT://$DomainNetBIOS/$SamAccountNameOrSid"
                    }

                    $GetDirectoryEntryParams['PropertiesToLoad'] = @(
                        'members',
                        'objectClass',
                        'objectSid',
                        'samAccountName',
                        'distinguishedName',
                        'name',
                        'grouptype',
                        'description',
                        'managedby',
                        'member',
                        'Department',
                        'Title',
                        'primaryGroupToken'
                    )

                    Write-LogMsg @LogParams -Text "Get-DirectoryEntry" -Expand $GetDirectoryEntryParams, $LoggingParams

                    try {
                        $DirectoryEntry = Get-DirectoryEntry @GetDirectoryEntryParams @LoggingParams
                    } catch {

                        $LogParams['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
                        Write-LogMsg @LogParams -Text " # '$($GetDirectoryEntryParams['DirectoryPath'])' Couldn't be resolved for '$IdentityReference'. Error: $($_.Exception.Message.Trim())"
                        $LogParams['Type'] = $DebugOutputStream

                    }

                }

            }

        }

        $PropertiesToAdd = @{
            DomainDn            = $DomainDn
            DomainNetbios       = $DomainNetBIOS
            ResolvedAccountName = $IdentityReference
        }

        if ($null -ne $DirectoryEntry) {

            ForEach ($Prop in $DirectoryEntry.PSObject.Properties.GetEnumerator().Name) {
                $null = ConvertTo-SimpleProperty -InputObject $DirectoryEntry -Property $Prop -PropertyDictionary $PropertiesToAdd
            }

            if ($DirectoryEntry.Name) {
                $AccountName = $DirectoryEntry.Name
            } else {

                if ($DirectoryEntry.Properties) {

                    if ($DirectoryEntry.Properties['name'].Value) {
                        $AccountName = $DirectoryEntry.Properties['name'].Value
                    } else {
                        $AccountName = $DirectoryEntry.Properties['name']
                    }

                }

            }

            $PropertiesToAdd['ResolvedAccountName'] = "$DomainNetBIOS\$AccountName"

            # WinNT objects have a SchemaClassName property which is a string
            # LDAP objects have an objectClass property which is an ordered list of strings, the last being the class name of the object instance
            # ToDo: LDAP objects may have SchemaClassName too.  When/why?  Should I just request it always in the list of properties?
            # ToDo: Actually I should create an AdsiObjectType property of my own or something...don't expose the dependency
            if (-not $DirectoryEntry.SchemaClassName) {
                $PropertiesToAdd['SchemaClassName'] = @($DirectoryEntry.Properties['objectClass'])[-1] #untested but should work, last value should be the correct one https://learn.microsoft.com/en-us/windows/win32/ad/retrieving-the-objectclass-property
            }

            if ($NoGroupMembers -eq $false) {

                if (

                    # WinNT DirectoryEntries do not contain an objectClass property
                    # If this property exists it is an LDAP DirectoryEntry rather than WinNT
                    $PropertiesToAdd.ContainsKey('objectClass')

                ) {

                    # Retrieve the members of groups from the LDAP provider
                    Write-LogMsg @LogParams -Text " # '$($DirectoryEntry.Path)' is an LDAP security principal for '$IdentityReference'"
                    $Members = (Get-AdsiGroupMember -Group $DirectoryEntry -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LoggingParams).FullMembers

                } else {

                    Write-LogMsg @LogParams -Text " # '$($DirectoryEntry.Path)' is a WinNT security principal for '$IdentityReference'"

                    if ( $DirectoryEntry.SchemaClassName -in @('group', 'SidTypeWellKnownGroup', 'SidTypeAlias')) {

                        Write-LogMsg @LogParams -Text " # '$($DirectoryEntry.Path)' is a WinNT group for '$IdentityReference'"
                        $Members = Get-WinNTGroupMember -DirectoryEntry $DirectoryEntry -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LoggingParams

                    }

                }

                # (Get-AdsiGroupMember).FullMembers or Get-WinNTGroupMember could return an array with null members so we must verify that is not true
                if ($Members) {

                    $GroupMembers = ForEach ($ThisMember in $Members) {

                        if ($ThisMember.Domain) {

                            # Include specific desired properties
                            $OutputProperties = @{}

                        } else {

                            # Include specific desired properties
                            $OutputProperties = @{

                                Domain = [pscustomobject]@{
                                    Dns     = $DomainNetBIOS
                                    Netbios = $DomainNetBIOS
                                    Sid     = @($SamAccountNameOrSid -split '-')[-1]
                                }

                            }

                        }

                        # Get any existing properties for inclusion later
                        $InputProperties = $ThisMember.PSObject.Properties.GetEnumerator().Name

                        # Include any existing properties found earlier
                        ForEach ($ThisProperty in $InputProperties) {
                            $null = ConvertTo-SimpleProperty -InputObject $ThisMember -Property $ThisProperty -PropertyDictionary $OutputProperties
                        }

                        if ($ThisMember.sAmAccountName) {
                            $ResolvedAccountName = "$($OutputProperties['Domain'].Netbios)\$($ThisMember.sAmAccountName)"
                        } else {
                            $ResolvedAccountName = "$($OutputProperties['Domain'].Netbios)\$($ThisMember.Name)"
                        }

                        $OutputProperties['ResolvedAccountName'] = $ResolvedAccountName
                        $PrincipalById[$ResolvedAccountName] = [PSCustomObject]$OutputProperties
                        $ACEsByResolvedID[$ResolvedAccountName] = $AccessControlEntries
                        $ResolvedAccountName

                    }

                }

                Write-LogMsg @LogParams -Text " # '$($DirectoryEntry.Path)' has $(($Members | Measure-Object).Count) members for '$IdentityReference'"

            }

            $PropertiesToAdd['Members'] = $GroupMembers

        } else {

            $LogParams['Type'] = 'Verbose' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
            Write-LogMsg @LogParams -Text " # '$IdentityReference' Couldn't be matched to a DirectoryEntry"
            $LogParams['Type'] = $DebugOutputStream

        }

        $PrincipalById[$IdentityReference] = [PSCustomObject]$PropertiesToAdd

    }

}
