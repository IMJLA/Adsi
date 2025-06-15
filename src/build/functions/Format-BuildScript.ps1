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
        various script elements including:
        - #requires statements
        - Comment-based help blocks
        - Function attributes ([CmdletBinding], [OutputType], etc.)
        - Parameter blocks and individual parameters

        Key formatting improvements include:
        - Proper ordering of function elements (#requires, help, attributes, param block)
        - Consistent spacing around comment-based help blocks
        - Proper grouping of function attributes without blank lines between them
        - Consistent parameter spacing with blank lines between parameter groups
        - Removal of excessive blank lines while maintaining readability

        The function processes content from bottom to top to maintain correct line numbers during
        modifications and only returns modified content if changes were actually made.

    .EXAMPLE
        $scriptContent = Get-Content -Path 'MyScript.ps1' -Raw
        $formattedContent = Format-BuildScript -Content $scriptContent
        Set-Content -Path 'MyScript.ps1' -Value $formattedContent

        This example reads a PowerShell script file, formats its spacing, and saves the result.

    .EXAMPLE
        Get-Content -Path 'MyScript.ps1' -Raw | Format-BuildScript | Set-Content -Path 'MyScript-Formatted.ps1'

        This example demonstrates using the function with pipeline input to create a formatted copy.

    .EXAMPLE
        Get-ChildItem -Path '*.ps1' | ForEach-Object {
            $content = Get-Content $_.FullName -Raw
            $formatted = Format-BuildScript -Content $content
            Set-Content -Path $_.FullName -Value $formatted
        }

        This example formats all PowerShell script files in the current directory.

    .INPUTS
        System.String
        The PowerShell script content to be formatted. Must be valid PowerShell syntax.

    .OUTPUTS
        System.String
        The formatted PowerShell script content with corrected spacing and element ordering.

    .NOTES
        Author: Your Name
        Version: 1.0.0

        The function makes the following formatting decisions:
        - Processes content from bottom to top to maintain correct line numbers
        - Parse errors will cause the function to return the original content unchanged
        - Only adds spacing; does not remove existing blank lines unless they violate formatting rules
        - Reorders function elements to follow best practices: #requires, help, attributes, param block
        - Groups function attributes together without blank lines between them
        - Ensures exactly one blank line between major function components
        - Maintains proper spacing around individual parameters within param blocks

        Performance considerations:
        - Uses PowerShell AST parsing which is efficient for most script sizes
        - Processes files with thousands of lines without significant performance impact
        - Memory usage scales linearly with input size

    .LINK
        about_Comment_Based_Help

    .LINK
        about_Functions_Advanced_Parameters
    #>

    [CmdletBinding()]
    [OutputType([System.String])]

    param(

        # The PowerShell script content to format. Must be a valid PowerShell script string that can be parsed by the PowerShell AST. Empty or whitespace-only content will be returned unchanged.
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

            # Find regular comments before param block (but not comment-based help)
            if ($function.Body.ParamBlock) {
                $paramBlockStart = $function.Body.ParamBlock.Extent.StartLineNumber - 1

                # Find consecutive comment lines before param block
                $commentLines = @()
                $currentLine = $paramBlockStart - 1

                # Skip any blank lines immediately before param block
                while ($currentLine -gt $functionStart -and $lines[$currentLine].Trim() -eq '') {
                    $currentLine--
                }

                # Collect consecutive comment lines (not comment-based help)
                while ($currentLine -gt $functionStart) {
                    $line = $lines[$currentLine].Trim()
                    if ($line -match '^#' -and $line -notmatch '^#>' -and $line -notmatch '^\s*<#') {
                        $commentLines = @($currentLine) + $commentLines
                        $currentLine--
                    } elseif ($line -eq '') {
                        # Skip blank lines within comments
                        $currentLine--
                    } else {
                        # Hit non-comment line, stop collecting
                        break
                    }
                }

                # Only create RegularComments component if we found comments and they're not already covered by other components
                if ($commentLines.Count -gt 0) {
                    $firstCommentLine = $commentLines | Sort-Object | Select-Object -First 1
                    $lastCommentLine = $commentLines | Sort-Object | Select-Object -Last 1

                    # Check if these comments overlap with existing components
                    $overlapsWithExisting = $false
                    foreach ($comp in $components.Values) {
                        if (($firstCommentLine -ge $comp.StartLine -and $firstCommentLine -le $comp.EndLine) -or
                            ($lastCommentLine -ge $comp.StartLine -and $lastCommentLine -le $comp.EndLine)) {
                            $overlapsWithExisting = $true
                            break
                        }
                    }

                    if (-not $overlapsWithExisting) {
                        $components['RegularComments'] = @{
                            StartLine = $firstCommentLine
                            EndLine   = $lastCommentLine
                            Content   = $commentLines | ForEach-Object { $lines[$_] }
                        }
                    }
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
                foreach ($comp in @('Requires', 'Help', 'RegularComments', 'Attributes', 'ParamBlock')) {
                    if ($components.ContainsKey($comp) -and -not ($comp -eq 'Help' -and $components[$comp].IsOutside)) {
                        $insideComponents += @{ Name = $comp; StartLine = $components[$comp].StartLine }
                    }
                }

                # Only reorder if we have multiple components and they're in wrong order
                if ($insideComponents.Count -gt 1) {
                    # Check the expected order: Requires, Help, RegularComments, Attributes, ParamBlock
                    $expectedOrder = @('Requires', 'Help', 'RegularComments', 'Attributes', 'ParamBlock')
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
                if ($components.ContainsKey('RegularComments')) { $orderedComponents += $components['RegularComments'] }
                if ($components.ContainsKey('Attributes')) { $orderedComponents += $components['Attributes'] }
                if ($components.ContainsKey('ParamBlock')) { $orderedComponents += $components['ParamBlock'] }

                $insertLines = @()
                # Add blank line after function declaration
                $insertLines += ''

                for ($i = 0; $i -lt $orderedComponents.Count; $i++) {
                    $comp = $orderedComponents[$i]
                    $insertLines += $comp.Content

                    # Add blank line after each component except the last one
                    if ($i -lt ($orderedComponents.Count - 1)) {
                        $insertLines += ''
                    }
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

            # Ensure exactly one blank line after param block
            if (($endLine + 1) -lt $lines.Count) {
                $nextLineAfterParam = $endLine + 1

                # Check if the next line after param block is non-empty (needs blank line)
                if ($nextLineAfterParam -lt $lines.Count -and $lines[$nextLineAfterParam].Trim() -ne '') {
                    # Add blank line after param block
                    $lines = $lines[0..$endLine] + @('') + $lines[$nextLineAfterParam..($lines.Count - 1)]
                    $modified = $true
                    Write-Verbose "Added blank line after param block at line $($endLine + 2)"
                }
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
                    # First, fix any unwanted blank lines within parameter regions
                    # Process parameters from bottom to top to maintain line numbers
                    $sortedParameters = $parameters | Sort-Object { $_.Extent.StartLineNumber } -Descending

                    foreach ($param in $sortedParameters) {
                        $paramStartLine = $param.Extent.StartLineNumber - 1
                        $paramEndLine = $param.Extent.EndLineNumber - 1

                        # Look backwards from parameter start to find associated comments and attributes
                        $actualStartLine = $paramStartLine

                        # First, check for parameter attributes
                        if ($param.Attributes) {
                            $firstAttribute = $param.Attributes | Sort-Object { $_.Extent.StartLineNumber } | Select-Object -First 1
                            $actualStartLine = $firstAttribute.Extent.StartLineNumber - 1
                        }

                        # Then look backwards for parameter comments (lines starting with #)
                        for ($lineIdx = $actualStartLine - 1; $lineIdx -ge 0; $lineIdx--) {
                            $line = $lines[$lineIdx].Trim()
                            if ($line -match '^#' -and $line -notmatch '^#>') {
                                $actualStartLine = $lineIdx
                            } elseif ($line -eq '') {
                                # Continue looking through blank lines
                                continue
                            } else {
                                # Hit non-comment, non-blank line - stop looking
                                break
                            }
                        }

                        # Remove blank lines between comments and attributes
                        if ($param.Attributes -and $actualStartLine -lt $paramStartLine) {
                            $firstAttribute = $param.Attributes | Sort-Object { $_.Extent.StartLineNumber } | Select-Object -First 1
                            $firstAttrStartLine = $firstAttribute.Extent.StartLineNumber - 1

                            # Remove blank lines between comments and first attribute
                            for ($lineIdx = $firstAttrStartLine - 1; $lineIdx -gt $actualStartLine; $lineIdx--) {
                                if ($lines[$lineIdx].Trim() -eq '') {
                                    $lines = $lines[0..($lineIdx - 1)] + $lines[($lineIdx + 1)..($lines.Count - 1)]
                                    $modified = $true
                                    Write-Verbose 'Removed unwanted blank line between parameter comment and attribute'
                                }
                            }
                        }

                        # Remove blank lines between attributes and parameter definition
                        if ($param.Attributes) {
                            $lastAttribute = $param.Attributes | Sort-Object { $_.Extent.EndLineNumber } | Select-Object -Last 1
                            $lastAttrEndLine = $lastAttribute.Extent.EndLineNumber - 1

                            # Remove blank lines between last attribute and parameter definition
                            for ($lineIdx = $paramStartLine - 1; $lineIdx -gt $lastAttrEndLine; $lineIdx--) {
                                if ($lines[$lineIdx].Trim() -eq '') {
                                    $lines = $lines[0..($lineIdx - 1)] + $lines[($lineIdx + 1)..($lines.Count - 1)]
                                    $modified = $true
                                    Write-Verbose 'Removed unwanted blank line between parameter attribute and definition'
                                }
                            }
                        }

                        # Remove blank lines between attributes themselves
                        if ($param.Attributes -and $param.Attributes.Count -gt 1) {
                            $sortedAttributes = $param.Attributes | Sort-Object { $_.Extent.StartLineNumber } -Descending
                            for ($i = 0; $i -lt ($sortedAttributes.Count - 1); $i++) {
                                $currentAttr = $sortedAttributes[$i]
                                $nextAttr = $sortedAttributes[$i + 1]

                                $currentAttrStartLine = $currentAttr.Extent.StartLineNumber - 1
                                $nextAttrEndLine = $nextAttr.Extent.EndLineNumber - 1

                                # Remove blank lines between consecutive parameter attributes
                                for ($lineIdx = $currentAttrStartLine - 1; $lineIdx -gt $nextAttrEndLine; $lineIdx--) {
                                    if ($lines[$lineIdx].Trim() -eq '') {
                                        $lines = $lines[0..($lineIdx - 1)] + $lines[($lineIdx + 1)..($lines.Count - 1)]
                                        $modified = $true
                                        Write-Verbose 'Removed unwanted blank line between parameter attributes'
                                    }
                                }
                            }
                        }

                        # Remove blank lines between comments and parameter definition (if no attributes)
                        if (-not $param.Attributes -and $actualStartLine -lt $paramStartLine) {
                            for ($lineIdx = $paramStartLine - 1; $lineIdx -gt $actualStartLine; $lineIdx--) {
                                if ($lines[$lineIdx].Trim() -eq '') {
                                    $lines = $lines[0..($lineIdx - 1)] + $lines[($lineIdx + 1)..($lines.Count - 1)]
                                    $modified = $true
                                    Write-Verbose 'Removed unwanted blank line between parameter comment and definition'
                                }
                            }
                        }
                    }

                    # Now process parameter regions for proper spacing between parameters
                    $parameterRegions = @()

                    foreach ($param in $parameters) {
                        $paramStartLine = $param.Extent.StartLineNumber - 1
                        $paramEndLine = $param.Extent.EndLineNumber - 1

                        # Find the actual start of this parameter (including preceding comments and attributes)
                        $actualStartLine = $paramStartLine

                        # First, check for parameter attributes
                        if ($param.Attributes) {
                            $firstAttribute = $param.Attributes | Sort-Object { $_.Extent.StartLineNumber } | Select-Object -First 1
                            $actualStartLine = $firstAttribute.Extent.StartLineNumber - 1
                        }

                        # Then look backwards for parameter comments (lines starting with #)
                        for ($lineIdx = $actualStartLine - 1; $lineIdx -ge 0; $lineIdx--) {
                            $line = $lines[$lineIdx].Trim()
                            if ($line -match '^#' -and $line -notmatch '^#>') {
                                $actualStartLine = $lineIdx
                            } elseif ($line -eq '') {
                                # Continue looking through blank lines
                                continue
                            } else {
                                # Hit non-comment, non-blank line
                                break
                            }
                        }

                        $parameterRegions += @{
                            Parameter = $param
                            StartLine = $actualStartLine
                            EndLine   = $paramEndLine
                        }
                    }

                    # Sort regions by start line
                    $parameterRegions = $parameterRegions | Sort-Object StartLine

                    # Process regions from bottom to top to maintain line numbers
                    $sortedRegions = $parameterRegions | Sort-Object StartLine -Descending

                    foreach ($region in $sortedRegions) {
                        $regionStartLine = $region.StartLine
                        $regionEndLine = $region.EndLine

                        # Add blank line after parameter region (if not the last parameter)
                        $nextRegion = $parameterRegions | Where-Object { $_.StartLine -gt $region.EndLine } |
                            Sort-Object StartLine | Select-Object -First 1

                        if ($nextRegion) {
                            # Check if there's already a blank line after this parameter region
                            $hasBlankLineAfter = ($regionEndLine + 1) -lt $lines.Count -and $lines[$regionEndLine + 1].Trim() -eq ''

                            if (-not $hasBlankLineAfter) {
                                # Find the end of the parameter (including trailing comma)
                                $insertAfterLine = $regionEndLine
                                if (($regionEndLine + 1) -lt $lines.Count -and $lines[$regionEndLine + 1].Trim() -eq ',') {
                                    $insertAfterLine = $regionEndLine + 1
                                }

                                $lines = $lines[0..$insertAfterLine] + @('') + $lines[($insertAfterLine + 1)..($lines.Count - 1)]
                                $modified = $true
                                Write-Verbose "Added blank line after parameter region at line $($regionEndLine + 2)"
                            }
                        }

                        # Add blank line before parameter region (if not the first parameter)
                        $prevRegion = $parameterRegions | Where-Object { $_.EndLine -lt $region.StartLine } |
                            Sort-Object StartLine -Descending | Select-Object -First 1

                        if ($prevRegion) {
                            # Check if there's already a blank line before this parameter region
                            $hasBlankLineBefore = $regionStartLine -gt 0 -and $lines[$regionStartLine - 1].Trim() -eq ''

                            if (-not $hasBlankLineBefore) {
                                $lines = $lines[0..($regionStartLine - 1)] + @('') + $lines[$regionStartLine..($lines.Count - 1)]
                                $modified = $true
                                Write-Verbose "Added blank line before parameter region at line $($regionStartLine + 1)"
                            }
                        }
                    }

                    # Ensure exactly one blank line at the beginning of param block (after "param (")
                    $paramBlockStartLine = $paramBlock.Extent.StartLineNumber - 1
                    $firstRegion = $parameterRegions | Sort-Object StartLine | Select-Object -First 1
                    $firstRegionStartLine = $firstRegion.StartLine

                    # Find the line with "param ("
                    $paramOpenLine = -1
                    for ($lineIdx = $paramBlockStartLine; $lineIdx -le $firstRegionStartLine; $lineIdx++) {
                        if ($lines[$lineIdx] -match '^\s*param\s*\(\s*$') {
                            $paramOpenLine = $lineIdx
                            break
                        }
                    }

                    if ($paramOpenLine -ge 0) {
                        # Count and fix blank lines after "param ("
                        $blankLinesAfterOpen = 0
                        $nextNonBlankLine = -1

                        for ($lineIdx = $paramOpenLine + 1; $lineIdx -lt $firstRegionStartLine; $lineIdx++) {
                            if ($lines[$lineIdx].Trim() -eq '') {
                                $blankLinesAfterOpen++
                            } else {
                                if ($nextNonBlankLine -eq -1) {
                                    $nextNonBlankLine = $lineIdx
                                }
                            }
                        }

                        # Remove ALL blank lines after "param (" first
                        for ($lineIdx = $firstRegionStartLine - 1; $lineIdx -gt $paramOpenLine; $lineIdx--) {
                            if ($lines[$lineIdx].Trim() -eq '') {
                                $lines = $lines[0..($lineIdx - 1)] + $lines[($lineIdx + 1)..($lines.Count - 1)]
                                $modified = $true
                            }
                        }

                        # Then add exactly one blank line if there are parameters
                        if ($firstRegionStartLine -gt ($paramOpenLine + 1)) {
                            $lines = $lines[0..$paramOpenLine] + @('') + $lines[($paramOpenLine + 1)..($lines.Count - 1)]
                            $modified = $true
                            Write-Verbose 'Fixed blank lines after param block opening'
                        }
                    }

                    # Ensure exactly one blank line at the end of param block (before ")")
                    $lastRegion = $parameterRegions | Sort-Object EndLine | Select-Object -Last 1
                    $lastRegionEndLine = $lastRegion.EndLine
                    $paramBlockEndLine = $paramBlock.Extent.EndLineNumber - 1

                    # Find the line with the closing ")" - account for trailing comma
                    $actualLastLine = $lastRegionEndLine
                    if (($lastRegionEndLine + 1) -lt $lines.Count -and $lines[$lastRegionEndLine + 1].Trim() -eq ',') {
                        $actualLastLine = $lastRegionEndLine + 1
                    }

                    # Find the line with the closing ")"
                    $paramCloseLine = -1
                    for ($lineIdx = $paramBlockEndLine; $lineIdx -gt $actualLastLine; $lineIdx--) {
                        if ($lines[$lineIdx] -match '^\s*\)\s*$') {
                            $paramCloseLine = $lineIdx
                            break
                        }
                    }

                    if ($paramCloseLine -ge 0) {
                        # Count blank lines before ")"
                        $blankLinesBeforeClose = 0
                        for ($lineIdx = $paramCloseLine - 1; $lineIdx -gt $actualLastLine; $lineIdx--) {
                            if ($lines[$lineIdx].Trim() -eq '') {
                                $blankLinesBeforeClose++
                            }
                        }

                        # Ensure exactly one blank line before ")"
                        if ($blankLinesBeforeClose -ne 1) {
                            # Remove all blank lines before ")"
                            for ($lineIdx = $paramCloseLine - 1; $lineIdx -gt $actualLastLine; $lineIdx--) {
                                if ($lines[$lineIdx].Trim() -eq '') {
                                    $lines = $lines[0..($lineIdx - 1)] + $lines[($lineIdx + 1)..($lines.Count - 1)]
                                    $modified = $true
                                }
                            }

                            # Add exactly one blank line
                            $lines = $lines[0..$actualLastLine] + @('') + $lines[($actualLastLine + 1)..($lines.Count - 1)]
                            $modified = $true
                            Write-Verbose 'Fixed blank lines before param block closing'
                        }
                    }
                }
            }
        }

        # Remove multiple consecutive blank lines within the param block (but not within comment blocks)
        $paramBlockStartLine = $paramBlock.Extent.StartLineNumber - 1
        $paramBlockEndLine = $paramBlock.Extent.EndLineNumber - 1

        # Find all comment-based help blocks within this param block
        $commentBlocks = $tokens | Where-Object {
            $_.Kind -eq 'Comment' -and
            $_.Text -match '^\s*<#[\s\S]*?#>\s*$' -and
            $_.Extent.StartLineNumber -gt ($paramBlockStartLine + 1) -and
            $_.Extent.EndLineNumber -lt $paramBlockEndLine
        }

        # Process from bottom to top to maintain line numbers
        for ($lineIdx = $paramBlockEndLine - 1; $lineIdx -gt ($paramBlockStartLine + 1); $lineIdx--) {
            # Check if we're inside a comment block
            $insideCommentBlock = $false
            foreach ($commentBlock in $commentBlocks) {
                if ($lineIdx -ge ($commentBlock.Extent.StartLineNumber - 1) -and
                    $lineIdx -le ($commentBlock.Extent.EndLineNumber - 1)) {
                    $insideCommentBlock = $true
                    break
                }
            }

            # Only process blank lines that are not inside comment blocks
            if (-not $insideCommentBlock -and $lines[$lineIdx].Trim() -eq '') {
                # Count consecutive blank lines
                $consecutiveBlankLines = 1
                $checkIdx = $lineIdx - 1

                while ($checkIdx -gt $paramBlockStartLine -and $lines[$checkIdx].Trim() -eq '') {
                    # Make sure this blank line is also not inside a comment block
                    $blankLineInsideComment = $false
                    foreach ($commentBlock in $commentBlocks) {
                        if ($checkIdx -ge ($commentBlock.Extent.StartLineNumber - 1) -and
                            $checkIdx -le ($commentBlock.Extent.EndLineNumber - 1)) {
                            $blankLineInsideComment = $true
                            break
                        }
                    }

                    if ($blankLineInsideComment) {
                        break
                    }

                    $consecutiveBlankLines++
                    $checkIdx--
                }

                # If we have more than one consecutive blank line, remove the extras
                if ($consecutiveBlankLines -gt 1) {
                    # Remove the extra blank lines (keep only one)
                    for ($removeIdx = $lineIdx; $removeIdx -gt ($lineIdx - $consecutiveBlankLines + 1); $removeIdx--) {
                        $lines = $lines[0..($removeIdx - 1)] + $lines[($removeIdx + 1)..($lines.Count - 1)]
                        $modified = $true
                        Write-Verbose "Removed extra blank line within param block at line $($removeIdx + 1)"
                    }

                    # Skip past the blank lines we just processed
                    $lineIdx = $lineIdx - $consecutiveBlankLines + 1
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
