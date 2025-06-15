function Format-BuildScript {

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

    [CmdletBinding()]
    [OutputType([System.String])]

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
            $components = @{}

            # Find #requires statements within this function
            $requiresStatements = $tokens | Where-Object {
                $_.Kind -eq 'Comment' -and
                $_.Text -match '^\s*#requires\s' -and
                $_.Extent.StartLineNumber -gt $functionStart -and
                $_.Extent.EndLineNumber -le $functionEnd
            } | Sort-Object { $_.Extent.StartLineNumber }

            if ($requiresStatements) {
                # Group consecutive #requires statements
                $requiresGroups = @()
                $currentGroup = @()
                $lastLineNumber = -1

                foreach ($req in $requiresStatements) {
                    $currentLineNumber = $req.Extent.StartLineNumber - 1

                    # If this is consecutive to the last one (within 1 line), add to current group
                    if ($lastLineNumber -eq -1 -or $currentLineNumber -le ($lastLineNumber + 2)) {
                        $currentGroup += $req
                    } else {
                        # Start a new group
                        if ($currentGroup.Count -gt 0) {
                            $requiresGroups += , $currentGroup
                        }
                        $currentGroup = @($req)
                    }
                    $lastLineNumber = $req.Extent.EndLineNumber - 1
                }

                # Add the last group
                if ($currentGroup.Count -gt 0) {
                    $requiresGroups += , $currentGroup
                }

                # For simplicity, treat all as one component (we'll handle them as a block)
                if ($requiresGroups.Count -gt 0) {
                    $firstRequires = $requiresGroups[0][0]
                    $lastRequires = $requiresGroups[-1][-1]

                    $components['Requires'] = @{
                        StartLine = $firstRequires.Extent.StartLineNumber - 1
                        EndLine   = $lastRequires.Extent.EndLineNumber - 1
                        Content   = $requiresStatements | ForEach-Object { $lines[$_.Extent.StartLineNumber - 1] }
                    }
                }
            }

            # Find comment-based help - look for it both inside and immediately before the function
            $helpComment = $null

            # First, look for comment-based help inside the function body
            $helpComment = $tokens | Where-Object {
                $_.Kind -eq 'Comment' -and
                $_.Text -match '^\s*<#[\s\S]*?#>\s*$' -and
                $_.Extent.StartLineNumber -gt $functionStart -and
                $_.Extent.EndLineNumber -le $functionEnd
            } | Sort-Object { $_.Extent.StartLineNumber } | Select-Object -First 1

            # If not found inside, look for it immediately before the function (common pattern)
            # Only consider it if it's not part of another function
            if (-not $helpComment) {
                $candidateHelp = $tokens | Where-Object {
                    $_.Kind -eq 'Comment' -and
                    $_.Text -match '^\s*<#[\s\S]*?#>\s*$' -and
                    $_.Extent.EndLineNumber -lt $functionStart -and
                    ($_.Extent.EndLineNumber + 3) -ge $functionStart  # Within 2 lines of function start
                } | Sort-Object { $_.Extent.StartLineNumber } -Descending | Select-Object -First 1

                # Verify this help comment isn't inside another function
                if ($candidateHelp) {
                    $isInsideOtherFunction = $functions | Where-Object {
                        $_ -ne $function -and
                        $candidateHelp.Extent.StartLineNumber -gt ($_.Extent.StartLineNumber) -and
                        $candidateHelp.Extent.EndLineNumber -lt ($_.Extent.EndLineNumber)
                    }

                    if (-not $isInsideOtherFunction) {
                        $helpComment = $candidateHelp
                    }
                }
            }

            if ($helpComment) {
                $components['Help'] = @{
                    StartLine = $helpComment.Extent.StartLineNumber - 1
                    EndLine   = $helpComment.Extent.EndLineNumber - 1
                    Content   = $lines[($helpComment.Extent.StartLineNumber - 1)..($helpComment.Extent.EndLineNumber - 1)]
                    IsOutside = $helpComment.Extent.EndLineNumber -lt $functionStart
                }
            }

            # Find CmdletBinding attribute - only within this function's param block
            $cmdletBinding = $null
            if ($function.Body.ParamBlock -and $function.Body.ParamBlock.Attributes) {
                $cmdletBinding = $function.Body.ParamBlock.Attributes | Where-Object {
                    $_.TypeName.Name -eq 'CmdletBinding'
                } | Select-Object -First 1
            }

            if ($cmdletBinding) {
                $components['CmdletBinding'] = @{
                    StartLine = $cmdletBinding.Extent.StartLineNumber - 1
                    EndLine   = $cmdletBinding.Extent.EndLineNumber - 1
                    Content   = $lines[($cmdletBinding.Extent.StartLineNumber - 1)..($cmdletBinding.Extent.EndLineNumber - 1)]
                }
            }

            # Find OutputType attribute - only within this function's param block
            $outputType = $null
            if ($function.Body.ParamBlock -and $function.Body.ParamBlock.Attributes) {
                $outputType = $function.Body.ParamBlock.Attributes | Where-Object {
                    $_.TypeName.Name -eq 'OutputType'
                } | Select-Object -First 1
            }

            if ($outputType) {
                $components['OutputType'] = @{
                    StartLine = $outputType.Extent.StartLineNumber - 1
                    EndLine   = $outputType.Extent.EndLineNumber - 1
                    Content   = $lines[($outputType.Extent.StartLineNumber - 1)..($outputType.Extent.EndLineNumber - 1)]
                }
            }

            # Find param block - only for this specific function
            if ($function.Body.ParamBlock) {
                $paramBlock = $function.Body.ParamBlock
                $components['ParamBlock'] = @{
                    StartLine = $paramBlock.Extent.StartLineNumber - 1
                    EndLine   = $paramBlock.Extent.EndLineNumber - 1
                    Content   = $lines[($paramBlock.Extent.StartLineNumber - 1)..($paramBlock.Extent.EndLineNumber - 1)]
                }
            }

            # Check if reordering is needed - be more conservative
            $needsReordering = $false

            # Check if we have #requires statements that need repositioning
            if ($components.ContainsKey('Requires')) {
                $needsReordering = $true
                Write-Verbose 'Found #requires statements - will reposition'
            }

            # Only reorder if help is outside the function (needs to be moved in)
            if ($components.ContainsKey('Help') -and $components['Help'].IsOutside) {
                $needsReordering = $true
                Write-Verbose 'Found comment-based help outside function - will move inside'
            } else {
                # Check if the order inside the function is wrong
                $insideComponents = @()
                foreach ($comp in @('Requires', 'Help', 'CmdletBinding', 'OutputType', 'ParamBlock')) {
                    if ($components.ContainsKey($comp) -and -not ($comp -eq 'Help' -and $components[$comp].IsOutside)) {
                        $insideComponents += @{ Name = $comp; StartLine = $components[$comp].StartLine }
                    }
                }

                # Only reorder if we have multiple components and they're in wrong order
                if ($insideComponents.Count -gt 1) {
                    # Check the expected order: Requires, Help, CmdletBinding, OutputType, ParamBlock
                    $expectedOrder = @('Requires', 'Help', 'CmdletBinding', 'OutputType', 'ParamBlock')
                    $actualOrder = ($insideComponents | Sort-Object StartLine | ForEach-Object { $_.Name })
                    $filteredExpectedOrder = $expectedOrder | Where-Object { $_ -in $actualOrder }

                    # Compare arrays element by element
                    $isCorrectOrder = $true
                    if ($actualOrder.Count -eq $filteredExpectedOrder.Count) {
                        for ($i = 0; $i -lt $actualOrder.Count; $i++) {
                            if ($actualOrder[$i] -ne $filteredExpectedOrder[$i]) {
                                $isCorrectOrder = $false
                                break
                            }
                        }
                    } else {
                        $isCorrectOrder = $false
                    }

                    if (-not $isCorrectOrder) {
                        $needsReordering = $true
                        Write-Verbose "Function components are in wrong order. Expected: $($filteredExpectedOrder -join ', '), Actual: $($actualOrder -join ', ')"
                    }
                }
            }

            # Only proceed if we actually need to reorder
            if ($needsReordering -and $components.Count -gt 0) {
                Write-Verbose "Reordering function components for function at line $($functionStart + 1)"

                # Find the insertion point (after function declaration)
                $insertionPoint = $functionStart + 1

                # Remove all components from their current positions (from bottom to top)
                $componentsToRemove = $components.Values | Sort-Object StartLine -Descending
                $linesRemovedBeforeInsertion = 0

                foreach ($comp in $componentsToRemove) {
                    # Track how many lines we're removing before the insertion point
                    if ($comp.StartLine -lt $insertionPoint) {
                        $linesRemovedBeforeInsertion += ($comp.EndLine - $comp.StartLine + 1)
                        # Add any blank lines that might be removed
                        if ($comp.EndLine + 1 -lt $lines.Count -and $lines[$comp.EndLine + 1].Trim() -eq '') {
                            $linesRemovedBeforeInsertion += 1
                        }
                    }

                    # Remove the component lines
                    for ($lineIdx = $comp.EndLine; $lineIdx -ge $comp.StartLine; $lineIdx--) {
                        if ($lineIdx -lt $lines.Count) {
                            $lines = $lines[0..($lineIdx - 1)] + $lines[($lineIdx + 1)..($lines.Count - 1)]
                        }
                    }

                    # Remove trailing blank line if it exists
                    if ($comp.StartLine -lt $lines.Count -and $lines[$comp.StartLine].Trim() -eq '') {
                        $lines = $lines[0..($comp.StartLine - 1)] + $lines[($comp.StartLine + 1)..($lines.Count - 1)]
                    }
                }

                # Adjust insertion point
                $insertionPoint -= $linesRemovedBeforeInsertion

                # Insert components in correct order
                $orderedComponents = @()
                if ($components.ContainsKey('Requires')) { $orderedComponents += $components['Requires'] }
                if ($components.ContainsKey('Help')) { $orderedComponents += $components['Help'] }
                if ($components.ContainsKey('CmdletBinding')) { $orderedComponents += $components['CmdletBinding'] }
                if ($components.ContainsKey('OutputType')) { $orderedComponents += $components['OutputType'] }
                if ($components.ContainsKey('ParamBlock')) { $orderedComponents += $components['ParamBlock'] }

                $insertLines = @()
                # Add blank line after function declaration
                $insertLines += ''

                foreach ($comp in $orderedComponents) {
                    $insertLines += $comp.Content
                    $insertLines += ''  # Add blank line after each component
                }

                # Remove the last blank line
                if ($insertLines.Count -gt 1) {
                    $insertLines = $insertLines[0..($insertLines.Count - 2)]
                }

                # Insert the reordered components
                if ($insertionPoint -lt $lines.Count) {
                    $lines = $lines[0..($insertionPoint - 1)] + $insertLines + $lines[$insertionPoint..($lines.Count - 1)]
                } else {
                    $lines = $lines + $insertLines
                }
                $modified = $true
            }
        }

        # Process standalone #requires statements (outside functions) for spacing
        $standaloneRequires = $tokens | Where-Object {
            $_ -and
            $_.Kind -eq 'Comment' -and
            $_.Text -and
            $_.Text -match '^\s*#requires\s'
        }

        # Filter out #requires that are inside functions (already handled above)
        $standaloneRequires = $standaloneRequires | Where-Object {
            $requiresLine = $_.Extent.StartLineNumber
            $isInFunction = $functions | Where-Object {
                $requiresLine -gt $_.Extent.StartLineNumber -and
                $requiresLine -le $_.Extent.EndLineNumber
            }
            -not $isInFunction
        }

        # Process from bottom to top to maintain line numbers
        $standaloneRequires = $standaloneRequires | Sort-Object { $_.Extent.StartLineNumber } -Descending

        foreach ($requiresToken in $standaloneRequires) {
            $startLine = $requiresToken.Extent.StartLineNumber - 1
            $endLine = $requiresToken.Extent.EndLineNumber - 1

            # Add blank line after if missing
            if (($endLine + 1) -lt $lines.Count -and $lines[$endLine + 1].Trim() -ne '') {
                $lines = $lines[0..$endLine] + @('') + $lines[($endLine + 1)..($lines.Count - 1)]
                $modified = $true
                Write-Verbose "Added blank line after #requires statement at line $($endLine + 2)"
            }

            # Add blank line before if missing
            if ($startLine -gt 0 -and $lines[$startLine - 1].Trim() -ne '') {
                $lines = $lines[0..($startLine - 1)] + @('') + $lines[$startLine..($lines.Count - 1)]
                $modified = $true
                Write-Verbose "Added blank line before #requires statement at line $($startLine + 1)"
            }
        }

        # Process ALL comment-based help blocks for spacing (including function help)
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
