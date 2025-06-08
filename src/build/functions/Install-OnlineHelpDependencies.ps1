function Install-OnlineHelpDependencies {
    <#
    .SYNOPSIS
    Installs all npm dependencies for the Online Help website.

    .DESCRIPTION
    This function runs 'npm install' to install all dependencies for the Docusaurus-based online help website
    and verifies that the node_modules directory was created successfully.

    .EXAMPLE
    Install-OnlineHelpDependencies -WorkingDirectory 'C:\MyProject\docs\online\MyModule'
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The working directory where npm install should be performed
        [Parameter(Mandatory)]
        [string]$WorkingDirectory
    )

    if ($PSCmdlet.ShouldProcess($WorkingDirectory, 'Install all npm dependencies')) {
        Write-Verbose "`tInvoke-NpmCommand -Command 'install' -WorkingDirectory '$WorkingDirectory' -ErrorAction Stop"
        Invoke-NpmCommand -Command 'install' -WorkingDirectory $WorkingDirectory -ErrorAction Stop

        # Determine whether the node_modules directory was created (indicating successful install)
        $TestPath = [IO.Path]::Combine($WorkingDirectory, 'node_modules')
        if (Test-Path $TestPath) {
            Write-InfoColor "`t# Successfully installed dependencies for the Online Help website" -ForegroundColor Green
        } else {
            Write-Error 'Failed to install Online Help dependencies. The node_modules directory was not created.'
        }
    }
}
