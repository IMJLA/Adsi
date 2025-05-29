function Format-SourceCode {
    #requires -module PSScriptAnalyzer

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

    .EXAMPLE
    .\Format-SourceCode.ps1

    .EXAMPLE
    .\Format-SourceCode.ps1 -Path "C:\MyProject\src" -WhatIf
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(
        [string]$Path = (Join-Path $PSScriptRoot '..' ),

        [string]$SettingsPath = (Join-Path $PSScriptRoot 'psscriptanalyzerSettings.psd1')
    )

    # Verify PSScriptAnalyzer is available
    if (-not (Get-Module -Name PSScriptAnalyzer -ListAvailable)) {
        throw 'PSScriptAnalyzer module is required but not installed. Install with: Install-Module PSScriptAnalyzer'
    }

    # Get all PowerShell script files
    Write-Verbose "`tGet-ChildItem -Path '$Path' -Include '*.ps1', '*.psm1', '*.psd1' -Recurse"
    $ScriptFiles = Get-ChildItem -Path $Path -Include '*.ps1', '*.psm1', '*.psd1' -Recurse

    foreach ($File in $ScriptFiles) {

        $RelativePath = $File.FullName.Substring($Path.Length).TrimStart('\')
        Write-Verbose "`tGet-Content -Path '$RelativePath' -Raw"
        $OriginalContent = Get-Content $File.FullName -Raw
        # Format the content
        Write-Verbose "`tInvoke-Formatter -ScriptDefinition '$RelativePath' -Settings '$SettingsPath' -ErrorAction Stop"
        $FormattedContent = Invoke-Formatter -ScriptDefinition $OriginalContent -Settings $SettingsPath -ErrorAction Stop

        # Check if content changed
        if ($FormattedContent -ne $OriginalContent) {

            if ($WhatIfPreference) {
                Write-Information "`t`twould run: Set-Content -Path '$($File.FullName)' -Value `'$FormattedContent' -NoNewline"
            } elseif ($PSCmdlet.ShouldProcess($File.FullName, 'Format PowerShell file')) {
                Write-Information "`t`tSet-Content -Path '$($File.FullName)' -Value '`$FormattedContent' -NoNewline"
                Set-Content -Path $File.FullName -Value $FormattedContent -NoNewline
            }

        }

    }

}
