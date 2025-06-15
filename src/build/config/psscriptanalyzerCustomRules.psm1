function Measure-CommentBasedHelpSpacing {
    <#
    .SYNOPSIS
        Custom PSScriptAnalyzer rules for enforcing consistent formatting

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
        $ast = [System.Management.Automation.Language.Parser]::ParseInput(
            $ScriptBlockAst.Extent.Text,
            [ref]$tokens,
            [ref]$parseErrors
        )

        if (-not $tokens) {
            return [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]$results
        }

        # Find comment tokens that look like comment-based help
        $commentTokens = $tokens | Where-Object {
            $_ -and
            $_.Kind -eq 'Comment' -and
            $_.Text -and
            $_.Text -match '^\s*<#[\s\S]*?#>\s*$'
        }

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

        # Get tokens to find actual param block boundaries
        $tokens = $null
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput(
            $ScriptBlockAst.Extent.Text,
            [ref]$tokens,
            [ref]$parseErrors
        )

        if (-not $tokens) {
            return [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]$results
        }

        # Find param blocks
        $paramBlocks = $ScriptBlockAst.FindAll({

                param($ast)

                $ast -is [System.Management.Automation.Language.ParamBlockAst]
            }, $true)

        if (-not $paramBlocks) {
            return [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]$results
        }

        $lines = $ScriptBlockAst.Extent.Text -split "`r?`n"

        foreach ($paramBlock in $paramBlocks) {
            if (-not $paramBlock.Extent) {
                continue
            }

            $startLine = $paramBlock.Extent.StartLineNumber - 1

            # Find the actual end of the param block by looking for the closing parenthesis
            $paramStartOffset = $paramBlock.Extent.StartOffset
            $paramEndOffset = $paramBlock.Extent.EndOffset

            # Find the closing parenthesis token that matches this param block
            $closingParen = $tokens | Where-Object {
                $_.Kind -eq 'RParen' -and
                $_.Extent.StartOffset -ge $paramStartOffset -and
                $_.Extent.StartOffset -le $paramEndOffset
            } | Select-Object -Last 1

            if ($closingParen) {
                $endLine = $closingParen.Extent.EndLineNumber - 1
            } else {
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

            # Check blank line after
            if ($endLine -ge 0 -and ($endLine + 1) -lt $lines.Count -and $lines[$endLine + 1].Trim() -ne '') {
                $results += [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                    Message  = 'Param block should have a blank line after it'
                    Extent   = $paramBlock.Extent
                    RuleName = 'ParamBlockSpacing'
                    Severity = 'Warning'
                }
            }
        }
    } catch {
        Write-Warning "Error in Measure-ParamBlockSpacing: $_"
    }

    return [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]$results
}

Export-ModuleMember -Function Measure-CommentBasedHelpSpacing, Measure-ParamBlockSpacing
