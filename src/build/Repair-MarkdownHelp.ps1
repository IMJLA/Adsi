param (
    # The directory where build output is stored
    [string]
    $BuildOutputDir,

    # The name of the module
    [string]
    $ModuleName,

    # The directory containing markdown documentation files in the default locale
    [string]
    $DocsMarkdownDefaultLocaleDir,

    # The newline character(s) to use in documentation
    [string]$NewLine = [Environment]::NewLine,

    # The default locale code for documentation (e.g., "en-US")
    [string]$DocsDefaultLocale,

    # Collection of files containing public functions
    [System.IO.FileInfo[]]
    $PublicFunctionFiles
)

$ManifestPath = [IO.Path]::Combine($BuildOutputDir, "$ModuleName.psd1")
$NewManifestTest = Test-ModuleManifest -Path $ManifestPath

#Fix the Module Page () things PlatyPS does not do):
$ModuleHelpFile = [IO.Path]::Combine($DocsMarkdownDefaultLocaleDir, "$ModuleName.md")

Write-Verbose "`t[string]`$ModuleHelp = Get-Content -LiteralPath '$ModuleHelpFile' -Raw"
[string]$ModuleHelp = Get-Content -LiteralPath $ModuleHelpFile -Raw

#Update the module description
$RegEx = '(?ms)\#\#\ Description\s*[^\r\n]*\s*'
$NewString = "## Description$NewLine$($NewManifestTest.Description)$NewLine$NewLine"
Write-Verbose "`t`$ModuleHelp -replace '$RegEx', `"$($NewString -replace '\r', '`r' -replace '\n', '`n')`""
$ModuleHelp = $ModuleHelp -replace $RegEx, $NewString

#Update the description of each function (use its synopsis for brevity)
ForEach ($ThisFunction in $NewManifestTest.ExportedCommands.Keys) {
    $Synopsis = (Get-Help -Name $ThisFunction).Synopsis
    $RegEx = "(?ms)\#\#\#\ \[$ThisFunction]\($ThisFunction\.md\)\s*[^\r\n]*\s*"
    $NewString = "### [$ThisFunction]($ThisFunction.md)$NewLine$Synopsis$NewLine$NewLine"
    $ModuleHelp = $ModuleHelp -replace $RegEx, $NewString
    Write-Verbose "`t`$ModuleHelp -replace '$RegEx', `"$($NewString -replace '\r', '`r' -replace '\n', '`n')`""
}

