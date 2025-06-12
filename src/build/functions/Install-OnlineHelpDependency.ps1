function Install-OnlineHelpDependency {

    <#
    .SYNOPSIS
    Installs all npm dependencies for the Online Help website.

    .DESCRIPTION
    This function runs 'npm install' to install all dependencies for the Docusaurus-based online help website
    and verifies that the node_modules directory was created successfully.

    .EXAMPLE
    Install-OnlineHelpDependency -WorkingDirectory 'C:\MyProject\docs\online\MyModule'
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(
        # The working directory where npm dependencies should be installed
        [Parameter(Mandatory)]
        [string]$WorkingDirectory,

        # Array of npm packages to install (in addition to what is already in package.json)
        [string[]]$Dependency = @('@docusaurus/theme-mermaid', '@docusaurus/tsconfig')
    )

    if ($PSCmdlet.ShouldProcess($WorkingDirectory, "Install all npm dependencies, plus: $($Dependency -join ', ')")) {

        $installCommand = "install $($Dependency -join ' ')"
        Write-Verbose "`tInvoke-NpmCommand -Command '$installCommand' -WorkingDirectory '$WorkingDirectory'"
        Invoke-NpmCommand -Command $installCommand -WorkingDirectory $WorkingDirectory -ErrorAction Stop

        # Determine whether the node_modules directory was created (indicating successful install)
        $TestPath = [IO.Path]::Combine($WorkingDirectory, 'node_modules')

        if (Test-Path $TestPath) {
            Write-InfoColor "`t# Successfully added dependencies to the Online Help website: $($Dependency -join ', ')" -ForegroundColor Green
        } else {
            Write-Error 'Failed to install Online Help dependencies. The node_modules directory was not created.'
        }

    }

}
