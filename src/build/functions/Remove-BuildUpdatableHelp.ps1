<#
.SYNOPSIS
Delete existing Updateable help files to prepare for PlatyPS to build new ones.

.DESCRIPTION
This function removes all existing updateable help files from the specified directory to ensure a clean build environment for new updateable help generation.
#>
function Remove-BuildUpdatableHelp {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        # Path to the updateable help directory
        [Parameter(Mandatory)]
        [string]$DocsUpdateableDir
    )

    Write-Information "`tGet-ChildItem -Path '$DocsUpdateableDir' -Recurse -ErrorAction Stop | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue -ProgressAction SilentlyContinue"

    if ($PSCmdlet.ShouldProcess($DocsUpdateableDir, 'Remove existing updateable help files')) {
        Get-ChildItem -Path $DocsUpdateableDir -Recurse -ErrorAction Stop | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue -ProgressAction SilentlyContinue
        Write-InfoColor "`t# Successfully deleted existing Updateable help files." -ForegroundColor Green
    }

    return $true
}