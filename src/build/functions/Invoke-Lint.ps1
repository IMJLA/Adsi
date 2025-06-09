function Invoke-Lint {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourceCodeDir,

        [Parameter(Mandatory)]
        [string]$LintSettingsFile
    )

    Write-Information "`tInvoke-ScriptAnalyzer -Path '$SourceCodeDir' -Settings '$LintSettingsFile' -Recurse"
    $LintResult = Invoke-ScriptAnalyzer -Path $SourceCodeDir -Settings $LintSettingsFile -Recurse
    Write-InfoColor "`t# Successfully performed linting with PSScriptAnalyzer." -ForegroundColor Green
    return $LintResult
}