function Remove-BuildModule {
    <#
    .SYNOPSIS
    Removes a PowerShell module from the current session.

    .DESCRIPTION
    This function removes a specified PowerShell module from the current PowerShell session.
    It is typically used during the build process after help generation is complete.

    .EXAMPLE
    Remove-BuildModule -ModuleName 'MyModule'
    Removes the 'MyModule' from the current PowerShell session.

    .EXAMPLE
    Remove-BuildModule -ModuleName 'MyModule' -WhatIf
    Shows what would happen if the module were removed without actually removing it.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of the module to remove from the current PowerShell session
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    if ($PSCmdlet.ShouldProcess($ModuleName, 'Remove module from current PowerShell session')) {
        Write-Information "`tRemove-Module -Name '$ModuleName' -Force"
        Remove-Module -Name $ModuleName -Force -ErrorAction Stop
        Write-InfoColor "`t# Successfully removed the module." -ForegroundColor Green
    }
}