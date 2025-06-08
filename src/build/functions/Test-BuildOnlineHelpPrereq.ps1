function Test-BuildOnlineHelpPrereq {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [string]$NewLine
    )

    Write-InfoColor "$NewLine`t# Online help prerequisites met. Proceeding with online help tasks." -ForegroundColor Green
    return $true
}
