param (

    # The collection of files containing public functions
    [System.IO.FileInfo[]]
    $PublicFunctionFiles,

    # Path to the module file (.psm1)
    [string]
    $ModuleFilePath,

    # Path to the module manifest file (.psd1)
    [string]
    $ModuleManifestPath

)
# Export public functions in the module
$publicFunctions = $PublicFunctionFiles.BaseName
$PublicFunctionsJoined = $publicFunctions -join "','"

Write-Host "`t[string]`$ModuleContent = Get-Content -LiteralPath '$ModuleFilePath' -Raw"
$ModuleContent = Get-Content -Path $ModuleFilePath -Raw
$NewFunctionExportStatement = "Export-ModuleMember -Function @('$PublicFunctionsJoined')"

if ($ModuleContent -match 'Export-ModuleMember -Function') {

    Write-Host "`t`$ModuleContent = `$ModuleContent -replace 'Export-ModuleMember -Function.*' , `"$NewFunctionExportStatement`""
    $ModuleContent = $ModuleContent -replace 'Export-ModuleMember -Function.*' , $NewFunctionExportStatement
    Write-Host "`t`$ModuleContent | Out-File -Path '$ModuleFilePath' -Force"
    $ModuleContent | Out-File -Path $ModuleFilePath -Force

}
else {
    Write-Host "`t`"$NewFunctionExportStatement`" | Out-File '$ModuleFilePath' -Append"
    $NewFunctionExportStatement | Out-File $ModuleFilePath -Append
}

# Create a string representation of the public functions array
$publicFunctionsAsString = "@('" + ($publicFunctions -join "','") + "')"

# Export public functions in the manifest
Write-Host "`tUpdate-Metadata -Path '$ModuleManifestPath' -PropertyName FunctionsToExport -Value $publicFunctionsAsString"
Update-Metadata -Path $ModuleManifestPath -PropertyName FunctionsToExport -Value $publicFunctions