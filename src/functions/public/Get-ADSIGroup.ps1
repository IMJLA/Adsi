function Get-ADSIGroup {
    <#
        .SYNOPSIS
        Get the directory entries for a group and its members using ADSI
        .DESCRIPTION
        Uses the ADSI components to search a directory for a group, then get its members
        .INPUTS
        None.
        .OUTPUTS
        [System.DirectoryServices.DirectoryEntry] Possible return values are:
            None
            LDAP
            WinNT
        .EXAMPLE
        Get-ADSIGroup -DirectoryPath 'WinNT://WORKGROUP/localhost' -GroupName Administrators

        Find the ADSI provider of the local computer
        .EXAMPLE
        Get-ADSIGroup -GroupName Administrators

        On a domain-joined computer, this will get the the domain's Administrators group
        On a workgroup computer, this will get the local Administrators group
    #>
    [OutputType([System.DirectoryServices.DirectoryEntry])]

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
    if ($DirectoryPath -match '^WinNT') {
        $SearchParams['DirectoryPath'] = "$DirectoryPath/$GroupName"
        Get-DirectoryEntry @SearchParams |
        Get-WinNTGroupMember -DirectoryEntryCache $DirectoryEntryCache
    } else {

        if ($GroupName) {
            $SearchParams['Filter'] = "(&(objectClass=group)(cn=$GroupName))"
        } else {
            $SearchParams['Filter'] = "(objectClass=group)"
        }

        Search-Directory @SearchParams |
        Get-ADSIGroupMember -DirectoryEntryCache $DirectoryEntryCache
    }

}
