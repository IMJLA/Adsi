function Get-DirectoryEntryParentName {
    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Get-DirectoryEntryParentName')]

    # Possibly a debugging issue, not sure whether I need to prepare for both here.
    # in vscode Watch shows it as a DirectoryEntry with properties but the console (and results) have it as a String
    param (
        $DirectoryEntry
    )

    if ($DirectoryEntry.Parent.Name) {

        return $DirectoryEntry.Parent.Name

    } else {

        $LastIndexOf = $DirectoryEntry.Parent.LastIndexOf('/')
        return $DirectoryEntry.Parent.Substring($LastIndexOf + 1, $DirectoryEntry.Parent.Length - $LastIndexOf - 1)

    }

}
