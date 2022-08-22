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
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{}))

    )

    begin {

        #Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$(($AccessControlEntry | Measure).Count) unique IdentityReferences found in the $(($AccessControlEntry | Measure).Count) ACEs"

        # Get the SID of the current domain
        $CurrentDomain = (Get-CurrentDomain)

        # Convert the objectSID attribute (byte array) to a security descriptor string formatted according to SDDL syntax (Security Descriptor Definition Language)
        [string]$CurrentDomainSID = & { [System.Security.Principal.SecurityIdentifier]::new([byte[]]$CurrentDomain.objectSid.Value, 0) } 2>$null

        #$i = 0

    }

    process {

        ForEach ($ThisIdentity in $AccessControlEntry) {

            $ThisIdentityGroup = $ThisIdentity.Group

            #$i++
            #Calculate the completion percentage, and format it to show 0 decimal places
            #$percentage = "{0:N0}" -f (($i / ($AccessControlEntry.Count)) * 100)

            #Display the progress bar
            #$status = $percentage + "% - Using ADSI to get info on NTFS IdentityReference $i of " + $AccessControlEntry.Count + ": " + $ThisIdentity.Name
            #Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`tStatus: $status"

            #Write-Progress -Activity ("Unique IdentityReferences: " + $AccessControlEntry.Count) -Status $status -PercentComplete $percentage

            if ($null -eq $IdentityReferenceCache[$ThisIdentity.Name]) {

                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # IdentityReferenceCache miss for '$($ThisIdentity.Name)'"

                $DomainDN = $null
                $DirectoryEntry = $null
                $Members = $null

                $GetDirectoryEntryParams = @{
                    DirectoryEntryCache = $DirectoryEntryCache
                    DomainsByNetbios    = $DomainsByNetbios
                }
                $SearchDirectoryParams = @{
                    DirectoryEntryCache = $DirectoryEntryCache
                    DomainsByNetbios    = $DomainsByNetbios
                }

                $StartingIdentityName = $ThisIdentity.Name
                $split = $StartingIdentityName.Split('\')
                $domainNetbiosString = $split[0]
                $name = $split[1]

                if (
                    $null -ne $name -and
                    ($ThisIdentity.Group.AdsiProvider | Select-Object -First 1) -eq 'LDAP'
                ) {
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # '$StartingIdentityName' is a domain security principal"

                    $DomainNetbiosCacheResult = $DomainsByNetbios[$domainNetbiosString]
                    if ($DomainNetbiosCacheResult) {
                        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # Domain NetBIOS cache hit for '$domainNetbiosString' for '$StartingIdentityName'"
                        $DomainDn = $DomainNetbiosCacheResult.DistinguishedName
                        $SearchDirectoryParams['DirectoryPath'] = "LDAP://$($DomainNetbiosCacheResult.Dns)/$DomainDn"
                    } else {
                        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # Domain NetBIOS cache miss for '$domainNetbiosString' for '$StartingIdentityName'"
                        if ( -not [string]::IsNullOrEmpty($domainNetbiosString) ) {
                            $DomainDn = ConvertTo-DistinguishedName -Domain $domainNetbiosString -DomainsByNetbios $DomainsByNetbios
                        }
                        $SearchDirectoryParams['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath "LDAP://$domainNetbiosString"
                    }

                    # Search the domain for the principal
                    $SearchDirectoryParams['Filter'] = "(samaccountname=$Name)"
                    $SearchDirectoryParams['PropertiesToLoad'] = @(
                        'objectClass',
                        'distinguishedName',
                        'name',
                        'grouptype',
                        'description',
                        'managedby',
                        'member',
                        'objectClass',
                        'Department',
                        'Title'
                    )
                    try {
                        $DirectoryEntry = Search-Directory @SearchDirectoryParams
                    } catch {
                        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # '$StartingIdentityName' could not be resolved against its directory"
                        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # $($_.Exception.Message) for '$StartingIdentityName"
                    }

                } elseif (((($StartingIdentityName -split '-') | Select-Object -SkipLast 1) -join '-') -eq $CurrentDomainSID) {
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # '$StartingIdentityName' is an unresolved SID from the current domain"

                    # Get the distinguishedName and netBIOSName of the current domain.  This also determines whether the domain is online.
                    $DomainDN = $CurrentDomain.distinguishedName.Value
                    $DomainFQDN = ConvertTo-Fqdn -DistinguishedName $DomainDN

                    $SearchDirectoryParams['DirectoryPath'] = "LDAP://$DomainFQDN/cn=partitions,cn=configuration,$DomainDn"
                    $SearchDirectoryParams['Filter'] = "(&(objectcategory=crossref)(dnsroot=$DomainFQDN)(netbiosname=*))"
                    $SearchDirectoryParams['PropertiesToLoad'] = 'netbiosname'

                    $DomainCrossReference = Search-Directory @SearchDirectoryParams
                    if ($DomainCrossReference.Properties ) {
                        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t# The domain '$DomainFQDN' is online for '$StartingIdentityName'"
                        [string]$domainNetbiosString = $DomainCrossReference.Properties['netbiosname']
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
                        'distinguishedName',
                        'name',
                        'grouptype',
                        'description',
                        'managedby',
                        'member',
                        'objectClass',
                        'Department',
                        'Title'
                    )
                    try {
                        $DirectoryEntry = Search-Directory @SearchDirectoryParams
                    } catch {
                        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # '$StartingIdentityName' could not be resolved against its directory"
                        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # $($_.Exception.Message) for '$StartingIdentityName'"
                    }


                } else {

                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # '$StartingIdentityName' is a local security principal or unresolved SID"

                    if ($null -eq $name) { $name = $StartingIdentityName }

                    if ($name -like "S-1-*") {
                        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) is an unresolved SID"

                        # The SID of the domain is the SID of the user minus the last block of numbers
                        $DomainSid = $name.Substring(0, $name.LastIndexOf("-"))

                        # Determine if SID belongs to current domain
                        if ($DomainSid -eq $CurrentDomainSID) {
                            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) belongs to the current domain.  Could be a deleted user.  ?possibly a foreign security principal corresponding to an offline trusted domain or deleted user in the trusted domain?"
                        } else {
                            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) does not belong to the current domain. Could be a local security principal or belong to an unresolvable domain."
                        }

                        # Lookup other information about the domain using its SID as the key
                        $DomainObject = $DomainsBySID[$DomainSid]
                        if ($DomainObject) {
                            $GetDirectoryEntryParams['DirectoryPath'] = "WinNT://$($DomainObject.Dns)/Users,group"
                            $domainNetbiosString = $DomainObject.Netbios
                        } else {
                            $GetDirectoryEntryParams['DirectoryPath'] = "WinNT://$domainNetbiosString/Users,group"
                        }

                        try {
                            $UsersGroup = Get-DirectoryEntry @GetDirectoryEntryParams
                        } catch {
                            Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`tCould not get '$($GetDirectoryEntryParams['DirectoryPath'])' using PSRemoting"
                            Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$_"
                        }
                        $MembersOfUsersGroup = Get-WinNTGroupMember -DirectoryEntry $UsersGroup -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid

                        $DirectoryEntry = $MembersOfUsersGroup |
                        Where-Object -FilterScript { ($name -eq [System.Security.Principal.SecurityIdentifier]::new([byte[]]$_.Properties['objectSid'].Value, 0)) }

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
                            Name  = "$domainNetbiosString\" + $AccountName
                            Group = $ThisIdentityGroup
                            # Unclear why this was filtered so I have removed it to see what happens
                            #Group = $ThisIdentityGroup | Where-Object -FilterScript { ($_.SourceAccessList.Path -split '\\')[2] -eq $domainNetbiosString } # Should be already Resolved to a UNC path so it reflects the server name
                        }

                    } else {
                        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # '$StartingIdentityName' is a local security principal"
                        $DomainNetbiosCacheResult = $DomainsByNetbios[$domainNetbiosString]
                        if ($DomainNetbiosCacheResult) {
                            $GetDirectoryEntryParams['DirectoryPath'] = "WinNT://$($DomainNetbiosCacheResult.Dns)/$name"
                        } else {
                            $GetDirectoryEntryParams['DirectoryPath'] = "WinNT://$domainNetbiosString/$name"
                        }
                        try {
                            $GetDirectoryEntryParams['PropertiesToLoad'] = 'members'
                            $DirectoryEntry = Get-DirectoryEntry @GetDirectoryEntryParams
                        } catch {
                            Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($GetDirectoryEntryParams['DirectoryPath']) could not be resolved for '$StartingIdentityName'"
                        }
                    }
                }

                $ObjectType = $null
                if ($null -ne $DirectoryEntry) {
                    #$ThisIdentity |
                    #Add-Member -Name 'DirectoryEntry' -Value $DirectoryEntry -MemberType NoteProperty -Force

                    if (
                        $DirectoryEntry.Properties['objectClass'] -contains 'group' -or
                        $DirectoryEntry.SchemaClassName -eq 'group'
                    ) {
                        $ObjectType = 'Group'
                    } else {
                        $ObjectType = 'User'
                    }

                    if ($NoGroupMembers -eq $false) {

                        if (
                            # WinNT DirectoryEntries do not contain an objectClass property
                            # If this property exists it is an LDAP DirectoryEntry rather than WinNT
                            $DirectoryEntry.Properties['objectClass'] -contains 'group'
                        ) {
                            # Retrieve the members of groups from the LDAP provider
                            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # $($DirectoryEntry.Path) is an LDAP security principal for '$StartingIdentityName'"
                            $Members = (Get-AdsiGroupMember -Group $DirectoryEntry -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid).FullMembers
                        } else {
                            # Retrieve the members of groups from the WinNT provider
                            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # $($DirectoryEntry.Path) is a WinNT security principal for '$StartingIdentityName'"
                            if ( $DirectoryEntry.SchemaClassName -eq 'group') {
                                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # $($DirectoryEntry.Path) is a WinNT group for '$StartingIdentityName'"
                                $Members = Get-WinNTGroupMember -DirectoryEntry $DirectoryEntry -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
                            }

                        }

                        $Members |
                        ForEach-Object {

                            if ($_.Domain) {

                                $_ |
                                Add-Member -Force -NotePropertyMembers @{
                                    Group = $ThisIdentityGroup
                                }

                            } else {

                                $_ |
                                Add-Member -Force -NotePropertyMembers @{
                                    Group  = $ThisIdentityGroup
                                    Domain = [pscustomobject]@{
                                        Dns     = $domainNetbiosString
                                        Netbios = $domainNetbiosString
                                        Sid     = ($name -split '-') | Select-Object -Last 1
                                    }
                                }

                            }
                        }

                        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # $($DirectoryEntry.Path) has $(($Members | Measure-Object).Count) members for '$StartingIdentityName'"

                        #$ThisIdentity |
                        #Add-Member -Name 'Members' -Value $Members -MemberType NoteProperty -Force

                    }
                } else {
                    Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # '$StartingIdentityName' could not be matched to a DirectoryEntry"
                }

                $ThisIdentity |
                Add-Member -Force -NotePropertyMembers @{
                    DomainDn       = $DomainDn
                    DomainNetbios  = $DomainNetBiosString
                    ObjectType     = $ObjectType
                    DirectoryEntry = $DirectoryEntry
                    Members        = $Members
                }
                $IdentityReferenceCache[$StartingIdentityName] = $ThisIdentity

            }

            else {
                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # IdentityReferenceCache hit for '$($ThisIdentity.Name)'"
                $null = $IdentityReferenceCache[$ThisIdentity.Name].Group.Add($ThisIdentityGroup)
                $ThisIdentity = $IdentityReferenceCache[$ThisIdentity.Name]
            }

            $ThisIdentity

        }

    }

}
