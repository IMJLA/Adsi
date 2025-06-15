function Export-PublicFunction {

    <#
    .SYNOPSIS
    Exports public functions from a PowerShell module.

    .DESCRIPTION
    This function extracts function names from public function files and updates both the module file
    and module manifest to properly export those functions for use by consumers of the module.

    .EXAMPLE
    Export-PublicFunction -PublicFunctionFile $files -ModuleFilePath './MyModule.psm1' -ModuleManifestPath './MyModule.psd1'
    #>

    [CmdletBinding()]

    param(

        # Path to the public function files (.ps1)
        [Parameter(Mandatory)]
        [System.IO.FileInfo[]]$PublicFunctionFile,

        # Path to the module file (.psm1)

        [string]$ModuleFilePath,

        # Path to the module manifest file (.psd1)

        [Parameter(Mandatory)]
        [string]$ModuleManifestPath

    )

    # Extract function names from files
    $FunctionNames = $PublicFunctionFile | ForEach-Object {
        $Content = Get-Content -Path $_.FullName -Raw
        if ($Content -match 'function\s+([A-Za-z0-9-_]+)') {
            $Matches[1]
        }
    }

    # Update module manifest with exported functions
    if ($FunctionNames) {

        Export-BuildModuleFileFunction -ModuleFilePath $ModuleFilePath -FunctionName $FunctionNames -ErrorAction Stop -InformationAction Continue
        Export-BuildModuleManifestFunction -ModuleManifestPath $ModuleManifestPath -FunctionName $FunctionNames -ErrorAction Stop -InformationAction Continue
        Write-InfoColor "`t# Successfully exported $($FunctionNames.Count) public functions in the module file and module manifest." -ForegroundColor Green

    } else {
        Write-InfoColor "`t# No public functions found to export." -ForegroundColor Yellow
    }

}
