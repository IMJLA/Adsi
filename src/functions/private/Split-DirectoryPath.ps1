function Split-DirectoryPath {

    param ([string]$DirectoryPath)

    $LastSlashIndex = $DirectoryPath.LastIndexOf('/')
    $StartIndex = $LastSlashIndex + 1
    $AccountName = $DirectoryPath.Substring($StartIndex, $DirectoryPath.Length - $StartIndex)
    $ParentDirectoryPath = $DirectoryPath.Substring(0, $LastSlashIndex)
    $FirstSlashIndex = $ParentDirectoryPath.IndexOf('/')
    $ParentPath = $ParentDirectoryPath.Substring($FirstSlashIndex + 2, $ParentDirectoryPath.Length - $FirstSlashIndex - 2)
    $FirstSlashIndex = $ParentPath.IndexOf('/')

    if ($FirstSlashIndex -ne (-1)) {

        $Server = $ParentPath.Substring(0, $FirstSlashIndex)

        if ($Server.Equals('WORKGROUP')) {
            $FirstSlashIndex = $ParentPath.IndexOf('/')
            $Server = $ParentPath.Substring($FirstSlashIndex + 1, $ParentPath.Length - $FirstSlashIndex - 1)
        }

    } else {
        $Server = $ParentPath
    }

    if ($Server -ne 'JLA-LoftHTPC') { pause }

    return @{
        'AccountName' = $AccountName
        'Server'      = $Server
    }

}
