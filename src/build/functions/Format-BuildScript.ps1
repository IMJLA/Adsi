<#
.SYNOPSIS
    Formats PowerShell script content by fixing spacing around comment-based help and param blocks.

.DESCRIPTION
    The Format-BuildScript function processes PowerShell script content to ensure proper spacing
    around comment-based help blocks and parameter blocks. It adds blank lines before and after
    these elements when they are missing, improving code readability and following PowerShell
    formatting best practices.

    The function uses the PowerShell AST (Abstract Syntax Tree) to parse the content and identify
    comment-based help blocks and parameter blocks, then modifies the spacing accordingly.

.EXAMPLE
    $scriptContent = Get-Content -Path 'MyScript.ps1' -Raw
    $formattedContent = Format-BuildScript -Content $scriptContent

    This example reads a PowerShell script file and formats its spacing.

.EXAMPLE
    Get-Content -Path 'MyScript.ps1' -Raw | Format-BuildScript

    This example demonstrates using the function with pipeline input.

.INPUTS
    System.String
    The PowerShell script content to be formatted.

.OUTPUTS
    System.String
    The formatted PowerShell script content with corrected spacing.

.NOTES
    - The function processes content from bottom to top to maintain correct line numbers during modifications
    - Parse errors will cause the function to return the original content unchanged
    - Only adds spacing; does not remove existing blank lines
    - Designed specifically for PowerShell script formatting
#>

