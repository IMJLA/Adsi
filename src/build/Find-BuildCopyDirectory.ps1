[CmdletBinding()]
param (
    [string[]]$BuildCopyDirectory
)

$EmptyFolders = Get-ChildItem -Path . -Directory |
ForEach-Object {
    $Files = Get-ChildItem -Path $_.FullName -File
    if ($Fiels.Count -eq 0 -or ($Files.Count -eq 1 -and $Files.Name -eq '.gitkeep')) {
        [io.path]::Combine('..', $_.Name)
    }
}

$BuildCopyDirectory |
Where-Object -FilterScript {
    $EmptyFolders -notcontains $_
}