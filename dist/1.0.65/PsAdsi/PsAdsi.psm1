
function Add-DomainFqdnToLdapPath {
    param (
        [Parameter(ValueFromPipeline)]
        [string[]]$DirectoryPath
    )
    begin {
        $PathRegEx = '(?<Path>LDAP:\/\/[^\/]*)'
        $DomainRegEx = '(?i)DC=\w{1,}?\b'
    }
    process {

        ForEach ($ThisPath in $DirectoryPath) {

            if ($ThisPath -match $PathRegEx) {

                #$NewPath = $Matches.Path

                if ($ThisPath -match $DomainRegEx) {
                    $DomainDN = $null
                    $DomainFqdn = $null
                    $DomainDN = ([regex]::Matches($ThisPath, $DomainRegEx) | ForEach-Object { $_.Value }) -join ','
                    $DomainFqdn = $DomainDN | ConvertTo-Fqdn
                    if ($ThisPath -match "LDAP:\/\/$DomainFqdn\/") {
                        #Write-Debug "Domain FQDN already found in the directory path: $($ThisPath)"
                        $FQDNPath = $ThisPath
                    } else {
                        $FQDNPath = $ThisPath -replace 'LDAP:\/\/', "LDAP://$DomainFqdn/"
                    }
                } else {
                    #Write-Debug "Domain DN not found in the directory path: $($ThisPath)"
                    $FQDNPath = $ThisPath
                }
            } else {
                #Write-Debug "Not an expected directory path: $($ThisPath)"
                $FQDNPath = $ThisPath
            }

            Write-Output $FQDNPath
        }
    }
}
function Add-SidInfo {

    param (

        # Expecting a DirectoryEntry from the LDAP or WinNT providers
        # Must contain the objectSid property
        [Parameter(ValueFromPipeline)]
        $InputObject,

        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        $TrustedDomainSidNameMap = (Get-TrustedDomainSidNameMap -DirectoryEntryCache $DirectoryEntryCache)

    )

    begin {}

    process {
        ForEach ($Object in $InputObject) {
            if ($null -eq $Object) { continue }
            elseif ($Object.objectSid.Value) {
                [string]$SID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]$Object.objectSid.Value, 0)
            } elseif ($Object.Properties['objectSid'].Value) {
                [string]$SID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]$Object.Properties['objectSid'].Value, 0)
            } elseif ($Object.Properties['objectSid']) {
                [string]$SID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]($Object.Properties['objectSid'] | ForEach-Object { $_ }), 0)
            }

            if ($Object.Properties['samaccountname']) {
                $SamAccountName = $Object.Properties['samaccountname']
            } else {
                #DirectoryEntries from the WinNT provider for local accounts do not have a samaccountname attribute so we use name instead
                $SamAccountName = $Object.Properties['name']
            }

            # The SID of the domain is the SID of the user minus the last block of numbers
            $DomainSid = $SID.Substring(0, $Sid.LastIndexOf("-"))

            # Lookup other information about the domain using its SID as the key
            $DomainObject = $TrustedDomainSidNameMap[$DomainSid]

            #Write-Debug "$SamAccountName`t$SID"

            $Object |
            Add-Member -PassThru -Force @{
                SidString      = $SID
                Domain         = $DomainObject
                SamAccountName = $SamAccountName
            }
        }
    }

    end {

    }
}
function ConvertTo-DistinguishedName {
    # https://docs.microsoft.com/en-us/windows/win32/api/iads/nn-iads-iadsnametranslate
    param ([string]$Domain)
    $IADsNameTranslateComObject = New-Object -comObject "NameTranslate"
    $IADsNameTranslateInterface = $IADsNameTranslateComObject.GetType()
    $null = $IADsNameTranslateInterface.InvokeMember("Init", "InvokeMethod", $Null, $IADsNameTranslateComObject, (3, $Null))
    $null = $IADsNameTranslateInterface.InvokeMember("Set", "InvokeMethod", $Null, $IADsNameTranslateComObject, (3, "$Domain\"))
    $DNSDomain = $IADsNameTranslateInterface.InvokeMember("Get", "InvokeMethod", $Null, $IADsNameTranslateComObject, 1)
    Write-Output $DNSDomain
}
function ConvertTo-Fqdn {
    param (
        [Parameter(ValueFromPipeline)]
        [string[]]$DistinguishedName
    )
    process {
        ForEach ($DN in $DistinguishedName) {
            $DN -replace ',DC=', '.' -replace 'DC=', ''
        }
    }
}
function ConvertTo-HexStringRepresentation {
    param (
        [byte[]]$SIDByteArray
    )
    $SIDByteArray |
    ForEach-Object {
        '{0:X}' -f $_
    }
}
function ConvertTo-HexStringRepresentationForLDAPFilterString {
    param (
        [byte[]]$SIDByteArray
    )
    $Hexes = $SIDByteArray |
    ForEach-Object {
        '{0:X}' -f $_
    } |
    ForEach-Object {
        if ($_.Length -eq 2) {
            $_
        } else {
            "0$_"
        }
    }
    "\$($Hexes -join '\')"
}
function ConvertTo-SidByteArray {
    param (
        [Parameter(ValueFromPipeline)]
        [string]$SidString
    )
    process {
        $SID = [System.Security.Principal.SecurityIdentifier]::new($SidString)
        [byte[]]$Bytes = [byte[]]::new($SID.BinaryLength)
        $SID.GetBinaryForm($Bytes, 0)
        Write-Output $Bytes
    }
}
function Expand-AdsiGroupMember {

    param (

        [parameter(ValueFromPipeline)]
        $DirectoryEntry,

        [string[]]$PropertiesToLoad = @('operatingSystem', 'objectSid', 'samAccountName', 'objectClass', 'distinguishedName', 'name', 'grouptype', 'description', 'managedby', 'member', 'objectClass', 'Department', 'Title'),

        $TrustedDomainSidNameMap = (Get-TrustedDomainSidNameMap -DirectoryEntryCache $DirectoryEntryCache),

        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{}))

    )

    begin {
        $i = 0
    }

    process {

        ForEach ($Entry in $DirectoryEntry) {

            $i++

            $status = ("$(Get-Date -Format s)`t$(hostname)`tExpand-AdsiGroupMember`tStatus: Using ADSI to get info on group member $i`: " + $Entry.Name)
            #Write-Debug "  $status"

            $Principal = $null

            if ($Entry.objectClass -contains 'foreignSecurityPrincipal') {

                if ($Entry.distinguishedName.Value -match '(?>^CN=)(?<SID>[^,]*)') {

                    [string]$SID = $Matches.SID

                    #The SID of the domain is the SID of the user minus the last block of numbers
                    $DomainSid = $SID.Substring(0, $Sid.LastIndexOf("-"))
                    $Domain = $TrustedDomainSidNameMap[$DomainSid]

                    $Success = $true
                    try {
                        $Principal = Get-DirectoryEntry -DirectoryPath "LDAP://$($Domain.Dns)/<SID=$SID>" -DirectoryEntryCache $DirectoryEntryCache
                    } catch {
                        $Success = $false
                        $Principal = $Entry
                        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-AdsiGroupMember`t$SID could not be retrieved from $Domain"
                    }

                    if ($Success -eq $true) {

                        $null = $Principal.RefreshCache($PropertiesToLoad)

                        # Recursively enumerate group members
                        if ($Principal.properties['objectClass'].Value -contains 'group') {
                            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-AdsiGroupMember`t'$($Principal.properties['name'])' is a group in $Domain"
                            $Principal = ($Principal | Get-ADSIGroupMember -DirectoryEntryCache $DirectoryEntryCache).FullMembers | Expand-AdsiGroupMember -DirectoryEntryCache $DirectoryEntryCache -TrustedDomainSidNameMap $TrustedDomainSidNameMap

                        }

                    }

                }

            } else {
                $Principal = $Entry
            }

            $Principal | Add-SidInfo -DirectoryEntryCache $DirectoryEntryCache -TrustedDomainSidNameMap $TrustedDomainSidNameMap

        }
    }

}
function Expand-IdentityReference {

    # Use ADSI to collect more information about the IdentityReference in NTFS Access Control Entries

    param (

        # The NTFS AccessControlEntry object(s), grouped by their IdentityReference property
        [Parameter(ValueFromPipeline)]
        [System.Object[]]$AccessControlEntry,

        # Get group members
        [bool]$GroupMember = $true,

        # Get group members recursively
        # If true, implies $GroupMember = $true
        [bool]$GroupMemberRecursion = $true,

        # Thread-safe hashtable to use for caching directory entries and avoiding duplicate directory queries
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Thread-safe hashtable to use for caching directory entries and avoiding duplicate directory queries
        [hashtable]$IdentityReferenceCache = ([hashtable]::Synchronized(@{}))

    )


    begin {

        #Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$(($AccessControlEntry | Measure).Count) unique IdentityReferences found in the $(($AccessControlEntry | Measure).Count) ACEs"

        # Get the SID of the current domain
        $CurrentDomain = (Get-CurrentDomain)

        # Convert the objectSID attribute (byte array) to a security descriptor string formatted according to SDDL syntax (Security Descriptor Definition Language)
        [string]$CurrentDomainSID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]$CurrentDomain.objectSid.Value, 0)

        $LocalDomains = @('NT AUTHORITY', 'BUILTIN', "$(hostname)")
        $KnownDomains = @{}
        $i = 0

    }

    process {

        ForEach ($ThisIdentity in $AccessControlEntry) {

            $ThisIdentityGroup = $ThisIdentity.Group

            $i++
            #Calculate the completion percentage, and format it to show 0 decimal places
            $percentage = "{0:N0}" -f (($i / ($AccessControlEntry.Count)) * 100)

            #Display the progress bar
            $status = $percentage + "% - Using ADSI to get info on NTFS IdentityReference $i of " + $AccessControlEntry.Count + ": " + $ThisIdentity.Name
            #Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`tStatus: $status"

            #Write-Progress -Activity ("Unique IdentityReferences: " + $AccessControlEntry.Count) -Status $status -PercentComplete $percentage

            if ($null -eq $IdentityReferenceCache[$ThisIdentity.Name]) {

                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`tIdentityReferenceCache miss for '$($ThisIdentity.Name)'"

                $DomainDN = $null
                $DirectoryEntry = $null
                $Members = $null

                $StartingIdentityName = $ThisIdentity.Name
                $split = $StartingIdentityName.Split('\')
                $domainNetbiosString = $split[0]
                $name = $split[1]

                if ($null -ne $name -and ($ThisIdentity.Group.AdsiProvider | Select-Object -First 1) -eq 'LDAP') {
                    Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) is a domain security principal"

                    # Add this domain to our list of known domains
                    if (!($KnownDomains[$domainNetbiosString])) {
                        $KnownDomains[$domainNetbiosString] = ConvertTo-DistinguishedName -Domain $domainNetbiosString
                        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`tCache miss for domain $($domainNetbiosString).  Adding its Distinguished Name to dictionary of known domains for future lookup"
                    }

                    # Search the domain for the principal
                    $DomainDn = $KnownDomains[$domainNetbiosString]
                    try {
                        $SearchPath = "LDAP://$DomainDn" | Add-DomainFqdnToLdapPath
                        $DirectoryEntry = Search-Directory -DirectoryEntryCache $DirectoryEntryCache -DirectoryPath $SearchPath -Filter "(samaccountname=$Name)" -PropertiesToLoad @('objectClass', 'distinguishedName', 'name', 'grouptype', 'description', 'managedby', 'member', 'objectClass', 'Department', 'Title')
                    } catch {
                        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) could not be resolved against its directory"
                        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($_.Exception.Message)"
                    }

                } elseif (((($StartingIdentityName -split '-') | Select-Object -SkipLast 1) -join '-') -eq $CurrentDomainSID) {
                    Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) is an unresolved SID from the current domain"

                    # Get the distinguishedName and netBIOSName of the current domain.  This also determines whether the domain is online.
                    $DomainDN = $CurrentDomain.distinguishedName.Value
                    $DomainFQDN = $DomainDN | ConvertTo-Fqdn
                    $PartitionsPath = "LDAP://cn=partitions,cn=configuration,$DomainDn" | Add-DomainFqdnToLdapPath
                    $DomainCrossReference = Search-Directory -DirectoryEntryCache $DirectoryEntryCache -DirectoryPath $PartitionsPath -Filter "(&(objectcategory=crossref)(dnsroot=$DomainFQDN)(netbiosname=*))" -PropertiesToLoad netbiosname
                    if ($DomainCrossReference.Properties ) {
                        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`tThe domain '$DomainFQDN' is online"
                        $domainNetbiosString = $DomainCrossReference.Properties['netbiosname']
                        # TODO: The domain is online, so let's see if any domain trusts have issues?  Determine if SID is foreign security principal?
                        # TODO: What if the foreign security principal exists but the corresponding domain trust is down?  Don't want to recommend deletion of the ACE in that case.
                    }
                    $SidObject = [System.Security.Principal.SecurityIdentifier]::new($StartingIdentityName)
                    $SidBytes = [byte[]]::new($SidObject.BinaryLength)
                    $null = $SidObject.GetBinaryForm($SidBytes, 0)
                    $ObjectSid = ConvertTo-HexStringRepresentationForLDAPFilterString -SIDByteArray $SidBytes
                    try {
                        $DirectoryEntry = Search-Directory -DirectoryEntryCache $DirectoryEntryCache -DirectoryPath "LDAP://$DomainDn" -Filter "(objectsid=$ObjectSid)" -PropertiesToLoad @('objectClass', 'distinguishedName', 'name', 'grouptype', 'description', 'managedby', 'member', 'objectClass', 'Department', 'Title')
                    } catch {
                        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) could not be resolved against its directory"
                        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($_.Exception.Message)"
                    }


                } else {

                    Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) is a local security principal or unresolved SID"

                    # Determine if SID belongs to current domain
                    $IdentityDomainSID = (($StartingIdentityName -split '-') | Select-Object -SkipLast 1) -join '-'
                    if ($IdentityDomainSID -eq $CurrentDomainSID) {
                        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) belongs to the current domain.  Could be a deleted user.  ?possibly a foreign security principal corresponding to an offline trusted domain or deleted user in the trusted domain?"
                    } else {
                        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) does not belong to the current domain. Could be a local security principal or belong to an unresolvable domain."
                        <#
                        #Write-Host ($ThisIdentity | Fl * | out-string) -ForegroundColor Red
                        $Domains = $ThisIdentityGroup.Path | ForEach-Object {($_ -split '\\')[2]}
                        $ThisIdentity = ForEach ($domainNetbiosString in $Domains) {
                            $DomainDN = "dc=$domainNetbiosString"
                            switch ($StartingIdentityName) {
                                'NT AUTHORITY\SYSTEM' {
                                    $StartingIdentityName = "$domainNetbiosString\SYSTEM"
                                }
                                default {
                                }
                            }
                            [pscustomobject]@{
                                Count = $ThisIdentity.Count
                                Name = $StartingIdentityName
                                Group = $ThisIdentityGroup | Where-Object -FilterScript {($_.Path -split '\\')[2] -eq $domainNetbiosString}
                                DomainNetBios = $domainNetbiosString
                            }
                        }#>

                    }

                    if ($null -eq $name) { $name = $StartingIdentityName }


                    if ($name -match 'S-\d+-\d+-\d+-\d+-\d+\-\d+\-\d+') {
                        if ($Domains.Count -gt 1) {
                            $DirectoryEntry = ForEach ($domainNetbiosString in $Domains) {

                                try {
                                    $UsersGroup = Get-DirectoryEntry -DirectoryPath "WinNT://$domainNetbiosString/Users,group" -DirectoryEntryCache $DirectoryEntryCache
                                } catch {
                                    Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`tCould not connect to $domainNetbiosString using PSRemoting"
                                    Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$_"
                                }
                                $MembersOfUsersGroup = Get-WinNTGroupMember -DirectoryEntry $UsersGroup -DirectoryEntryCache $DirectoryEntryCache
                                $MembersOfUsersGroup | Where-Object -FilterScript { ($name -eq [System.Security.Principal.SecurityIdentifier]::new([byte[]]$_.Properties['objectSid'].Value, 0)) }
                                $ThisIdentity = [pscustomobject]@{
                                    Count = $(($ThisIdentityGroup | Measure-Object).Count)
                                    Name  = "$domainNetbiosString\" + $DirectoryEntry.Name
                                    Group = $ThisIdentityGroup | Where-Object -FilterScript { ($_.Path -split '\\')[2] -eq $domainNetbiosString }
                                }

                            }

                        }

                        else {

                            try {
                                $UsersGroup = Get-DirectoryEntry -DirectoryPath "WinNT://$domainNetbiosString/Users,group" -DirectoryEntryCache $DirectoryEntryCache
                            } catch {
                                Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`tCould not connect to $domainNetbiosString using PSRemoting"
                                Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$_"
                            }
                            $MembersOfUsersGroup = Get-WinNTGroupMember -DirectoryEntry $UsersGroup -DirectoryEntryCache $DirectoryEntryCache
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
                                    Get-DirectoryEntry -DirectoryPath $DirectoryPath -PropertiesToLoad members -DirectoryEntryCache $DirectoryEntryCache
                                } catch {
                                    Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($DirectoryPath) could not be resolved"
                                }
                            }
                        } else {
                            $DirectoryPath = "WinNT://$domainNetbiosString/$name"
                            try {
                                $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath -PropertiesToLoad members -DirectoryEntryCache $DirectoryEntryCache
                            } catch {
                                Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($DirectoryPath) could not be resolved"
                            }

                        }
                    }

                }

                $ObjectType = $null
                if ($null -ne $DirectoryEntry) {
                    $ThisIdentity | Add-Member -Name 'DirectoryEntry' -Value $DirectoryEntry -MemberType NoteProperty -Force

                    # Not needed after changes but not yet ready to let go in case I need it again for troubleshooting after I mess it up the same way again
                    #if ($DirectoryEntry.Properties.GetType().FullName -eq 'System.DirectoryServices.ResultPropertyCollection') {
                    #$ThisIdentity | Add-Member -Force -NotePropertyMembers $DirectoryEntry.Properties -ErrorAction SilentlyContinue
                    #}

                    if (
                        $DirectoryEntry.Properties['objectClass'] -contains 'group' -or
                        $DirectoryEntry.SchemaClassName -contains 'Group'
                    ) {
                        $ObjectType = 'Group'
                    } else {
                        $ObjectType = 'User'
                    }

                    if ($GroupMember) {

                        if ($DirectoryEntry.Properties['objectClass'] -contains 'group') {

                            # Retrieve the members of groups from the LDAP provider
                            $Members = (Get-ADSIGroup -DirectoryEntryCache $DirectoryEntryCache -DirectoryPath $DirectoryEntry.Path).FullMembers

                        } else {

                            # Retrieve the members of groups from the WinNT provider
                            $Members = Get-WinNTGroupMember -DirectoryEntryCache $DirectoryEntryCache -DirectoryEntry $DirectoryEntry -KnownDomains $KnownDomains

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

                        $ThisIdentity |
                        Add-Member -Name 'Members' -Value $Members -MemberType NoteProperty -Force
                    }
                } else {
                    Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) could not be matched to a DirectoryEntry"
                }
                $ThisIdentity | Add-Member -Name "DomainDn" -Type NoteProperty -Value $DomainDn -Force
                $ThisIdentity | Add-Member -Name "DomainNetbios" -Type NoteProperty -Value $DomainNetBiosString -Force
                $ThisIdentity | Add-Member -Name "ObjectType" -Type NoteProperty -Value $ObjectType -Force

                $IdentityReferenceCache[$StartingIdentityName] = $ThisIdentity

            }

            else {
                #Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`tIdentityReferenceCache hit for '$($ThisIdentity.Name)'"
                $null = $IdentityReferenceCache[$ThisIdentity.Name].Group.Add($ThisIdentityGroup)
                $ThisIdentity = $IdentityReferenceCache[$ThisIdentity.Name]
            }

            Write-Output $ThisIdentity

        }

    }

    end {
        #Write-Progress -Activity Completed -Completed
    }
}
function Expand-WinNTGroupMember {

    param (

        [Parameter(ValueFromPipeline)]
        $DirectoryEntry,

        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{}))

    )
    begin {}
    process {
        ForEach ($ThisEntry in $DirectoryEntry) {

            if (!($ThisEntry.Properties)) {
                Write-Warning "'$ThisEntry' has no properties"
            } elseif ($ThisEntry.Properties['objectClass'] -contains 'group') {

                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-WinNTGroupMember`t$($ThisEntry.Path) is a group"

                    (Get-ADSIGroup -DirectoryEntryCache $DirectoryEntryCache -DirectoryPath $ThisEntry.Path).FullMembers |
                Add-SidInfo -DirectoryEntryCache $DirectoryEntryCache

            } else {

                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-WinNTGroupMember`t'$($ThisEntry.Path) is an account"
                $ThisEntry | Add-SidInfo -DirectoryEntryCache $DirectoryEntryCache

            }

        }
    }
    end {}
}
function Find-AdsiProvider {
    param (
        [string]$AdsiServer,

        [hashtable]$KnownServers = [hashtable]::Synchronized(@{})
    )
    $AdsiProvider = $null
    if ($KnownServers[$AdsiServer]) {
        $AdsiProvider = $KnownServers[$AdsiServer]
    } else {
        try {
            $null = [System.DirectoryServices.DirectoryEntry]::Exists("LDAP://$AdsiServer")
            $AdsiProvider = 'LDAP'
        } catch {}
        if (!$AdsiProvider) {
            try {
                $null = [System.DirectoryServices.DirectoryEntry]::Exists("WinNT://$AdsiServer")
                $AdsiProvider = 'WinNT'
            } catch {}
        }
        if (!$AdsiProvider) {
            $AdsiProvider = 'none'
        }
        $KnownServers[$AdsiServer] = $AdsiProvider
    }
    Write-Output $AdsiProvider
}
function Get-ADSIGroup {

    param (

        [string]$DirectoryPath = (([adsisearcher]'').SearchRoot.Path),
        [string]$GroupName,
        [string[]]$PropertiesToLoad = @('objectClass', 'distinguishedName', 'name', 'grouptype', 'description', 'managedby', 'member', 'objectClass', 'department', 'title'),
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{}))

    )

    $SearchParams = @{
        PropertiesToLoad    = $PropertiesToLoad
        DirectoryPath       = $DirectoryPath
        DirectoryEntryCache = $DirectoryEntryCache
    }


    if ($GroupName) {
        $SearchParams['Filter'] = "(&(objectClass=group)(cn=$GroupName))"
    } else {
        $SearchParams['Filter'] = "(objectClass=group)"
    }

    Search-Directory @SearchParams |
    Get-ADSIGroupMember -DirectoryEntryCache $DirectoryEntryCache

}
function Get-ADSIGroupMember {

    <#
    Get a group and its members
    #>

    param (

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $Group,

        [string[]]$PropertiesToLoad = @('operatingSystem', 'objectSid', 'samAccountName', 'objectClass', 'distinguishedName', 'name', 'grouptype', 'description', 'managedby', 'member', 'objectClass', 'department', 'title'),

        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{}))

    )
    begin {}
    process {

        foreach ($ThisGroup in $Group) {

            $SearchParameters = @{

                # Recursive search
                Filter              = "(memberof:1.2.840.113556.1.4.1941:=$($ThisGroup.Properties['distinguishedname']))"

                # Non-recursive search
                #Filter = "(memberof=$($ThisGroup.Properties['distinguishedname']))"

                PropertiesToLoad    = $PropertiesToLoad

                DirectoryEntryCache = $DirectoryEntryCache

            }

            $PathRegEx = '(?<Path>LDAP:\/\/[^\/]*)'
            if ($ThisGroup.Path -match $PathRegEx) {

                $SearchParameters['DirectoryPath'] = $Matches.Path | Add-DomainFqdnToLdapPath

                $DomainRegEx = '(?i)DC=\w{1,}?\b'
                if ($ThisGroup.Path -match $DomainRegEx) {
                    $Domain = ([regex]::Matches($ThisGroup.Path, $DomainRegEx) | ForEach-Object { $_.Value }) -join ','
                    $SearchParameters['DirectoryPath'] = "LDAP://$Domain" | Add-DomainFqdnToLdapPath
                } else {
                    $SearchParameters['DirectoryPath'] = $ThisGroup.Path | Add-DomainFqdnToLdapPath
                }

            } else {
                $SearchParameters['DirectoryPath'] = $ThisGroup.Path | Add-DomainFqdnToLdapPath
            }
            #>

            #Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-AdsiGroupMember`t$($SearchParameters['Filter'])"

            $GroupMemberSearch = Search-Directory @SearchParameters

            if ($GroupMemberSearch.Count -gt 0) {

                $CurrentADGroupMembers = $GroupMemberSearch | ForEach-Object {
                    $FQDNPath = $_.Path | Add-DomainFqdnToLdapPath
                    Get-DirectoryEntry -DirectoryPath $FQDNPath -DirectoryEntryCache $DirectoryEntryCache
                }

            } else {
                $CurrentADGroupMembers = $null
            }

            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-AdsiGroupMember`t$($ThisGroup.Properties.name) has $(($CurrentADGroupMembers | Measure-Object).Count) members"

            $TrustedDomainSidNameMap = Get-TrustedDomainSidNameMap -DirectoryEntryCache $DirectoryEntryCache
            $ProcessedGroupMembers = $CurrentADGroupMembers | Expand-AdsiGroupMember -DirectoryEntryCache $DirectoryEntryCache -TrustedDomainSidNameMap $TrustedDomainSidNameMap
            $ThisGroup |
            Add-Member -MemberType NoteProperty -Name FullMembers -Value $ProcessedGroupMembers -Force -PassThru

        }
    }
    end {}
}
function Get-CurrentDomain {
    $Obj = [adsi]::new()
    $Obj.RefreshCache({ 'objectSid' })
    Write-Output $Obj
}
function Get-DirectoryEntry {
    <#
        .SYNOPSIS
        Use Active Directory Service Interfaces to retrieve an object from a directory
        .DESCRIPTION
        Retrieve a directory entry using either the WinNT or LDAP provider for ADSI
        .EXAMPLE
        ----------  EXAMPLE 1  ----------
        As the current user, bind to the current domain and retrieve the DirectoryEntry for the root of the domain

        Get-DirectoryEntry
    #>
    [OutputType([PSObject[]])]
    [CmdletBinding()]
    param (

        <#
        Path to the directory object to retrieve
        Defaults to the root of the current domain (but don't use it for that, just do this instead: [System.DirectoryServices.DirectorySearcher]::new())
        #>
        [string]$DirectoryPath = (([System.DirectoryServices.DirectorySearcher]'').SearchRoot.Path),

        <#
        Credentials to use to bind to the directory
        Defaults to the credentials of the current user
        #>
        [pscredential]$Credential,

        # Properties of the target object to retrieve
        [string[]]$PropertiesToLoad,

        <#
        A hashtable containing cached directory entries so they don't have to be retrieved from the directory again
        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{}))

    )

    $DirectoryEntry = $null
    if ($null -eq $DirectoryEntryCache[$DirectoryPath]) {
        <#
        The WinNT provider only throws an error if you try to retrieve certain accounts/identities
        We will create own dummy objects instead of performing the query
        #>
        switch -regex ($DirectoryPath) {

            '^WinNT\:\/\/[^\/]*\/CREATOR OWNER$' {
                $SidByteAray = 'S-1-3-0' | ConvertTo-SidByteArray
                $DirectoryEntry = [pscustomobject]@{
                    Name            = 'CREATOR OWNER'
                    Description     = 'A SID to be replaced by the SID of the user who creates a new object. This SID is used in inheritable ACEs.'
                    objectSid       = $SidByteAray
                    Parent          = $DirectoryPath | Split-Path -Parent
                    Path            = $DirectoryPath
                    Properties      = @{
                        Name        = 'CREATOR OWNER'
                        Description = 'A SID to be replaced by the SID of the user who creates a new object. This SID is used in inheritable ACEs.'
                        objectSid   = $SidByteAray
                    }
                    SchemaClassName = 'User'
                    SchemaEntry     = [System.DirectoryServices.DirectoryEntry]
                }
                $DirectoryEntry | Add-Member -MemberType ScriptMethod -Name RefreshCache -Force -Value {}

            }
            '^WinNT\:\/\/[^\/]*\/SYSTEM$' {
                $SidByteAray = 'S-1-5-18' | ConvertTo-SidByteArray
                $DirectoryEntry = [pscustomobject]@{
                    Name            = 'SYSTEM'
                    Description     = 'By default, the SYSTEM account is granted Full Control permissions to all files on an NTFS volume'
                    objectSid       = $SidByteAray
                    Parent          = $DirectoryPath | Split-Path -Parent
                    Path            = $DirectoryPath
                    Properties      = @{
                        Name        = 'SYSTEM'
                        Description = 'By default, the SYSTEM account is granted Full Control permissions to all files on an NTFS volume'
                        objectSid   = $SidByteAray
                    }
                    SchemaClassName = 'User'
                    SchemaEntry     = [System.DirectoryServices.DirectoryEntry]
                }
                $DirectoryEntry | Add-Member -MemberType ScriptMethod -Name RefreshCache -Force -Value {}

            }
            '^WinNT\:\/\/[^\/]*\/INTERACTIVE$' {
                $SidByteAray = 'S-1-5-4' | ConvertTo-SidByteArray
                $DirectoryEntry = [pscustomobject]@{
                    Name            = 'INTERACTIVE'
                    Description     = 'Users who log on for interactive operation. This is a group identifier added to the token of a process when it was logged on interactively.'
                    objectSid       = $SidByteAray
                    Parent          = $DirectoryPath | Split-Path -Parent
                    Path            = $DirectoryPath
                    Properties      = @{
                        Name        = 'INTERACTIVE'
                        Description = 'Users who log on for interactive operation. This is a group identifier added to the token of a process when it was logged on interactively.'
                        objectSid   = $SidByteAray
                    }
                    SchemaClassName = 'Group'
                    SchemaEntry     = [System.DirectoryServices.DirectoryEntry]
                }
                $DirectoryEntry | Add-Member -MemberType ScriptMethod -Name RefreshCache -Force -Value {}

            }
            '^WinNT\:\/\/[^\/]*\/Authenticated Users$' {
                $SidByteAray = 'S-1-5-11' | ConvertTo-SidByteArray
                $DirectoryEntry = [pscustomobject]@{
                    Name            = 'Authenticated Users'
                    Description     = 'Any user who accesses the system through a sign-in process has the Authenticated Users identity.'
                    objectSid       = $SidByteAray
                    Parent          = $DirectoryPath | Split-Path -Parent
                    Path            = $DirectoryPath
                    Properties      = @{
                        Name        = 'Authenticated Users'
                        Description = 'Any user who accesses the system through a sign-in process has the Authenticated Users identity.'
                        objectSid   = $SidByteAray
                    }
                    SchemaClassName = 'Group'
                    SchemaEntry     = [System.DirectoryServices.DirectoryEntry]
                }
                $DirectoryEntry | Add-Member -MemberType ScriptMethod -Name RefreshCache -Force -Value {}
            }
            default {

                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-DirectoryEntry`t[System.DirectoryServices.DirectoryEntry]::new('$DirectoryPath')"
                if ($Credential) {
                    $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath, $($Credential.UserName), $($Credential.GetNetworkCredential().password))
                } else {
                    $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath)
                }

            }

        }

        $DirectoryEntryCache[$DirectoryPath] = $DirectoryEntry
    } else {
        #Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-DirectoryEntry`tDirectoryEntryCache hit for '$DirectoryPath'"
        $DirectoryEntry = $DirectoryEntryCache[$DirectoryPath]
    }

    try {
        if ($PropertiesToLoad) {
            # If the $DirectoryPath was invalid, this line will return an error
            $null = $DirectoryEntry.RefreshCache($PropertiesToLoad)
        }

        Write-Output $DirectoryEntry
    } catch {
        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tGet-DirectoryEntry`t'$DirectoryPath' could not be retrieved."

        # Ensure that the error message appears on 1 line
        # Use .Trim() to remove leading and trailing whitespace
        # Use -replace to remove an errant line break in the following specific error I encountered: The following exception occurred while retrieving member "RefreshCache": "The group name could not be found.`r`n"
        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tGet-DirectoryEntry`t'$($_.Exception.Message.Trim() -replace '\s"',' "')"
    }

}
function Get-TrustedDomainSidNameMap {

    param (

        [Switch]$KeyByNetbios,

        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{}))

    )

    $Map = @{}

    $nltestresults = & nltest /domain_trusts
    $NlTestRegEx = '[\d]*: .*'
    $TrustRelationships = $nltestresults -match $NlTestRegEx

    foreach ($TrustRelationship in $TrustRelationships) {

        $RegEx = '(?<index>[\d]*): (?<netbios>\S*) (?<dns>\S*).*'
        if ($TrustRelationship -match $RegEx) {
            $DomainDnsName = $Matches.dns
            $DomainNetbios = $Matches.netbios
        }

        $DomainDirectoryEntry = Get-DirectoryEntry -DirectoryPath "LDAP://$DomainDnsName" -DirectoryEntryCache $DirectoryEntryCache

        $DistinguishedName = ConvertTo-DistinguishedName -Domain $DomainNetbios

        try {
            $DomainDirectoryEntry.RefreshCache({ "objectSid" })
            $DomainSid = [System.Security.Principal.SecurityIdentifier]::new([byte[]]$DomainDirectoryEntry.Properties["objectSid"].Value, 0).ToString()
            if ($KeyByNetbios -eq $true) {
                $Map[$DomainNetbios] = [pscustomobject]@{
                    Dns               = $DomainDnsName
                    Netbios           = $DomainNetbios
                    Sid               = $DomainSid
                    DistinguishedName = $DistinguishedName
                }
            } else {
                $Map[$DomainSid] = [pscustomobject]@{
                    Dns               = $DomainDnsName
                    Netbios           = $DomainNetbios
                    Sid               = $DomainSid
                    DistinguishedName = $DistinguishedName
                }
            }
        } catch {
            Write-Warning "$(Get-Date -Format s)`t$(hostname)`tGet-TrustedDomainSidNameMap`tDomain: '$DomainDnsName' - $($_.Exception.Message)"
        }
    }

    $LocalAccountSID = Get-CimInstance -Query "SELECT SID FROM Win32_UserAccount WHERE LocalAccount = 'True'" |
    Select-Object -First 1 -ExpandProperty SID
    $DomainSid = $LocalAccountSID.Substring(0, $LocalAccountSID.LastIndexOf("-"))
    $DomainNetBios = hostname
    $DomainDnsName = "$DomainNetbios.$((Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters').'NV Domain')"

    $Map[$DomainSid] = [pscustomobject]@{
        Dns     = $DomainDnsName
        Netbios = $DomainNetbios
        Sid     = $DomainSid
    }

    Write-Output $Map

}
function Get-WinNTGroupMember {

    param (

        $DirectoryEntry,

        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{}))

    )

    #TODO: Default should know at least any trusted domains
    $KnownDomains = Get-TrustedDomainSidNameMap -DirectoryEntryCache $DirectoryEntryCache -KeyByNetbios

    $SourceDomain = $DirectoryEntry.Path | Split-Path -Parent | Split-Path -Leaf

    # Retrieve the members of local groups
    if ($null -ne $DirectoryEntry.Properties['groupType']) {
        $DirectoryMembers = $DirectoryEntry.Invoke('Members')
        ForEach ($DirectoryMember in $DirectoryMembers) {
            # Convert the COM Objects from the WinNT provider to proper [System.DirectoryServices.DirectoryEntry] objects from the LDAP provider
            $DirectoryPath = Invoke-ComObject -ComObject $DirectoryMember -Property 'ADsPath'
            $MemberDomainDn = $null
            if ($DirectoryPath -match 'WinNT:\/\/(?<Domain>[^\/]*)\/(?<Acct>.*$)') {
                $MemberName = $Matches.Acct
                $MemberDomainNetbios = $Matches.Domain

                if ($KnownDomains[$MemberDomainNetbios] -and $MemberDomainNetbios -ne $SourceDomain) {
                    $MemberDomainDn = $KnownDomains[$MemberDomainNetbios].DistinguishedName
                }
                if ($DirectoryPath -match 'WinNT:\/\/(?<Domain>[^\/]*)\/(?<Middle>[^\/]*)\/(?<Acct>.*$)') {
                    if ($Matches.Middle -eq ($DirectoryEntry.Path | Split-Path -Parent | Split-Path -Leaf)) {
                        $MemberDomainDn = $null
                    }
                }
            }

            if ($MemberDomainDn) {
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-WinNTGroupMember`t'$MemberName' is a domain security principal"
                $MemberDirectoryEntry = Search-Directory -DirectoryEntryCache $DirectoryEntryCache -DirectoryPath "LDAP://$MemberDomainDn" -Filter "(samaccountname=$MemberName)" -PropertiesToLoad @('objectClass', 'distinguishedName', 'name', 'grouptype', 'description', 'managedby', 'member', 'objectClass', 'Department', 'Title', 'samAccountName', 'objectSid')
            } else {
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-WinNTGroupMember`t'$DirectoryPath' is a local security principal"
                $MemberDirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath -PropertiesToLoad @('objectClass', 'distinguishedName', 'name', 'grouptype', 'description', 'managedby', 'member', 'objectClass', 'Department', 'Title', 'samAccountName', 'objectSid') -DirectoryEntryCache $DirectoryEntryCache
            }

            $MemberDirectoryEntry | Expand-WinNTGroupMember -DirectoryEntryCache $DirectoryEntryCache

        }
    }

}
function Invoke-ComObject {
    param (
        [Parameter(Mandatory)]
        $ComObject,

        [Parameter(Mandatory)]
        [String]$Property,

        $Value,

        [Switch]$Method
    )
    <#
    If ($ComObject -IsNot "__ComObject") {
        If (!$ComInvoke) {
            $Global:ComInvoke = @{}
        }
        If (!$ComInvoke.$ComObject) {
            $ComInvoke.$ComObject = New-Object -ComObject $ComObject
        }
        $ComObject = $ComInvoke.$ComObject
    }
    #>
    If ($Method) {
        $Invoke = "InvokeMethod"
    } ElseIf ($MyInvocation.BoundParameters.ContainsKey("Value")) {
        $Invoke = "SetProperty"
    } Else {
        $Invoke = "GetProperty"
    }
    [__ComObject].InvokeMember($Property, $Invoke, $Null, $ComObject, $Value)
}
function New-FakeDirectoryEntry {
    <#
        .SYNOPSIS
        Returns a PSCustomObject in place of a DirectoryEntry for certain WinNT security principals that do not have objects in the directory
        .DESCRIPTION
        Retrieve a directory entry using either the WinNT or LDAP provider for ADSI
        .EXAMPLE
        ----------  EXAMPLE 1  ----------
        As the current user, bind to the current domain and retrieve the DirectoryEntry for the root of the domain

        Get-DirectoryEntry
    #>
    [OutputType([PSObject[]])]
    [CmdletBinding()]
    param (

        <#
        Path to the directory object to retrieve
        Defaults to the root of the current domain (but don't use it for that, just do this instead: [System.DirectoryServices.DirectorySearcher]::new())
        #>
        [string]$DirectoryPath = (([System.DirectoryServices.DirectorySearcher]'').SearchRoot.Path),

        <#
        Credentials to use to bind to the directory
        Defaults to the credentials of the current user
        #>
        [pscredential]$Credential,

        # Properties of the target object to retrieve
        [string[]]$PropertiesToLoad,

        <#
        A hashtable containing cached directory entries so they don't have to be retrieved from the directory again
        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{}))

    )

    $DirectoryEntry = $null
    if ($null -eq $DirectoryEntryCache[$DirectoryPath]) {
        <#
        The WinNT provider only throws an error if you try to retrieve certain accounts/identities
        We will create own dummy objects instead of performing the query
        #>
        switch -regex ($DirectoryPath) {

            '^WinNT\:\/\/[^\/]*\/CREATOR OWNER$' {
                $SidByteAray = 'S-1-3-0' | ConvertTo-SidByteArray
                $DirectoryEntry = [pscustomobject]@{
                    Name            = 'CREATOR OWNER'
                    Description     = 'A SID to be replaced by the SID of the user who creates a new object. This SID is used in inheritable ACEs.'
                    objectSid       = $SidByteAray
                    Parent          = $DirectoryPath | Split-Path -Parent
                    Path            = $DirectoryPath
                    Properties      = @{
                        Name        = 'CREATOR OWNER'
                        Description = 'A SID to be replaced by the SID of the user who creates a new object. This SID is used in inheritable ACEs.'
                        objectSid   = $SidByteAray
                    }
                    SchemaClassName = 'User'
                    SchemaEntry     = [System.DirectoryServices.DirectoryEntry]
                }
                $DirectoryEntry | Add-Member -MemberType ScriptMethod -Name RefreshCache -Force -Value {}

            }
            '^WinNT\:\/\/[^\/]*\/SYSTEM$' {
                $SidByteAray = 'S-1-5-18' | ConvertTo-SidByteArray
                $DirectoryEntry = [pscustomobject]@{
                    Name            = 'SYSTEM'
                    Description     = 'By default, the SYSTEM account is granted Full Control permissions to all files on an NTFS volume'
                    objectSid       = $SidByteAray
                    Parent          = $DirectoryPath | Split-Path -Parent
                    Path            = $DirectoryPath
                    Properties      = @{
                        Name        = 'SYSTEM'
                        Description = 'By default, the SYSTEM account is granted Full Control permissions to all files on an NTFS volume'
                        objectSid   = $SidByteAray
                    }
                    SchemaClassName = 'User'
                    SchemaEntry     = [System.DirectoryServices.DirectoryEntry]
                }
                $DirectoryEntry | Add-Member -MemberType ScriptMethod -Name RefreshCache -Force -Value {}

            }
            '^WinNT\:\/\/[^\/]*\/INTERACTIVE$' {
                $SidByteAray = 'S-1-5-4' | ConvertTo-SidByteArray
                $DirectoryEntry = [pscustomobject]@{
                    Name            = 'INTERACTIVE'
                    Description     = 'Users who log on for interactive operation. This is a group identifier added to the token of a process when it was logged on interactively.'
                    objectSid       = $SidByteAray
                    Parent          = $DirectoryPath | Split-Path -Parent
                    Path            = $DirectoryPath
                    Properties      = @{
                        Name        = 'INTERACTIVE'
                        Description = 'Users who log on for interactive operation. This is a group identifier added to the token of a process when it was logged on interactively.'
                        objectSid   = $SidByteAray
                    }
                    SchemaClassName = 'Group'
                    SchemaEntry     = [System.DirectoryServices.DirectoryEntry]
                }
                $DirectoryEntry | Add-Member -MemberType ScriptMethod -Name RefreshCache -Force -Value {}

            }
            '^WinNT\:\/\/[^\/]*\/Authenticated Users$' {
                $SidByteAray = 'S-1-5-11' | ConvertTo-SidByteArray
                $DirectoryEntry = [pscustomobject]@{
                    Name            = 'Authenticated Users'
                    Description     = 'Any user who accesses the system through a sign-in process has the Authenticated Users identity.'
                    objectSid       = $SidByteAray
                    Parent          = $DirectoryPath | Split-Path -Parent
                    Path            = $DirectoryPath
                    Properties      = @{
                        Name        = 'Authenticated Users'
                        Description = 'Any user who accesses the system through a sign-in process has the Authenticated Users identity.'
                        objectSid   = $SidByteAray
                    }
                    SchemaClassName = 'Group'
                    SchemaEntry     = [System.DirectoryServices.DirectoryEntry]
                }
                $DirectoryEntry | Add-Member -MemberType ScriptMethod -Name RefreshCache -Force -Value {}
            }
            default {

                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-DirectoryEntry`t[System.DirectoryServices.DirectoryEntry]::new('$DirectoryPath')"
                if ($Credential) {
                    $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath, $($Credential.UserName), $($Credential.GetNetworkCredential().password))
                } else {
                    $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath)
                }

            }

        }

        $DirectoryEntryCache[$DirectoryPath] = $DirectoryEntry
    } else {
        #Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-DirectoryEntry`tDirectoryEntryCache hit for '$DirectoryPath'"
        $DirectoryEntry = $DirectoryEntryCache[$DirectoryPath]
    }

    try {
        if ($PropertiesToLoad) {
            # If the $DirectoryPath was invalid, this line will return an error
            $null = $DirectoryEntry.RefreshCache($PropertiesToLoad)
        }

        Write-Output $DirectoryEntry
    } catch {
        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tGet-DirectoryEntry`t'$DirectoryPath' could not be retrieved."

        # Ensure that the error message appears on 1 line
        # Use .Trim() to remove leading and trailing whitespace
        # Use -replace to remove an errant line break in the following specific error I encountered: The following exception occurred while retrieving member "RefreshCache": "The group name could not be found.`r`n"
        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tGet-DirectoryEntry`t'$($_.Exception.Message.Trim() -replace '\s"',' "')"
    }

}
function Resolve-IdentityReference {
    param (
        [psobject[]]$AccessControlEntry,

        [hashtable]$KnownServers = [hashtable]::Synchronized(@{})
    )
    begin {}
    process {
        ForEach ($ThisACE in $AccessControlEntry) {
            $ThisServer = $null
            $AdsiProvider = $null
            $ThisServer = $ThisACE.Path -split '\\' | Where-Object { $_ -ne '' } | Select-Object -First 1
            $ResolvedIdentityReference = $ThisACE.IdentityReference -replace 'NT AUTHORITY', $ThisServer -replace 'BUILTIN', $ThisServer

            $ThisServer = $ResolvedIdentityReference -split '\\' | Where-Object { $_ -ne '' } | Select-Object -First 1
            $AdsiProvider = Find-AdsiProvider -AdsiServer $ThisServer -KnownServers $KnownServers
            $ThisACE | Add-Member -PassThru -Force -NotePropertyMembers @{
                ResolvedIdentityReference = $ResolvedIdentityReference
                AdsiProvider              = $AdsiProvider
            }
        }
    }
    end {}
}
function Search-Directory {
    param (

        [string]$DirectoryPath = (([adsisearcher]'').SearchRoot.Path),
        [string]$Filter,
        [int]$PageSize = 1000,
        [string[]]$PropertiesToLoad,
        [pscredential]$Credential,
        [string]$SearchScope = 'subtree',
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{}))

    )

    if ($Credential) {
        #$DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath,$($Credential.UserName),$($Credential.GetNetworkCredential().password))
        $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath -Credential $Credential -DirectoryEntryCache $DirectoryEntryCache
    } else {
        #$DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath)
        $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath -DirectoryEntryCache $DirectoryEntryCache
    }

    $DirectorySearcher = [System.DirectoryServices.DirectorySearcher]::new($DirectoryEntry)

    if ($Filter) {
        $DirectorySearcher.Filter = $Filter
    }

    $DirectorySearcher.PageSize = $PageSize
    $DirectorySearcher.SearchScope = $SearchScope

    ForEach ($Property in $PropertiesToLoad) {
        $null = $DirectorySearcher.PropertiesToLoad.Add($Property)
    }

    $SearchResultCollection = $DirectorySearcher.FindAll()
    #$null = $DirectorySearcher.Dispose()
    #$null = $DirectoryEntry.Dispose()
    $Output = [System.DirectoryServices.SearchResult[]]::new($SearchResultCollection.Count)
    $SearchResultCollection.CopyTo($Output, 0)
    #$null = $SearchResultCollection.Dispose()
    Write-Output $Output

}
function Test-PublicFunction_511f9c72-4f82-4b90-be93-ad7576481d5b {
    <#
        .SYNOPSIS
        Short synopsis of the function
        .DESCRIPTION
        Long description of the function
        .EXAMPLE
        ----------  EXAMPLE 1  ----------
        This is a demo example with no parameters. It may not even be valid.

        Test-PublicFunction_511f9c72-4f82-4b90-be93-ad7576481d5b
    #>
    [OutputType([PSObject[]])]
    [CmdletBinding()]
    param (

        # Comment-based help for $InputObject
        [Parameter(ValueFromPipeline)]
        [PSObject[]]$InputObject

    )
    begin {

    }
    process {
        ForEach ($ThisObject in $InputObject) {
            Write-Output $ThisObject
        }
    }
    end {

    }
}

