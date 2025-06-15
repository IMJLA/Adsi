function Test-Inkscape {

    <#
    .SYNOPSIS
    Test if the Inkscape command is available on the system.

    .DESCRIPTION
    This function checks if the Inkscape command-line tool is available by attempting to run it.
    Returns true if Inkscape is found and accessible, false otherwise.

    .EXAMPLE
    Test-Inkscape

    .OUTPUTS
    [bool] True if Inkscape is available, false otherwise.
    #>

    [CmdletBinding()]
    [OutputType([bool])]

    param(

        [string]$NewLine = "`n"

    )

    Write-InfoColor "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-InfoColor "TestArtConverter$NewLine" -ForegroundColor Blue
    Write-Information "`t& inkscape --version"

    try {

        # Try to run inkscape with version flag to test availability
        $null = & inkscape --version 2>$null

    } catch {
        return $false
    }

    if ($LASTEXITCODE -eq 0) {
        Write-InfoColor "$NewLine`t# Prerequisites met for static art conversion from SVG to PNG (inkscape is installed). Proceeding with ConvertArt task." -ForegroundColor Green
        return $true
    } else {
        Write-InfoColor "$NewLine`t# Prerequisites missing for static art conversion from SVG to PNG (inkscape is missing). Skipping ConvertArt task." -ForegroundColor Yellow
        return $false
    }

}
