function Remove-BuildUpdatableHelp {

    <#
    .SYNOPSIS
    Delete existing Updatable help files to prepare for PlatyPS to build new ones.

    .DESCRIPTION
    This function removes all existing updatable help files from the specified directory to ensure a clean build environment for new updatable help generation.

    .EXAMPLE
    Remove-BuildUpdatableHelp -DocsUpdatableDir './docs/updatable'
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]

    param(
        # Path to the updatable help directory
        [Parameter(Mandatory)]
        [string]$DocsUpdatableDir
    )

    Write-Information "`tGet-ChildItem -Path '$DocsUpdatableDir' -Recurse | Remove-Item -Recurse -Force"

    if ($PSCmdlet.ShouldProcess($DocsUpdatableDir, 'Remove existing updatable help files')) {
        Get-ChildItem -Path $DocsUpdatableDir -Recurse -ErrorAction Stop | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue -ProgressAction SilentlyContinue
        Write-InfoColor "`t# Successfully deleted existing Updatable help files." -ForegroundColor Green
    }

    return $true
}
