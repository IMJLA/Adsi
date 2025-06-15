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
    [System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrators') | Get-WinNTGroupMember -Cache $Cache

    Retrieves all members of the local Administrators group and returns them as DirectoryEntry objects.
    This allows for further processing of group membership information, including nested groups, and provides
    a consistent object format that works well with other ADSI functions. The Cache parameter ensures efficient
    operation by avoiding redundant directory queries.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Get-WinNTGroupMember')]
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

        $PropertiesToLoad = $PropertiesToLoad | Sort-Object -Unique

        $Log = @{ 'Cache' = $Cache }
        $DirectoryParams = @{ 'Cache' = $Cache ; 'PropertiesToLoad' = $PropertiesToLoad }

    }

    process {

        ForEach ($ThisDirEntry in $DirectoryEntry) {

            $LogSuffix = "# For '$($ThisDirEntry.Path)'"
            $Log['Suffix'] = " $LogSuffix"

            if (
                $null -ne $ThisDirEntry.Properties['groupType'] -or
                $ThisDirEntry.schemaclassname -in @('group', 'SidTypeWellKnownGroup', 'SidTypeAlias')
            ) {

                Write-LogMsg @Log -Text "`$DirectoryMembers = Invoke-IADsGroupMembersMethod -DirectoryEntry `$ThisDirEntry"
                $DirectoryMembers = Invoke-IADsGroupMembersMethod -DirectoryEntry $ThisDirEntry

                $MembersToGet = @{
                    'WinNTMembers' = @()
                }

                Write-LogMsg @Log -Text "Find-WinNTGroupMember -ComObject `$DirectoryMembers -Out $MembersToGet -LogSuffix `"$LogSuffix`" -DirectoryEntry `$ThisDirEntry -Cache `$Cache # for $(@($DirectoryMembers).Count) members"
                Find-WinNTGroupMember -ComObject $DirectoryMembers -Out $MembersToGet -LogSuffix $LogSuffix -DirectoryEntry $ThisDirEntry -Cache $Cache

                # Get and Expand the directory entries for the WinNT group members
                ForEach ($ThisMember in $MembersToGet['WinNTMembers']) {

                    Write-LogMsg @Log -Text "`$MemberDirectoryEntry = Get-DirectoryEntry -DirectoryPath '$ThisMember'" -Expand $DirectoryParams -ExpansionMap $Cache.Value['LogCacheMap'].Value
                    $MemberDirectoryEntry = Get-DirectoryEntry -DirectoryPath $ThisMember @DirectoryParams
                    Write-LogMsg @Log -Text "Expand-WinNTGroupMember = Get-DirectoryEntry -DirectoryEntry `$MemberDirectoryEntry -Cache `$Cache"
                    Expand-WinNTGroupMember -DirectoryEntry $MemberDirectoryEntry -AccountProperty $PropertiesToLoad -Cache $Cache

                }

                # Remove the WinNTMembers key from the hashtable so the only remaining keys are distinguishedName(s) of LDAP directories
                $MembersToGet.Remove('WinNTMembers')

                # Get and Expand the directory entries for the LDAP group members
                ForEach ($MemberPath in $MembersToGet.Keys) {

                    $ThisMemberToGet = $MembersToGet[$MemberPath]
                    Write-LogMsg @Log -Text "`$MemberDirectoryEntries = Search-Directory -DirectoryPath '$MemberPath' -Filter '(|$ThisMemberToGet)'" -Expand $DirectoryParams -ExpansionMap $Cache.Value['LogCacheMap'].Value
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
