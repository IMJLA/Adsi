function Export-BuildModuleManifestFunction {

    <#
    .SYNOPSIS
    Updates the module manifest to export specific functions.

    .DESCRIPTION
    Modifies the FunctionsToExport section of a PowerShell module manifest file to include
    the specified function names.

    .EXAMPLE
    Export-BuildModuleManifestFunction -ModuleManifestPath './MyModule.psd1' -FunctionName @('Get-Something', 'Set-Something')
    #>

    [CmdletBinding()]

    param(

        # Path to the module manifest file to update
        [Parameter(Mandatory)]
        [string]$ModuleManifestPath,

        # Array of function names to export in the manifest
        [Parameter(Mandatory)]
        [string[]]$FunctionName
    )

    Write-Verbose "`t[string]`$ManifestContent = Get-Content -LiteralPath '$ModuleManifestPath' -Raw"
    $ManifestContent = Get-Content -Path $ModuleManifestPath -Raw
    $UpdatedContent = $ManifestContent -replace '(FunctionsToExport\s*=\s*)@\([^)]*\)', "`$1@('$($FunctionName -join "', '")')"
    Write-Information "`tSet-Content -Path '$ModuleManifestPath' -Value `$UpdatedManifestContent -Encoding UTF8BOM -NoNewLine"
    Set-Content -Path $ModuleManifestPath -Value $UpdatedContent -Encoding UTF8BOM -NoNewLine -ErrorAction Stop

}
