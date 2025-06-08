function Install-TempModule {
    <#
    .SYNOPSIS
    Install a module temporarily for help generation.

    .DESCRIPTION
    Creates a temporary module installation directory and copies the built module files
    to it so the module can be loaded by name for help generation.

    .PARAMETER ModuleName
    The name of the module to install.

    .PARAMETER ModulePath
    The directory containing the built module files.

    .EXAMPLE
    Install-TempModule -ModuleName 'MyModule' -Path 'C:\Build\Output'
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([string])]

    param(

        [Parameter(Mandatory)]
        [string]$ModuleName,

        [Parameter(Mandatory)]
        [string]$ModulePath
    )

    $ModuleInstallDir = $env:PSModulePath -split ';' | Select-Object -First 1
    $Path = [IO.Path]::Combine($ModulePath, $ModuleName)
    $InstalledPath = [IO.Path]::Combine($ModuleInstallDir, $ModuleName)

    Write-Information "`tCopy-Item -Path '$Path' -Destination '$ModuleInstallDir' -Recurse -Force"
    if ($PSCmdlet.ShouldProcess($ModuleInstallDir, 'Copy module files to installation directory')) {
        Copy-Item -Path "$Path" -Destination $ModuleInstallDir -Recurse -Force -ErrorAction Stop
        Write-InfoColor "`t# Successfully copied the module files to the version installation directory." -ForegroundColor Green
    }

    return $InstalledPath
}
