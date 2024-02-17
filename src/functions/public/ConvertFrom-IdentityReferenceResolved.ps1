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
        [hashtable]$PrincipalsByResolvedID = ([hashtable]::Synchronized(@{})),

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

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # The current domain
        # Can be passed as a parameter to reduce calls to Get-CurrentDomain
        [string]$CurrentDomain = (Get-CurrentDomain)

    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    $LoggingParams = @{
        ThisHostname = $ThisHostname
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    $AccessControlEntries = $ACEsByResolvedID[$IdentityReference]

    if ($null -eq $PrincipalsByResolvedID[$IdentityReference]) {

        Write-LogMsg @LogParams -Text " # ADSI Principal cache miss for '$IdentityReference'"

        $GetDirectoryEntryParams = @{
            DirectoryEntryCache = $DirectoryEntryCache
            DomainsByNetbios    = $DomainsByNetbios
            ThisFqdn            = $ThisFqdn
            ThisHostname        = $ThisHostname
            CimCache            = $CimCache
            LogMsgCache         = $LogMsgCache
            WhoAmI              = $WhoAmI
            DebugOutputStream   = $DebugOutputStream
        }

        $SearchDirectoryParams = @{
            CimCache            = $CimCache
            DebugOutputStream   = $DebugOutputStream
            DirectoryEntryCache = $DirectoryEntryCache
            DomainsByNetbios    = $DomainsByNetbios
            LogMsgCache         = $LogMsgCache
            ThisFqdn            = $ThisFqdn
            ThisHostname        = $ThisHostname
            WhoAmI              = $WhoAmI
        }

        $split = $IdentityReference.Split('\')
        $DomainNetBIOS = $split[0]
        $SamaccountnameOrSid = $split[1]

        if (
            $null -ne $SamaccountnameOrSid -and
            @($AccessControlEntries.AdsiProvider)[0] -eq 'LDAP'
        ) {
            Write-LogMsg @LogParams -Text " # '$IdentityReference' is a domain security principal"

            $DomainNetbiosCacheResult = $DomainsByNetbios[$DomainNetBIOS]
            if ($DomainNetbiosCacheResult) {
                Write-LogMsg @LogParams -Text " # Domain NetBIOS cache hit for '$DomainNetBIOS' for '$IdentityReference'"
                $DomainDn = $DomainNetbiosCacheResult.DistinguishedName
                $SearchDirectoryParams['DirectoryPath'] = "LDAP://$($DomainNetbiosCacheResult.Dns)/$DomainDn"
            } else {
                Write-LogMsg @LogParams -Text " # Domain NetBIOS cache miss for '$DomainNetBIOS' for '$IdentityReference'"
                if ( -not [string]::IsNullOrEmpty($DomainNetBIOS) ) {
                    $DomainDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -DomainsByNetbios $DomainsByNetbios @LoggingParams
                }
                $SearchDirectoryParams['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath "LDAP://$DomainNetBIOS" -ThisFqdn $ThisFqdn -CimCache $CimCache @LogParams
            }

            # Search the domain for the principal
            $SearchDirectoryParams['Filter'] = "(samaccountname=$SamaccountnameOrSid)"
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
            try {
                $DirectoryEntry = Search-Directory @SearchDirectoryParams
            } catch {
                $LogParams['Type'] = 'Warning' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat
                Write-LogMsg @LogParams -Text " # '$IdentityReference' could not be resolved against its directory: $($_.Exception.Message)"
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

            $DomainCrossReference = Search-Directory @SearchDirectoryParams
            if ($DomainCrossReference.Properties ) {
                Write-LogMsg @LogParams -Text " # The domain '$DomainFQDN' is online for '$IdentityReference'"
                [string]$DomainNetBIOS = $DomainCrossReference.Properties['netbiosname']
                # TODO: The domain is online, so let's see if any domain trusts have issues?  Determine if SID is foreign security principal?
                # TODO: What if the foreign security principal exists but the corresponding domain trust is down?  Don't want to recommend deletion of the ACE in that case.
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
            try {
                $DirectoryEntry = Search-Directory @SearchDirectoryParams
            } catch {
                $LogParams['Type'] = 'Warning' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat
                Write-LogMsg @LogParams -Text " # '$IdentityReference' could not be resolved against its directory. Error: $($_.Exception.Message.Trim())"
                $LogParams['Type'] = $DebugOutputStream
            }

        } else {

            Write-LogMsg @LogParams -Text " # '$IdentityReference' is a local security principal or unresolved SID"

            if ($null -eq $SamaccountnameOrSid) { $SamaccountnameOrSid = $IdentityReference }

            if ($SamaccountnameOrSid -like "S-1-*") {

                Write-LogMsg @LogParams -Text "$($IdentityReference) is an unresolved SID"

                # The SID of the domain is the SID of the user minus the last block of numbers
                $DomainSid = $SamaccountnameOrSid.Substring(0, $SamaccountnameOrSid.LastIndexOf("-"))

                # Determine if SID belongs to current domain
                if ($DomainSid -eq $CurrentDomain.SIDString) {
                    Write-LogMsg @LogParams -Text "$($IdentityReference) belongs to the current domain.  Could be a deleted user.  ?possibly a foreign security principal corresponding to an offline trusted domain or deleted user in the trusted domain?"
                } else {
                    Write-LogMsg @LogParams -Text "$($IdentityReference) does not belong to the current domain. Could be a local security principal or belong to an unresolvable domain."
                }

                # Lookup other information about the domain using its SID as the key
                $DomainObject = $DomainsBySID[$DomainSid]

                if ($DomainObject) {
                    $GetDirectoryEntryParams['DirectoryPath'] = "WinNT://$($DomainObject.Dns)/Users,group"
                    $DomainNetBIOS = $DomainObject.Netbios
                    $DomainDN = $DomainObject.DistinguishedName
                } else {
                    $GetDirectoryEntryParams['DirectoryPath'] = "WinNT://$DomainNetBIOS/Users,group"
                    $DomainDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -DomainsByNetbios $DomainsByNetbios @LoggingParams
                }

                try {
                    $UsersGroup = Get-DirectoryEntry @GetDirectoryEntryParams
                } catch {
                    $LogParams['Type'] = 'Warning' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat
                    Write-LogMsg @LogParams -Text "Could not get '$($GetDirectoryEntryParams['DirectoryPath'])' using PSRemoting. Error: $_"
                    $LogParams['Type'] = $DebugOutputStream
                }

                $MembersOfUsersGroup = Get-WinNTGroupMember -DirectoryEntry $UsersGroup -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LoggingParams

                $DirectoryEntry = $MembersOfUsersGroup |
                Where-Object -FilterScript { ($SamaccountnameOrSid -eq [System.Security.Principal.SecurityIdentifier]::new([byte[]]$_.Properties['objectSid'].Value, 0)) }

            } else {

                Write-LogMsg @LogParams -Text " # '$IdentityReference' is a local security principal"
                $DomainNetbiosCacheResult = $DomainsByNetbios[$DomainNetBIOS]

                if ($DomainNetbiosCacheResult) {
                    $GetDirectoryEntryParams['DirectoryPath'] = "WinNT://$($DomainNetbiosCacheResult.Dns)/$SamaccountnameOrSid"
                } else {
                    $GetDirectoryEntryParams['DirectoryPath'] = "WinNT://$DomainNetBIOS/$SamaccountnameOrSid"
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

                try {
                    $DirectoryEntry = Get-DirectoryEntry @GetDirectoryEntryParams
                } catch {
                    $LogParams['Type'] = 'Warning' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat
                    Write-LogMsg @LogParams -Text " # '$($GetDirectoryEntryParams['DirectoryPath'])' could not be resolved for '$IdentityReference'. Error: $($_.Exception.Message.Trim())"
                    $LogParams['Type'] = $DebugOutputStream
                }

            }

        }

        $PropertiesToAdd = @{
            DomainDn      = $DomainDn
            DomainNetbios = $DomainNetBIOS
        }        

        if ($null -ne $DirectoryEntry) {
            
            ForEach ($Prop in ($DirectoryEntry | Get-Member -View All -MemberType Property).Name) {
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
                    # Retrieve the members of groups from the WinNT provider
                    Write-LogMsg @LogParams -Text " # '$($DirectoryEntry.Path)' is a WinNT security principal for '$IdentityReference'"
                    if ( $DirectoryEntry.SchemaClassName -eq 'group') {
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
                                    Sid     = @($SamaccountnameOrSid -split '-')[-1]
                                }
                            }

                        }

                        # Get any existing properties for inclusion later
                        $InputProperties = (Get-Member -InputObject $ThisMember -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name

                        # Include any existing properties found earlier
                        ForEach ($ThisProperty in $InputProperties) {
                            $OutputProperties[$ThisProperty] = $ThisMember.$ThisProperty
                        }

                        if ($ThisMember.sAmAccountName) {
                            $ResolvedAccountName = "$($OutputProperties['Domain'].Netbios)\$($ThisMember.sAmAccountName)"
                        } else {
                            $ResolvedAccountName = "$($OutputProperties['Domain'].Netbios)\$($ThisMember.Name)"
                        }

                        $OutputProperties['ResolvedAccountName'] = $ResolvedAccountName
                        $PrincipalsByResolvedID[$ResolvedAccountName] = [PSCustomObject]$OutputProperties
                        $ACEsByResolvedID[$ResolvedAccountName] = $AccessControlEntries
                        $ResolvedAccountName

                    }

                }

            }

            $PropertiesToAdd['Members'] = $GroupMembers
            Write-LogMsg @LogParams -Text " # '$($DirectoryEntry.Path)' has $(($Members | Measure-Object).Count) members for '$IdentityReference'"

        } else {

            $LogParams['Type'] = 'Warning' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat
            Write-LogMsg @LogParams -Text " # '$IdentityReference' could not be matched to a DirectoryEntry"
            $LogParams['Type'] = $DebugOutputStream

        }

        $PrincipalsByResolvedID[$IdentityReference] = [PSCustomObject]$PropertiesToAdd

    }

}
