function Get-VersionFolder {

    <#
    .SYNOPSIS
    Finds the version folder dynamically within a distribution directory.

    .DESCRIPTION
    This function searches for version folders in the module distribution directory and returns
    the first version folder found. Version folders are identified by a pattern matching semantic versioning.

    .EXAMPLE
    Get-VersionFolder -DistPath './dist'
    #>

    [CmdletBinding()]
    [OutputType([System.IO.DirectoryInfo])]

    param(
        # Path to the distribution directory containing the module
        [string]$DistPath
    )

    if (-not (Test-Path $DistPath)) {
        throw "Dist folder not found at: $DistPath"
    }

    $InformationPreference = 'Continue'
    Write-Verbose "`tGet-ChildItem -Path '$DistPath' -Directory"
    $ModuleFolder = Get-ChildItem -Path $DistPath -Directory
    $ModuleFolderPath = [io.path]::Combine($DistPath, $ModuleFolder.Name)
    Write-Verbose "`tGet-ChildItem -Path '$ModuleFolderPath' -Directory | Where-Object {`$_.Name -match '^\d+\.\d+\.\d+'}"
    $versionFolders = Get-ChildItem -Path $ModuleFolderPath -Directory | Where-Object { $_.Name -match '^\d+\.\d+\.\d+' }

    if ($versionFolders.Count -eq 0) {
        throw "No version folder found in: $DistPath"
    }

    if ($versionFolders.Count -gt 1) {
        Write-Warning "Multiple version folders found. Using the first one: $($versionFolders[0].Name)"
    }

    return $versionFolders[0]
}
