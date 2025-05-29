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
    Write-Information "`t`t& cmd /c `"npm $Command`" 2>&1"

    try {

        # Capture both stdout and stderr
        $output = & cmd /c "npm $Command" 2>&1

    } finally {
        Set-Location $originalLocation
    }

    # Process output
    foreach ($line in $output) {

        if ($line -is [System.Management.Automation.ErrorRecord]) {

            switch -Wildcard ($line.Exception.Message) {
                'npm warn*' {
                    Write-InfoColor "`t`tWARNING: $_" -ForegroundColor Yellow
                    break
                }
                '*EACCES*' {
                    Write-InfoColor "`t`tERROR: Permission denied. Try running with elevated privileges." -ForegroundColor Red
                    break
                }
                '*ENOENT*' {
                    Write-InfoColor "`t`tERROR: Command not found. Ensure npm is installed and in your PATH." -ForegroundColor Red
                    break
                }
                '*EEXIST*' {
                    Write-InfoColor "`t`tERROR: File or directory already exists. Check your command." -ForegroundColor Red
                    break
                }
                '*ENOTEMPTY*' {
                    Write-InfoColor "`t`tERROR: Directory not empty. Cannot remove." -ForegroundColor Red
                    break
                }
                '*EISDIR*' {
                    Write-InfoColor "`t`tERROR: Expected a file but found a directory. Check your command." -ForegroundColor Red
                    break
                }
                '*ECONNREFUSED*' {
                    Write-InfoColor "`t`tERROR: Connection refused. Check your network connection." -ForegroundColor Red
                    break
                }
                '*EADDRINUSE*' {
                    Write-InfoColor "`t`tERROR: Address in use. Another process is using the port." -ForegroundColor Red
                    break
                }
                default {
                    Write-InfoColor "`t`tERROR: $_" -ForegroundColor Red
                }

            }

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
}
