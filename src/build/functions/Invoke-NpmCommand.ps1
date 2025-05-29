function Invoke-NpmCommand {

    # Custom npm wrapper function

    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Using Console.WriteLine to preserve ANSI color codes from npm output')]
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
        # Set console to UTF-8 to handle npm's unicode output properly
        $originalOutputEncoding = [Console]::OutputEncoding
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

        if ($PassThru) {
            # For PassThru, we need to capture the raw output
            $output = & cmd /c "chcp 65001 >nul && npm $Command" 2>&1

            # Display the output with tab prefixes, preserving line breaks
            $rawOutput = ($output -join "`n") -replace "`r`n", "`n" -replace "`r", "`n"
            foreach ($line in $rawOutput -split "`n") {
                if ($line.Trim()) {
                    [Console]::WriteLine("`t`t$line")
                } else {
                    [Console]::WriteLine('')
                }
            }
        } else {
            # For direct output, use Start-Process to preserve formatting better
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = 'cmd'
            $psi.Arguments = "/c chcp 65001 >nul && npm $Command"
            $psi.UseShellExecute = $false
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true
            $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
            $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
            $psi.WorkingDirectory = [System.IO.Path]::GetFullPath($WorkingDirectory, $originalLocation.Path)

            # Force npm to output colors even when redirected
            $psi.EnvironmentVariables['FORCE_COLOR'] = '1'
            $psi.EnvironmentVariables['NPM_CONFIG_COLOR'] = 'always'
            $psi.EnvironmentVariables['TERM'] = 'xterm-256color'

            # Set a large console width for better formatting
            # Maximum practical width is usually around 1000-2000 characters
            $psi.EnvironmentVariables['COLUMNS'] = '200'
            $psi.EnvironmentVariables['LINES'] = '50'

            $process = [System.Diagnostics.Process]::Start($psi)

            # Read all output first, then add tabs to each line
            $allOutput = ''
            while (-not $process.HasExited -or $process.StandardOutput.Peek() -ge 0 -or $process.StandardError.Peek() -ge 0) {
                # Process stdout
                while ($process.StandardOutput.Peek() -ge 0) {
                    $char = $process.StandardOutput.Read()
                    if ($char -ge 0) {
                        $allOutput += [char]$char
                    }
                }

                # Process stderr
                while ($process.StandardError.Peek() -ge 0) {
                    $char = $process.StandardError.Read()
                    if ($char -ge 0) {
                        $allOutput += [char]$char
                    }
                }

                # Small delay to prevent excessive CPU usage
                Start-Sleep -Milliseconds 10
            }

            $process.WaitForExit()

            # Split into lines and add tab prefixes
            $lines = $allOutput -split "`r`n|`n"
            foreach ($line in $lines) {
                if ($line.Trim()) {
                    [Console]::WriteLine("`t`t$line")
                } else {
                    [Console]::WriteLine('')
                }
            }
        }

    } finally {
        # Restore original encoding
        if ($originalOutputEncoding) {
            [Console]::OutputEncoding = $originalOutputEncoding
        }
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
