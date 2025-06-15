function Find-PublicFunction {

    <#
    .SYNOPSIS
    Finds all public function files in the specified directory.

    .DESCRIPTION
    Searches for PowerShell function files in the public functions directory and returns
    information about each file found.

    .EXAMPLE
    Find-PublicFunction -PublicFunctionPath './src/functions/public'
    #>

    [CmdletBinding()]

    param(

        # Path to the directory containing public function files
        [string]$PublicFunctionPath
    )

    Write-Verbose "`tGet-ChildItem -Path '$PublicFunctionPath'"
    $PublicFunctionFiles = Get-ChildItem -Path $PublicFunctionPath -ErrorAction SilentlyContinue
    Write-InfoColor "`t# Found $($PublicFunctionFiles.Count) public function files." -ForegroundColor Green
    return $PublicFunctionFiles

}
