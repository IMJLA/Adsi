function Uninstall-BuildModule {
    <#
    .SYNOPSIS
    Uninstall all versions of a specified module.

    .DESCRIPTION
    This function attempts to uninstall all versions of the specified module using Uninstall-Module.
    If that fails, it falls back to manually removing the module installation directory.

    .PARAMETER ModuleName
    The name of the module to uninstall.

    .PARAMETER ModuleInstallDir
    The installation directory path to remove if Uninstall-Module fails.

    .EXAMPLE
    Uninstall-BuildModule -ModuleName 'MyModule' -ModuleInstallDir 'C:\Path\To\Module'
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [string]$ModuleInstallDir
    )

    Write-Information "`tGet-Module -Name '$ModuleName' -ListAvailable"
    $Result = Get-Module -Name $ModuleName -ListAvailable

    if ($Result) {
        Write-Information "`tGet-Module -Name '$ModuleName' -ListAvailable | Uninstall-Module -ErrorAction Stop"
        try {
            $Result | Uninstall-Module -ErrorAction Stop
        } catch {
            $ErrorMessage = "$_"
            switch ("$ErrorMessage") {
                "No match was found for the specified search criteria and module names '$ModuleName'." {
                    if ($ModuleInstallDir) {
                        Write-Information "`tRemove-Item -Path '$ModuleInstallDir' -Recurse -Force -ErrorAction Stop -ProgressAction SilentlyContinue"
                        Remove-Item $ModuleInstallDir -Recurse -Force -ErrorAction Stop -ProgressAction SilentlyContinue
                    }
                }
                default {
                    Write-Error "An unexpected error occurred while uninstalling module $ModuleName`: $ErrorMessage"
                }
            }
        }
        Write-InfoColor "`t# Successfully uninstalled all versions of module $ModuleName." -ForegroundColor Green
    } else {
        Write-InfoColor "`t# No versions of module $ModuleName found to uninstall." -ForegroundColor Green
    }
}
