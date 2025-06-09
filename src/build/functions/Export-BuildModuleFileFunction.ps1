function Export-BuildModuleFileFunction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleFilePath,

        [Parameter(Mandatory)]
        [string[]]$FunctionName
    )

    # Create a string representation of the public functions array
    $PublicFunctionsJoined = $FunctionName -join "', '"
    $strPublicFunctions = "@('$publicFunctionsJoined')"
    Write-Verbose "`t[string]`$ModuleContent = Get-Content -LiteralPath '$ModuleFilePath' -Raw"
    $ModuleContent = Get-Content -Path $ModuleFilePath -Raw
    $NewExportStmt = "Export-ModuleMember -Function $strPublicFunctions"

    if ($ModuleContent -match 'Export-ModuleMember -Function') {

        $OldExportStmt = 'Export-ModuleMember -Function .*'
        Write-Verbose "`t`$ModuleContent = `$ModuleContent -replace '$OldExportStmt' , `"$NewExportStmt`""
        $ModuleContent = $ModuleContent -replace 'Export-ModuleMember -Function.*' , $NewExportStmt
        Write-Information "`tSet-Content -Path '$ModuleFilePath' -Value `$UpdatedModuleContent -Encoding UTF8BOM -NoNewline"
        Set-Content -Path $ModuleFilePath -Value $ModuleContent -Encoding UTF8BOM -NoNewline -ErrorAction Stop

    } else {

        # Ensure the module content doesn't end with a newline before appending
        if (-not $ModuleContent.EndsWith("`r`n") -and -not $ModuleContent.EndsWith("`n")) {
            $ModuleContent += "`r`n"
        }

        $ModuleContent += $NewExportStmt
        Write-Information "`tSet-Content -Path '$ModuleFilePath' -Value `$UpdatedModuleContent -Encoding UTF8BOM -NoNewline"
        Set-Content -Path $ModuleFilePath -Value $ModuleContent -Encoding UTF8BOM -NoNewline -ErrorAction Stop

    }
}