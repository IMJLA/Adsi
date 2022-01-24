function Get-ADSIGroupMember {

    <#
    Get a group and its members
    #>

    param (

        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        $Group,

        [string[]]$PropertiesToLoad = @('operatingSystem','objectSid','samAccountName','objectClass','distinguishedName','name','grouptype','description','managedby','member','objectClass','department','title'),

        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{}))

    )
    begin{}
    process{

        foreach ($ThisGroup in $Group) {
            
            $SearchParameters = @{

                # Recursive search
                Filter = "(memberof:1.2.840.113556.1.4.1941:=$($ThisGroup.Properties['distinguishedname']))"

                # Non-recursive search
                #Filter = "(memberof=$($ThisGroup.Properties['distinguishedname']))"

                PropertiesToLoad = $PropertiesToLoad

                DirectoryEntryCache = $DirectoryEntryCache

            }
                        
            $PathRegEx = '(?<Path>LDAP:\/\/[^\/]*)'
            if ($ThisGroup.Path -match $PathRegEx) {
                            
                $SearchParameters['DirectoryPath'] = $Matches.Path | Add-DomainFqdnToLdapPath
               
                $DomainRegEx = '(?i)DC=\w{1,}?\b'
                if ($ThisGroup.Path -match $DomainRegEx) {
                    $Domain = ([regex]::Matches($ThisGroup.Path,$DomainRegEx) | ForEach-Object {$_.Value}) -join ','
                    $SearchParameters['DirectoryPath'] = "LDAP://$Domain" | Add-DomainFqdnToLdapPath
                }
                else {
                    $SearchParameters['DirectoryPath'] = $ThisGroup.Path | Add-DomainFqdnToLdapPath
                }

            }
            else {
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

            }
            else {
                $CurrentADGroupMembers = $null
            }

            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-AdsiGroupMember`t$($ThisGroup.Properties.name) has $(($CurrentADGroupMembers | Measure-Object).Count) members"
            
            $TrustedDomainSidNameMap = Get-TrustedDomainSidNameMap -DirectoryEntryCache $DirectoryEntryCache
            $ProcessedGroupMembers = $CurrentADGroupMembers | Expand-AdsiGroupMember -DirectoryEntryCache $DirectoryEntryCache -TrustedDomainSidNameMap $TrustedDomainSidNameMap
            $ThisGroup |
                Add-Member -MemberType NoteProperty -Name FullMembers -Value $ProcessedGroupMembers -Force -PassThru
            
        }
    }
    end{}
}