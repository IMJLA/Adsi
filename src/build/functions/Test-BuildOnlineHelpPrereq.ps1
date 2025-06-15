function Test-BuildOnlineHelpPrereq {

    <#
    .SYNOPSIS
    Tests if online help prerequisites are met.

    .DESCRIPTION
    Checks if npm is installed and available, which is required for building the online help website.

    .EXAMPLE
    Test-BuildOnlineHelpPrereq -NewLine "`r`n"
    #>

    [CmdletBinding()]
    [OutputType([bool])]

    param(

        # Character sequence for line separation in output
        [string]$NewLine

    )

    Write-InfoColor "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-InfoColor "FindOnlineHelpPrerequisites$NewLine" -ForegroundColor Blue
    Write-Information "`t& npm --version"

    try {

        # Try to run inkscape with version flag to test availability
        $null = & npm --version 2>$null

    } catch {
        return $false
    }

    if ($LASTEXITCODE -eq 0) {
        Write-InfoColor "$NewLine`t# Online Help prerequisites met (npm is installed). Proceeding with Online Help tasks." -ForegroundColor Green
        return $true
    } else {
        Write-InfoColor "$NewLine`t# Online Help prerequisites met (npm is installed). Skipping Online Help tasks." -ForegroundColor Yellow
        return $false
    }

}
