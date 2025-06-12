function Test-BuildUpdateableHelpPrereq {

    <#
    .SYNOPSIS
    Tests if updateable help prerequisites are met.

    .DESCRIPTION
    Checks if the updateable help prerequisites are satisfied and returns a boolean indicating
    whether updateable help tasks should proceed.

    .EXAMPLE
    Test-BuildUpdateableHelpPrereq -ReadyForUpdateableHelp $true -NewLine "`r`n"
    #>

    [CmdletBinding()]
    [OutputType([bool])]
    param(
        # Whether the module is ready for updateable help
        [bool]$ReadyForUpdateableHelp,

        # Character sequence for line separation in output
        [string]$NewLine
    )

    if (-not $ReadyForUpdateableHelp) {
        Write-InfoColor "$NewLine`t# Updateable help prerequisites not met. Skipping updateable help tasks." -ForegroundColor Yellow
        return $false
    }

    return $true
}
