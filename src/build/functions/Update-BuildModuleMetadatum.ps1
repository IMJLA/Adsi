function Update-BuildModuleMetadatum {
    <#
    .SYNOPSIS
    Updates the module metadata with a new version number.

    .DESCRIPTION
    Updates the ModuleVersion property in the specified module manifest file.

    .PARAMETER ModuleManifestPath
    Path to the module manifest (.psd1) file to update.

    .PARAMETER NewVersion
    The new version number to set in the module manifest.

    .EXAMPLE
    Update-BuildModuleMetadatum -ModuleManifestPath './MyModule.psd1' -NewVersion '1.2.3'
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleManifestPath,

        [Parameter(Mandatory)]
        [version]$NewVersion,

        [Parameter(Mandatory)]
        [string]$HelpInfoUri
    )

    if ($PSCmdlet.ShouldProcess($ModuleManifestPath, "Update module version to $NewVersion")) {

        Write-Information "`tUpdate-PSModuleManifest -Path '$ModuleManifestPath' -ModuleVersion $NewVersion -HelpInfoUri '$HelpInfoUri'"
        Update-PSModuleManifest -Path $ModuleManifestPath -ModuleVersion $NewVersion -HelpInfoUri $HelpInfoUri -ErrorAction Stop
        Write-InfoColor "`t# Successfully updated the module manifest with the new version number." -ForegroundColor Green

    }

}
