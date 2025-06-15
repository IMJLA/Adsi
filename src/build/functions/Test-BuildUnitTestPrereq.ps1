function Test-BuildUnitTestPrereq {

    <#
    .SYNOPSIS
        Tests if unit test prerequisites are met.

    .DESCRIPTION
        Checks if unit testing is enabled and returns a boolean result indicating whether unit test tasks should proceed.

    .EXAMPLE
        Test-BuildUnitTestPrereq -TestEnabled $true -NewLine "`n"

        Tests if unit test prerequisites are met when testing is enabled.

    .OUTPUTS
        System.Boolean
        Returns $true if unit test prerequisites are met, $false otherwise.
    #>

    [CmdletBinding()]
    [OutputType([bool])]

    param(
        # Indicates whether unit testing is enabled for the build process.
        [bool]$TestEnabled,
        # String containing newline characters for formatting output messages.
        [string]$NewLine
    )

    if (-not $TestEnabled) {
        Write-InfoColor "$NewLine`t# Unit test prerequisites not met. Skipping unit test tasks." -ForegroundColor Yellow
        return $false
    }

    return $true
}
