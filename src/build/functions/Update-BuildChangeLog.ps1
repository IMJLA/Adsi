function Update-BuildChangeLog {

    <#
    .SYNOPSIS
    Updates the change log file with new version and commit message.

    .DESCRIPTION
    Analyzes the commit message to determine the type of change and adds it to the change log,
    then updates the change log with the new release version.

    .EXAMPLE
    Update-BuildChangeLog -Version '1.0.0' -CommitMessage 'Add new feature'
    #>

    #requires -Module ChangelogManagement

    [CmdletBinding(SupportsShouldProcess)]

    param (

        # The version number for the release
        [version]$Version,

        # The commit message to analyze and add to the change log
        [string]$CommitMessage,

        # Path to the change log file
        [string]$ChangeLog = [IO.Path]::Combine('..', '..', 'CHANGELOG.md')

    )

    switch -Wildcard ($CommitMessage) {
        'add*' { $Type = 'Added' }
        'bug*' { $Type = 'Fixed' }
        'change*' { $Type = 'Changed' }
        'deprecate*' { $Type = 'Deprecated' }
        'delete*' { $Type = 'Removed' }
        'fix*' { $Type = 'Fixed' }
        'implement*' { $Type = 'Added' }
        'remove*' { $Type = 'Removed' }
        '*security*' { $Type = 'Security' }
        default { $Type = 'Changed' }
    }

    $cmdstr = "`tAdd-ChangelogData -Type '$Type' -Path '$ChangeLog' -Data '$CommitMessage'"
    $cmdstr2 = "`tUpdate-Changelog -ReleaseVersion $Version -LinkMode 'None' -Path '$ChangeLog'"

    if ($WhatIfPreference) {
        Write-Information "`tWould run:$cmdstr"
        Write-Information "`tWould run:$cmdstr2"
        return
    } elseif ($PSCmdlet.ShouldProcess($ChangeLog, 'Update ChangeLog File')) {
        Write-Information $cmdstr
        Add-ChangelogData -Type $Type -Data $CommitMessage -Path $ChangeLog -ErrorAction Stop
        Write-Information $cmdstr2
        Update-Changelog -ReleaseVersion $Version -LinkMode 'None' -Path $ChangeLog -ErrorAction Stop
    }

    Write-InfoColor "`t# Successfully updated the Change Log with the new version and commit message." -ForegroundColor Green

    <#
    TODO
        This task runs before the Test task so that tests of the change log will pass
        But I also need one that runs *after* the build to compare it against the previous build
        The post-build UpdateChangeLog will automatically add to the change log any:
            New/removed exported commands
            New/removed files
    #>
}
