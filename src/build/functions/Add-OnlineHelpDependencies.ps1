function Add-OnlineHelpDependencies {
    <#
    .SYNOPSIS
    Adds Mermaid theme and TypeScript configuration dependencies to the Online Help website.

    .DESCRIPTION
    This function installs the required npm dependencies for the Docusaurus-based online help website,
    specifically the Mermaid theme and TypeScript configuration packages.

    .EXAMPLE
    Add-OnlineHelpDependencies -WorkingDirectory 'C:\MyProject\docs\online\MyModule'
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The working directory where npm dependencies should be installed
        [Parameter(Mandatory)]
        [string]$WorkingDirectory
    )

    if ($PSCmdlet.ShouldProcess($WorkingDirectory, 'Install npm dependencies')) {
        Write-Verbose "`tInvoke-NpmCommand -Command 'install @docusaurus/theme-mermaid' -WorkingDirectory '$WorkingDirectory' -ErrorAction Stop"
        Invoke-NpmCommand -Command 'install @docusaurus/theme-mermaid' -WorkingDirectory $WorkingDirectory -ErrorAction Stop

        Write-Verbose "`tInvoke-NpmCommand -Command 'install @docusaurus/tsconfig' -WorkingDirectory '$WorkingDirectory' -ErrorAction Stop"
        Invoke-NpmCommand -Command 'install @docusaurus/tsconfig' -WorkingDirectory $WorkingDirectory -ErrorAction Stop

        Write-InfoColor "`t# Successfully added Mermaid theme and tsconfig dependencies to the Online Help website" -ForegroundColor Green
    }
}
