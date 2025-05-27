function Repair-MarkdownHelp {
    [CmdletBinding()]
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

    #Fix the Module Page () things PlatyPS does not do):

    # Get the module manifest file
    $ManifestPath = [IO.Path]::Combine($BuildOutputDir, "$ModuleName.psd1")
    $NewManifestTest = Test-ModuleManifest -Path $ManifestPath

    # Get the module help file
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

        # Find the corresponding PS1 file for this function
        $FunctionFile = $PublicFunctionFiles | Where-Object { $_.BaseName -eq $ThisFunction }

        if ($FunctionFile) {

            try {

                # Parse the PowerShell file using AST
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($FunctionFile.FullName, [ref]$null, [ref]$null)

                # Find the function definition
                $AllFunctionDefinitions = $ast.FindAll(
                    {
                        param($node)
                        $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
                    },
                    $true
                )

                # Get the first function definition
                $functionAst = $AllFunctionDefinitions | Select-Object -First 1

                if ($functionAst -and $functionAst.GetHelpContent()) {
                    $helpContent = $functionAst.GetHelpContent()
                    $Synopsis = $helpContent.Synopsis
                    if ([string]::IsNullOrWhiteSpace($Synopsis)) {
                        $Synopsis = "Description for $ThisFunction"
                    }
                } else {
                    $Synopsis = "Description for $ThisFunction"
                }
            } catch {
                Write-Warning "Failed to parse $($FunctionFile.FullName): $_"
                $Synopsis = "Description for $ThisFunction"
            }
        } else {
            $Synopsis = "Description for $ThisFunction"
        }

        $RegEx = "(?ms)\#\#\#\ \[$ThisFunction]\($ThisFunction\.md\)\s*[^\r\n]*\s*"
        $NewString = "### [$ThisFunction]($ThisFunction.md)$NewLine$Synopsis$NewLine$NewLine"
        $ModuleHelp = $ModuleHelp -replace $RegEx, $NewString
        Write-Verbose "`t`$ModuleHelp -replace '$RegEx', `"$($NewString -replace '\r', '`r' -replace '\n', '`n')`""

    }

    # Change multi-line default parameter values (especially hashtables) to be a single line to avoid the error below:
    <#
        Error: 4/8/2025 11:35:12 PM:
        At C:\Users\User\OneDrive\Documents\PowerShell\Modules\platyPS\0.14.2\platyPS.psm1:1412 char:22 +     $markdownFiles | ForEach-Object { +                      ~~~~~~~~~~~~~~~~ [<<==>>] Exception: Exception calling "NodeModelToMamlModel" with "1" argument(s): ".\docs\en-US\ConvertTo-FakeDirectoryEntry.md:90:(200) '```yamlType: System.Collections.HashtableParam...'
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

    ForEach ($ThisFunction in $PublicFunctionFiles.Name) {

        # Get the help file for the function
        $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($ThisFunction)
        $ThisFunctionHelpFile = [IO.Path]::Combine($DocsMarkdownDefaultLocaleDir, "$fileNameWithoutExtension.md")
        Write-Verbose "`t[string]`$ThisFunctionHelp = Get-Content -LiteralPath '$ThisFunctionHelpFile' -Raw"
        [string]$ThisFunctionHelp = Get-Content -LiteralPath $ThisFunctionHelpFile -Raw

        # Change multi-line default parameter values (especially hashtables) to be a single line to avoid the error below:
        <#
        Error: 4/8/2025 11:35:12 PM:
        At C:\Users\User\OneDrive\Documents\PowerShell\Modules\platyPS\0.14.2\platyPS.psm1:1412 char:22 +     $markdownFiles | ForEach-Object { +                      ~~~~~~~~~~~~~~~~ [<<==>>] Exception: Exception calling "NodeModelToMamlModel" with "1" argument(s): ".\Adsi\docs\en-US\ConvertTo-FakeDirectoryEntry.md:90:(200) '```yamlType: System.Collections.HashtableParam...'
        Invalid yaml: expected simple key-value pairs" --> C:\blah.md:90:(200) '```yamlType: System.Collections.HashtableParam...'
        Invalid yaml: expected simple key-value pairs
        #>
        Write-Verbose "`t`$ThisFunctionHelp -replace '\r?\n[ ]{12}', ' ; ' -replace '{ ;', '{ ' -replace '[ ]{2,}', ' ' -replace '\r?\n\s\}', ' }'"
        $ThisFunctionHelp = $ThisFunctionHelp -replace '\r?\n[ ]{12}', ' ; '
        $ThisFunctionHelp = $ThisFunctionHelp -replace '{ ;', '{ '
        $ThisFunctionHelp = $ThisFunctionHelp -replace '[ ]{2,}', ' '
        $ThisFunctionHelp = $ThisFunctionHelp -replace '\r?\n\s\}', ' }'

        # Get rid of squiggly braces in parameter descriptions, synopsis, example descriptions, etc. to avoid Docusaurus HTML conversion issues due to JSON escaping not being supported.
        # This is a workaround for functions without these fields, which result in PlatyPS generating one in the format: {{ Fill in the Synopsis }}.
        # This can also be a bug in PlatyPS where it does not populate those fields correctly.
        <#
        [ERROR] Client bundle compiled with errors therefore further build is impossible.
    Error: MDX compilation failed for file ".\docs\online\Adsi\docs\en-US\Adsi.md"
    Cause: Could not parse expression with acorn
    Details:
    {
      "cause": {
        "pos": 1335,
        "loc": {
          "line": 36,
          "column": 8
        },
        "raisedAt": 9
      },
      "column": 9,
      "message": "Could not parse expression with acorn",
      "line": 36,
      "name": "36:9",
      "place": {
        "line": 36,
        "column": 9,
        "offset": 1335
      },
      "reason": "Could not parse expression with acorn",
      "ruleId": "acorn",
      "source": "micromark-extension-mdx-expression",
      "url": "https://github.com/micromark/micromark-extension-mdx-expression/tree/main/packages/micromark-extension-mdx-expression#could-not-parse-expression-with-acorn"
    }

        #>
        while ($ThisFunctionHelp -match '{{(?<expression>[^}]+)}}') {
            $ThisFunctionHelp = $ThisFunctionHelp.Replace( $Matches[0], $Matches['expression'].Trim() )
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

    [regex]::Matches($ModuleHelp, '[^(]*\.md').Value | ForEach-Object {
        $EscapedTextToReplace = [regex]::Escape($_)
        $Replacement = "$DocsRootForURL/$_"
        Write-Verbose "`t`$ReadMeContents -replace '$EscapedTextToReplace', '$Replacement'"
        $ReadMeContents = $ReadMeContents -replace $EscapedTextToReplace, $Replacement
    }

    $readMePath = Get-ChildItem -Path '.' -Include 'readme.md', 'readme.markdown', 'readme.txt' -Depth 1 | Select-Object -First 1
    Write-Verbose "`tSet-Content -LiteralPath '$($ReadMePath.FullName)' -Value `$ReadMeContents"
    Set-Content -Path $ReadMePath.FullName -Value $ReadMeContents

}
