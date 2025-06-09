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
    Format-SourceCode

    .EXAMPLE
    Format-SourceCode -Path "C:\MyProject\src" -WhatIf
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
    Write-Verbose "`tGet-ChildItem -Path '$Path' -Filter '*.ps*1' -Recurse"
    $ScriptFiles = Get-ChildItem -Path $Path -Filter '*.ps*1' -Recurse

    foreach ($File in $ScriptFiles) {

        $CurrentDirectory = (Get-Location -PSProvider FileSystem).Path
        $PartialRelativePath = [IO.Path]::GetRelativePath($CurrentDirectory, $File.FullName)
        $FullRelativePath = [IO.Path]::Combine('.', $PartialRelativePath)

        # Read the original content of the file
        $strings = @()
        $strings += "`t`$OriginalContent = Get-Content -Path '$FullRelativePath' -Raw"
        [string]$OriginalContent = Get-Content $File.FullName -Raw -ErrorAction Stop

        # Check current file encoding
        $FileBytes = [System.IO.File]::ReadAllBytes($File.FullName)
        $HasBOM = $FileBytes.Length -ge 3 -and $FileBytes[0] -eq 0xEF -and $FileBytes[1] -eq 0xBB -and $FileBytes[2] -eq 0xBF

        <#
        Normalize line endings to Windows format (CRLF) before formatting
        In addition to ensuring consistency this prevents the following error from Invoke-Formatter:

            Cannot determine line endings as the text probably contain mixed line endings. (Parameter 'text')
        #>
        $strings += "`t`$NormalizedContent = `$OriginalContent -replace '``r``n|``n|``r', '``r``n'"
        [string]$NormalizedContent = $OriginalContent -replace "`r`n|`n|`r", "`r`n"

        $strings += "`t`$FormattedContent = Invoke-Formatter -ScriptDefinition `$NormalizedContent -Settings '$SettingsPath'"
        [string]$FormattedContent = Invoke-Formatter -ScriptDefinition $NormalizedContent -Settings $SettingsPath -ErrorAction Stop

        # Update file if content changed or encoding needs to be fixed
        $ContentChanged = $FormattedContent -ne $OriginalContent
        $EncodingNeedsUpdate = -not $HasBOM

        if ($ContentChanged -or $EncodingNeedsUpdate) {

            if ($PSCmdlet.ShouldProcess($FullRelativePath, 'Format PowerShell file and update encoding')) {
                $strings | ForEach-Object { Write-Information $_ }
                Write-Information "`tSet-Content -Path '$FullRelativePath' -Value `$FormattedContent -Encoding UTF8BOM -NoNewLine"
                Set-Content -Path $File.FullName -Value $FormattedContent -Encoding UTF8BOM -NoNewline -ErrorAction Stop
            }

        }

    }

    Write-InfoColor "`t# Successfully formatted PowerShell script files with PSScriptAnalyzer and ensured UTF8 with BOM encoding." -ForegroundColor Green

}
