<#
.SYNOPSIS
    Run PSScriptAnalyzer tests against a module.
.DESCRIPTION
    Run PSScriptAnalyzer tests against a module.
.PARAMETER Path
    Path to PowerShell module directory to run ScriptAnalyser on.
.PARAMETER SeverityThreshold
    Fail ScriptAnalyser test if any issues are found with this threshold or higher.
.PARAMETER SettingsPath
    Path to ScriptAnalyser settings to use.
.EXAMPLE
    PS> Invoke-Linter -Path ./Output/Mymodule/0.1.0 -SeverityThreshold Error

    Run ScriptAnalyzer on built module in ./Output/Mymodule/0.1.0. Throw error if any errors are found.
#>

[cmdletbinding()]

param(

    [parameter(Mandatory)]
    [string]$Path,

    [ValidateSet('None', 'Error', 'Warning', 'Information')]
    [string]$SeverityThreshold,

    [string]$SettingsPath,

    [hashtable]$ExcludeRulesByFile = @{
        #'psakeFile.ps1' = @('PSUseDeclaredVarsMoreThanAssignments') # Exclude this rule for psakeFile.ps1 as uses the psake syntax.
    },

    $LintResult

)

$filteredResult = ForEach ($result in $LintResult) {
    if ($ExcludeRulesByFile.ContainsKey($result.ScriptName)) {
        if ($ExcludeRulesByFile[$result.ScriptName] -contains $result.RuleName) {
            continue
        }
    }
    $result
}
$errors = ($filteredResult.where({ $_Severity -eq 'Error' })).Count
$warnings = ($filteredResult.where({ $_Severity -eq 'Warning' })).Count
$infos = ($filteredResult.where({ $_Severity -eq 'Information' })).Count

if ($filteredResult) {
    Write-InfoColor "`tPSScriptAnalyzer results:" -ForegroundColor Cyan
    $formattedOutput = ($filteredResult | Format-Table -AutoSize | Out-String) -split "`n" | ForEach-Object { "`t$_" }
    Write-InfoColor ($formattedOutput -join "`n") -ForegroundColor Cyan
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