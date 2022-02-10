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
