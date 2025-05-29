function Invoke-NpmCommand {
    # Custom npm wrapper function

    [CmdletBinding()]

    param(
        [Parameter(Mandatory)]
        [string]$Command,

        [string]$WorkingDirectory = (Get-Location).Path,

        [switch]$PassThru
    )

    $InformationPreference = 'Continue'
    $originalLocation = Get-Location
    Write-Information "`t`tSet-Location -Path '$WorkingDirectory'"
    Set-Location $WorkingDirectory
    Write-Information "`t`t& cmd /c `"npm $Command`" 2>&1"

    try {

        # Capture both stdout and stderr
        $output = & cmd /c "npm $Command" 2>&1

        # Process output
        foreach ($line in $output) {
            if ($line -is [System.Management.Automation.ErrorRecord]) {
                Write-InfoColor "`t`tERROR: $($line.Exception.Message)" -ForegroundColor Red
            } else {
                Write-Information "`t`t$line"
            }
        }

        # Check exit code
        if ($LASTEXITCODE -ne 0) {
            throw "npm command failed with exit code $LASTEXITCODE"
        }

        if ($PassThru) {
            return $output
        }
    } finally {
        Set-Location $originalLocation
    }
}
