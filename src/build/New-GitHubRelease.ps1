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

# Function to find the version folder dynamically
function Get-VersionFolder {
    param([string]$DistPath)

    if (-not (Test-Path $DistPath)) {
        throw "Dist folder not found at: $DistPath"
    }

    Write-InfoColor "`t`t`tGet-ChildItem -Path '$DistPath' -Directory | Where-Object {`$_.Name -match '^\d+\.\d+\.\d+'}"
    $versionFolders = Get-ChildItem -Path $DistPath -Directory | Where-Object { $_.Name -match '^\d+\.\d+\.\d+' }

    if ($versionFolders.Count -eq 0) {
        throw "No version folder found in: $DistPath"
    }

    if ($versionFolders.Count -gt 1) {
        Write-Warning "Multiple version folders found. Using the first one: $($versionFolders[0].Name)"
    }

    return $versionFolders[0]
}

# Function to create GitHub release
function New-GitHubRelease {
    param(
        [string]$Token,
        [string]$Repo,
        [string]$TagName,
        [string]$ReleaseName,
        [string]$Body
    )

    $headers = @{
        'Authorization' = "Bearer $Token"
        'Accept'        = 'application/vnd.github.v3+json'
        'Content-Type'  = 'application/json'
    }

    $releaseData = @{
        tag_name         = $TagName
        target_commitish = 'main'
        name             = $ReleaseName
        body             = $Body
        draft            = $false
        prerelease       = $false
    } | ConvertTo-Json

    $uri = "https://api.github.com/repos/$Repo/releases"

    Write-InfoColor "`t`t`tInvoke-RestMethod -Uri '$uri' -Method Post -Headers `$headers -Body `$releaseData"
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $releaseData
        return $response
    }
    catch {
        throw "Failed to create release: $($_.Exception.Message)"
    }
}

# Function to upload release asset
function Add-ReleaseAsset {
    param(
        [string]$Token,
        [string]$UploadUrl,
        [string]$FilePath,
        [string]$FileName
    )

    $headers = @{
        'Authorization' = "Bearer $Token"
        'Content-Type'  = 'application/octet-stream'
    }

    $uploadUri = $UploadUrl -replace '\{\?name,label\}', "?name=$FileName"
    Write-InfoColor "`t`t`tInvoke-RestMethod -Uri '$uploadUri' -Method Post -Headers `$headers -InFile '$FilePath'"

    try {
        $response = Invoke-RestMethod -Uri $uploadUri -Method Post -Headers $headers -InFile $FilePath
        return $response
    }
    catch {
        throw "Failed to upload asset $FileName : $($_.Exception.Message)"
    }
}

# Main script execution
try {

    # Find the version folder
    Write-InfoColor "`t`tGet-VersionFolder -DistPath '$DistPath'"
    $versionFolder = Get-VersionFolder -DistPath $DistPath
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

    Write-InfoColor "`t`tCompress-Archive -Path '$versionFolderPath\*' -DestinationPath '$ZipFileDisplayPath' -Force"
    Compress-Archive -Path "$($versionFolder.FullName)\*" -DestinationPath $zipFilePath -Force

    # Check if zip file was created successfully
    if (Test-Path $zipFilePath) {
        Write-InfoColor "`t`tAdd-ReleaseAsset -Token `$GitHubToken -UploadUrl '$($release.upload_url)' -FilePath '$ZipFileDisplayPath' -FileName '$zipFileName'"
        $null = Add-ReleaseAsset -Token $GitHubToken -UploadUrl $release.upload_url -FilePath $zipFilePath -FileName $zipFileName

        # Clean up temporary zip file
        Write-Information "`t`tRemove-Item '$ZipFileDisplayPath' -Force"
        Remove-Item $zipFilePath -Force
    }
    else {
        throw "Failed to create zip file at: $zipFilePath"
    }

    return $release
}
catch {

    Write-Error "Script failed: $($_.Exception.Message)"
    exit 1

}
