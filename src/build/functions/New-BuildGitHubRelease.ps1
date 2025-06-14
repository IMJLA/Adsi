﻿function New-BuildGitHubRelease {

    <#
    .SYNOPSIS
    Creates a new GitHub release with module assets.

    .DESCRIPTION
    This function creates a new GitHub release for a PowerShell module, including creating a zip file
    of the module and uploading it as a release asset.

    .EXAMPLE
    New-BuildGitHubRelease -GitHubToken $token -GitHubOrgName 'MyOrg' -ModuleName 'MyModule'
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(

        # GitHub authentication token for API access
        [Parameter(Mandatory = $true)]
        [string]$GitHubToken,

        # GitHub organization name
        [Parameter(Mandatory = $true)]
        [string]$GitHubOrgName,

        # Name of the module to release
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        # Path to the distribution directory. Defaults to '.\dist'
        [Parameter(Mandatory = $false)]
        [string]$DistPath = '.\dist',

        # Release notes for the GitHub release
        [Parameter(Mandatory = $false)]
        [string]$ReleaseNotes = 'Automated release'

    )

    # Main script execution

    Write-Verbose "`tGet-VersionFolder -DistPath '$DistPath'"
    $versionFolder = Get-VersionFolder -DistPath $DistPath

    # Find the version folder
    $version = $versionFolder.Name

    # Construct repository path
    $Repository = "$GitHubOrgName/$ModuleName"


    try {

        # Create the release
        Write-Verbose "`tNew-GitHubRelease -Token `$GitHubToken -Repo '$Repository' -TagName 'v$version' -ReleaseName 'Release $version' -Body '$ReleaseNotes' -InformationAction 'Continue'"
        $release = New-GitHubRelease -Token $GitHubToken -Repo $Repository -TagName "v$version" -ReleaseName "Release $version" -Body $ReleaseNotes -InformationAction 'Continue'
        Write-Information ''

        # Create zip file from version folder contents
        $zipFileName = "$version.zip"
        $zipFilePath = Join-Path $env:TEMP $zipFileName
        $ZipFileDisplayPath = [IO.Path]::Combine('$env:TEMP', $zipFileName)
        Write-Information "`tCompress-Archive -Path '$DistPath\*' -DestinationPath `"$ZipFileDisplayPath`" -Force"

        if ($PSCmdlet.ShouldProcess($zipFilePath, 'Create Archive')) {
            Compress-Archive -Path "$DistPath\*" -DestinationPath $zipFilePath -Force
        }

        # Check if zip file was created successfully
        if (Test-Path $zipFilePath) {

            # Add the module zip file to the release
            Write-Verbose "`tAdd-GitHubReleaseAsset -Token `$GitHubToken -UploadUrl '$($release.upload_url)' -FilePath `"$ZipFileDisplayPath`" -FileName '$zipFileName' -FileDisplayPath $ZipFileDisplayPath"
            $null = Add-GitHubReleaseAsset -Token $GitHubToken -UploadUrl $release.upload_url -FilePath $zipFilePath -FileName $zipFileName -InformationAction 'Continue' -FileDisplayPath $ZipFileDisplayPath

            # Clean up temporary zip file
            Write-Information "`tRemove-Item `"$ZipFileDisplayPath`" -Force -ProgressAction 'SilentlyContinue'"
            if ($PSCmdlet.ShouldProcess($zipFilePath, 'Remove Temporary Zip File')) {
                Remove-Item $zipFilePath -Force -ProgressAction 'SilentlyContinue'
            }
            Write-Information ''

        } else {
            throw "Failed to create zip file at: $zipFilePath"
        }

        # Validate release creation and provide output
        if ($release -and $release.html_url) {
            Write-InfoColor "`t# Successfully created GitHub release: $($release.html_url)" -ForegroundColor Green
        } else {
            Write-Error 'Failed to create GitHub release'
        }

        return $release

    } catch {

        Write-Error "Script failed: $($_.Exception.Message)"
        exit 1

    }

}
