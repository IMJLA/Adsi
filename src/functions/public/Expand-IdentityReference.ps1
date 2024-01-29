function Expand-IdentityReference {
    <#
        .SYNOPSIS
        Use ADSI to collect more information about the IdentityReference in NTFS Access Control Entries
        .DESCRIPTION
        Recursively retrieves group members and detailed information about them
        Use caching to reduce duplicate directory queries
        .INPUTS
        [System.Object]$AccessControlEntry
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
        Expand-IdentityReference

        Incomplete example but it shows the chain of functions to generate the expected input for this
    #>
    [OutputType([System.Object])]
    param (

        # The NTFS AccessControlEntry object(s), grouped by their IdentityReference property
        # TODO: Use System.Security.Principal.NTAccount instead
        [Parameter(ValueFromPipeline)]
        [System.Object[]]$AccessControlEntry,

        # Do not get group members
        [switch]$NoGroupMembers,

        # Thread-safe hashtable to use for caching directory entries and avoiding duplicate directory queries
        [hashtable]$IdentityReferenceCache = ([hashtable]::Synchronized(@{})),

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
            Type         = 'Debug'
            LogMsgCache  = $LogMsgCache
            WhoAmI       = $WhoAmI
        }

        $LoggingParams = @{
            ThisHostname = $ThisHostname
            LogMsgCache  = $LogMsgCache
            WhoAmI       = $WhoAmI
        }

        #Write-LogMsg @LogParams -Text "$(($AccessControlEntry | Measure).Count) unique IdentityReferences found in the $(($AccessControlEntry | Measure).Count) ACEs"

        # Get the SID of the current domain
        $CurrentDomain = (Get-CurrentDomain)

        # Convert the objectSID attribute (byte array) to a security descriptor string formatted according to SDDL syntax (Security Descriptor Definition Language)
        [string]$CurrentDomainSID = & { [System.Security.Principal.SecurityIdentifier]::new([byte[]]$CurrentDomain.objectSid.Value, 0) } 2>$null

        #$i = 0

    }

    process {

        ForEach ($ThisIdentity in $AccessControlEntry) {

            if (-not $ThisIdentity) {
                continue
            }

            $ThisIdentityGroup = $ThisIdentity.Group

            #$i++
            #Calculate the completion percentage, and format it to show 0 decimal places
            #$percentage = "{0:N0}" -f (($i / ($AccessControlEntry.Count)) * 100)

            #Display the progress bar
            #$status = $percentage + "% - Using ADSI to get info on NTFS IdentityReference $i of " + $AccessControlEntry.Count + ": " + $ThisIdentity.Name
            #Write-LogMsg @LogParams -Text "Status: $status"

            #Write-Progress -Activity ("Unique IdentityReferences: " + $AccessControlEntry.Count) -Status $status -PercentComplete $percentage

            if ($null -eq $IdentityReferenceCache[$ThisIdentity.Name]) {

                Write-LogMsg @LogParams -Text " # IdentityReferenceCache miss for '$($ThisIdentity.Name)'"

                $DomainDN = $null
                $DirectoryEntry = $null
                $Members = $null
                $ObjectType = $null

                $GetDirectoryEntryParams = @{
                    DirectoryEntryCache = $DirectoryEntryCache
                    DomainsByNetbios    = $DomainsByNetbios
                    ThisHostname        = $ThisHostname
                    LogMsgCache         = $LogMsgCache
                    WhoAmI              = $WhoAmI
                }
                $SearchDirectoryParams = @{
                    DirectoryEntryCache = $DirectoryEntryCache
                    DomainsByNetbios    = $DomainsByNetbios
                    ThisHostname        = $ThisHostname
                    LogMsgCache         = $LogMsgCache
                    WhoAmI              = $WhoAmI
                }

                $StartingIdentityName = $ThisIdentity.Name
                $split = $StartingIdentityName.Split('\')
                $DomainNetBIOS = $split[0]
                $SamaccountnameOrSid = $split[1]

                if (
                    $null -ne $SamaccountnameOrSid -and
                    @($ThisIdentity.Group.AdsiProvider)[0] -eq 'LDAP'
                ) {
                    Write-LogMsg @LogParams -Text " # '$StartingIdentityName' is a domain security principal"

                    $DomainNetbiosCacheResult = $DomainsByNetbios[$DomainNetBIOS]
                    if ($DomainNetbiosCacheResult) {
                        Write-LogMsg @LogParams -Text " # Domain NetBIOS cache hit for '$DomainNetBIOS' for '$StartingIdentityName'"
                        $DomainDn = $DomainNetbiosCacheResult.DistinguishedName
                        $SearchDirectoryParams['DirectoryPath'] = "LDAP://$($DomainNetbiosCacheResult.Dns)/$DomainDn"
                    } else {
                        Write-LogMsg @LogParams -Text " # Domain NetBIOS cache miss for '$DomainNetBIOS' for '$StartingIdentityName'"
                        if ( -not [string]::IsNullOrEmpty($DomainNetBIOS) ) {
                            $DomainDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -DomainsByNetbios $DomainsByNetbios @LoggingParams
                        }
                        $SearchDirectoryParams['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath "LDAP://$DomainNetBIOS" -ThisFqdn $ThisFqdn @LogParams
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
                        Write-LogMsg @LogParams -Type Warning -Text " # '$StartingIdentityName' could not be resolved against its directory"
                        Write-LogMsg @LogParams -Type Warning -Text " # $($_.Exception.Message) for '$StartingIdentityName"
                    }

                } elseif (
                    $StartingIdentityName.Substring(0, $StartingIdentityName.LastIndexOf('-') + 1) -eq $CurrentDomainSID
                ) {
                    Write-LogMsg @LogParams -Text " # '$StartingIdentityName' is an unresolved SID from the current domain"

                    # Get the distinguishedName and netBIOSName of the current domain.  This also determines whether the domain is online.
                    $DomainDN = $CurrentDomain.distinguishedName.Value
                    $DomainFQDN = ConvertTo-Fqdn -DistinguishedName $DomainDN -ThisFqdn $ThisFqdn @LoggingParams

                    $SearchDirectoryParams['DirectoryPath'] = "LDAP://$DomainFQDN/cn=partitions,cn=configuration,$DomainDn"
                    $SearchDirectoryParams['Filter'] = "(&(objectcategory=crossref)(dnsroot=$DomainFQDN)(netbiosname=*))"
                    $SearchDirectoryParams['PropertiesToLoad'] = 'netbiosname'

                    $DomainCrossReference = Search-Directory @SearchDirectoryParams
                    if ($DomainCrossReference.Properties ) {
                        Write-LogMsg @LogParams -Text " # The domain '$DomainFQDN' is online for '$StartingIdentityName'"
                        [string]$DomainNetBIOS = $DomainCrossReference.Properties['netbiosname']
                        # TODO: The domain is online, so let's see if any domain trusts have issues?  Determine if SID is foreign security principal?
                        # TODO: What if the foreign security principal exists but the corresponding domain trust is down?  Don't want to recommend deletion of the ACE in that case.
                    }
                    $SidObject = [System.Security.Principal.SecurityIdentifier]::new($StartingIdentityName)
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
                        Write-LogMsg @LogParams -Type Warning -Text " # '$StartingIdentityName' could not be resolved against its directory"
                        Write-LogMsg @LogParams -Type Warning -Text " # $($_.Exception.Message) for '$StartingIdentityName'"
                    }

                } else {

                    Write-LogMsg @LogParams -Text " # '$StartingIdentityName' is a local security principal or unresolved SID"

                    if ($null -eq $SamaccountnameOrSid) { $SamaccountnameOrSid = $StartingIdentityName }

                    if ($SamaccountnameOrSid -like "S-1-*") {

                        Write-LogMsg @LogParams -Text "$($StartingIdentityName) is an unresolved SID"

                        # The SID of the domain is the SID of the user minus the last block of numbers
                        $DomainSid = $SamaccountnameOrSid.Substring(0, $SamaccountnameOrSid.LastIndexOf("-"))

                        # Determine if SID belongs to current domain
                        if ($DomainSid -eq $CurrentDomainSID) {
                            Write-LogMsg @LogParams -Text "$($StartingIdentityName) belongs to the current domain.  Could be a deleted user.  ?possibly a foreign security principal corresponding to an offline trusted domain or deleted user in the trusted domain?"
                        } else {
                            Write-LogMsg @LogParams -Text "$($StartingIdentityName) does not belong to the current domain. Could be a local security principal or belong to an unresolvable domain."
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
                            Write-LogMsg @LogParams -Type Warning -Text "Could not get '$($GetDirectoryEntryParams['DirectoryPath'])' using PSRemoting"
                            Write-LogMsg @LogParams -Type Warning -Text "$_"
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

                        $ThisIdentity = [pscustomobject]@{
                            Count = $(($ThisIdentityGroup | Measure-Object).Count)
                            Name  = "$DomainNetBIOS\" + $AccountName
                            Group = $ThisIdentityGroup
                            # Unclear why this was filtered so I have removed it to see what happens
                            #Group = $ThisIdentityGroup | Where-Object -FilterScript { ($_.SourceAccessList.Path -split '\\')[2] -eq $DomainNetBIOS } # Should be already Resolved to a UNC path so it reflects the server name
                        }

                    } else {
                        Write-LogMsg @LogParams -Text " # '$StartingIdentityName' is a local security principal"
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
                            Write-LogMsg @LogParams -Type Warning -Text " # '$($GetDirectoryEntryParams['DirectoryPath'])' could not be resolved for '$StartingIdentityName'. Error: $($_.Exception.Message.Trim())"
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
                            Write-LogMsg @LogParams -Text " # '$($DirectoryEntry.Path)' is an LDAP security principal for '$StartingIdentityName'"
                            $Members = (Get-AdsiGroupMember -Group $DirectoryEntry -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LoggingParams).FullMembers
                        } else {
                            # Retrieve the members of groups from the WinNT provider
                            Write-LogMsg @LogParams -Text " # '$($DirectoryEntry.Path)' is a WinNT security principal for '$StartingIdentityName'"
                            if ( $DirectoryEntry.SchemaClassName -eq 'group') {
                                Write-LogMsg @LogParams -Text " # '$($DirectoryEntry.Path)' is a WinNT group for '$StartingIdentityName'"
                                $Members = Get-WinNTGroupMember -DirectoryEntry $DirectoryEntry -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LoggingParams
                            }
                        }

                        # (Get-AdsiGroupMember).FullMembers or Get-WinNTGroupMember could return an array with null members so we must verify that is not true
                        if ($Members) {
                            $Members |
                            ForEach-Object {

                                if ($_.Domain) {

                                    Add-Member -InputObject $_ -Force -NotePropertyMembers @{
                                        Group = $ThisIdentityGroup
                                    }

                                } else {

                                    Add-Member -InputObject $_ -Force -NotePropertyMembers @{
                                        Group  = $ThisIdentityGroup
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
                        Write-LogMsg @LogParams -Text " # $($DirectoryEntry.Path) has $(($Members | Measure-Object).Count) members for '$StartingIdentityName'"

                    }
                } else {
                    Write-LogMsg @LogParams -Type Warning -Text " # '$StartingIdentityName' could not be matched to a DirectoryEntry"
                }

                Add-Member -InputObject $ThisIdentity -Force -NotePropertyMembers $PropertiesToAdd
                $IdentityReferenceCache[$StartingIdentityName] = $ThisIdentity

            } else {
                Write-LogMsg @LogParams -Text " # IdentityReferenceCache hit for '$($ThisIdentity.Name)'"
                $null = $IdentityReferenceCache[$ThisIdentity.Name].Group.Add($ThisIdentityGroup)
                $ThisIdentity = $IdentityReferenceCache[$ThisIdentity.Name]
            }

            $ThisIdentity

        }

    }

}
