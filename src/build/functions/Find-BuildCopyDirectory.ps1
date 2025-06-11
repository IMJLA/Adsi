function Find-BuildCopyDirectory {

    [CmdletBinding()]

    param (
        [string[]]$BuildCopyDirectoryPath
    )

    Write-Verbose "`tGet-ChildItem -Path '.' -Directory"

    $EmptyFolders = Get-ChildItem -Path . -Directory | ForEach-Object {

        $JoinedPath = [io.path]::Combine('.', $_.Name)
        Write-Verbose "`tGet-ChildItem -Path '$JoinedPath' -File"
        $Files = Get-ChildItem -Path $_.FullName -File

        if ($Files.Count -eq 0 -or ($Files.Count -eq 1 -and $Files.Name -eq '.gitkeep')) {
            [io.path]::Combine('..', $_.Name)
        }

    }

    $CopyDirectories = $BuildCopyDirectoryPath | Where-Object -FilterScript {
        $EmptyFolders -notcontains $_
    }

    Write-InfoColor "`t# Found $($CopyDirectories.Count) directories to copy to the build output directory (this means they are all empty)." -ForegroundColor Green
    return $CopyDirectories

}
