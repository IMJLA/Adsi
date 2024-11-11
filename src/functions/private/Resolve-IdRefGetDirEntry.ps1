function Resolve-IdRefGetDirEntry {

    [OutputType([string])]

    param (

        # Object from Get-AdsiServer representing the directory server and its attributes
        [PSObject]$AdsiServer,

        [string]$ServerNetBIOS,

        [string]$Name,

        [hashtable]$GetDirectoryEntryParams,

        [hashtable]$LogThis

    )

    $DirectoryPath = "$($AdsiServer.AdsiProvider)`://$ServerNetBIOS/$Name"
    $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath @GetDirectoryEntryParams @LogThis
    $DirectoryEntryWithSidInfo = Add-SidInfo -InputObject $DirectoryEntry -DomainsBySid $LogThis['Cache'].Value['DomainBySid']
    return $DirectoryEntryWithSidInfo.SidString

}
