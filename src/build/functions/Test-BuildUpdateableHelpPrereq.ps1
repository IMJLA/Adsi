function Test-BuildUpdateableHelpPrereq {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [bool]$ReadyForUpdateableHelp,
        [string]$NewLine
    )

    if (-not $ReadyForUpdateableHelp) {
        Write-InfoColor "$NewLine`t# Updateable help prerequisites not met. Skipping updateable help tasks." -ForegroundColor Yellow
        return $false
    }

    return $true
}