# Change multi-line default parameter values (especially hashtables) to be a single line to avoid the error below:
<#
    Error: 4/8/2025 11:35:12 PM:
    At C:\Users\User\OneDrive\Documents\PowerShell\Modules\platyPS\0.14.2\platyPS.psm1:1412 char:22 +     $markdownFiles | ForEach-Object { +                      ~~~~~~~~~~~~~~~~ [<<==>>] Exception: Exception calling "NodeModelToMamlModel" with "1" argument(s): "C:\Export-Permission\Entire Project\Adsi\docs\en-US\New-FakeDirectoryEntry.md:90:(200) '```yamlType: System.Collections.HashtableParam...'
    Invalid yaml: expected simple key-value pairs" --> C:\blah.md:90:(200) '```yamlType: System.Collections.HashtableParam...'
    Invalid yaml: expected simple key-value pairs
#>
Write-Verbose "`t`$ModuleHelp -replace '\r?\n[ ]{12}', ' ; ' -replace '{ ;', '{ ' -replace '[ ]{2,}', ' ' -replace '\r?\n\s\}', ' }'"
$ModuleHelp = $ModuleHelp -replace '\r?\n[ ]{12}', ' ; '
$ModuleHelp = $ModuleHelp -replace '{ ;', '{ '
$ModuleHelp = $ModuleHelp -replace '[ ]{2,}', ' '
$ModuleHelp = $ModuleHelp -replace '\r?\n\s\}', ' }'

Write-Verbose "`t`$ModuleHelp | Set-Content -LiteralPath $ModuleHelpFile -Encoding utf8"
$ModuleHelp | Set-Content -LiteralPath $ModuleHelpFile -Encoding utf8

Remove-Module $ModuleName -Force

ForEach ($ThisFunction in $PublicFunctionFiles.Name) {
    $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($ThisFunction)
    $ThisFunctionHelpFile = [IO.Path]::Combine($DocsMarkdownDefaultLocaleDir, "$fileNameWithoutExtension.md")
    Write-Verbose "`t[string]`$ThisFunctionHelp = Get-Content -LiteralPath '$ThisFunctionHelpFile' -Raw"
    [string]$ThisFunctionHelp = Get-Content -LiteralPath $ThisFunctionHelpFile -Raw
    Write-Verbose "`t`$ThisFunctionHelp -replace '\r?\n[ ]{12}', ' ; ' -replace '{ ;', '{ ' -replace '[ ]{2,}', ' ' -replace '\r?\n\s\}', ' }'"
    $ThisFunctionHelp = $ThisFunctionHelp -replace '\r?\n[ ]{12}', ' ; '
    $ThisFunctionHelp = $ThisFunctionHelp -replace '{ ;', '{ '
    $ThisFunctionHelp = $ThisFunctionHelp -replace '[ ]{2,}', ' '
    $ThisFunctionHelp = $ThisFunctionHelp -replace '\r?\n\s\}', ' }'

    # Get rid of squiggly braces in parameter descriptions to avoid Docusaurus HTML conversion issues because of JSON escaping not being supported.
    while ($ThisFunctionHelp -match '[^:][\s]{(?<expression>[^}]+)}') {
        $ThisFunctionHelp = $ThisFunctionHelp.Replace($Matches[0], "- ``$($Matches['expression']))``")
    }

    # Workaround a bug since PS 7.4 introduced the ProgressAction common param which is not yet supported by PlatyPS
    $ParamToRemove = '-ProgressAction'
    $Pattern = "### $ParamToRemove\r?\n[\S\s\r\n]*?(?=#{2,3}?)"
    $ThisFunctionHelp = [regex]::replace($ThisFunctionHelp, $Pattern, '')
    $Pattern = [regex]::Escape('[-ProgressAction <ActionPreference>] ')
    $ThisFunctionHelp = [regex]::replace($ThisFunctionHelp, $Pattern, '')

    # Add PowerShell syntax highlighting
    $ThisFunctionHelp = $ThisFunctionHelp -replace '\x60\x60\x60\r*\n(?!\r*\n)', "``````powershell`n"

    Write-Verbose "`tSet-Content -LiteralPath '$ThisFunctionHelpFile' -Value `$ThisFunctionHelp"
    Set-Content -LiteralPath $ThisFunctionHelpFile -Value $ThisFunctionHelp
}

# Fix the readme file to point to the correct location of the markdown files
Write-Verbose "`t`$ReadMeContents = `$ModuleHelp"
$ReadMeContents = $ModuleHelp
$DocsRootForURL = [IO.Path]::Combine('docs', $DocsDefaultLocale)
[regex]::Matches($ModuleHelp, '[^(]*\.md').Value |
ForEach-Object {
    $EscapedTextToReplace = [regex]::Escape($_)
    $Replacement = "$DocsRootForURL/$_"
    Write-Verbose "`t`$ReadMeContents -replace '$EscapedTextToReplace', '$Replacement'"
    $ReadMeContents = $ReadMeContents -replace $EscapedTextToReplace, $Replacement
}
$readMePath = Get-ChildItem -Path '.' -Include 'readme.md', 'readme.markdown', 'readme.txt' -Depth 1 |
Select-Object -First 1

Write-Verbose "`tSet-Content -LiteralPath '$($ReadMePath.FullName)' -Value `$ReadMeContents"
Set-Content -Path $ReadMePath.FullName -Value $ReadMeContents