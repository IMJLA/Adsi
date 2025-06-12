function Invoke-SourceControl {

    <#
    .SYNOPSIS
    Commit and push changes to source control using git.

    .DESCRIPTION
    Performs git add, commit, and push operations to commit changes to source control.
    Includes validation to ensure all changes are successfully committed.

    .EXAMPLE
    Invoke-SourceControl -CommitMessage "Updated module version"
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The commit message to use for the git commit
        [Parameter(Mandatory)]
        [string]$CommitMessage,

        # The newline character(s) to use in output messages
        [string]$NewLine = [System.Environment]::NewLine
    )

    # Find the current git branch
    Write-Verbose "`tInvoke-FileWithOutputPrefix -Command 'git' -ArgumentArray @('branch', '--show-current') -InformationAction 'Continue' -OutputPrefix ''"
    Write-Verbose "`t& git branch --show-current"
    $CurrentBranch = & git branch --show-current

    # Add all changes
    if ($PSCmdlet.ShouldProcess('.', 'git add all changes')) {
        Write-Verbose "`tInvoke-FileWithOutputPrefix -Command 'git' -ArgumentArray @('add', '.') -InformationAction 'Continue' -OutputPrefix ''"
        Write-Information "`t& git add .$NewLine"
        $null = Invoke-FileWithOutputPrefix -Command 'git' -ArgumentArray @('add', '.') -InformationAction 'Continue' -OutputPrefix ''
    }

    # Commit changes
    if ($PSCmdlet.ShouldProcess($CommitMessage, 'git commit')) {
        Write-Verbose "`tInvoke-FileWithOutputPrefix -Command 'git' -ArgumentArray @('commit', '-m', `$CommitMessage) -InformationAction 'Continue' -OutputPrefix ''"
        Write-Information "`t& git commit -m `"$CommitMessage`""
        $null = Invoke-FileWithOutputPrefix -Command 'git' -ArgumentArray @('commit', '-m', "`"$CommitMessage`"") -InformationAction 'Continue' -OutputPrefix ''
    }

    # Push to remote
    if ($PSCmdlet.ShouldProcess("origin $CurrentBranch", 'git push')) {
        Write-Verbose "`tInvoke-FileWithOutputPrefix -Command 'git' -ArgumentArray @('push', 'origin', '$CurrentBranch') -InformationAction 'Continue' -OutputPrefix ''"
        Write-Information "`t& git push origin $CurrentBranch"
        $null = Invoke-FileWithOutputPrefix -Command 'git' -ArgumentArray @('push', 'origin', $CurrentBranch) -InformationAction 'Continue' -OutputPrefix ''
    }

    # Test if commit was successful by checking git status
    Write-Verbose "`tInvoke-FileWithOutputPrefix -Command 'git' -ArgumentString 'status --porcelain' -InformationAction 'Continue' -OutputPrefix ''"
    Write-Verbose "`t& git status --porcelain"
    $gitStatus = Invoke-FileWithOutputPrefix -Command 'git' -ArgumentArray @('status', '--porcelain') -InformationAction 'Continue' -OutputPrefix ''

    if ($gitStatus) {
        Write-Error 'Failed to commit all changes to source control'
    } else {
        Write-InfoColor "`t# Successfully committed and pushed changes to source control." -ForegroundColor Green
    }
}
