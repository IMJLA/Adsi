function Set-BuildLocation {
    <#
    .SYNOPSIS
    Set the working directory to the project root to ensure all relative paths are correct.

    .DESCRIPTION
    This function navigates from the build script location to the project root directory
    and validates that the current directory matches the expected module name.

    .PARAMETER BuildScriptRoot
    The root path of the PowerShell script (typically $BuildScriptRoot from the calling script).

    .PARAMETER ModuleName
    The name of the module/project to validate against the current directory.

    .EXAMPLE
    Set-BuildLocation -BuildScriptRoot $BuildScriptRoot -ModuleName 'MyModule'
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(

        [Parameter(Mandatory)]
        [string]$BuildScriptRoot,

        [Parameter(Mandatory)]
        [string]$ModuleName

    )

    if ($PSCmdlet.ShouldProcess('Working Directory', 'Set location to project root')) {

        Write-InfoColor "`tSet-Location -Path '$BuildScriptRoot'"
        Set-Location -Path $BuildScriptRoot
        [string]$ProjectRoot = [IO.Path]::Combine('..', '..')
        Set-Location -Path $ProjectRoot

        if (((Get-Location -PSProvider FileSystem -ErrorAction Stop).Path | Split-Path -Leaf) -eq $ModuleName) {
            Write-InfoColor "`t# Current Working Directory is now '$ModuleName'" -ForegroundColor Green
        } else {
            Write-Error "Failed to set Working Directory to '$ModuleName'."
        }

    }

}
