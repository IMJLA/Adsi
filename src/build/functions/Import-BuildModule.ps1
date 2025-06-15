function Import-BuildModule {

    <#
    .SYNOPSIS
    Import a PowerShell module for build operations.

    .DESCRIPTION
    Imports a PowerShell module by name and validates that it loaded successfully.
    Provides error handling for multiple versions and import failures.

    .EXAMPLE
    Import-BuildModule -ModuleName 'MyModule'

    .EXAMPLE
    Import-BuildModule -ModuleName 'MyModule' -WhatIf
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(

        # Name of the module to import
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    if ($PSCmdlet.ShouldProcess($ModuleName, 'Import Module')) {
        Write-Information "`tImport-Module -Name '$ModuleName' -Force"
        Import-Module -Name $ModuleName -Force -ErrorAction Stop

        Write-Information "`tGet-Module -Name '$ModuleName'"
        $Result = Get-Module -Name $ModuleName -ErrorAction Stop

        if ($Result) {
            if ($Result.Count -gt 1) {
                Write-Error "`t# Multiple versions of the module '$ModuleName' are loaded: $($Result.Version -join ' & ')."
            } else {
                Write-InfoColor "`t# Successfully imported the '$($Result.Name)' module (version $($Result.Version))" -ForegroundColor Green
            }
        } else {
            Write-Error "Failed to import the module '$ModuleName'."
        }
    }
}
