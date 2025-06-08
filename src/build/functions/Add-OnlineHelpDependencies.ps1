function Add-OnlineHelpDependencies {
    <#
    .SYNOPSIS
    Adds npm dependencies to the Online Help website.

    .DESCRIPTION
    This function installs the required npm dependencies for the Docusaurus-based online help website
    in a single npm install command for improved efficiency.

    .EXAMPLE
    Add-OnlineHelpDependencies -WorkingDirectory 'C:\MyProject\docs\online\MyModule' -Dependency '@docusaurus/theme-mermaid', '@docusaurus/tsconfig'
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(
        # The working directory where npm dependencies should be installed
        [Parameter(Mandatory)]
        [string]$WorkingDirectory,

        # Array of npm packages to install (in addition to what is already in package.json)
        [string[]]$Dependency = @('@docusaurus/theme-mermaid', '@docusaurus/tsconfig')
    )

    if ($PSCmdlet.ShouldProcess($WorkingDirectory, "Install npm dependencies: $($Dependency -join ', ')")) {

        $installCommand = "install $($Dependency -join ' ')"
        Write-Verbose "`tInvoke-NpmCommand -Command '$installCommand' -WorkingDirectory '$WorkingDirectory' -ErrorAction Stop"
        Invoke-NpmCommand -Command $installCommand -WorkingDirectory $WorkingDirectory -ErrorAction Stop
        Write-InfoColor "`t# Successfully added dependencies to the Online Help website: $($Dependency -join ', ')" -ForegroundColor Green

    }

}
