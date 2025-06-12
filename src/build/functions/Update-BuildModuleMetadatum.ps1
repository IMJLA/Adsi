function Update-BuildModuleMetadatum {

    <#
    .SYNOPSIS
    Updates the module metadata with a new version number.

    .DESCRIPTION
    Updates the ModuleVersion property in the specified module manifest file.

    .EXAMPLE
    Update-BuildModuleMetadatum -ModuleManifestPath './MyModule.psd1' -NewVersion '1.2.3'
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        # Path to the module manifest (.psd1) file to update
        [Parameter(Mandatory)]
        [string]$ModuleManifestPath,

        # The new version number to set in the module manifest
        [Parameter(Mandatory)]
        [version]$NewVersion,

        # The help info URI for the module
        [Parameter(Mandatory)]
        [string]$HelpInfoUri
    )

    if ($PSCmdlet.ShouldProcess($ModuleManifestPath, "Update module version to $NewVersion")) {

        Write-Information "`tUpdate-PSModuleManifest -Path '$ModuleManifestPath' -ModuleVersion $NewVersion -HelpInfoUri '$HelpInfoUri'"
        Update-PSModuleManifest -Path $ModuleManifestPath -ModuleVersion $NewVersion -HelpInfoUri $HelpInfoUri -ErrorAction Stop
        Write-InfoColor "`t# Successfully updated the module manifest with the new version number." -ForegroundColor Green

    }

}
