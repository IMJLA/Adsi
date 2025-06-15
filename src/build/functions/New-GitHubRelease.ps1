function New-GitHubRelease {

    <#
    .SYNOPSIS
    Creates a new GitHub release using the GitHub API.

    .DESCRIPTION
    This function creates a new release on GitHub for the specified repository using the GitHub REST API.
    It handles authentication and provides detailed error handling for common issues.

    .EXAMPLE
    New-GitHubRelease -Token $token -Repo 'owner/repository' -TagName 'v1.0.0' -ReleaseName 'Release 1.0.0' -Body 'Release notes'
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(

        # GitHub authentication token
        [Parameter(Mandatory)]
        [string]$Token,

        # Repository in the format 'owner/repository'

        [Parameter(Mandatory)]
        [string]$Repo,

        # Git tag name for the release

        [Parameter(Mandatory)]
        [string]$TagName,

        # Name/title of the release

        [Parameter(Mandatory)]
        [string]$ReleaseName,

        # Release notes/body content

        [string]$Body = '',

        # Whether this is a draft release

        [bool]$Draft = $false,

        # Whether this is a prerelease

        [bool]$Prerelease = $false
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
        'draft'            = $Draft
        'prerelease'       = $Prerelease
    } | ConvertTo-Json

    $uri = "https://api.github.com/repos/$Repo/releases"
    Write-Information "`t`$Headers = @{'Authorization'=`"Bearer `$Token`";'Accept'='application/vnd.github.v3+json';'Content-Type'='application/json'}"
    Write-Information "`t`$BodyFields = @{'tag_name'='$TagName';'target_commitish'='main';'name'='$ReleaseName';'body'=`"$Body`";'draft'=`$false;'prerelease'=`$false}"
    Write-Information "`t`$Body = `$BodyFields | ConvertTo-Json"
    Write-Information "`tInvoke-RestMethod -Uri '$uri' -Method Post -Headers `$Headers -Body `$Body"

    if ($PSCmdlet.ShouldProcess("Repository: $Repo, Tag: $TagName", 'Create GitHub Release')) {

        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $releaseData -ErrorAction Stop
        Start-Sleep -Seconds 1 # wait for the API to process the request to avoid HTTP 422 Unprocessable Entity or other errors
        return $response

    }

}
