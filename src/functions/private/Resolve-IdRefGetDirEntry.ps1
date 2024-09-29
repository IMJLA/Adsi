function Resolve-IdRefGetDirEntry {

    [OutputType([string])]

    param (

        # Object from Get-AdsiServer representing the directory server and its attributes
        [PSObject]$AdsiServer,

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        [string]$ServerNetBIOS,

        [string]$Name,

        [hashtable]$GetDirectoryEntryParams,

        [hashtable]$LogParams

    )

    $DirectoryPath = "$($AdsiServer.AdsiProvider)`://$ServerNetBIOS/$Name"
    $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath @GetDirectoryEntryParams @LogParams
    $DirectoryEntryWithSidInfo = Add-SidInfo -InputObject $DirectoryEntry -DomainsBySid $DomainsBySid @LogParams
    return $DirectoryEntryWithSidInfo.SidString

}
