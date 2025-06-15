function Test-BuildPrereq {

    <#
    .SYNOPSIS
        Tests if build prerequisites are met.

    .DESCRIPTION
        Checks if the module compilation prerequisites are satisfied and returns a boolean result.

    .EXAMPLE
        Test-BuildPrereq -BuildCompileModule $true -NewLine "`n"

        Tests if build prerequisites are met for module compilation.

    .OUTPUTS
        System.Boolean
        Returns $true if prerequisites are met, $false otherwise.
    #>

    [CmdletBinding()]
    [OutputType([bool])]

    param(

        # Indicates whether the module should be compiled during the build process.
        [bool]$BuildCompileModule,

        # String containing newline characters for formatting output messages.

        [string]$NewLine
    )

    if (-not $BuildCompileModule) {
        Write-InfoColor "$NewLine`t# Build prerequisites not met. Skipping build tasks." -ForegroundColor Yellow
        return $false
    }

    return $true
}
