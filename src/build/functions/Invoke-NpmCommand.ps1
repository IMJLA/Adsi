function Invoke-NpmCommand {

    # Custom npm wrapper function

    [CmdletBinding()]

    param(
        # The npm command to execute
        [Parameter(Mandatory)]
        [string]$Command,

        [string]$WorkingDirectory = (Get-Location).Path,

        [switch]$PassThru

    )

    $InformationPreference = 'Continue'
    $originalLocation = Get-Location
    Write-Information "`t`tSet-Location -Path '$WorkingDirectory'"
    Set-Location $WorkingDirectory
    Write-Information "`t`t& cmd /c `"npm $Command`""

    try {
        if ($PassThru) {
            # Capture output for return value while also displaying with tabs
            $output = & cmd /c "npm $Command" 2>&1
            foreach ($line in $output) {
                [Console]::Write("`t`t")
                [Console]::WriteLine($line)
            }
        } else {
            # Direct output with tab prefixing, preserving colors
            & cmd /c "npm $Command" 2>&1 | ForEach-Object {
                [Console]::Write("`t`t")
                [Console]::WriteLine($_)
            }
        }

    } finally {
        Set-Location $originalLocation
    }

    # Check exit code
    if ($LASTEXITCODE -ne 0) {
        throw "npm command failed with exit code $LASTEXITCODE"
    }

    if ($PassThru) {
        return $output
    }
}
