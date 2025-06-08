function Install-TempModule {
    <#
    .SYNOPSIS
    Install a module temporarily for help generation.

    .DESCRIPTION
    Creates a temporary module installation directory and copies the built module files
    to it so the module can be loaded by name for help generation.

    .PARAMETER ModuleName
    The name of the module to install.

    .PARAMETER ModuleVersion
    The version of the module to install.

    .PARAMETER Path
    The directory containing the built module files.

    .EXAMPLE
    Install-TempModule -ModuleName 'MyModule' -ModuleVersion '1.0.0' -Path 'C:\Build\Output'
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([string])]

    param(

        [Parameter(Mandatory)]
        [string]$ModuleName,

        [Parameter(Mandatory)]
        [version]$ModuleVersion,

        [Parameter(Mandatory)]
        [string]$Path
    )

    $ModuleInstallDir = $env:PSModulePath -split ';' | Select-Object -First 1
    $ModuleInstallDir = [IO.Path]::Combine($ModuleInstallDir, $ModuleName)

    Write-Information "`tNew-Item -Path '$ModuleInstallDir' -ItemType Directory -ErrorAction SilentlyContinue"
    if ($PSCmdlet.ShouldProcess($ModuleInstallDir, 'Create module installation directory')) {
        $null = New-Item -Path $ModuleInstallDir -ItemType Directory -ErrorAction SilentlyContinue
    }

    if (Test-Path -Path $ModuleInstallDir) {
        Write-Verbose "`t# Module installation directory exists."
    } else {
        Write-Error 'Failed to create the module installation directory.'
    }

    $ModuleInstallDir = [IO.Path]::Combine($ModuleInstallDir, $ModuleVersion)
    Write-Information "`tNew-Item -Path '$ModuleInstallDir' -ItemType Directory -ErrorAction SilentlyContinue"
    if ($PSCmdlet.ShouldProcess($ModuleInstallDir, 'Create module version installation directory')) {
        $null = New-Item -Path $ModuleInstallDir -ItemType Directory -ErrorAction SilentlyContinue
    }

    if (Test-Path -Path $ModuleInstallDir) {
        Write-Verbose "`t# Module version installation directory exists."
    } else {
        Write-Error 'Failed to create the module version installation directory.'
    }

    Write-Information "`tCopy-Item -Path '$Path\*' -Destination '$ModuleInstallDir' -Recurse -Force"
    if ($PSCmdlet.ShouldProcess($ModuleInstallDir, 'Copy module files to installation directory')) {
        Copy-Item -Path "$Path\*" -Destination $ModuleInstallDir -Recurse -Force -ErrorAction Stop
        Write-InfoColor "`t# Successfully copied the module files to the version installation directory." -ForegroundColor Green
    }

    return $ModuleInstallDir
}
