function Format-PowerShellSpacing {
    [CmdletBinding()]

    param(
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
