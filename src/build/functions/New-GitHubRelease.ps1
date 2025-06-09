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
        'tag_name'         = $TagName
        'target_commitish' = 'main'
        'name'             = $ReleaseName
        'body'             = $Body
        'draft'            = $false
        'prerelease'       = $false
    } | ConvertTo-Json

    $uri = "https://api.github.com/repos/$Repo/releases"
    Write-Information "`t`$Headers = @{ 'Authorization'=`"Bearer `$Token`" ; 'Accept'='application/vnd.github.v3+json' ; 'Content-Type'='application/json' }"
    Write-Information "`t`$Body = @{ 'tag_name'='$TagName'; 'target_commitish'='main'; 'name'='$ReleaseName'; 'body'='$Body'; 'draft'=`$false; 'prerelease'=`$false } | ConvertTo-Json"
    Write-Information "`tInvoke-RestMethod -Uri '$uri' -Method Post -Headers `$Headers -Body '`$Body'"

    if ($PSCmdlet.ShouldProcess("Repository: $Repo, Tag: $TagName", 'Create GitHub Release')) {

        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $releaseData -ErrorAction Stop
        Start-Sleep -Seconds 1 # wait for the API to process the request to avoid HTTP 422 Unprocessable Entity or other errors
        return $response

    }

}
