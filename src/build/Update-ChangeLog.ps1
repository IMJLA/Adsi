#requires -Module ChangelogManagement

[CmdletBinding()]
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

Write-Verbose "`tAdd-ChangelogData -Type '$Type' -Path '$ChangeLog' -Data '$CommitMessage'"
Add-ChangelogData -Type $Type -Data $CommitMessage -Path $ChangeLog
Write-Verbose "`tUpdate-Changelog -Version '$Version' -LinkMode 'None' -Path '$ChangeLog'"
Update-Changelog -ReleaseVersion $Version -LinkMode 'None' -Path $ChangeLog
