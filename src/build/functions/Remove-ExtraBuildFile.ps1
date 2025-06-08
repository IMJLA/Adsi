function Remove-ExtraBuildFile {
    <#
    .SYNOPSIS
    Remove unnecessary files from the build output directory.

    .DESCRIPTION
    This function removes specific files that are not needed in the final build output,
    such as dependency requirement files and PSScriptAnalyzer settings files.

    .PARAMETER BuildOutputDir
    The path to the build output directory where files should be removed.

    .PARAMETER FilesToRemove
    Array of filenames to remove from the build output directory.
    Default removes 'psdependRequirements.psd1' and 'psscriptanalyzerSettings.psd1'.

    .EXAMPLE
    Remove-ExtraBuildFile -BuildOutputDir 'C:\Build\Output'
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BuildOutputDir,

        [string[]]$FilesToRemove = @(
            'psdependRequirements.psd1',
            'psscriptanalyzerSettings.psd1'
        )
    )

    $anyErrors = $false

    foreach ($fileName in $FilesToRemove) {
        $filePath = [IO.Path]::Combine($BuildOutputDir, $fileName)
        Write-Information "`tRemove-Item -Path '$filePath' -ProgressAction SilentlyContinue"
        Remove-Item -Path $filePath -ErrorAction SilentlyContinue -ProgressAction SilentlyContinue

        if (Test-Path -Path $filePath) {
            Write-Error "Failed to remove unnecessary file '$filePath' from the build output directory."
            $anyErrors = $true
        }
    }

    if (-not $anyErrors) {
        Write-InfoColor "`t# Successfully removed unnecessary files from the build output directory." -ForegroundColor Green
    }
}
