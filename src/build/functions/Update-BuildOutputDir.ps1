function Update-BuildOutputDir {
    <#
    .SYNOPSIS
        Updates the build output directory environment variable.

    .DESCRIPTION
        Sets the build output directory path based on the module version and updates environment variables.

    .EXAMPLE
        Update-BuildOutputDir -BuildOutDir './dist' -ModuleVersion '1.0.0' -ModuleName 'MyModule'

    .EXAMPLE
        Update-BuildOutputDir -BuildOutDir './dist' -ModuleVersion '1.0.0' -ModuleName 'MyModule' -WhatIf
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([string])]

    param(

        # Path to the base build output directory.
        [string]$BuildOutDir,

        # Module version for the build.
        [version]$ModuleVersion,

        # Name of the module being built.
        [string]$ModuleName

    )

    $BuildOutputDir = [IO.Path]::Combine($BuildOutDir, $ModuleName, $ModuleVersion.ToString())

    if ($PSCmdlet.ShouldProcess('BHBuildOutput environment variable', "Set to '$BuildOutputDir'")) {
        $env:BHBuildOutput = $BuildOutputDir # still used by Module.tests.ps1
        Write-InfoColor "`t# Successfully updated the build output directory variable: $BuildOutputDir" -ForegroundColor Green
    }

    return $BuildOutputDir
}
