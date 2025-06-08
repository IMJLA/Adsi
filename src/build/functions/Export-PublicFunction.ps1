function Export-PublicFunction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo[]]$PublicFunctionFile,

        [Parameter(Mandatory)]
        [string]$ModuleFilePath,

        [Parameter(Mandatory)]
        [string]$ModuleManifestPath
    )

    Write-Information "`tExport-PublicFunction -PublicFunctionFile `$PublicFunctionFile -ModuleFilePath '$ModuleFilePath' -ModuleManifestPath '$ModuleManifestPath'"

    # Extract function names from files
    $FunctionNames = $PublicFunctionFile | ForEach-Object {
        $Content = Get-Content -Path $_.FullName -Raw
        if ($Content -match 'function\s+([A-Za-z0-9-_]+)') {
            $Matches[1]
        }
    }

    # Update module manifest with exported functions
    if ($FunctionNames) {
        $ManifestContent = Get-Content -Path $ModuleManifestPath -Raw
        $UpdatedContent = $ManifestContent -replace '(FunctionsToExport\s*=\s*)@\([^)]*\)', "`$1@('$($FunctionNames -join "', '")')"
        Set-Content -Path $ModuleManifestPath -Value $UpdatedContent -Encoding UTF8

        Write-InfoColor "`t# Successfully exported $($FunctionNames.Count) public functions in the module." -ForegroundColor Green
    } else {
        Write-InfoColor "`t# No public functions found to export." -ForegroundColor Yellow
    }
}
