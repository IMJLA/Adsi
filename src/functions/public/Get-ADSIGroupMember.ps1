function Get-ADSIGroupMember {
    <#
        .SYNOPSIS
        Get members of a group from the LDAP provider
        .DESCRIPTION
        Use ADSI to get members of a group from the LDAP provider
        Return the group's DirectoryEntry plus a FullMembers property containing the member DirectoryEntries
        .INPUTS
        [System.DirectoryServices.DirectoryEntry]$DirectoryEntry
        .OUTPUTS
        [System.DirectoryServices.DirectoryEntry] plus a FullMembers property
        .EXAMPLE
        [System.DirectoryServices.DirectoryEntry]::new('LDAP://ad.contoso.com/CN=Administrators,CN=BuiltIn,DC=ad,DC=contoso,DC=com') | Get-ADSIGroupMember

        Get members of the domain Administrators group
    #>
    [OutputType([System.DirectoryServices.DirectoryEntry])]
    param (

        # Directory entry of the LDAP group whose members to get
        [Parameter(ValueFromPipeline)]
        $Group,

        # Properties of the group members to find in the directory
        [string[]]$PropertiesToLoad,

        <#
        Hashtable containing cached directory entries so they don't have to be retrieved from the directory again
        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{}))

    )
    begin {

        $PathRegEx = '(?<Path>LDAP:\/\/[^\/]*)'
        $DomainRegEx = '(?i)DC=\w{1,}?\b'

        $SearchParameters = @{
            PropertiesToLoad    = $PropertiesToLoad
            DirectoryEntryCache = $DirectoryEntryCache
        }

        $TrustedDomainSidNameMap = Get-TrustedDomainSidNameMap -DirectoryEntryCache $DirectoryEntryCache

    }
    process {

        foreach ($ThisGroup in $Group) {

            # Recursive search
            $SearchParameters['Filter'] = "(memberof:1.2.840.113556.1.4.1941:=$($ThisGroup.Properties['distinguishedname']))"

            # Non-recursive search
            #$SearchParameters['Filter'] = "(memberof=$($ThisGroup.Properties['distinguishedname']))"

            if ($ThisGroup.Path -match $PathRegEx) {

                $SearchParameters['DirectoryPath'] = $Matches.Path | Add-DomainFqdnToLdapPath

                if ($ThisGroup.Path -match $DomainRegEx) {
                    $Domain = ([regex]::Matches($ThisGroup.Path, $DomainRegEx) | ForEach-Object { $_.Value }) -join ','
                    $SearchParameters['DirectoryPath'] = "LDAP://$Domain" | Add-DomainFqdnToLdapPath
                } else {
                    $SearchParameters['DirectoryPath'] = $ThisGroup.Path | Add-DomainFqdnToLdapPath
                }

            } else {
                $SearchParameters['DirectoryPath'] = $ThisGroup.Path | Add-DomainFqdnToLdapPath
            }

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

            $ProcessedGroupMembers = $CurrentADGroupMembers | Expand-AdsiGroupMember -DirectoryEntryCache $DirectoryEntryCache -TrustedDomainSidNameMap $TrustedDomainSidNameMap
            $ThisGroup |
            Add-Member -MemberType NoteProperty -Name FullMembers -Value $ProcessedGroupMembers -Force -PassThru

        }
    }
    end {}
}
