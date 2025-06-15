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

            # Find ALL function attributes - not just CmdletBinding and OutputType
            $allAttributes = @()
            if ($function.Body.ParamBlock -and $function.Body.ParamBlock.Attributes) {
                $allAttributes = $function.Body.ParamBlock.Attributes | Sort-Object { $_.Extent.StartLineNumber }
            }

            if ($allAttributes.Count -gt 0) {
                $firstAttribute = $allAttributes | Sort-Object { $_.Extent.StartLineNumber } | Select-Object -First 1
                $lastAttribute = $allAttributes | Sort-Object { $_.Extent.StartLineNumber } | Select-Object -Last 1

                # Collect all attribute content
                $attributeContent = @()
                foreach ($attr in $allAttributes) {
                    $attrLines = $lines[($attr.Extent.StartLineNumber - 1)..($attr.Extent.EndLineNumber - 1)]
                    $attributeContent += $attrLines
                }

                $components['Attributes'] = @{
                    StartLine = $firstAttribute.Extent.StartLineNumber - 1
                    EndLine   = $lastAttribute.Extent.EndLineNumber - 1
                    Content   = $attributeContent
                }
            }

            # Remove the old CmdletBinding and OutputType logic since they're now part of Attributes
            # Find CmdletBinding attribute - only within this function's param block
            # $cmdletBinding = $null
            # if ($function.Body.ParamBlock -and $function.Body.ParamBlock.Attributes) {
            #     $cmdletBinding = $function.Body.ParamBlock.Attributes | Where-Object {
            #         $_.TypeName.Name -eq 'CmdletBinding'
            #     } | Select-Object -First 1
            # }

            # if ($cmdletBinding) {
            #     $components['CmdletBinding'] = @{
            #         StartLine = $cmdletBinding.Extent.StartLineNumber - 1
            #         EndLine   = $cmdletBinding.Extent.EndLineNumber - 1
            #         Content   = $lines[($cmdletBinding.Extent.StartLineNumber - 1)..($cmdletBinding.Extent.EndLineNumber - 1)]
            #     }
            # }

            # Find OutputType attribute - only within this function's param block
            # $outputType = $null
            # if ($function.Body.ParamBlock -and $function.Body.ParamBlock.Attributes) {
            #     $outputType = $function.Body.ParamBlock.Attributes | Where-Object {
            #         $_.TypeName.Name -eq 'OutputType'
            #     } | Select-Object -First 1
            # }

            # if ($outputType) {
            #     $components['OutputType'] = @{
            #         StartLine = $outputType.Extent.StartLineNumber - 1
            #         EndLine   = $outputType.Extent.EndLineNumber - 1
            #         Content   = $lines[($outputType.Extent.StartLineNumber - 1)..($outputType.Extent.EndLineNumber - 1)]
            #     }
            # }

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
                foreach ($comp in @('Requires', 'Help', 'Attributes', 'ParamBlock')) {
                    if ($components.ContainsKey($comp) -and -not ($comp -eq 'Help' -and $components[$comp].IsOutside)) {
                        $insideComponents += @{ Name = $comp; StartLine = $components[$comp].StartLine }
                    }
                }

                # Only reorder if we have multiple components and they're in wrong order
                if ($insideComponents.Count -gt 1) {
                    # Check the expected order: Requires, Help, Attributes, ParamBlock
                    $expectedOrder = @('Requires', 'Help', 'Attributes', 'ParamBlock')
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
                if ($components.ContainsKey('Attributes')) { $orderedComponents += $components['Attributes'] }
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

        # Process function attributes for proper grouping and spacing
        foreach ($function in $functions) {
            if ($function.Body.ParamBlock -and $function.Body.ParamBlock.Attributes) {
                $functionStart = $function.Extent.StartLineNumber - 1
                $attributes = $function.Body.ParamBlock.Attributes | Sort-Object { $_.Extent.StartLineNumber }

                # Check if attributes need spacing fixes (remove blank lines between them)
                if ($attributes.Count -gt 1) {
                    for ($i = 0; $i -lt ($attributes.Count - 1); $i++) {
                        $currentAttr = $attributes[$i]
                        $nextAttr = $attributes[$i + 1]

                        $currentEndLine = $currentAttr.Extent.EndLineNumber - 1
                        $nextStartLine = $nextAttr.Extent.StartLineNumber - 1

                        # Remove blank lines between consecutive attributes
                        while (($currentEndLine + 1) -lt $nextStartLine -and
                            ($currentEndLine + 1) -lt $lines.Count -and
                            $lines[$currentEndLine + 1].Trim() -eq '') {
                            $lines = $lines[0..$currentEndLine] + $lines[($currentEndLine + 2)..($lines.Count - 1)]
                            $nextStartLine--
                            $modified = $true
                            Write-Verbose 'Removed blank line between function attributes'
                        }
                    }
                }

                # Fix spacing between attributes group and param block
                if ($function.Body.ParamBlock) {
                    $lastAttribute = $attributes | Sort-Object { $_.Extent.EndLineNumber } | Select-Object -Last 1
                    $paramBlock = $function.Body.ParamBlock

                    $lastAttrEndLine = $lastAttribute.Extent.EndLineNumber - 1
                    $paramStartLine = $paramBlock.Extent.StartLineNumber - 1

                    # Count blank lines between last attribute and param block
                    $blankLineCount = 0
                    for ($lineIdx = $lastAttrEndLine + 1; $lineIdx -lt $paramStartLine; $lineIdx++) {
                        if ($lineIdx -lt $lines.Count -and $lines[$lineIdx].Trim() -eq '') {
                            $blankLineCount++
                        }
                    }

                    # Ensure exactly one blank line between attributes and param block
                    if ($blankLineCount -ne 1) {
                        # Remove all blank lines between attributes and param block
                        for ($lineIdx = $paramStartLine - 1; $lineIdx -gt $lastAttrEndLine; $lineIdx--) {
                            if ($lineIdx -lt $lines.Count -and $lines[$lineIdx].Trim() -eq '') {
                                $lines = $lines[0..($lineIdx - 1)] + $lines[($lineIdx + 1)..($lines.Count - 1)]
                                $modified = $true
                            }
                        }

                        # Add exactly one blank line
                        $lines = $lines[0..$lastAttrEndLine] + @('') + $lines[($lastAttrEndLine + 1)..($lines.Count - 1)]
                        $modified = $true
                        Write-Verbose 'Fixed spacing between attribute group and param block'
                    }
                }
            }
        }

        # Process parameters within param blocks for proper spacing
        foreach ($function in $functions) {
            if ($function.Body.ParamBlock -and $function.Body.ParamBlock.Parameters) {
                $paramBlock = $function.Body.ParamBlock
                $parameters = $paramBlock.Parameters

                if ($parameters.Count -gt 0) {
                    # Process parameters from bottom to top to maintain line numbers
                    $sortedParameters = $parameters | Sort-Object { $_.Extent.StartLineNumber } -Descending

                    foreach ($param in $sortedParameters) {
                        $paramStartLine = $param.Extent.StartLineNumber - 1
                        $paramEndLine = $param.Extent.EndLineNumber - 1

                        # Add blank line after parameter (if not the last parameter)
                        $nextParam = $parameters | Where-Object { $_.Extent.StartLineNumber -gt $param.Extent.EndLineNumber } |
                            Sort-Object { $_.Extent.StartLineNumber } | Select-Object -First 1

                        if ($nextParam) {
                            # Check if there's already a blank line after this parameter
                            $hasBlankLineAfter = ($paramEndLine + 1) -lt $lines.Count -and $lines[$paramEndLine + 1].Trim() -eq ''

                            if (-not $hasBlankLineAfter) {
                                # Find the end of the parameter (including trailing comma)
                                $insertAfterLine = $paramEndLine
                                if (($paramEndLine + 1) -lt $lines.Count -and $lines[$paramEndLine + 1].Trim() -eq ',') {
                                    $insertAfterLine = $paramEndLine + 1
                                }

                                $lines = $lines[0..$insertAfterLine] + @('') + $lines[($insertAfterLine + 1)..($lines.Count - 1)]
                                $modified = $true
                                Write-Verbose "Added blank line after parameter at line $($paramEndLine + 2)"
                            }
                        }

                        # Add blank line before parameter (if not the first parameter)
                        $prevParam = $parameters | Where-Object { $_.Extent.EndLineNumber -lt $param.Extent.StartLineNumber } |
                            Sort-Object { $_.Extent.StartLineNumber } -Descending | Select-Object -First 1

                        if ($prevParam) {
                            # Check if there's already a blank line before this parameter
                            $hasBlankLineBefore = $paramStartLine -gt 0 -and $lines[$paramStartLine - 1].Trim() -eq ''

                            if (-not $hasBlankLineBefore) {
                                $lines = $lines[0..($paramStartLine - 1)] + @('') + $lines[$paramStartLine..($lines.Count - 1)]
                                $modified = $true
                                Write-Verbose "Added blank line before parameter at line $($paramStartLine + 1)"
                            }
                        }
                    }

                    # Ensure exactly one blank line at the beginning of param block (after "param (")
                    $paramBlockStartLine = $paramBlock.Extent.StartLineNumber - 1
                    $firstParam = $parameters | Sort-Object { $_.Extent.StartLineNumber } | Select-Object -First 1
                    $firstParamStartLine = $firstParam.Extent.StartLineNumber - 1

                    # Find the line with "param ("
                    $paramOpenLine = -1
                    for ($lineIdx = $paramBlockStartLine; $lineIdx -le $firstParamStartLine; $lineIdx++) {
                        if ($lines[$lineIdx] -match '^\s*param\s*\(\s*$') {
                            $paramOpenLine = $lineIdx
                            break
                        }
                    }

                    if ($paramOpenLine -ge 0) {
                        # Count and fix blank lines after "param ("
                        $blankLinesAfterOpen = 0
                        for ($lineIdx = $paramOpenLine + 1; $lineIdx -lt $firstParamStartLine; $lineIdx++) {
                            if ($lines[$lineIdx].Trim() -eq '') {
                                $blankLinesAfterOpen++
                            }
                        }

                        # Ensure exactly one blank line after "param ("
                        if ($blankLinesAfterOpen -ne 1) {
                            # Remove all blank lines after "param ("
                            for ($lineIdx = $firstParamStartLine - 1; $lineIdx -gt $paramOpenLine; $lineIdx--) {
                                if ($lines[$lineIdx].Trim() -eq '') {
                                    $lines = $lines[0..($lineIdx - 1)] + $lines[($lineIdx + 1)..($lines.Count - 1)]
                                    $modified = $true
                                }
                            }

                            # Add exactly one blank line
                            $lines = $lines[0..$paramOpenLine] + @('') + $lines[($paramOpenLine + 1)..($lines.Count - 1)]
                            $modified = $true
                            Write-Verbose 'Fixed blank lines after param block opening'
                        }
                    }

                    # Ensure exactly one blank line at the end of param block (before ")")
                    $lastParam = $parameters | Sort-Object { $_.Extent.EndLineNumber } | Select-Object -Last 1
                    $lastParamEndLine = $lastParam.Extent.EndLineNumber - 1
                    $paramBlockEndLine = $paramBlock.Extent.EndLineNumber - 1

                    # Find the line with the closing ")"
                    $paramCloseLine = -1
                    for ($lineIdx = $paramBlockEndLine; $lineIdx -ge $lastParamEndLine; $lineIdx--) {
                        if ($lines[$lineIdx] -match '^\s*\)\s*$') {
                            $paramCloseLine = $lineIdx
                            break
                        }
                    }

                    if ($paramCloseLine -ge 0) {
                        # Count blank lines before ")"
                        $blankLinesBeforeClose = 0
                        for ($lineIdx = $paramCloseLine - 1; $lineIdx -gt $lastParamEndLine; $lineIdx--) {
                            if ($lines[$lineIdx].Trim() -eq '') {
                                $blankLinesBeforeClose++
                            }
                        }

                        # Ensure exactly one blank line before ")"
                        if ($blankLinesBeforeClose -ne 1) {
                            # Remove all blank lines before ")"
                            for ($lineIdx = $paramCloseLine - 1; $lineIdx -gt $lastParamEndLine; $lineIdx--) {
                                if ($lines[$lineIdx].Trim() -eq '') {
                                    $lines = $lines[0..($lineIdx - 1)] + $lines[($lineIdx + 1)..($lines.Count - 1)]
                                    $modified = $true
                                }
                            }

                            # Add exactly one blank line
                            $lines = $lines[0..$lastParamEndLine] + @('') + $lines[($lastParamEndLine + 1)..($lines.Count - 1)]
                            $modified = $true
                            Write-Verbose 'Fixed blank lines before param block closing'
                        }
                    }
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
