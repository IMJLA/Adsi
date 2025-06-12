function Invoke-Lint {

    <#
    .SYNOPSIS
    Performs PowerShell script analysis using PSScriptAnalyzer.

    .DESCRIPTION
    Runs PSScriptAnalyzer against the specified source code directory using the provided settings file
    to identify potential issues and coding standard violations.

    .EXAMPLE
    Invoke-Lint -SourceCodeDir './src' -LintSettingsFile './psscriptanalyzer.psd1'
    #>

    [CmdletBinding()]
    param(
        # Path to the source code directory to analyze
        [Parameter(Mandatory)]
        [string]$SourceCodeDir,

        # Path to the PSScriptAnalyzer settings file
        [Parameter(Mandatory)]
        [string]$LintSettingsFile
    )

    Write-Information "`tInvoke-ScriptAnalyzer -Path '$SourceCodeDir' -Settings '$LintSettingsFile' -Recurse"
    $LintResult = Invoke-ScriptAnalyzer -Path $SourceCodeDir -Settings $LintSettingsFile -Recurse
    Write-InfoColor "`t# Successfully performed linting with PSScriptAnalyzer." -ForegroundColor Green
    return $LintResult
}
