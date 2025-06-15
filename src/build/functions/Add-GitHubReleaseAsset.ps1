function Add-GitHubReleaseAsset {

    <#
    .SYNOPSIS
    Uploads a release asset to a GitHub release.

    .DESCRIPTION
    Function to upload release asset to a specified GitHub release using the provided upload URL and authentication token.

    .EXAMPLE
    Add-GitHubReleaseAsset -Token $token -UploadUrl $uploadUrl -FilePath 'package.zip' -FileName 'package.zip' -FileDisplayPath './package.zip'
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(

        # GitHub authentication token
        [string]$Token,

        # GitHub release upload URL
        [string]$UploadUrl,

        # Full path to the file to upload
        [string]$FilePath,

        # Name for the uploaded file
        [string]$FileName,

        # Display path for the file (for logging purposes)
        [string]$FileDisplayPath

    )

    $Headers = @{

        'Authorization' = "Bearer $Token"
        'Content-Type'  = 'application/octet-stream'
    }

    $uploadUri = $UploadUrl -replace '\{\?name,label\}', "?name=$FileName"
    Write-Information "`t`$Headers = @{ 'Authorization'=`"Bearer `$Token`" ; 'Content-Type'='application/octet-stream' }"
    Write-Information "`tInvoke-RestMethod -Uri '$uploadUri' -Method Post -Headers `$Headers -InFile `"$FileDisplayPath`""

    if ($PSCmdlet.ShouldProcess("File: $FileName", 'Upload Release Asset')) {
        try {
            Invoke-RestMethod -Uri $uploadUri -Method Post -Headers $Headers -InFile $FilePath -ErrorAction Stop
        } catch {
            throw "Failed to upload asset $FileName : $($_.Exception.Message)"
        }
    }

}
