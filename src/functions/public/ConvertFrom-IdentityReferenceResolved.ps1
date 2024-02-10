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
    [OutputType([System.Object])]
    param (

        # The NTFS AccessControlEntry object(s), grouped by their IdentityReference property
        # TODO: Use System.Security.Principal.NTAccount instead
        [Parameter(ValueFromPipeline)]
        [System.Object[]]$IdentityReference,

        # Do not get group members
        [switch]$NoGroupMembers,

        # Cache of access control entries keyed by their resolved identities
        [hashtable]$ACEbyResolvedIDCache = ([hashtable]::Synchronized(@{})),

        # Thread-safe hashtable to use for caching directory entries and avoiding duplicate directory queries
        [hashtable]$IdentityReferenceCache = ([hashtable]::Synchronized(@{})),

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
        [hashtable]$LogMsgCache = $Global:LogMessages

    )

    begin {

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

        # Get the SID of the current domain. TODO: THIS SHOULD BE PASSED IN AS A PARAMETER ALL THE WAY FROM THE PARENT SCRIPT (EXPORT-PERMISSION)
        Write-LogMsg @LogParams -Text '$CurrentDomain = Get-CurrentDomain'
        $CurrentDomain = Get-CurrentDomain -ComputerName $ThisFqdn -CimCache $CimCache -DebugOutputStream $DebugOutputStream -ThisFqdn $ThisFqdn @LoggingParams

        # Convert the objectSID attribute (byte array) to a security descriptor string formatted according to SDDL syntax (Security Descriptor Definition Language)
        Write-LogMsg @LogParams -Text '[System.Security.Principal.SecurityIdentifier]::new([byte[]]$CurrentDomain.objectSid.Value, 0)'
        [string]$CurrentDomainSID = & { [System.Security.Principal.SecurityIdentifier]::new([byte[]]$CurrentDomain.objectSid.Value, 0) } 2>$null

    }

    process {

        ForEach ($ResolvedIdentityReferenceString in $IdentityReference) {

            $AccessControlEntries = $ACEbyResolvedIDCache[$ResolvedIdentityReferenceString]

            # Why is this needed?  Do not uncomment without adding comment indicating purpose.  Not expecting null objects, want to improve performance by skipping this check.
            if (-not $AccessControlEntries) {
                continue
            }

            if ($null -eq $IdentityReferenceCache[$ResolvedIdentityReferenceString]) {

                Write-LogMsg @LogParams -Text " # IdentityReferenceCache miss for '$ResolvedIdentityReferenceString'"

                $DomainDN = $null
                $DirectoryEntry = $null
                $Members = $null

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

                $split = $ResolvedIdentityReferenceString.Split('\')
                $DomainNetBIOS = $split[0]
                $SamaccountnameOrSid = $split[1]

                if (
                    $null -ne $SamaccountnameOrSid -and
                    @($AccessControlEntries.AdsiProvider)[0] -eq 'LDAP'
                ) {
                    Write-LogMsg @LogParams -Text " # '$ResolvedIdentityReferenceString' is a domain security principal"

                    $DomainNetbiosCacheResult = $DomainsByNetbios[$DomainNetBIOS]
                    if ($DomainNetbiosCacheResult) {
                        Write-LogMsg @LogParams -Text " # Domain NetBIOS cache hit for '$DomainNetBIOS' for '$ResolvedIdentityReferenceString'"
                        $DomainDn = $DomainNetbiosCacheResult.DistinguishedName
                        $SearchDirectoryParams['DirectoryPath'] = "LDAP://$($DomainNetbiosCacheResult.Dns)/$DomainDn"
                    } else {
                        Write-LogMsg @LogParams -Text " # Domain NetBIOS cache miss for '$DomainNetBIOS' for '$ResolvedIdentityReferenceString'"
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
                        Write-LogMsg @LogParams -Text " # '$ResolvedIdentityReferenceString' could not be resolved against its directory: $($_.Exception.Message)"
                        $LogParams['Type'] = $DebugOutputStream
                    }

                } elseif (
                    $ResolvedIdentityReferenceString.Substring(0, $ResolvedIdentityReferenceString.LastIndexOf('-') + 1) -eq $CurrentDomainSID
                ) {
                    Write-LogMsg @LogParams -Text " # '$ResolvedIdentityReferenceString' is an unresolved SID from the current domain"

                    # Get the distinguishedName and netBIOSName of the current domain.  This also determines whether the domain is online.
                    $DomainDN = $CurrentDomain.distinguishedName.Value
                    $DomainFQDN = ConvertTo-Fqdn -DistinguishedName $DomainDN -ThisFqdn $ThisFqdn -CimCache $CimCache @LoggingParams

                    $SearchDirectoryParams['DirectoryPath'] = "LDAP://$DomainFQDN/cn=partitions,cn=configuration,$DomainDn"
                    $SearchDirectoryParams['Filter'] = "(&(objectcategory=crossref)(dnsroot=$DomainFQDN)(netbiosname=*))"
                    $SearchDirectoryParams['PropertiesToLoad'] = 'netbiosname'

                    $DomainCrossReference = Search-Directory @SearchDirectoryParams
                    if ($DomainCrossReference.Properties ) {
                        Write-LogMsg @LogParams -Text " # The domain '$DomainFQDN' is online for '$ResolvedIdentityReferenceString'"
                        [string]$DomainNetBIOS = $DomainCrossReference.Properties['netbiosname']
                        # TODO: The domain is online, so let's see if any domain trusts have issues?  Determine if SID is foreign security principal?
                        # TODO: What if the foreign security principal exists but the corresponding domain trust is down?  Don't want to recommend deletion of the ACE in that case.
                    }
                    $SidObject = [System.Security.Principal.SecurityIdentifier]::new($ResolvedIdentityReferenceString)
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
                        Write-LogMsg @LogParams -Text " # '$ResolvedIdentityReferenceString' could not be resolved against its directory. Error: $($_.Exception.Message.Trim())"
                        $LogParams['Type'] = $DebugOutputStream
                    }

                } else {

                    Write-LogMsg @LogParams -Text " # '$ResolvedIdentityReferenceString' is a local security principal or unresolved SID"

                    if ($null -eq $SamaccountnameOrSid) { $SamaccountnameOrSid = $ResolvedIdentityReferenceString }

                    if ($SamaccountnameOrSid -like "S-1-*") {

                        Write-LogMsg @LogParams -Text "$($ResolvedIdentityReferenceString) is an unresolved SID"

                        # The SID of the domain is the SID of the user minus the last block of numbers
                        $DomainSid = $SamaccountnameOrSid.Substring(0, $SamaccountnameOrSid.LastIndexOf("-"))

                        # Determine if SID belongs to current domain
                        if ($DomainSid -eq $CurrentDomainSID) {
                            Write-LogMsg @LogParams -Text "$($ResolvedIdentityReferenceString) belongs to the current domain.  Could be a deleted user.  ?possibly a foreign security principal corresponding to an offline trusted domain or deleted user in the trusted domain?"
                        } else {
                            Write-LogMsg @LogParams -Text "$($ResolvedIdentityReferenceString) does not belong to the current domain. Could be a local security principal or belong to an unresolvable domain."
                        }

                        # Lookup other information about the domain using its SID as the key
                        $DomainObject = $DomainsBySID[$DomainSid]
                        if ($DomainObject) {
                            $GetDirectoryEntryParams['DirectoryPath'] = "WinNT://$($DomainObject.Dns)/Users,group"
                            $DomainNetBIOS = $DomainObject.Netbios
                        } else {
                            $GetDirectoryEntryParams['DirectoryPath'] = "WinNT://$DomainNetBIOS/Users,group"
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

                        $AccessControlEntries = [pscustomobject]@{
                            Count = $AccessControlEntries.Count
                            Name  = "$DomainNetBIOS\" + $AccountName
                            Group = $AccessControlEntries
                            # Unclear why this was filtered so I have removed it to see what happens
                            #Group = $AccessControlEntries | Where-Object -FilterScript { ($_.SourceAccessList.Path -split '\\')[2] -eq $DomainNetBIOS } # Should be already Resolved to a UNC path so it reflects the server name
                        }

                    } else {
                        Write-LogMsg @LogParams -Text " # '$ResolvedIdentityReferenceString' is a local security principal"
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
                            Write-LogMsg @LogParams -Text " # '$($GetDirectoryEntryParams['DirectoryPath'])' could not be resolved for '$ResolvedIdentityReferenceString'. Error: $($_.Exception.Message.Trim())"
                            $LogParams['Type'] = $DebugOutputStream
                        }
                    }
                }

                $PropertiesToAdd = @{
                    DomainDn       = $DomainDn
                    DomainNetbios  = $DomainNetBIOS
                    DirectoryEntry = $DirectoryEntry
                }
                if ($null -ne $DirectoryEntry) {

                    # WinNT objects have a SchemaClassName property which is a string
                    # LDAP objects have an objectClass property which is an ordered list of strings, the last being the class name of the object instance
                    # ToDo: LDAP objects may have SchemaClassName too.  When/why?  Should I just request it always in the list of properties?
                    if (-not $DirectoryEntry.SchemaClassName) {
                        $PropertiesToAdd['SchemaClassName'] = @($DirectoryEntry.Properties['objectClass'])[-1] #untested but should work, last value should be the correct one https://learn.microsoft.com/en-us/windows/win32/ad/retrieving-the-objectclass-property
                    }

                    if ($NoGroupMembers -eq $false) {

                        if (
                            # WinNT DirectoryEntries do not contain an objectClass property
                            # If this property exists it is an LDAP DirectoryEntry rather than WinNT
                            $PropertiesToAdd['SchemaClassName'] -eq 'group'
                        ) {
                            # Retrieve the members of groups from the LDAP provider
                            Write-LogMsg @LogParams -Text " # '$($DirectoryEntry.Path)' is an LDAP security principal for '$ResolvedIdentityReferenceString'"
                            $Members = (Get-AdsiGroupMember -Group $DirectoryEntry -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LoggingParams).FullMembers
                        } else {
                            # Retrieve the members of groups from the WinNT provider
                            Write-LogMsg @LogParams -Text " # '$($DirectoryEntry.Path)' is a WinNT security principal for '$ResolvedIdentityReferenceString'"
                            if ( $DirectoryEntry.SchemaClassName -eq 'group') {
                                Write-LogMsg @LogParams -Text " # '$($DirectoryEntry.Path)' is a WinNT group for '$ResolvedIdentityReferenceString'"
                                $Members = Get-WinNTGroupMember -DirectoryEntry $DirectoryEntry -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LoggingParams
                            }
                        }

                        # (Get-AdsiGroupMember).FullMembers or Get-WinNTGroupMember could return an array with null members so we must verify that is not true
                        if ($Members) {
                            $Members |
                            ForEach-Object {

                                if ($_.Domain) {

                                    Add-Member -InputObject $_ -Force -NotePropertyMembers @{
                                        Group = $AccessControlEntries
                                    }

                                } else {

                                    Add-Member -InputObject $_ -Force -NotePropertyMembers @{
                                        Group  = $AccessControlEntries
                                        Domain = [pscustomobject]@{
                                            Dns     = $DomainNetBIOS
                                            Netbios = $DomainNetBIOS
                                            Sid     = ($SamaccountnameOrSid -split '-') | Select-Object -Last 1
                                        }
                                    }

                                }
                            }
                        }

                        $PropertiesToAdd['Members'] = $Members
                        Write-LogMsg @LogParams -Text " # $($DirectoryEntry.Path) has $(($Members | Measure-Object).Count) members for '$ResolvedIdentityReferenceString'"

                    }
                } else {
                    $LogParams['Type'] = 'Warning' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat
                    Write-LogMsg @LogParams -Text " # '$ResolvedIdentityReferenceString' could not be matched to a DirectoryEntry"
                    $LogParams['Type'] = $DebugOutputStream
                }

                Add-Member -InputObject $AccessControlEntries -Force -NotePropertyMembers $PropertiesToAdd
                $IdentityReferenceCache[$ResolvedIdentityReferenceString] = $AccessControlEntries

            } else {
                Write-LogMsg @LogParams -Text " # IdentityReferenceCache hit for '$ResolvedIdentityReferenceString'"
                $null = $IdentityReferenceCache[$ResolvedIdentityReferenceString].Add($AccessControlEntries)
                $AccessControlEntries = $IdentityReferenceCache[$ResolvedIdentityReferenceString]
            }

            $AccessControlEntries

        }

    }

}
