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
        [System.DirectoryServices.DirectoryEntry]::new('LDAP://ad.contoso.com/CN=Administrators,CN=BuiltIn,DC=ad,DC=contoso,DC=com') | Get-AdsiGroupMember

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

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    begin {

        $Log = @{ ThisHostname = $ThisHostname ; Type = $DebugOutputStream ; Buffer = $Cache.Value['LogBuffer'] ; WhoAmI = $WhoAmI }

        $LogThis = @{ ThisHostname = $ThisHostname ; Cache = $Cache ; WhoAmI = $WhoAmI ; DebugOutputStream = $DebugOutputStream }

        $PathRegEx = '(?<Path>LDAP:\/\/[^\/]*)'
        $DomainRegEx = '(?i)DC=\w{1,}?\b'
        $PropertiesToLoad += 'primaryGroupToken', 'objectSid', 'objectClass'

        $PropertiesToLoad = $PropertiesToLoad |
        Sort-Object -Unique

        $SearchParameters = @{
            PropertiesToLoad = $PropertiesToLoad
            ThisFqdn         = $ThisFqdn
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
                $SearchParameters['Filter'] = $primaryGroupIdFilter
            } else {

                if ($NoRecurse) {

                    # Non-recursive search of the memberOf attribute
                    $MemberOfFilter = "(memberOf=$($ThisGroup.Properties['distinguishedname']))"

                } else {

                    # Recursive search of the memberOf attribute
                    $MemberOfFilter = "(memberOf:1.2.840.113556.1.4.1941:=$($ThisGroup.Properties['distinguishedname']))"

                }

                $SearchParameters['Filter'] = "(|$MemberOfFilter$primaryGroupIdFilter)"
            }

            if ($ThisGroup.Path -match $PathRegEx) {

                $SearchParameters['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath $Matches.Path -ThisFqdn $ThisFqdn @LogThis

                if ($ThisGroup.Path -match $DomainRegEx) {

                    $Domain = ([regex]::Matches($ThisGroup.Path, $DomainRegEx) | ForEach-Object { $_.Value }) -join ','
                    $SearchParameters['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath "LDAP://$Domain" -ThisFqdn $ThisFqdn @LogThis

                } else {
                    $SearchParameters['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath $ThisGroup.Path -ThisFqdn $ThisFqdn @LogThis
                }

            } else {
                $SearchParameters['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath $ThisGroup.Path -ThisFqdn $ThisFqdn @LogThis
            }

            Write-LogMsg @Log -Text 'Search-Directory' -Expand $SearchParameters, $LogThis -ExpandKeyMap @{ 'Cache' = '$Cache' }
            $GroupMemberSearch = Search-Directory @SearchParameters @LogThis
            #Write-LogMsg @Log -Text " # '$($GroupMemberSearch.Count)' results for Search-Directory -DirectoryPath '$($SearchParameters['DirectoryPath'])' -Filter '$($SearchParameters['Filter'])'"

            if ($GroupMemberSearch.Count -gt 0) {

                $DirectoryEntryParams = @{
                    PropertiesToLoad = $PropertiesToLoad
                    ThisFqdn         = $ThisFqdn
                }

                $CurrentADGroupMembers = [System.Collections.Generic.List[System.DirectoryServices.DirectoryEntry]]::new()

                $MembersThatAreGroups = $GroupMemberSearch |
                Where-Object -FilterScript { $_.Properties['objectClass'] -contains 'group' }

                $DirectoryEntryParams = @{
                    PropertiesToLoad = $PropertiesToLoad
                    ThisFqdn         = $ThisFqdn
                }

                if ($MembersThatAreGroups.Count -gt 0) {

                    $FilterBuilder = [System.Text.StringBuilder]::new('(|')

                    ForEach ($ThisMember in $MembersThatAreGroups) {
                        $null = $FilterBuilder.Append("(primaryGroupId=$($ThisMember.Properties['primaryGroupToken'])))")
                    }

                    $null = $FilterBuilder.Append(')')
                    $PrimaryGroupFilter = $FilterBuilder.ToString()
                    $SearchParameters['Filter'] = $PrimaryGroupFilter
                    Write-LogMsg @Log -Text 'Search-Directory' -Expand $SearchParameters, $LogThis -ExpandKeyMap @{ 'Cache' = '$Cache' }
                    $PrimaryGroupMembers = Search-Directory @SearchParameters @LogThis

                    ForEach ($ThisMember in $PrimaryGroupMembers) {

                        $FQDNPath = Add-DomainFqdnToLdapPath -DirectoryPath $ThisMember.Path -ThisFqdn $ThisFqdn @LogThis
                        $DirectoryEntry = $null
                        Write-LogMsg @Log -Text "Get-DirectoryEntry -DirectoryPath '$FQDNPath'" -Expand $DirectoryEntryParams, $LogThis -ExpandKeyMap @{ 'Cache' = '$Cache' }
                        $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $FQDNPath @DirectoryEntryParams @LogThis

                        if ($DirectoryEntry) {
                            $null = $CurrentADGroupMembers.Add($DirectoryEntry)
                        }

                    }

                }

                ForEach ($ThisMember in $GroupMemberSearch) {

                    $FQDNPath = Add-DomainFqdnToLdapPath -DirectoryPath $ThisMember.Path -ThisFqdn $ThisFqdn @LogThis
                    $DirectoryEntry = $null
                    Write-LogMsg @Log -Text "Get-DirectoryEntry -DirectoryPath '$FQDNPath'" -Expand $DirectoryEntryParams, $LogThis -ExpandKeyMap @{ 'Cache' = '$Cache' }
                    $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $FQDNPath @DirectoryEntryParams @LogThis

                    if ($DirectoryEntry) {
                        $null = $CurrentADGroupMembers.Add($DirectoryEntry)
                    }

                }

            } else {
                $CurrentADGroupMembers = $null
            }

            Write-LogMsg @Log -Text "Expand-AdsiGroupMember -DirectoryEntry `$CurrentADGroupMembers # for $(@($CurrentADGroupMembers).Count) members"
            $ProcessedGroupMembers = Expand-AdsiGroupMember -DirectoryEntry $CurrentADGroupMembers -ThisFqdn $ThisFqdn @LogThis
            Add-Member -InputObject $ThisGroup -MemberType NoteProperty -Name FullMembers -Value $ProcessedGroupMembers -Force -PassThru

        }

    }

}
