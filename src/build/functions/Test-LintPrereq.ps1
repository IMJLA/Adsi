function Test-LintPrereq {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [bool]$LintEnabled,
        [string]$NewLine
    )

    if (-not $LintEnabled) {
        Write-InfoColor "$NewLine`t# Linting prerequisites not met. Skipping linting tasks." -ForegroundColor Yellow
        return $false
    }

    return $true
}