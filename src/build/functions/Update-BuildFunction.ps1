function Update-BuildFunction {

    <#
    .SYNOPSIS
    Updates PowerShell functions to include HelpUri attributes in their CmdletBinding.

    .DESCRIPTION
    This function finds all PowerShell functions in the private and public folders and adds or updates
    the HelpUri parameter in their [CmdletBinding()] attribute. The HelpUri is generated using the
    online help URL combined with the relative path to the documentation for that specific function.
    If a function doesn't have a param block, an empty one will be added when CmdletBinding is added.

    .EXAMPLE
    Update-BuildFunction -SourceCodeDir './src' -DocsOnlineHelpUrl 'https://example.github.io/MyModule/' -DocsDefaultLocale 'en-US'
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The source code directory containing the functions folders
        [Parameter(Mandatory)]
        [string]$SourceCodeDir,

        # The base URL for the online help documentation
        [Parameter(Mandatory)]
        [string]$DocsOnlineHelpUrl,

        # The default locale for documentation (e.g., "en-US")
        [Parameter(Mandatory)]
        [string]$DocsDefaultLocale
    )

    $functionsDir = [IO.Path]::Combine($SourceCodeDir, 'functions')

    if (-not (Test-Path $functionsDir)) {
        Write-InfoColor "`t# No functions directory found at '$functionsDir'." -ForegroundColor Yellow
        return
    }

    # Find all PowerShell function files in private and public folders
    $functionFolders = @('private', 'public')
    $updatedFiles = 0

    foreach ($folder in $functionFolders) {
        $folderPath = [IO.Path]::Combine($functionsDir, $folder)

        if (-not (Test-Path $folderPath)) {
            Write-Verbose "`t# Folder not found: $folderPath"
            continue
        }

        $relativeFolderPath = [IO.Path]::Combine($SourceCodeDir, 'functions', $folder)
        Write-Verbose "`tGet-ChildItem -Path '$relativeFolderPath' -Filter '*.ps1'"
        $functionFiles = Get-ChildItem -Path $folderPath -Filter '*.ps1'

        foreach ($functionFile in $functionFiles) {
            $relativeFunctionPath = [IO.Path]::Combine($SourceCodeDir, 'functions', $folder, $functionFile.Name)
            Write-Verbose "`t[string]`$functionContent = Get-Content -LiteralPath '$relativeFunctionPath' -Raw"
            [string]$functionContent = Get-Content -LiteralPath $functionFile.FullName -Raw
            $originalContent = $functionContent

            # Extract the function name from the file content
            if ($functionContent -match 'function\s+([A-Za-z0-9-_]+)') {
                $functionName = $Matches[1]

                # Generate the HelpUri
                $helpUri = "${DocsOnlineHelpUrl}docs/$DocsDefaultLocale/$functionName"

                # Check if CmdletBinding already exists
                if ($functionContent -match '\[CmdletBinding\([^\]]*\)\]') {
                    # CmdletBinding exists, check if HelpUri is already present
                    if ($functionContent -match '\[CmdletBinding\([^)]*HelpUri\s*=\s*[''"][^''"]*[''"][^)]*\)\]') {
                        # Update existing HelpUri
                        $functionContent = $functionContent -replace '(HelpUri\s*=\s*)[''"][^''"]*[''"]', "`$1'$helpUri'"
                    } else {
                        # Add HelpUri to existing CmdletBinding
                        $functionContent = $functionContent -replace '\[CmdletBinding\(([^)]*)\)\]', "[CmdletBinding(HelpUri = '$helpUri', `$1)]"
                        # Clean up any double commas that might result from the replacement
                        $functionContent = $functionContent -replace ',\s*,', ','
                        $functionContent = $functionContent -replace '\(\s*,', '('
                        $functionContent = $functionContent -replace ',\s*\)', ')'
                    }
                } elseif ($functionContent -match '\[CmdletBinding\(\)\]') {
                    # Empty CmdletBinding exists, add HelpUri
                    $functionContent = $functionContent -replace '\[CmdletBinding\(\)\]', "[CmdletBinding(HelpUri = '$helpUri')]"
                } else {
                    # No CmdletBinding exists, add it with HelpUri after function declaration
                    # Check if param block exists
                    if ($functionContent -match 'param\s*\(') {
                        # param block exists, add CmdletBinding before it
                        $functionContent = $functionContent -replace '(\s*)(param\s*\()', "`$1[CmdletBinding(HelpUri = '$helpUri')]`r`n`$1`$2"
                    } else {
                        # No param block exists, add CmdletBinding and empty param block
                        $functionContent = $functionContent -replace '(function\s+[A-Za-z0-9-_]+\s*\{)', "`$1`r`n    [CmdletBinding(HelpUri = '$helpUri')]`r`n    param()`r`n"
                    }
                }

                if ($functionContent -ne $originalContent) {
                    if ($PSCmdlet.ShouldProcess($functionFile.FullName, 'Update function with HelpUri')) {
                        Write-Information "`tSet-Content -LiteralPath '$relativeFunctionPath' -Value `$functionContent -Encoding UTF8BOM -NoNewLine"
                        Set-Content -LiteralPath $functionFile.FullName -Value $functionContent -Encoding UTF8BOM -NoNewLine -ErrorAction Stop
                        $updatedFiles++
                    }
                }
            } else {
                Write-Warning "Could not extract function name from file: $($functionFile.Name)"
            }
        }
    }

    if ($updatedFiles -gt 0) {
        Write-InfoColor "`t# Successfully updated $updatedFiles function file(s) with HelpUri attributes." -ForegroundColor Green
    } else {
        Write-InfoColor "`t# No function files needed updating (already have correct HelpUri attributes)." -ForegroundColor Green
    }
}
