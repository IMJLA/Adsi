function New-BuildGitHubRelease {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$GitHubToken,

        [Parameter(Mandatory = $true)]
        [string]$Repository,

        [Parameter(Mandatory = $false)]
        [string]$DistPath = '.\Dist',

        [Parameter(Mandatory = $false)]
        [string]$ReleaseNotes = 'Automated release'
    )

    $InformationPreference = 'Continue'
    Write-InfoColor "`t`tGet-VersionFolder -DistPath '$DistPath'"
    $versionFolder = Get-VersionFolder -DistPath $DistPath

    # Main script execution
    try {

        # Find the version folder
        $version = $versionFolder.Name
        $versionFolderParentToReplace = $versionFolder.FullName | Split-Path -Parent
        $versionFolderPath = $versionFolder.FullName -replace [regex]::Escape($versionFolderParentToReplace), $DistPath

        # Create the release
        Write-InfoColor "`t`tNew-GitHubRelease -Token `$GitHubToken -Repo '$Repository' -TagName 'v$version' -ReleaseName 'Release $version' -Body '$ReleaseNotes'"
        $release = New-GitHubRelease -Token $GitHubToken -Repo $Repository -TagName "v$version" -ReleaseName "Release $version" -Body $ReleaseNotes

        # Create zip file from version folder contents
        $zipFileName = "$version.zip"
        $zipFilePath = Join-Path $env:TEMP $zipFileName
        $ZipFileDisplayPath = [IO.Path]::Combine('$env:TEMP', $zipFileName)

        Write-InfoColor "`t`tCompress-Archive -Path '$versionFolderPath\*' -DestinationPath `"$ZipFileDisplayPath`" -Force"

        if ($PSCmdlet.ShouldProcess($zipFilePath, 'Create Archive')) {
            Compress-Archive -Path "$($versionFolder.FullName)\*" -DestinationPath $zipFilePath -Force
        }

        # Check if zip file was created successfully
        if (Test-Path $zipFilePath) {
            Write-InfoColor "`t`tAdd-GitHubReleaseAsset -Token `$GitHubToken -UploadUrl '$($release.upload_url)' -FilePath `"$ZipFileDisplayPath`" -FileName '$zipFileName'"
            $null = Add-GitHubReleaseAsset -Token $GitHubToken -UploadUrl $release.upload_url -FilePath $zipFilePath -FileName $zipFileName

            # Clean up temporary zip file
            Write-Information "`t`tRemove-Item `"$ZipFileDisplayPath`" -Force"
            if ($PSCmdlet.ShouldProcess($zipFilePath, 'Remove Temporary Zip File')) {
                Remove-Item $zipFilePath -Force
            }
        } else {
            throw "Failed to create zip file at: $zipFilePath"
        }

        return $release
    } catch {

        Write-Error "Script failed: $($_.Exception.Message)"
        exit 1

    }
}
