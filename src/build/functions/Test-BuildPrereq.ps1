function Test-BuildPrereq {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [bool]$BuildCompileModule,
        [string]$NewLine
    )

    if (-not $BuildCompileModule) {
        Write-InfoColor "$NewLine`t# Build prerequisites not met. Skipping build tasks." -ForegroundColor Yellow
        return $false
    }

    return $true
}