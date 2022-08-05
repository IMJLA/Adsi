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
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Thread-safe hashtable to use for caching directory entries and avoiding duplicate directory queries
        [hashtable]$IdentityReferenceCache = ([hashtable]::Synchronized(@{})),

        [hashtable]$DomainsBySID = ([hashtable]::Synchronized(@{})),

        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{}))

    )

    begin {

        #Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$(($AccessControlEntry | Measure).Count) unique IdentityReferences found in the $(($AccessControlEntry | Measure).Count) ACEs"

        # Get the SID of the current domain
        $CurrentDomain = (Get-CurrentDomain)

        # Convert the objectSID attribute (byte array) to a security descriptor string formatted according to SDDL syntax (Security Descriptor Definition Language)
        [string]$CurrentDomainSID = & { [System.Security.Principal.SecurityIdentifier]::new([byte[]]$CurrentDomain.objectSid.Value, 0) } 2>$null

        $KnownDomains = @{}
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

                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`tIdentityReferenceCache miss for '$($ThisIdentity.Name)'"

                $DomainDN = $null
                $DirectoryEntry = $null
                $Members = $null

                $StartingIdentityName = $ThisIdentity.Name
                $split = $StartingIdentityName.Split('\')
                $domainNetbiosString = $split[0]
                $name = $split[1]

                if (
                    $null -ne $name -and
                    ($ThisIdentity.Group.AdsiProvider | Select-Object -First 1) -eq 'LDAP'
                ) {
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) is a domain security principal"

                    # Add this domain to our list of known domains
                    if (
                        -not $KnownDomains[$domainNetbiosString] -and
                        -not [string]::IsNullOrEmpty($domainNetbiosString)
                    ) {
                        $KnownDomains[$domainNetbiosString] = ConvertTo-DistinguishedName -Domain $domainNetbiosString -DomainsByNetbios $DomainsByNetbios
                        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`tCache miss for domain $($domainNetbiosString).  Adding its Distinguished Name to dictionary of known domains for future lookup"
                    }

                    # Search the domain for the principal
                    $DomainDn = $KnownDomains[$domainNetbiosString]
                    try {
                        $SearchPath = Add-DomainFqdnToLdapPath -DirectoryPath "LDAP://$DomainDn" -DomainsByNetbios $DomainsByNetbios
                        $DirectoryEntry = Search-Directory -DirectoryEntryCache $DirectoryEntryCache -DirectoryPath $SearchPath -Filter "(samaccountname=$Name)" -PropertiesToLoad @('objectClass', 'distinguishedName', 'name', 'grouptype', 'description', 'managedby', 'member', 'objectClass', 'Department', 'Title') -DomainsByNetbios $DomainsByNetbios
                    } catch {
                        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) could not be resolved against its directory"
                        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($_.Exception.Message)"
                    }

                } elseif (((($StartingIdentityName -split '-') | Select-Object -SkipLast 1) -join '-') -eq $CurrentDomainSID) {
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) is an unresolved SID from the current domain"

                    # Get the distinguishedName and netBIOSName of the current domain.  This also determines whether the domain is online.
                    $DomainDN = $CurrentDomain.distinguishedName.Value
                    $DomainFQDN = $DomainDN | ConvertTo-Fqdn
                    $PartitionsPath = Add-DomainFqdnToLdapPath -DirectoryPath "LDAP://cn=partitions,cn=configuration,$DomainDn" -DomainsByNetbios $DomainsByNetbios
                    $DomainCrossReference = Search-Directory -DirectoryEntryCache $DirectoryEntryCache -DirectoryPath $PartitionsPath -Filter "(&(objectcategory=crossref)(dnsroot=$DomainFQDN)(netbiosname=*))" -PropertiesToLoad netbiosname -DomainsByNetbios $DomainsByNetbios
                    if ($DomainCrossReference.Properties ) {
                        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`tThe domain '$DomainFQDN' is online"
                        $domainNetbiosString = $DomainCrossReference.Properties['netbiosname']
                        # TODO: The domain is online, so let's see if any domain trusts have issues?  Determine if SID is foreign security principal?
                        # TODO: What if the foreign security principal exists but the corresponding domain trust is down?  Don't want to recommend deletion of the ACE in that case.
                    }
                    $SidObject = [System.Security.Principal.SecurityIdentifier]::new($StartingIdentityName)
                    $SidBytes = [byte[]]::new($SidObject.BinaryLength)
                    $null = $SidObject.GetBinaryForm($SidBytes, 0)
                    $ObjectSid = ConvertTo-HexStringRepresentationForLDAPFilterString -SIDByteArray $SidBytes
                    try {
                        $DirectoryEntry = Search-Directory -DirectoryEntryCache $DirectoryEntryCache -DirectoryPath "LDAP://$DomainDn" -Filter "(objectsid=$ObjectSid)" -PropertiesToLoad @('objectClass', 'distinguishedName', 'name', 'grouptype', 'description', 'managedby', 'member', 'objectClass', 'Department', 'Title') -DomainsByNetbios $DomainsByNetbios
                    } catch {
                        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) could not be resolved against its directory"
                        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($_.Exception.Message)"
                    }


                } else {

                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) is a local security principal or unresolved SID"

                    # Determine if SID belongs to current domain
                    $IdentityDomainSID = (($StartingIdentityName -split '-') | Select-Object -SkipLast 1) -join '-'
                    if ($IdentityDomainSID -eq $CurrentDomainSID) {
                        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) belongs to the current domain.  Could be a deleted user.  ?possibly a foreign security principal corresponding to an offline trusted domain or deleted user in the trusted domain?"
                    } else {
                        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) does not belong to the current domain. Could be a local security principal or belong to an unresolvable domain."
                    }

                    if ($null -eq $name) { $name = $StartingIdentityName }

                    if ($name -match 'S-\d+-\d+-\d+-\d+-\d+\-\d+\-\d+') {
                        if ($Domains.Count -gt 1) {
                            $DirectoryEntry = ForEach ($domainNetbiosString in $Domains) {

                                try {
                                    $UsersGroup = Get-DirectoryEntry -DirectoryPath "WinNT://$domainNetbiosString/Users,group" -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios
                                } catch {
                                    Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`tCould not connect to $domainNetbiosString using PSRemoting"
                                    Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$_"
                                }
                                $MembersOfUsersGroup = Get-WinNTGroupMember -DirectoryEntry $UsersGroup -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios
                                $MembersOfUsersGroup | Where-Object -FilterScript { ($name -eq [System.Security.Principal.SecurityIdentifier]::new([byte[]]$_.Properties['objectSid'].Value, 0)) }
                                $ThisIdentity = [pscustomobject]@{
                                    Count = $(($ThisIdentityGroup | Measure-Object).Count)
                                    Name  = "$domainNetbiosString\" + $DirectoryEntry.Name
                                    Group = $ThisIdentityGroup | Where-Object -FilterScript { ($_.SourceAccessList.Path -split '\\')[2] -eq $domainNetbiosString }
                                    #####Group = $ThisIdentityGroup | Where-Object -FilterScript { ($_.Path -split '\\')[2] -eq $domainNetbiosString }
                                }

                            }

                        }

                        else {

                            try {
                                $UsersGroup = Get-DirectoryEntry -DirectoryPath "WinNT://$domainNetbiosString/Users,group" -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios
                            } catch {
                                Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`tCould not connect to $domainNetbiosString using PSRemoting"
                                Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$_"
                            }
                            $MembersOfUsersGroup = Get-WinNTGroupMember -DirectoryEntry $UsersGroup -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios
                            $DirectoryEntry = $MembersOfUsersGroup | Where-Object -FilterScript { ($name -eq [System.Security.Principal.SecurityIdentifier]::new([byte[]]$_.Properties['objectSid'].Value, 0)) }
                            $ThisIdentity = [pscustomobject]@{
                                Count = $(($ThisIdentityGroup | Measure-Object).Count)
                                Name  = "$domainNetbiosString\" + $DirectoryEntry.Name
                                Group = $ThisIdentityGroup
                            }

                        }

                    }

                    else {
                        if ($Domains.Count -gt 1) {
                            $DirectoryEntry = ForEach ($domainNetbiosString in $Domains) {
                                $DirectoryPath = "WinNT://$domainNetbiosString/$name"
                                try {
                                    Get-DirectoryEntry -DirectoryPath $DirectoryPath -PropertiesToLoad members -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios
                                } catch {
                                    Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($DirectoryPath) could not be resolved"
                                }
                            }
                        } else {
                            $DirectoryPath = "WinNT://$domainNetbiosString/$name"
                            try {
                                $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath -PropertiesToLoad members -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios
                            } catch {
                                Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($DirectoryPath) could not be resolved"
                            }

                        }
                    }

                }

                $ObjectType = $null
                if ($null -ne $DirectoryEntry) {
                    $ThisIdentity | Add-Member -Name 'DirectoryEntry' -Value $DirectoryEntry -MemberType NoteProperty -Force

                    if (
                        $DirectoryEntry.Properties['objectClass'] -contains 'group' -or
                        $DirectoryEntry.SchemaClassName -contains 'Group'
                    ) {
                        $ObjectType = 'Group'
                    } else {
                        $ObjectType = 'User'
                    }

                    if ($NoGroupMembers -eq $false) {

                        if ($DirectoryEntry.Properties['objectClass'] -contains 'group') {

                            # Retrieve the members of groups from the LDAP provider
                            #$Members = (Get-AdsiGroup -DirectoryEntryCache $DirectoryEntryCache -DirectoryPath $DirectoryEntry.Path -DomainsByNetbios $DomainsByNetbios).FullMembers
                            $Members = Get-AdsiGroupMember -Group $DirectoryEntry -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios

                        } else {

                            # Retrieve the members of groups from the WinNT provider
                            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($DirectoryEntry.Path) must be a WinNT user or group"
                            $Members = Get-WinNTGroupMember -DirectoryEntryCache $DirectoryEntryCache -DirectoryEntry $DirectoryEntry -KnownDomains $KnownDomains -DomainsByNetbios $DomainsByNetbios

                        }

                        if ($Members) {

                            $Members |
                            ForEach-Object {

                                if ($_.Domain) {

                                    $_ | Add-Member -Force -NotePropertyMembers @{
                                        Group = $ThisIdentityGroup
                                    }

                                } else {

                                    $_ | Add-Member -Force -NotePropertyMembers @{
                                        Group  = $ThisIdentityGroup
                                        Domain = [pscustomobject]@{
                                            Dns     = $domainNetbiosString
                                            Netbios = $domainNetbiosString
                                            Sid     = ($name -split '-') | Select-Object -Last 1
                                        }
                                    }
                                }
                            }
                        }

                        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($DirectoryEntry.Path) has $(($Members | Measure-Object).Count) members"

                        $ThisIdentity |
                        Add-Member -Name 'Members' -Value $Members -MemberType NoteProperty -Force
                    }
                } else {
                    Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) could not be matched to a DirectoryEntry"
                }
                $ThisIdentity | Add-Member -Force -NotePropertyMembers @{
                    DomainDn      = $DomainDn
                    DomainNetbios = $DomainNetBiosString
                    ObjectType    = $ObjectType
                }
                $IdentityReferenceCache[$StartingIdentityName] = $ThisIdentity

            }

            else {
                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`tIdentityReferenceCache hit for '$($ThisIdentity.Name)'"
                $null = $IdentityReferenceCache[$ThisIdentity.Name].Group.Add($ThisIdentityGroup)
                $ThisIdentity = $IdentityReferenceCache[$ThisIdentity.Name]
            }

            $ThisIdentity

        }

    }

    end {
        #Write-Progress -Activity Completed -Completed
    }
}
