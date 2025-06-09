function Test-BuildManifest {
    <#
    .SYNOPSIS
        Validates a PowerShell module manifest file.

    .DESCRIPTION
        Tests the specified module manifest file for validity and returns the manifest object if successful.

    .PARAMETER Path
        Path to the module manifest (.psd1) file to validate.

    .EXAMPLE
        Test-BuildManifest -Path 'C:\Module\MyModule.psd1'

        Validates the MyModule.psd1 manifest file.

    .OUTPUTS
        System.Management.Automation.PSModuleInfo
        Returns the validated module manifest object.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    Write-Information "`tTest-ModuleManifest -Path '$Path'"
    $ManifestTest = Test-ModuleManifest -Path $Path -ErrorAction Stop
    Write-InfoColor "`t# Successfully validated the module manifest." -ForegroundColor Green

    return $ManifestTest
}