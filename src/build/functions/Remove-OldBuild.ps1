function Remove-OldBuild {

    <#
    .SYNOPSIS
    Removes old build files from the specified build output directory.

    .DESCRIPTION
    Recursively removes all files and directories from the build output directory to prepare for a clean build.

    .EXAMPLE
    Remove-OldBuild -BuildOutDir './dist'
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(

        # Path to the build output directory to clean
        [Parameter(Mandatory)]
        [string]$BuildOutDir

    )

    if ($PSCmdlet.ShouldProcess($BuildOutDir, 'Remove old build files')) {
        Write-Information "`tGet-ChildItem -Path '$BuildOutDir' -Recurse | Remove-Item -Recurse -Force"
        Get-ChildItem -Path $BuildOutDir -Recurse -ErrorAction Stop | Remove-Item -Recurse -Force -ErrorAction Stop -ProgressAction SilentlyContinue
        Write-InfoColor "`t# Successfully deleted old builds." -ForegroundColor Green
    }
}