<#$ScriptFiles = Get-ChildItem -Path "$PSScriptRoot\*.ps1" -Recurse

# Dot source any functions
ForEach ($ThisScript in $ScriptFiles) {
    # Dot source the function
    . $($ThisScript.FullName)
}

# Add any custom C# classes as usable (exported) types
$CSharpFiles = Get-ChildItem -Path "$PSScriptRoot\*.cs"
ForEach ($ThisFile in $CSharpFiles) {
    Add-Type -Path $ThisFile.FullName -ErrorAction Stop
}

# Export any public functions
$PublicScriptFiles = $ScriptFiles | Where-Object -FilterScript {
    ($_.PSParentPath | Split-Path -Leaf) -eq 'public'
}
$publicFunctions = $PublicScriptFiles.BaseName
Export-ModuleMember -Function @('Add-DomainFqdnToLdapPath','Add-SidInfo','ConvertTo-DistinguishedName','ConvertTo-Fqdn','ConvertTo-HexStringRepresentation','ConvertTo-HexStringRepresentationForLDAPFilterString','ConvertTo-SidByteArray','Expand-AdsiGroupMember','Expand-IdentityReference','Expand-WinNTGroupMember','Find-AdsiProvider','Get-ADSIGroup','Get-ADSIGroupMember','Get-CurrentDomain','Get-DirectoryEntry','Get-TrustedDomainSidNameMap','Get-WinNTGroupMember','Invoke-ComObject','New-FakeDirectoryEntry','Resolve-IdentityReference','Search-Directory','Test-PublicFunction_511f9c72-4f82-4b90-be93-ad7576481d5b')
#>
Export-ModuleMember -Function @('Add-DomainFqdnToLdapPath','Add-SidInfo','ConvertTo-DistinguishedName','ConvertTo-Fqdn','ConvertTo-HexStringRepresentation','ConvertTo-HexStringRepresentationForLDAPFilterString','ConvertTo-SidByteArray','Expand-AdsiGroupMember','Expand-IdentityReference','Expand-WinNTGroupMember','Find-AdsiProvider','Get-ADSIGroup','Get-ADSIGroupMember','Get-CurrentDomain','Get-DirectoryEntry','Get-TrustedDomainSidNameMap','Get-WinNTGroupMember','Invoke-ComObject','New-FakeDirectoryEntry','Resolve-IdentityReference','Search-Directory','Test-PublicFunction_511f9c72-4f82-4b90-be93-ad7576481d5b')





















