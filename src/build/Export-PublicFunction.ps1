[CmdletBinding()]
param (

    # The collection of files containing public functions
    [System.IO.FileInfo[]]$PublicFunctionFiles,

    # Path to the module file (.psm1)
    [string]$ModuleFilePath,

    # Path to the module manifest file (.psd1)
    [string]$ModuleManifestPath

)
# Export public functions in the module
$publicFunctions = $PublicFunctionFiles.BaseName
$PublicFunctionsJoined = $publicFunctions -join "','"

Write-Verbose "`t[string]`$ModuleContent = Get-Content -LiteralPath '$ModuleFilePath' -Raw"
$ModuleContent = Get-Content -Path $ModuleFilePath -Raw
$NewFunctionExportStatement = "Export-ModuleMember -Function @('$PublicFunctionsJoined')"

if ($ModuleContent -match 'Export-ModuleMember -Function') {

    Write-Verbose "`t`$ModuleContent = `$ModuleContent -replace 'Export-ModuleMember -Function.*' , `"$NewFunctionExportStatement`""
    $ModuleContent = $ModuleContent -replace 'Export-ModuleMember -Function.*' , $NewFunctionExportStatement
    Write-Verbose "`tSet-Content -Path '$ModuleFilePath' -Value `$ModuleContent -Encoding UTF8BOM -NoNewline"
    Set-Content -Path $ModuleFilePath -Value $ModuleContent -Encoding UTF8BOM -NoNewline

} else {
    # Ensure the module content doesn't end with a newline before appending
    if (-not $ModuleContent.EndsWith("`r`n") -and -not $ModuleContent.EndsWith("`n")) {
        $ModuleContent += "`r`n"
    }
    $ModuleContent += $NewFunctionExportStatement
    Write-Verbose "`tSet-Content -Path '$ModuleFilePath' -Value `$ModuleContent -Encoding UTF8BOM -NoNewline"
    Set-Content -Path $ModuleFilePath -Value $ModuleContent -Encoding UTF8BOM -NoNewline
}

# Create a string representation of the public functions array
$publicFunctionsAsString = "@('" + ($publicFunctions -join "','") + "')"

# Export public functions in the manifest
Write-Verbose "`tUpdate-Metadata -Path '$ModuleManifestPath' -PropertyName FunctionsToExport -Value $publicFunctionsAsString"
Update-Metadata -Path $ModuleManifestPath -PropertyName FunctionsToExport -Value $publicFunctions
