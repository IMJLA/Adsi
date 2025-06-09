function Update-OnlineHelpWebsite {
    <#
    .SYNOPSIS
    Builds the online help website using Docusaurus.

    .DESCRIPTION
    This function uses npm to build the Docusaurus-based online help website and verifies
    that the build was successful by checking for the build directory.

    .EXAMPLE
    Update-OnlineHelpWebsite -DocsOnlineHelpDir 'C:\MyProject\docs\online\MyModule'
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The working directory containing the Docusaurus project
        [Parameter(Mandatory)]
        [string]$DocsOnlineHelpDir
    )

    if ($PSCmdlet.ShouldProcess($DocsOnlineHelpDir, 'Build online help website')) {
        Write-Verbose "`tInvoke-NpmCommand -Command 'run build' -WorkingDirectory '$DocsOnlineHelpDir'"

        Invoke-NpmCommand -Command 'run build' -WorkingDirectory $DocsOnlineHelpDir -ErrorAction Stop

        # Determine whether the build directory was created (indicating successful build)
        $TestPath = [IO.Path]::Combine($DocsOnlineHelpDir, 'build')
        if (Test-Path $TestPath) {
            Write-InfoColor "`t# Successfully built online help website." -ForegroundColor Green
        } else {
            Write-Error 'Failed to build online help website'
        }
    }
}