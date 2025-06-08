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
        [version]$NewVersion
    )

    if ($PSCmdlet.ShouldProcess($ModuleManifestPath, "Update module version to $NewVersion")) {

        Write-Information "`tUpdate-Metadata -Path '$ModuleManifestPath' -PropertyName ModuleVersion -Value $NewVersion -ErrorAction Stop"
        Update-Metadata -Path $ModuleManifestPath -PropertyName ModuleVersion -Value $NewVersion -ErrorAction Stop
        Write-InfoColor "`t# Successfully updated the module manifest with the new version number." -ForegroundColor Green

    }

}
