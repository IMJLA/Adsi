function Measure-CommentBasedHelpSpacing {

    <#
    .SYNOPSIS
        Custom PSScriptAnalyzer rule for enforcing proper spacing around comment-based help blocks

    .DESCRIPTION
        This rule ensures that comment-based help blocks have proper blank line spacing before and after them.
        A blank line should exist before and after comment-based help blocks to improve readability.

    .PARAMETER ScriptBlockAst
        The AST object representing the script block to analyze

    .OUTPUTS
        Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]
        Returns diagnostic records for any spacing violations found
    #>

    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]


    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]

        [System.Management.Automation.Language.ScriptBlockAst]$ScriptBlockAst

    )

    [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]$results = @()

    try {
        if (-not $ScriptBlockAst.Extent -or -not $ScriptBlockAst.Extent.Text) {
            return [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]$results
        }

        # Find all tokens to locate comment-based help
        $tokens = $null
        $parseErrors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseInput(
            $ScriptBlockAst.Extent.Text,
            [ref]$tokens,
            [ref]$parseErrors
        )

        if (-not $tokens) {
            return [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]$results
        }

        # Find comment tokens that look like comment-based help and deduplicate by position
        $commentTokens = $tokens | Where-Object {
            $_ -and
            $_.Kind -eq 'Comment' -and
            $_.Text -and
            $_.Text -match '^\s*<#[\s\S]*?#>\s*$'
        } | Sort-Object { $_.Extent.StartOffset } | Group-Object { $_.Extent.StartOffset } | ForEach-Object { $_.Group[0] }

        if (-not $commentTokens) {
            return [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]$results
        }

        $lines = $ScriptBlockAst.Extent.Text -split "`r?`n"

        foreach ($commentToken in $commentTokens) {
            if (-not $commentToken.Extent) {
                continue
            }

            $startLine = $commentToken.Extent.StartLineNumber - 1
            $endLine = $commentToken.Extent.EndLineNumber - 1

            # Check blank line before (skip if at beginning of file)
            if ($startLine -gt 0 -and $startLine -lt $lines.Count -and $lines[$startLine - 1].Trim() -ne '') {
                $results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                    Message  = 'Comment-based help should have a blank line before it'
                    Extent   = $commentToken.Extent
                    RuleName = 'CommentBasedHelpSpacing'
                    Severity = 'Warning'
                }
            }

            # Check blank line after (skip if at end of file)
            if ($endLine -ge 0 -and ($endLine + 1) -lt $lines.Count -and $lines[$endLine + 1].Trim() -ne '') {
                $results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                    Message  = 'Comment-based help should have a blank line after it'
                    Extent   = $commentToken.Extent
                    RuleName = 'CommentBasedHelpSpacing'
                    Severity = 'Warning'
                }
            }
        }
    } catch {
        Write-Warning "Error in Measure-CommentBasedHelpSpacing: $_"
    }

    return [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]$results
}

function Measure-ParamBlockSpacing {

    <#
    .SYNOPSIS
        Custom PSScriptAnalyzer rule for enforcing proper spacing around param blocks

    .DESCRIPTION
        This rule ensures that param blocks have proper blank line spacing before and after them.
        A blank line should exist before the param block (unless preceded by comment-based help)
        and after the param block's closing parenthesis.

    .PARAMETER ScriptBlockAst
        The AST object representing the script block to analyze

    .OUTPUTS
        Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]
        Returns diagnostic records for any spacing violations found

    .EXAMPLE
        Measure-ParamBlockSpacing -ScriptBlockAst $ast
        Analyzes the provided AST for param block spacing issues
    #>

    [CmdletBinding()]

    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]

    param(

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]

        [System.Management.Automation.Language.ScriptBlockAst]$ScriptBlockAst
    )

    [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]$results = @()

    try {
        if (-not $ScriptBlockAst.Extent -or -not $ScriptBlockAst.Extent.Text) {
            return [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]$results
        }

        # Find param blocks and deduplicate by position
        $paramBlocks = $ScriptBlockAst.FindAll({

                param($ast)

                $ast -is [System.Management.Automation.Language.ParamBlockAst]
            }, $true) | Sort-Object { $_.Extent.StartOffset } | Group-Object { $_.Extent.StartOffset } | ForEach-Object { $_.Group[0] }

        if (-not $paramBlocks) {
            return [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]$results
        }

        $lines = $ScriptBlockAst.Extent.Text -split "`r?`n"

        foreach ($paramBlock in $paramBlocks) {
            if (-not $paramBlock.Extent) {
                continue
            }

            $startLine = $paramBlock.Extent.StartLineNumber - 1

            # For param blocks, we want to find the line containing the closing parenthesis
            # The AST extent may include trailing whitespace or comments after the )
            $paramText = $paramBlock.Extent.Text
            $paramLines = $paramText -split "`r?`n"

            # Find the last line that contains a closing parenthesis
            $closingParenLineIndex = -1
            for ($i = $paramLines.Count - 1; $i -ge 0; $i--) {
                if ($paramLines[$i] -match '\)') {
                    $closingParenLineIndex = $i
                    break
                }
            }

            if ($closingParenLineIndex -ge 0) {
                $endLine = $startLine + $closingParenLineIndex
            } else {
                # Fallback to the AST extent end line
                $endLine = $paramBlock.Extent.EndLineNumber - 1
            }

            # Check blank line before (allow comment-based help immediately before)
            if ($startLine -gt 0 -and $startLine -lt $lines.Count) {
                $prevLine = $lines[$startLine - 1].Trim()
                if ($prevLine -ne '' -and $prevLine -notmatch '#>$') {
                    $results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                        Message  = 'Param block should have a blank line before it'
                        Extent   = $paramBlock.Extent
                        RuleName = 'ParamBlockSpacing'
                        Severity = 'Warning'
                    }
                }
            }

            # Check blank line after - ensure we're not at the end of the file and the next line isn't blank
            if ($endLine -ge 0 -and ($endLine + 1) -lt $lines.Count) {
                $nextLine = $lines[$endLine + 1].Trim()
                if ($nextLine -ne '') {
                    $results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                        Message  = 'Param block should have a blank line after it'
                        Extent   = $paramBlock.Extent
                        RuleName = 'ParamBlockSpacing'
                        Severity = 'Warning'
                    }
                }
            }
        }
    } catch {
        Write-Warning "Error in Measure-ParamBlockSpacing: $_"
    }

    return [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]$results
}

Export-ModuleMember -Function Measure-CommentBasedHelpSpacing, Measure-ParamBlockSpacing
