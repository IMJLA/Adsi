function Test-BuildDocumentationPrereq {

    <#
    .SYNOPSIS
    Tests if documentation prerequisites are met.

    .DESCRIPTION
    Checks if documentation is enabled and returns a boolean indicating whether documentation
    tasks should proceed.

    .EXAMPLE
    Test-BuildDocumentationPrereq -DocumentationEnabled $true -NewLine "`r`n"
    #>

    [CmdletBinding()]
    [OutputType([bool])]

    param(
        # Whether documentation is enabled
        [bool]$DocumentationEnabled,

        # Character sequence for line separation in output
        [string]$NewLine
    )

    if (-not $DocumentationEnabled) {
        Write-InfoColor "$NewLine`t# Documentation prerequisites not met. Skipping documentation tasks." -ForegroundColor Yellow
        return $false
    }

    return $true
}
