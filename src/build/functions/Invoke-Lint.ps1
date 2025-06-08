function Invoke-Lint {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourceCodeDir,

        [Parameter(Mandatory)]
        [string]$LintSettingsFile
    )

    Write-Information "`tInvoke-Lint -SourceCodeDir '$SourceCodeDir' -LintSettingsFile '$LintSettingsFile'"

    # Run PSScriptAnalyzer
    $LintResult = Invoke-ScriptAnalyzer -Path $SourceCodeDir -Settings $LintSettingsFile -Recurse

    Write-InfoColor "`t# Successfully performed linting with PSScriptAnalyzer." -ForegroundColor Green
    return $LintResult
}
