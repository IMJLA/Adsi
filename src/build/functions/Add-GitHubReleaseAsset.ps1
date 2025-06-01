function Add-GitHubReleaseAsset {
    # Function to upload release asset
    [CmdletBinding(SupportsShouldProcess)]
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
    Write-Information "`tInvoke-RestMethod -Uri '$uploadUri' -Method Post -Headers `$headers -InFile '$FilePath'"

    if ($PSCmdlet.ShouldProcess("File: $FileName", 'Upload Release Asset')) {
        try {
            $response = Invoke-RestMethod -Uri $uploadUri -Method Post -Headers $headers -InFile $FilePath
            return $response
        } catch {
            throw "Failed to upload asset $FileName : $($_.Exception.Message)"
        }
    }

}
