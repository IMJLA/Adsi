function Test-BuildDocumentationPrereq {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [bool]$DocumentationEnabled,
        [string]$NewLine
    )

    if (-not $DocumentationEnabled) {
        Write-InfoColor "$NewLine`t# Documentation prerequisites not met. Skipping documentation tasks." -ForegroundColor Yellow
        return $false
    }

    return $true
}