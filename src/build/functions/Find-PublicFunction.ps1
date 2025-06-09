function Find-PublicFunction {

    [CmdletBinding()]

    param(
        [string]$PublicFunctionPath
    )

    Write-Information "`tGet-ChildItem -Path '$PublicFunctionPath'"
    $PublicFunctionFiles = Get-ChildItem -Path $PublicFunctionPath -ErrorAction SilentlyContinue
    Write-InfoColor "`t# Found $($PublicFunctionFiles.Count) public function files." -ForegroundColor Green
    return $PublicFunctionFiles

}