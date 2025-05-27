function New-GitHubRelease {
    # Function to create GitHub release
    [CmdletBinding(SupportsShouldProcess)]
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

    if ($PSCmdlet.ShouldProcess("Repository: $Repo, Tag: $TagName", 'Create GitHub Release')) {
        try {
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $releaseData
            return $response
        } catch {
            throw "Failed to create release: $($_.Exception.Message)"
        }
    }
}
