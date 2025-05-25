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

    Write-Information "`t`tGet-ChildItem -Path '$DistPath' -Directory | Where-Object {`$_.Name -match '^\d+\.\d+\.\d+'}"
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

    Write-Information "`t`tInvoke-RestMethod -Uri '$uri' -Method Post -Headers `$headers -Body `$releaseData"
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
    Write-Information "`t`tInvoke-RestMethod -Uri '$uploadUri' -Method Post -Headers `$headers -InFile '$FilePath'"

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
    Write-Information "`tGet-VersionFolder -DistPath '$DistPath'"
    $versionFolder = Get-VersionFolder -DistPath $DistPath
    $version = $versionFolder.Name

    # Create the release
    Write-Information "`tNew-GitHubRelease -Token `$GitHubToken -Repo '$Repository' -TagName 'v$version' -ReleaseName 'Release $version' -Body '$ReleaseNotes'"
    $release = New-GitHubRelease -Token $GitHubToken -Repo $Repository -TagName "v$version" -ReleaseName "Release $version" -Body $ReleaseNotes

    #Write-Information "`tRelease created successfully. ID: $($release.id)"

    # Upload files from version folder
    Write-Information "`tGet-ChildItem -Path '$($versionFolder.FullName)' -File -Recurse"
    $files = Get-ChildItem -Path $versionFolder.FullName -File -Recurse

    if ($files.Count -eq 0) {
        Write-Warning 'No files found in version folder to upload'
    }
    else {

        foreach ($file in $files) {

            $relativePath = $file.FullName.Substring($versionFolder.FullName.Length + 1)
            $assetName = $relativePath -replace '\\', '-'

            Write-Information "`tAdd-ReleaseAsset -Token `$GitHubToken -UploadUrl '$($release.upload_url)' -FilePath '$($file.FullName)' -FileName '$assetName'" -ForegroundColor Yellow
            Add-ReleaseAsset -Token $GitHubToken -UploadUrl $release.upload_url -FilePath $file.FullName -FileName $assetName

        }

    }

    Write-Information "`tRelease URL: $($release.html_url)" -ForegroundColor Cyan
}
catch {

    Write-Error "Script failed: $($_.Exception.Message)"
    exit 1

}
