function Export-BuildModuleManifestFunction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleManifestPath,

        [Parameter(Mandatory)]
        [string[]]$FunctionName
    )

    Write-Verbose "`t[string]`$ManifestContent = Get-Content -LiteralPath '$ModuleManifestPath' -Raw"
    $ManifestContent = Get-Content -Path $ModuleManifestPath -Raw
    $UpdatedContent = $ManifestContent -replace '(FunctionsToExport\s*=\s*)@\([^)]*\)', "`$1@('$($FunctionName -join "', '")')"
    Write-Information "`tSet-Content -Path '$ModuleManifestPath' -Value `$UpdatedManifestContent -Encoding UTF8BOM -ErrorAction Stop"
    Set-Content -Path $ModuleManifestPath -Value $UpdatedContent -Encoding UTF8BOM -ErrorAction Stop

}
