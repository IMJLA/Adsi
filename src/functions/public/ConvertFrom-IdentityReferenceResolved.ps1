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
        [string]$IdentityReference,

        # Do not get group members
        [switch]$NoGroupMembers,

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

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

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache,

        # The current domain
        # Can be passed as a parameter to reduce calls to Get-CurrentDomain
        [string]$CurrentDomain = (Get-CurrentDomain -Cache $Cache)

    )

    $PrincipalById = $Cache.Value['PrincipalById']

    if ( -not $PrincipalById.Value.TryGetValue( $IdentityReference, [ref]$null ) ) {

        $Log = @{ ThisHostname = $ThisHostname ; Type = $DebugOutputStream ; Buffer = $Cache.Value['LogBuffer'] ; WhoAmI = $WhoAmI }
        #Write-LogMsg @Log -Text " # ADSI Principal cache miss for '$IdentityReference'"
        $LogThis = @{ ThisHostname = $ThisHostname ; Cache = $Cache ; WhoAmI = $WhoAmI ; DebugOutputStream = $DebugOutputStream }
        $AccessControlEntries = $null
        $AddOrUpdateScriptblock = { param($key, $val) $val }
        $AceGuidByID = $Cache.Value['AceGuidByID']
        $null = $AceGuidByID.Value.TryGetValue( $IdentityReference , [ref]$AccessControlEntries )
        $split = $IdentityReference.Split('\')
        $DomainNetBIOS = $split[0]
        $SamAccountNameOrSid = $split[1]
        $CachedWellKnownSID = Find-CachedWellKnownSID -IdentityReference $SamAccountNameOrSid -DomainNetBIOS $DomainNetBIOS -DomainByNetbios $Cache.Value['DomainByNetbios']

        if ($CachedWellKnownSID) {

            $FakeDirectoryEntryParams = @{
                DirectoryPath = "WinNT://$DomainNetBIOS/$($CachedWellKnownSID.Name)"
                InputObject   = $CachedWellKnownSID
            }

            $DirectoryEntry = New-FakeDirectoryEntry @FakeDirectoryEntryParams

        } else {
            Write-LogMsg @Log -Text " # Known SID cache miss for '$IdentityReference' on '$DomainNetBIOS'"
        }

        if ($null -eq $DirectoryEntry) {

            $DirectorySplat = @{
                DebugOutputStream = $DebugOutputStream
                ThisFqdn          = $ThisFqdn
            }

            $SearchSplat = @{}

            if (

                $null -ne $SamAccountNameOrSid -and
                @($AccessControlEntries.AdsiProvider)[0] -eq 'LDAP'

            ) {

                Write-LogMsg @Log -Text " # '$IdentityReference' is a domain security principal"

                if ($DomainNetbiosCacheResult) {

                    #Write-LogMsg @Log -Text " # Domain NetBIOS cache hit for '$DomainNetBIOS' for '$IdentityReference'"
                    $DomainDn = $DomainNetbiosCacheResult.DistinguishedName
                    $SearchSplat['DirectoryPath'] = "LDAP://$($DomainNetbiosCacheResult.Dns)/$DomainDn"

                } else {

                    #Write-LogMsg @Log -Text " # Domain NetBIOS cache miss for '$DomainNetBIOS' for '$IdentityReference'"

                    if ( -not [string]::IsNullOrEmpty($DomainNetBIOS) ) {
                        # The line below was commented out; why?  Isn't DN needed to be obtained for domain users?
                        $DomainDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -ThisFqdn $ThisFqdn @LogThis
                    }

                    $FqdnParams = @{
                        DirectoryPath = "LDAP://$DomainNetBIOS"
                        ThisFqdn      = $ThisFqdn
                    }
                    $SearchSplat['DirectoryPath'] = Add-DomainFqdnToLdapPath @FqdnParams @LogThis

                }

                # Search the domain for the principal
                $SearchSplat['Filter'] = "(samaccountname=$SamAccountNameOrSid)"

                $SearchSplat['PropertiesToLoad'] = @(
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

                Write-LogMsg @Log -Text 'Search-Directory' -Expand $SearchSplat, $LogThis

                try {
                    $DirectoryEntry = Search-Directory @DirectoryParams @SearchSplat @LogThis
                } catch {

                    $Log['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
                    Write-LogMsg @Log -Text " # Did not find '$IdentityReference' in a directory search: $($_.Exception.Message.Trim())"
                    $Log['Type'] = $DebugOutputStream

                }

            } elseif (
                $IdentityReference.Substring(0, $IdentityReference.LastIndexOf('-') + 1) -eq $CurrentDomain.SIDString
            ) {

                Write-LogMsg @Log -Text " # '$IdentityReference' is an unresolved SID from the current domain"

                # Get the distinguishedName and netBIOSName of the current domain.  This also determines whether the domain is online.
                $DomainDN = $CurrentDomain.distinguishedName.Value
                $DomainFQDN = ConvertTo-Fqdn -DistinguishedName $DomainDN -ThisFqdn $ThisFqdn @LogThis
                $SearchSplat['DirectoryPath'] = "LDAP://$DomainFQDN/cn=partitions,cn=configuration,$DomainDn"
                $SearchSplat['Filter'] = "(&(objectcategory=crossref)(dnsroot=$DomainFQDN)(netbiosname=*))"
                $SearchSplat['PropertiesToLoad'] = 'netbiosname'
                Write-LogMsg @Log -Text 'Search-Directory' -Expand $SearchSplat, $LogThis
                $DomainCrossReference = Search-Directory @DirectoryParams @SearchSplat @LogThis

                if ($DomainCrossReference.Properties ) {

                    Write-LogMsg @Log -Text " # The domain '$DomainFQDN' is online for '$IdentityReference'"
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
                $SearchSplat['DirectoryPath'] = "LDAP://$DomainFQDN/$DomainDn"
                $SearchSplat['Filter'] = "(objectsid=$ObjectSid)"
                $SearchSplat['PropertiesToLoad'] = @(
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

                Write-LogMsg @Log -Text 'Search-Directory' -Expand $SearchSplat, $LogThis

                try {
                    $DirectoryEntry = Search-Directory @DirectoryParams @SearchSplat @LogThis
                } catch {

                    $Log['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
                    Write-LogMsg @Log -Text " # Couldn't find '$IdentityReference' in a directory search: $($_.Exception.Message.Trim())"
                    $Log['Type'] = $DebugOutputStream

                }

            } else {

                Write-LogMsg @Log -Text " # '$IdentityReference' is a local security principal or unresolved SID."

                if ($null -eq $SamAccountNameOrSid) { $SamAccountNameOrSid = $IdentityReference }

                if ($SamAccountNameOrSid -like 'S-1-*') {

                    if ($DomainNetBIOS -in 'APPLICATION PACKAGE AUTHORITY', 'BUILTIN', 'NT SERVICE') {

                        Write-LogMsg @Log -Text " # '$($IdentityReference)' is a Capability SID or Service SID which could not be resolved to a friendly name."

                        $Known = Get-KnownSid -SID $SamAccountNameOrSid

                        $FakeDirectoryEntryParams = @{
                            DirectoryPath = "WinNT://$DomainNetBIOS/$SamAccountNameOrSid"
                            InputObject   = $Known
                        }

                        $DirectoryEntry = New-FakeDirectoryEntry @FakeDirectoryEntryParams

                    } else {

                        Write-LogMsg @Log -Text " # '$($IdentityReference)' is an unresolved SID"

                        # The SID of the domain is the SID of the user minus the last block of numbers
                        $DomainSid = $SamAccountNameOrSid.Substring(0, $SamAccountNameOrSid.LastIndexOf('-'))

                        # Determine if SID belongs to current domain
                        if ($DomainSid -eq $CurrentDomain.SIDString) {
                            Write-LogMsg @Log -Text " # '$($IdentityReference)' belongs to the current domain.  Could be a deleted user.  ?possibly a foreign security principal corresponding to an offline trusted domain or deleted user in the trusted domain?"
                        } else {
                            Write-LogMsg @Log -Text " # '$($IdentityReference)' does not belong to the current domain. Could be a local security principal or belong to an unresolvable domain."
                        }

                        # Lookup other information about the domain using its SID as the key
                        $DomainObject = $null
                        $TryGetValueResult = $Cache.Value['DomainBySid'].Value.TryGetValue($DomainSid, [ref]$DomainObject)

                        if ($TryGetValueResult) {

                            $DirectoryPath = "WinNT://$($DomainObject.Dns)/Users"
                            $DomainNetBIOS = $DomainObject.Netbios
                            $DomainDN = $DomainObject.DistinguishedName

                        } else {

                            $DirectoryPath = "WinNT://$DomainNetBIOS/Users"
                            $DomainDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -ThisFqdn $ThisFqdn @LogThis

                        }

                        Write-LogMsg @Log -Text "Get-DirectoryEntry -DirectoryPath '$DirectoryPath'" -Expand $DirectorySplat, $LogThis

                        try {
                            $UsersGroup = Get-DirectoryEntry -DirectoryPath $DirectoryPath @DirectorySplat @LogThis
                        } catch {

                            $Log['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
                            Write-LogMsg @Log -Text "Couldn't get '$($DirectoryPath)' using PSRemoting. Error: $_"
                            $Log['Type'] = $DebugOutputStream

                        }

                        $MembersOfUsersGroup = Get-WinNTGroupMember -DirectoryEntry $UsersGroup -ThisFqdn $ThisFqdn @LogThis

                        $DirectoryEntry = $MembersOfUsersGroup |
                        Where-Object -FilterScript {
                            ($SamAccountNameOrSid -eq $([System.Security.Principal.SecurityIdentifier]::new([byte[]]$_.Properties['objectSid'], 0)))
                        }

                    }

                } else {

                    Write-LogMsg @Log -Text " # '$IdentityReference' is a local security principal"
                    $DomainNetbiosCacheResult = $null
                    $TryGetValueResult = $Cache.Value['DomainByNetbios'].Value.TryGetValue($DomainNetBIOS, [ref]$DomainNetbiosCacheResult)

                    if ($TryGetValueResult) {
                        $DirectoryPath = "WinNT://$($DomainNetbiosCacheResult.Dns)/$SamAccountNameOrSid"
                    } else {
                        $DirectoryPath = "WinNT://$DomainNetBIOS/$SamAccountNameOrSid"
                    }

                    $DirectorySplat['PropertiesToLoad'] = @(
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

                    Write-LogMsg @Log -Text 'Get-DirectoryEntry' -Expand $DirectorySplat, $LogThis

                    try {
                        $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath @DirectorySplat @LogThis
                    } catch {

                        $Log['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
                        Write-LogMsg @Log -Text " # '$($DirectoryPath)' Couldn't be resolved for '$IdentityReference'. Error: $($_.Exception.Message.Trim())"
                        $Log['Type'] = $DebugOutputStream

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
                    Write-LogMsg @Log -Text " # '$($DirectoryEntry.Path)' is an LDAP security principal for '$IdentityReference'"
                    $Members = (Get-AdsiGroupMember -Group $DirectoryEntry -ThisFqdn $ThisFqdn @LogThis).FullMembers

                } else {

                    Write-LogMsg @Log -Text " # '$($DirectoryEntry.Path)' is a WinNT security principal for '$IdentityReference'"

                    if ( $DirectoryEntry.SchemaClassName -in @('group', 'SidTypeWellKnownGroup', 'SidTypeAlias')) {

                        Write-LogMsg @Log -Text " # '$($DirectoryEntry.Path)' is a WinNT group for '$IdentityReference'"
                        $Members = Get-WinNTGroupMember -DirectoryEntry $DirectoryEntry -ThisFqdn $ThisFqdn @LogThis

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
                        $null = $PrincipalById.Value.AddOrUpdate( $ResolvedAccountName , [PSCustomObject]$OutputProperties, $AddOrUpdateScriptblock )
                        $null = $AceGuidByID.Value.AddOrUpdate( $ResolvedAccountName , $AccessControlEntries, $AddOrUpdateScriptblock )
                        $ResolvedAccountName

                    }

                }

                Write-LogMsg @Log -Text " # '$($DirectoryEntry.Path)' has $(($Members | Measure-Object).Count) members for '$IdentityReference'"

            }

            $PropertiesToAdd['Members'] = $GroupMembers

        } else {

            $Log['Type'] = 'Verbose' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
            Write-LogMsg @Log -Text " # '$IdentityReference' Couldn't be matched to a DirectoryEntry"
            $Log['Type'] = $DebugOutputStream

        }

        $null = $PrincipalById.Value.AddOrUpdate( $IdentityReference , [PSCustomObject]$PropertiesToAdd, $AddOrUpdateScriptblock )

    }

}
