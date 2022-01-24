function Expand-AdsiGroupMember {

    param (

        [parameter(ValueFromPipeline)]
        $DirectoryEntry,
        
        [string[]]$PropertiesToLoad = @('operatingSystem','objectSid','samAccountName','objectClass','distinguishedName','name','grouptype','description','managedby','member','objectClass','Department','Title'),

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
                    $DomainSid = $SID.Substring(0,$Sid.LastIndexOf("-"))
                    $Domain = $TrustedDomainSidNameMap[$DomainSid]
                    
                    $Success = $true
                    try {
                        $Principal = Get-DirectoryEntry -DirectoryPath "LDAP://$($Domain.Dns)/<SID=$SID>" -DirectoryEntryCache $DirectoryEntryCache
                    }
                    catch {
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

            }
            else {
                $Principal = $Entry 
            }
                        
            $Principal | Add-SidInfo -DirectoryEntryCache $DirectoryEntryCache -TrustedDomainSidNameMap $TrustedDomainSidNameMap
        
        }
    }

}