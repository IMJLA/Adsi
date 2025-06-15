function Select-LintResult {

    <#
    .SYNOPSIS
    Run PSScriptAnalyzer tests against a module.

    .DESCRIPTION
    Run PSScriptAnalyzer tests against a module.

    .EXAMPLE
    PS> Invoke-Linter -Path ./Output/Mymodule/0.1.0 -SeverityThreshold Error

    Run ScriptAnalyzer on built module in ./Output/Mymodule/0.1.0. Throw error if any errors are found.
    #>

    [CmdletBinding()]

    param(

        # Fail ScriptAnalyser test if any issues are found with this threshold or higher
        [ValidateSet('None', 'Error', 'Warning', 'Information')]
        [string]$SeverityThreshold,

        # Rules to exclude by filename
        [hashtable]$ExcludeRuleByFile = @{

            # psake syntax does not support SupressMessageAttribute, so we need to exclude some rules.
            # Exclude the PSUseDeclaredVarsMoreThanAssignments rule for this file because psake variable scoping is not understood by PSScriptAnalyzer.
            # Exclude the PSUseCorrectCasing rule for this file due to a bug in PSScriptAnalyzer (wrongly sees the Task -name parameter as uppercase).
            'psakeFile.ps1' = @('PSUseDeclaredVarsMoreThanAssignments', 'PSUseCorrectCasing')
        },

        # The lint results to analyze
        $LintResult

    )

    $filteredOut = 0
    $filteredResult = ForEach ($result in $LintResult) {
        if ($ExcludeRuleByFile.ContainsKey($result.ScriptName)) {
            if ($ExcludeRuleByFile[$result.ScriptName] -contains $result.RuleName) {
                $filteredOut = $filteredOut + 1
                continue
            }
        }
        $result
    }
    $errors = ($filteredResult.where({ $_.Severity -eq 'Error' })).Count
    $warnings = ($filteredResult.where({ $_.Severity -eq 'Warning' })).Count
    $infos = ($filteredResult.where({ $_.Severity -eq 'Information' })).Count
    $sum = $errors + $warnings + $infos
    $InformationPreference = 'Continue'

    if ($filteredResult) {
        Write-InfoColor "`t# $filteredOut excluded violations which leaves $sum remaining: $errors errors, $warnings warnings, and $infos informational" -ForegroundColor Cyan
        $formattedOutput = ($filteredResult | Format-Table -AutoSize | Out-String) -split "`n" | ForEach-Object { "`t$_" }
        Write-InfoColor ($formattedOutput -join "`n") -ForegroundColor Cyan
    } else {
        Write-InfoColor "`t# No PSScriptAnalyzer rule violations found after exclusion filters ($($LintResult.Count) before filtering)." -ForegroundColor Cyan
    }

    switch ($SeverityThreshold) {
        'None' {
            return
        }
        'Error' {
            if ($errors -gt 0) {
                throw 'One or more ScriptAnalyzer errors were found!'
            }
        }
        'Warning' {
            if ($errors -gt 0 -or $warnings -gt 0) {
                throw 'One or more ScriptAnalyzer warnings were found!'
            }
        }
        'Information' {
            if ($errors -gt 0 -or $warnings -gt 0 -or $infos -gt 0) {
                throw 'One or more ScriptAnalyzer warnings were found!'
            }
        }
        default {
            if ($filteredResult.Count -ne 0) {
                throw 'One or more ScriptAnalyzer issues were found!'
            }
        }
    }

    Write-InfoColor "`t# Completed lint output analysis successfully." -ForegroundColor Green
}
