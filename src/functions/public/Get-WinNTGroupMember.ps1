function Get-WinNTGroupMember {

    <#
    .SYNOPSIS
    Get members of a group from the WinNT provider
    .DESCRIPTION
    Get members of a group from the WinNT provider
    Convert them from COM objects into usable DirectoryEntry objects
    .INPUTS
    [System.DirectoryServices.DirectoryEntry]$DirectoryEntry
    .OUTPUTS
    [System.DirectoryServices.DirectoryEntry] for each group member
    .EXAMPLE
    [System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrators') | Get-WinNTGroupMember

    Get members of the local Administrators group
    #>

    [OutputType([System.DirectoryServices.DirectoryEntry])]

    param (

        # DirectoryEntry [System.DirectoryServices.DirectoryEntry] of the WinNT group whose members to get
        [Parameter(ValueFromPipeline)]
        $DirectoryEntry,

        # Properties of the group members to find in the directory
        [string[]]$PropertiesToLoad = @('distinguishedName', 'groupType', 'member', 'name', 'objectClass', 'objectSid', 'primaryGroupToken', 'samAccountName'),

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    begin {

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

        $Log = @{ 'Cache' = $Cache }
        $DirectoryParams = @{ 'Cache' = $Cache ; 'PropertiesToLoad' = $PropertiesToLoad }

    }

    process {

        ForEach ($ThisDirEntry in $DirectoryEntry) {

            $LogSuffix = "# For '$($ThisDirEntry.Path)'"
            $Log['Suffix'] = " $LogSuffix"
            $ThisSplitPath = Split-DirectoryPath -DirectoryPath $ThisDirEntry.Path
            $SourceDomainNetbiosOrFqdn = $ThisSplitPath['Domain']
            Write-LogMsg @Log -Text "`$GroupDomain = Get-AdsiServer -Netbios '$SourceDomainNetbiosOrFqdn' -Cache `$Cache"
            $GroupDomain = Get-AdsiServer -Netbios $SourceDomainNetbiosOrFqdn -Cache $Cache

            if (-not $GroupDomain) {

                Write-LogMsg @Log -Text "`$GroupDomain = Get-AdsiServer -Fqdn '$SourceDomainNetbiosOrFqdn' -Cache `$Cache"
                $GroupDomain = Get-AdsiServer -Fqdn $SourceDomainNetbiosOrFqdn -Cache $Cache

            }

            if (
                $null -ne $ThisDirEntry.Properties['groupType'] -or
                $ThisDirEntry.schemaclassname -in @('group', 'SidTypeWellKnownGroup', 'SidTypeAlias')
            ) {

                Write-LogMsg @Log -Text "`$DirectoryMembers = Invoke-IADsGroupMembersMethod -DirectoryEntry `$ThisDirEntry"
                $DirectoryMembers = Invoke-IADsGroupMembersMethod -DirectoryEntry $ThisDirEntry

                $MembersToGet = @{
                    'WinNTMembers' = @()
                }

                Write-LogMsg @Log -Text "Find-WinNTGroupMember -ComObject `$DirectoryMembers -Out $MembersToGet -LogSuffix `"$LogSuffix`" -DirectoryEntry `$ThisDirEntry -GroupDomain `$GroupDomain -Cache `$Cache # for $(@($DirectoryMembers).Count) members"
                Find-WinNTGroupMember -ComObject $DirectoryMembers -Out $MembersToGet -LogSuffix $LogSuffix -DirectoryEntry $ThisDirEntry -GroupDomain $GroupDomain -Cache $Cache

                # Get and Expand the directory entries for the WinNT group members
                ForEach ($ThisMember in $MembersToGet['WinNTMembers']) {

                    Write-LogMsg @Log -Text "`$MemberDirectoryEntry = Get-DirectoryEntry -DirectoryPath '$ThisMember'" -Expand $DirectoryParams -MapKeyName 'LogCacheMap'
                    $MemberDirectoryEntry = Get-DirectoryEntry -DirectoryPath $ThisMember @DirectoryParams
                    Write-LogMsg @Log -Text "Expand-WinNTGroupMember = Get-DirectoryEntry -DirectoryEntry `$MemberDirectoryEntry -Cache `$Cache"
                    Expand-WinNTGroupMember -DirectoryEntry $MemberDirectoryEntry -AccountProperty $PropertiesToLoad -Cache $Cache

                }

                # Remove the WinNTMembers key from the hashtable so the only remaining keys are distinguishedName(s) of LDAP directories
                $MembersToGet.Remove('WinNTMembers')

                # Get and Expand the directory entries for the LDAP group members
                ForEach ($MemberPath in $MembersToGet.Keys) {

                    $ThisMemberToGet = $MembersToGet[$MemberPath]
                    Write-LogMsg @Log -Text "`$MemberDirectoryEntries = Search-Directory -DirectoryPath '$MemberPath' -Filter '(|$ThisMemberToGet)'" -Expand $DirectoryParams -MapKeyName 'LogCacheMap'
                    $MemberDirectoryEntries = Search-Directory -DirectoryPath $MemberPath -Filter "(|$ThisMemberToGet)" @DirectoryParams
                    Write-LogMsg @Log -Text "Expand-WinNTGroupMember -DirectoryEntry `$MemberDirectoryEntries -Cache `$Cache"
                    Expand-WinNTGroupMember -DirectoryEntry $MemberDirectoryEntries -AccountProperty $PropertiesToLoad -Cache $Cache

                }

            } else {
                Write-LogMsg @Log -Text ' # Is not a group'
            }

        }

    }

}
