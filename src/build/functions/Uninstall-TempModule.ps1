<#
.SYNOPSIS
Uninstall a temporary module installation directory.

.DESCRIPTION
Removes a temporary module installation directory that was created during the build process for help generation.

.EXAMPLE
Uninstall-TempModule -ModuleInstallDir 'C:\temp\MyModule'

Removes the temporary module installation directory.
#>
function Uninstall-TempModule {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # Path to the temporary module installation directory to remove
        [Parameter(Mandatory)]
        [string]$ModuleInstallDir
    )

    if ($PSCmdlet.ShouldProcess($ModuleInstallDir, 'Remove temporary module installation directory')) {
        Write-Information "`tRemove-Item -Path '$ModuleInstallDir' -Recurse -Force -ErrorAction Stop -ProgressAction SilentlyContinue"
        Remove-Item -Path $ModuleInstallDir -Recurse -Force -ErrorAction Stop -ProgressAction SilentlyContinue

        if (Test-Path -Path $ModuleInstallDir) {
            Write-Error 'Failed to remove the temporary module installation directory.'
        } else {
            Write-InfoColor "`t# Successfully removed the temporary module installation directory." -ForegroundColor Green
        }
    }
}
