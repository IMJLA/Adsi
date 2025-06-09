function Add-GitHubReleaseAsset {

    # Function to upload release asset

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$Token,
        [string]$UploadUrl,
        [string]$FilePath,
        [string]$FileName,
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