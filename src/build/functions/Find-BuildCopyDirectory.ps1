function Find-BuildCopyDirectory {

    [CmdletBinding()]
    param (
        [string[]]$BuildCopyDirectory
    )

    $InformationPreference = 'Continue'
    Write-Information "`t`tGet-ChildItem -Path '.' -Directory"

    $EmptyFolders = Get-ChildItem -Path . -Directory | ForEach-Object {
        $Files = Get-ChildItem -Path $_.FullName -File
        if ($Files.Count -eq 0 -or ($Files.Count -eq 1 -and $Files.Name -eq '.gitkeep')) {
            [io.path]::Combine('..', $_.Name)
        }
    }

    $BuildCopyDirectory | Where-Object -FilterScript {
        $EmptyFolders -notcontains $_
    }

}
