function Get-AdsiGroupMember {

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
    [System.DirectoryServices.DirectoryEntry]::new('LDAP://ad.contoso.com/CN=Administrators,CN=BuiltIn,DC=ad,DC=contoso,DC=com') |
    Get-AdsiGroupMember -Cache $Cache

    Retrieves all members of the domain's Administrators group, including both direct members and those
    who inherit membership through their primary group. The function returns the original group DirectoryEntry
    object with an added FullMembers property containing all member DirectoryEntry objects. This
    approach ensures proper resolution of all group memberships regardless of how they are assigned.
    #>

    [OutputType([System.DirectoryServices.DirectoryEntry])]

    param (

        # Directory entry of the LDAP group whose members to get
        [Parameter(ValueFromPipeline)]
        $Group,

        # Properties of the group members to find in the directory
        [string[]]$PropertiesToLoad = @('distinguishedName', 'groupType', 'member', 'name', 'objectClass', 'objectSid', 'primaryGroupToken', 'samAccountName'),

        <#
        Perform a non-recursive search of the memberOf attribute

        Otherwise the search will be recursive by default
        #>
        [switch]$NoRecurse,

        <#
        Search the primaryGroupId attribute only

        Ignore the memberOf attribute
        #>
        [switch]$PrimaryGroupOnly,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    begin {

        $Log = @{ Cache = $Cache }
        $PathRegEx = '(?<Path>LDAP:\/\/[^\/]*)'
        $DomainRegEx = '(?i)DC=\w{1,}?\b'

        # Add the bare minimum required properties
        $PropertiesToLoad = $PropertiesToLoad + @(
            'distinguishedName',
            'grouptype',
            'member',
            'name',
            'objectClass',
            'objectSid',
            'primaryGroupToken',
            'samAccountName'
        )

        $PropertiesToLoad = $PropertiesToLoad |
            Sort-Object -Unique

        $SearchParams = @{
            Cache            = $Cache
            PropertiesToLoad = $PropertiesToLoad
        }

    }

    process {

        foreach ($ThisGroup in $Group) {

            $Log['Suffix'] = " # for ADSI group named '$($ThisGroup.Properties.name)'"

            if (-not $ThisGroup.Properties['primaryGroupToken']) {
                $ThisGroup.RefreshCache('primaryGroupToken')
            }

            # The memberOf attribute does not reflect a user's Primary Group membership so the primaryGroupId attribute must be searched
            $primaryGroupIdFilter = "(primaryGroupId=$($ThisGroup.Properties['primaryGroupToken']))"

            if ($PrimaryGroupOnly) {
                $SearchParams['Filter'] = $primaryGroupIdFilter
            } else {

                if ($NoRecurse) {

                    # Non-recursive search of the memberOf attribute
                    $MemberOfFilter = "(memberOf=$($ThisGroup.Properties['distinguishedname']))"

                } else {

                    # Recursive search of the memberOf attribute
                    $MemberOfFilter = "(memberOf:1.2.840.113556.1.4.1941:=$($ThisGroup.Properties['distinguishedname']))"

                }

                $SearchParams['Filter'] = "(|$MemberOfFilter$primaryGroupIdFilter)"
            }

            if ($ThisGroup.Path -match $PathRegEx) {

                $SearchParams['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath $Matches.Path -Cache $Cache

                if ($ThisGroup.Path -match $DomainRegEx) {

                    $Domain = ([regex]::Matches($ThisGroup.Path, $DomainRegEx) | ForEach-Object { $_.Value }) -join ','
                    $SearchParams['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath "LDAP://$Domain" -Cache $Cache

                } else {
                    $SearchParams['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath $ThisGroup.Path -Cache $Cache
                }

            } else {
                $SearchParams['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath $ThisGroup.Path -Cache $Cache
            }

            Write-LogMsg @Log -Text 'Search-Directory' -Expand $SearchParams -ExpansionMap $Cache.Value['LogCacheMap'].Value
            $GroupMemberSearch = Search-Directory @SearchParams
            #Write-LogMsg @Log -Text " # '$($GroupMemberSearch.Count)' results for Search-Directory -DirectoryPath '$($SearchParams['DirectoryPath'])' -Filter '$($SearchParams['Filter'])'"

            if ($GroupMemberSearch.Count -gt 0) {

                $DirectoryEntryParams = @{
                    Cache            = $Cache
                    PropertiesToLoad = $PropertiesToLoad
                }

                $CurrentADGroupMembers = [System.Collections.Generic.List[System.DirectoryServices.DirectoryEntry]]::new()

                $MembersThatAreGroups = $GroupMemberSearch |
                    Where-Object -FilterScript { $_.Properties['objectClass'] -contains 'group' }

                $DirectoryEntryParams = @{
                    Cache            = $Cache
                    PropertiesToLoad = $PropertiesToLoad
                }

                if ($MembersThatAreGroups.Count -gt 0) {

                    $FilterBuilder = [System.Text.StringBuilder]::new('(|')

                    ForEach ($ThisMember in $MembersThatAreGroups) {
                        $null = $FilterBuilder.Append("(primaryGroupId=$($ThisMember.Properties['primaryGroupToken'])))")
                    }

                    $null = $FilterBuilder.Append(')')
                    $PrimaryGroupFilter = $FilterBuilder.ToString()
                    $SearchParams['Filter'] = $PrimaryGroupFilter
                    Write-LogMsg @Log -Text 'Search-Directory' -Expand $SearchParams -ExpansionMap $Cache.Value['LogCacheMap'].Value
                    $PrimaryGroupMembers = Search-Directory @SearchParams

                    ForEach ($ThisMember in $PrimaryGroupMembers) {

                        $FQDNPath = Add-DomainFqdnToLdapPath -DirectoryPath $ThisMember.Path -Cache $Cache
                        $DirectoryEntry = $null
                        Write-LogMsg @Log -Text "Get-DirectoryEntry -DirectoryPath '$FQDNPath'" -Expand $DirectoryEntryParams -ExpansionMap $Cache.Value['LogCacheMap'].Value
                        $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $FQDNPath @DirectoryEntryParams

                        if ($DirectoryEntry) {
                            $null = $CurrentADGroupMembers.Add($DirectoryEntry)
                        }

                    }

                }

                ForEach ($ThisMember in $GroupMemberSearch) {

                    $FQDNPath = Add-DomainFqdnToLdapPath -DirectoryPath $ThisMember.Path -Cache $Cache
                    $DirectoryEntry = $null
                    Write-LogMsg @Log -Text "Get-DirectoryEntry -DirectoryPath '$FQDNPath'" -Expand $DirectoryEntryParams -ExpansionMap $Cache.Value['LogCacheMap'].Value
                    $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $FQDNPath @DirectoryEntryParams

                    if ($DirectoryEntry) {
                        $null = $CurrentADGroupMembers.Add($DirectoryEntry)
                    }

                }

            } else {
                $CurrentADGroupMembers = $null
            }

            Write-LogMsg @Log -Text "Expand-AdsiGroupMember -DirectoryEntry `$CurrentADGroupMembers -Cache `$Cache # for $(@($CurrentADGroupMembers).Count) members"
            $ProcessedGroupMembers = Expand-AdsiGroupMember -DirectoryEntry $CurrentADGroupMembers -PropertiesToLoad $PropertiesToLoad -Cache $Cache
            Add-Member -InputObject $ThisGroup -MemberType NoteProperty -Name FullMembers -Value $ProcessedGroupMembers -Force -PassThru

        }

    }

}