function Format-BuildScript {
    [CmdletBinding()]


    param(
        # The PowerShell script content to format. Must be a valid PowerShell script string.
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Content

    )

    process {
        Write-Verbose 'Processing PowerShell content for spacing fixes'

        if ([string]::IsNullOrWhiteSpace($Content)) {
            return $Content
        }

        # Parse the content
        $tokens = $null
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput(
            $Content,
            [ref]$tokens,
            [ref]$parseErrors
        )

        if ($parseErrors) {
            Write-Warning 'Parse errors found - returning original content'
            return $Content
        }

        $lines = $Content -split "`r?`n"
        $modified = $false

        # Fix function element sequence

        $functions = $ast.FindAll({

                param($astNode)
                $astNode -is [System.Management.Automation.Language.FunctionDefinitionAst]
            }, $true)

        # Process functions from bottom to top to maintain line numbers
        $functions = $functions | Sort-Object { $_.Extent.StartLineNumber } -Descending

        foreach ($function in $functions) {
            $functionStart = $function.Extent.StartLineNumber - 1
            $functionEnd = $function.Extent.EndLineNumber - 1

            # Find function components
            $components = @{
            }

            # Find comment-based help (look for multi-line comment before function body)
            $helpComment = $tokens | Where-Object {
                $_.Kind -eq 'Comment' -and
                $_.Text -match '^\s*<#[\s\S]*?#>\s*$' -and
                $_.Extent.StartLineNumber -ge ($functionStart + 1) -and
                $_.Extent.EndLineNumber -le $functionEnd
            } | Sort-Object { $_.Extent.StartLineNumber } | Select-Object -First 1

            if ($helpComment) {
                $components['Help'] = @{
                    StartLine = $helpComment.Extent.StartLineNumber - 1
                    EndLine   = $helpComment.Extent.EndLineNumber - 1
                    Content   = $lines[($helpComment.Extent.StartLineNumber - 1)..($helpComment.Extent.EndLineNumber - 1)]
                }
            }

            # Find CmdletBinding attribute
            $cmdletBinding = $function.Body.ParamBlock.Attributes | Where-Object {
                $_.TypeName.Name -eq 'CmdletBinding'
            } | Select-Object -First 1

            if ($cmdletBinding) {
                $components['CmdletBinding'] = @{
                    StartLine = $cmdletBinding.Extent.StartLineNumber - 1
                    EndLine   = $cmdletBinding.Extent.EndLineNumber - 1
                    Content   = $lines[($cmdletBinding.Extent.StartLineNumber - 1)..($cmdletBinding.Extent.EndLineNumber - 1)]
                }
            }

            # Find OutputType attribute
            $outputType = $function.Body.ParamBlock.Attributes | Where-Object {
                $_.TypeName.Name -eq 'OutputType'
            } | Select-Object -First 1

            if ($outputType) {
                $components['OutputType'] = @{
                    StartLine = $outputType.Extent.StartLineNumber - 1
                    EndLine   = $outputType.Extent.EndLineNumber - 1
                    Content   = $lines[($outputType.Extent.StartLineNumber - 1)..($outputType.Extent.EndLineNumber - 1)]
                }
            }

            # Find param block
            if ($function.Body.ParamBlock) {
                $paramBlock = $function.Body.ParamBlock
                $components['ParamBlock'] = @{
                    StartLine = $paramBlock.Extent.StartLineNumber - 1
                    EndLine   = $paramBlock.Extent.EndLineNumber - 1
                    Content   = $lines[($paramBlock.Extent.StartLineNumber - 1)..($paramBlock.Extent.EndLineNumber - 1)]
                }
            }

            # Check if reordering is needed
            $currentOrder = @()
            foreach ($comp in @('Help', 'CmdletBinding', 'OutputType', 'ParamBlock')) {
                if ($components.ContainsKey($comp)) {
                    $currentOrder += @{ Name = $comp; StartLine = $components[$comp].StartLine }
                }
            }

            $sortedOrder = $currentOrder | Sort-Object StartLine
            $needsReordering = $false

            for ($i = 0; $i -lt $currentOrder.Count; $i++) {
                if ($currentOrder[$i].Name -ne $sortedOrder[$i].Name) {
                    $needsReordering = $true
                    break
                }
            }

            if ($needsReordering -and $components.Count -gt 0) {
                Write-Verbose "Reordering function components for function at line $($functionStart + 1)"

                # Find the insertion point (after function declaration)
                $insertionPoint = $functionStart + 1

                # Remove all components from their current positions (from bottom to top)
                $componentsToRemove = $components.Values | Sort-Object StartLine -Descending
                foreach ($comp in $componentsToRemove) {
                    for ($lineIdx = $comp.EndLine; $lineIdx -ge $comp.StartLine; $lineIdx--) {
                        $lines = $lines[0..($lineIdx - 1)] + $lines[($lineIdx + 1)..($lines.Count - 1)]
                    }
                }

                # Recalculate insertion point after removals
                $removedLinesBefore = ($componentsToRemove | Where-Object { $_.StartLine -lt $insertionPoint } | Measure-Object).Count
                if ($removedLinesBefore -gt 0) {
                    $insertionPoint -= $removedLinesBefore
                }

                # Insert components in correct order
                $orderedComponents = @()
                if ($components.ContainsKey('Help')) { $orderedComponents += $components['Help'] }
                if ($components.ContainsKey('CmdletBinding')) { $orderedComponents += $components['CmdletBinding'] }
                if ($components.ContainsKey('OutputType')) { $orderedComponents += $components['OutputType'] }
                if ($components.ContainsKey('ParamBlock')) { $orderedComponents += $components['ParamBlock'] }

                $insertLines = @()
                foreach ($comp in $orderedComponents) {
                    $insertLines += $comp.Content
                    $insertLines += ''  # Add blank line after each component
                }

                # Remove the last blank line
                if ($insertLines.Count -gt 0) {
                    $insertLines = $insertLines[0..($insertLines.Count - 2)]
                }

                # Insert the reordered components
                $lines = $lines[0..($insertionPoint - 1)] + $insertLines + $lines[$insertionPoint..($lines.Count - 1)]
                $modified = $true
            }
        }

        # Fix comment-based help spacing
        $commentTokens = $tokens | Where-Object {
            $_ -and
            $_.Kind -eq 'Comment' -and
            $_.Text -and
            $_.Text -match '^\s*<#[\s\S]*?#>\s*$'
        }

        # Process from bottom to top to maintain line numbers
        $commentTokens = $commentTokens | Sort-Object { $_.Extent.StartLineNumber } -Descending

        foreach ($commentToken in $commentTokens) {
            $startLine = $commentToken.Extent.StartLineNumber - 1
            $endLine = $commentToken.Extent.EndLineNumber - 1

            # Add blank line after if missing
            if (($endLine + 1) -lt $lines.Count -and $lines[$endLine + 1].Trim() -ne '') {
                $lines = $lines[0..$endLine] + @('') + $lines[($endLine + 1)..($lines.Count - 1)]
                $modified = $true
                Write-Verbose "Added blank line after comment-based help at line $($endLine + 2)"
            }

            # Add blank line before if missing
            if ($startLine -gt 0 -and $lines[$startLine - 1].Trim() -ne '') {
                $lines = $lines[0..($startLine - 1)] + @('') + $lines[$startLine..($lines.Count - 1)]
                $modified = $true
                Write-Verbose "Added blank line before comment-based help at line $($startLine + 1)"
            }
        }

        # Fix param block spacing
        $paramBlocks = $ast.FindAll({



                param($astNode)

                $astNode -is [System.Management.Automation.Language.ParamBlockAst]
            }, $true)

        # Process from bottom to top to maintain line numbers
        $paramBlocks = $paramBlocks | Sort-Object { $_.Extent.StartLineNumber } -Descending

        foreach ($paramBlock in $paramBlocks) {
            $startLine = $paramBlock.Extent.StartLineNumber - 1
            $endLine = $paramBlock.Extent.EndLineNumber - 1

            # Add blank line after if missing
            if (($endLine + 1) -lt $lines.Count -and $lines[$endLine + 1].Trim() -ne '') {
                $lines = $lines[0..$endLine] + @('') + $lines[($endLine + 1)..($lines.Count - 1)]
                $modified = $true
                Write-Verbose "Added blank line after param block at line $($endLine + 2)"
            }

            # Add blank line before if missing (unless preceded by comment-based help)
            if ($startLine -gt 0) {
                $prevLine = $lines[$startLine - 1].Trim()
                if ($prevLine -ne '' -and $prevLine -notmatch '#>$') {
                    $lines = $lines[0..($startLine - 1)] + @('') + $lines[$startLine..($lines.Count - 1)]
                    $modified = $true
                    Write-Verbose "Added blank line before param block at line $($startLine + 1)"
                }
            }
        }

        if ($modified) {
            $newContent = $lines -join [Environment]::NewLine
            Write-Verbose 'Applied spacing fixes to content'
            return $newContent
        } else {
            Write-Verbose 'No spacing issues found in content'
            return $Content
        }
    }
}
