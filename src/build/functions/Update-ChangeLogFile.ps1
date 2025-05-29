function Update-ChangeLogFile {
    #requires -Module ChangelogManagement
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [version]$Version,
        [string]$CommitMessage,
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

    $InformationPreference = 'Continue'
    $cmdstr = "`t`tAdd-ChangelogData -Type '$Type' -Path '$ChangeLog' -Data '$CommitMessage'"
    $cmdstr2 = "`t`tUpdate-Changelog -ReleaseVersion $Version -LinkMode 'None' -Path '$ChangeLog'"

    if ($WhatIfPreference) {
        Write-Information "`tWould run:$cmdstr"
        Write-Information "`tWould run:$cmdstr2"
        return
    } elseif ($PSCmdlet.ShouldProcess($ChangeLog, 'Update ChangeLog File')) {
        Write-Information $cmdstr
        Add-ChangelogData -Type $Type -Data $CommitMessage -Path $ChangeLog
        Write-Information $cmdstr2
        Update-Changelog -ReleaseVersion $Version -LinkMode 'None' -Path $ChangeLog
    }


}
