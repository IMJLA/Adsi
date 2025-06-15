function Remove-DownloadableHelp {

    <#
    .SYNOPSIS
    Removes the downloadable help directory from the online help website.

    .DESCRIPTION
    This function removes the static/UpdatableHelp directory from the online help website
    to prepare for copying fresh updatable help files.

    .EXAMPLE
    Remove-DownloadableHelp -DocsOnlineHelpDir './docs/online/MyModule'
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(
        # Directory of the online help website
        [Parameter(Mandatory)]
        [string]$DocsOnlineHelpDir
    )

    $downloadableHelpPath = [IO.Path]::Combine($DocsOnlineHelpDir, 'static', 'UpdatableHelp')

    if (Test-Path $downloadableHelpPath) {
        if ($PSCmdlet.ShouldProcess($downloadableHelpPath, 'Remove downloadable help directory')) {
            Write-Information "`tRemove-Item -Path '$downloadableHelpPath' -Recurse -Force"
            Remove-Item -Path $downloadableHelpPath -Recurse -Force -ErrorAction Stop
        }
    }

    $downloadableHelpPath = [IO.Path]::Combine($DocsOnlineHelpDir, 'build', 'UpdatableHelp')

    if (Test-Path $downloadableHelpPath) {
        if ($PSCmdlet.ShouldProcess($downloadableHelpPath, 'Remove downloadable help directory')) {
            Write-Information "`tRemove-Item -Path '$downloadableHelpPath' -Recurse -Force"
            Remove-Item -Path $downloadableHelpPath -Recurse -Force -ErrorAction Stop
        }
    }

    Write-InfoColor "`t# Successfully removed existing downloadable help directory." -ForegroundColor Green
}
