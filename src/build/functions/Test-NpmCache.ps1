function Test-NpmCache {

    <#
    .SYNOPSIS
    Verifies the npm cache to ensure clean dependency installation.

    .DESCRIPTION
    This function verifies the npm cache which can help resolve issues with npm dependencies.
    It uses the 'npm cache verify' command to check the integrity of the cache.

    .EXAMPLE
    Test-NpmCache -WorkingDirectory 'C:\MyProject\docs'
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(
        # The working directory where npm cache verification should be performed
        [Parameter(Mandatory)]
        [string]$WorkingDirectory
    )

    if ($PSCmdlet.ShouldProcess($WorkingDirectory, 'Verify npm cache')) {
        Write-Verbose "`tInvoke-NpmCommand -Command 'cache verify' -WorkingDirectory '$WorkingDirectory'"
        Invoke-NpmCommand -Command 'cache verify' -WorkingDirectory $WorkingDirectory -ErrorAction Stop
        Write-InfoColor "`t# Successfully verified npm cache." -ForegroundColor Green
    }
}
