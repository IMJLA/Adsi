function Test-BuildUpdatableHelpPrereq {

    <#
    .SYNOPSIS
    Tests if updatable help prerequisites are met.

    .DESCRIPTION
    Checks if the updatable help prerequisites are satisfied and returns a boolean indicating
    whether updatable help tasks should proceed.

    .EXAMPLE
    Test-BuildUpdatableHelpPrereq -ReadyForUpdatableHelp $true -NewLine "`r`n"
    #>

    [CmdletBinding()]
    [OutputType([bool])]
    param(
        # Whether the module is ready for updatable help
        [bool]$ReadyForUpdatableHelp,

        # Character sequence for line separation in output
        [string]$NewLine
    )

    if (-not $ReadyForUpdatableHelp) {
        Write-InfoColor "$NewLine`t# Updatable help prerequisites not met. Skipping updatable help tasks." -ForegroundColor Yellow
        return $false
    }

    return $true
}
