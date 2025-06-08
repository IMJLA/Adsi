function Test-BuildUnitTestPrereq {
    [CmdletBinding()]
    param(
        [bool]$TestEnabled,
        [string]$NewLine
    )

    if (-not $TestEnabled) {
        Write-InfoColor "$NewLine`t# Unit test prerequisites not met. Skipping unit test tasks." -ForegroundColor Yellow
        return $false
    }

    return $true
}
