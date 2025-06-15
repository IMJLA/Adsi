function Test-LintPrereq {

    <#
    .SYNOPSIS
        Tests if linting prerequisites are met.

    .DESCRIPTION
        Checks if linting is enabled and returns a boolean result indicating whether linting tasks should proceed.

    .EXAMPLE
        Test-LintPrereq -LintEnabled $true -NewLine "`n"

        Tests if linting prerequisites are met when linting is enabled.

    .OUTPUTS
        System.Boolean
        Returns $true if linting prerequisites are met, $false otherwise.
    #>

    [CmdletBinding()]
    [OutputType([bool])]

    param(

        # Indicates whether linting is enabled for the build process.
        [bool]$LintEnabled,

        # String containing newline characters for formatting output messages.
        [string]$NewLine

    )

    if (-not $LintEnabled) {
        Write-InfoColor "$NewLine`t# Linting prerequisites not met. Skipping linting tasks." -ForegroundColor Yellow
        return $false
    }

    return $true
}
