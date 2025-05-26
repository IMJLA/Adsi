<#
.SYNOPSIS
Format PowerShell source code files using PSScriptAnalyzer rules.

.DESCRIPTION
This script automatically formats all PowerShell script files in the source directory
according to the PSScriptAnalyzer rules defined in the settings file.

.PARAMETER Path
The path to format. Defaults to the src directory.

.PARAMETER SettingsPath
Path to the PSScriptAnalyzer settings file.

.PARAMETER WhatIf
Show what files would be formatted without actually changing them.

.EXAMPLE
.\Format-SourceCode.ps1

.EXAMPLE
.\Format-SourceCode.ps1 -Path "C:\MyProject\src" -WhatIf
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Path = (Join-Path $PSScriptRoot '..' ),

    [string]$SettingsPath = (Join-Path $PSScriptRoot 'psscriptanalyzerSettings.psd1'),

    [switch]$WhatIf
)

# Verify PSScriptAnalyzer is available
if (-not (Get-Module -Name PSScriptAnalyzer -ListAvailable)) {
    throw 'PSScriptAnalyzer module is required but not installed. Install with: Install-Module PSScriptAnalyzer'
}

Import-Module PSScriptAnalyzer

# Get all PowerShell script files
$ScriptFiles = Get-ChildItem -Path $Path -Include '*.ps1', '*.psm1', '*.psd1' -Recurse

Write-Host "Found $($ScriptFiles.Count) PowerShell files to process" -ForegroundColor Cyan

$FormattedCount = 0

foreach ($File in $ScriptFiles) {
    try {
        $OriginalContent = Get-Content $File.FullName -Raw

        # Format the content
        $FormattedContent = Invoke-Formatter -ScriptDefinition $OriginalContent -Settings $SettingsPath

        # Check if content changed
        if ($FormattedContent -ne $OriginalContent) {
            if ($WhatIf) {
                Write-Host "  Would format: $($File.FullName)" -ForegroundColor Yellow
            } elseif ($PSCmdlet.ShouldProcess($File.FullName, 'Format PowerShell file')) {
                Set-Content -Path $File.FullName -Value $FormattedContent -NoNewline
                Write-Host "  Formatted: $($File.FullName)" -ForegroundColor Green
                $FormattedCount++
            }
        }
    } catch {
        Write-Warning "Failed to format $($File.FullName): $_"
    }
}

if ($WhatIf) {
    Write-Host "Would format $FormattedCount files" -ForegroundColor Cyan
} else {
    Write-Host "Formatted $FormattedCount files" -ForegroundColor Green
}
