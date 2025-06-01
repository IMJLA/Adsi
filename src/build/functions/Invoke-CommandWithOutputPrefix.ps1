function Invoke-CommandWithOutputPrefix {

    # Generic command wrapper that adds prefixes to output lines

    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Using Console.WriteLine to preserve ANSI color codes from command output')]
    param(

        # The command to execute
        [Parameter(Mandatory)]
        [string]$Command,

        # Arguments as an array of objects
        [object[]]$ArgumentArray = @(),

        # Parameters as a hashtable (parameter names and values)
        [hashtable]$Parameter = @{},

        # Working directory for the command
        [string]$WorkingDirectory = (Get-Location).Path,

        # Prefix to add to each output line
        [string]$OutputPrefix = "`t",

        # Environment variables to set for the command
        [hashtable]$EnvironmentVariables = @{},

        # Skip console output
        [switch]$NoConsoleOutput

    )

    # Set console to UTF-8 to handle unicode output properly
    $originalOutputEncoding = [Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

    # Get original location before changing directory
    $originalLocation = Get-Location

    # Execute the command and handle output using a PowerShell job
    Write-Verbose "$OutputPrefix`Start-Job -ScriptBlock {...} -ArgumentList '$Command', `$ArgumentArray, `$Parameter, '$WorkingDirectory', `$EnvironmentVariables"

    # These take place inside the job, but we don't want this debug output mixed up in the output stream
    Write-Verbose "`t$OutputPrefix`Set-Location '$WorkingDirectory'"

    if ($Parameter.Count -gt 0 -and $ArgumentArray.Count -gt 0) {
        Write-Verbose "`t$OutputPrefix`& $Command @Parameters @ArgumentArray"
    } elseif ($Parameter.Count -gt 0) {
        Write-Verbose "`t$OutputPrefix`& $Command @Parameters"
    } elseif ($ArgumentArray.Count -gt 0) {
        Write-Verbose "`t$OutputPrefix`& $Command @ArgumentArray"
    } else {
        Write-Verbose "`t$OutputPrefix`& $Command"
    }

    try {

        # Use Start-Job to run commands in isolation
        $job = Start-Job -ScriptBlock {
            param($Command, $ArgumentArray, $Parameter, $WorkingDirectory, $EnvironmentVariables, $OutputPrefix)

            # Apply environment variables
            foreach ($key in $EnvironmentVariables.Keys) {
                [Environment]::SetEnvironmentVariable($key, $EnvironmentVariables[$key])
            }

            Set-Location $WorkingDirectory

            try {

                # Execute the PowerShell command with parameters and arguments
                if ($Parameter.Count -gt 0 -and $ArgumentArray.Count -gt 0) {
                    $output = & $Command @Parameter @ArgumentArray 2>&1
                } elseif ($Parameter.Count -gt 0) {
                    $output = & $Command @Parameter 2>&1
                } elseif ($ArgumentArray.Count -gt 0) {
                    $output = & $Command @ArgumentArray 2>&1
                } else {
                    $output = & $Command 2>&1
                }

                # Output the results and exit code separately
                $output
                Write-Output "EXITCODE:$LASTEXITCODE"

            } catch {

                Write-Error $_.Exception.Message
                Write-Output 'EXITCODE:1'

            }
        } -ArgumentList $Command, $ArgumentArray, $Parameter, $WorkingDirectory, $EnvironmentVariables, $OutputPrefix

        # Wait for job to complete
        Wait-Job $job | Out-Null

        # Get job output - simplified for PowerShell commands
        $allJobOutput = Receive-Job -Job $job | Where-Object { $_ -notmatch 'System.Management.Automation.RemoteException' }

        # Clean up job
        Remove-Job -Job $job

        # Separate exit code from output
        $exitCodeLine = $allJobOutput | Where-Object { $_ -like 'EXITCODE:*' } | Select-Object -Last 1
        if ($exitCodeLine) {
            $global:LASTEXITCODE = [int]($exitCodeLine -replace 'EXITCODE:', '')
            $output = $allJobOutput | Where-Object { $_ -notlike 'EXITCODE:*' }
        } else {
            $global:LASTEXITCODE = 0
            $output = $allJobOutput
        }

        # Display the output with prefixes, preserving ANSI color codes
        $result = Write-ConsoleOutput -Output $output -Prefix "`t`t$OutputPrefix" -PassThru -NoConsoleOutput:$NoConsoleOutput

    } finally {

        # Restore original encoding
        if ($originalOutputEncoding) {
            [Console]::OutputEncoding = $originalOutputEncoding
        }

        # Restore original location
        Set-Location $originalLocation

    }

    # Check exit code
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code $LASTEXITCODE"
    }

    return $output

}
