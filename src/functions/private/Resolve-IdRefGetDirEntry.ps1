function Resolve-IdRefGetDirEntry {

    [OutputType([string])]

    param (

        # Object from Get-AdsiServer representing the directory server and its attributes
        [PSObject]$AdsiServer,

        [string]$ServerNetBIOS,

        [string]$Name,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $DirectoryPath = "$($AdsiServer.AdsiProvider)`://$ServerNetBIOS/$Name"
    Write-LogMsg -Text "Get-DirectoryEntry -DirectoryPath '$DirectoryPath' -Cache `$Cache" -Cache $Cache
    $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath -Cache $Cache
    $DirectoryEntryWithSidInfo = Add-SidInfo -InputObject $DirectoryEntry -DomainsBySid $Cache.Value['DomainBySid']
    return $DirectoryEntryWithSidInfo.SidString

}