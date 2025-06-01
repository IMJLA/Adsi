function Invoke-CommandWithOutputPrefix {

    # Generic command wrapper that adds prefixes to output lines

    [CmdletBinding(DefaultParameterSetName = 'ArgumentString')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Using Console.WriteLine to preserve ANSI color codes from command output')]
    param(

        # The command to execute
        [Parameter(Mandatory)]
        [string]$Command,

        # Arguments as an array of strings
        [Parameter(ParameterSetName = 'ArgumentArray')]
        [string[]]$ArgumentArray = @(),

        # Arguments as a single string
        [Parameter(ParameterSetName = 'ArgumentString')]
        [string]$ArgumentString = '',

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

    # Determine which parameter set was used and prepare both formats
    if ($PSCmdlet.ParameterSetName -eq 'ArgumentArray') {
        $FinalArgumentArray = $ArgumentArray
        $FinalArgumentString = $ArgumentArray -join ' '
    } else {
        $FinalArgumentString = $ArgumentString
        $FinalArgumentArray = if ($ArgumentString) { $ArgumentString.Split(' ') } else { @() }
    }

    # Get original location before changing directory
    $originalLocation = Get-Location

    # Eecute the command and handle output using a PowerShell job
    Write-Verbose "$OutputPrefix`Start-Job -ScriptBlock {...} -ArgumentList '$Command', @('$($FinalArgumentArray -join "','")'), '$WorkingDirectory', `$EnvironmentVariables"

    # These take place inside the job, but we don't want this debug output mixed up in the output stream
    Write-Verbose "`t$OutputPrefix`Set-Location '$WorkingDirectory'"
    Write-Verbose "`t$OutputPrefix`& $Command $FinalArgumentString"

    try {

        # Use Start-Job to run npm commands in isolation
        $job = Start-Job -ScriptBlock {
            param($Command, $ArgumentsArray, $WorkingDirectory, $EnvironmentVariables, $OutputPrefix)

            # Apply environment variables
            foreach ($key in $EnvironmentVariables.Keys) {
                [Environment]::SetEnvironmentVariable($key, $EnvironmentVariables[$key])
            }

            Set-Location $WorkingDirectory

            try {

                # Execute the command
                if ($ArgumentsArray.Count -gt 0) {
                    $output = & $Command $ArgumentsArray 2>&1
                } else {
                    $output = & $Command 2>&1
                }

                # Give a moment for all output to be captured
                Start-Sleep -Milliseconds 500

                # Output the results and exit code separately
                $output
                Write-Output "EXITCODE:$LASTEXITCODE"

            } catch {

                Write-Error $_.Exception.Message
                Write-Output 'EXITCODE:1'

            }
        } -ArgumentList $Command, $FinalArgumentArray, $WorkingDirectory, $EnvironmentVariables, $OutputPrefix

        # Wait for job to complete
        Wait-Job $job | Out-Null

        # Give additional time for job output to be fully available
        Start-Sleep -Milliseconds 250

        # Get output in two separate reads and combine them.  For some reason without this, the output is sometimes incomplete (missing its last line).
        # This is especially important for npm commands which can produce a lot of output.
        $keepOutput = Receive-Job -Job $job -Keep | Where-Object { $_ -notmatch 'System.Management.Automation.RemoteException' }
        $finalOutput = Receive-Job -Job $job | Where-Object { $_ -notmatch 'System.Management.Automation.RemoteException' }

        # Clean up job
        Remove-Job -Job $job

        # Determine which output to use based on comparison
        if ($finalOutput -and $keepOutput) {
            # Both outputs have content, combine them
            $allJobOutput = $keepOutput + $finalOutput
        } elseif ($finalOutput) {
            # Only final output has content
            $allJobOutput = $finalOutput
        } elseif ($keepOutput) {
            # Only keep output has content
            $allJobOutput = $keepOutput
        } else {
            # No output from either
            $allJobOutput = @()
        }

        # Separate exit code from output
        $exitCodeLine = $allJobOutput | Where-Object { $_ -like 'EXITCODE:*' } | Select-Object -Last 1
        if ($exitCodeLine) {
            $global:LASTEXITCODE = [int]($exitCodeLine -replace 'EXITCODE:', '')
            $ExcessiveOutput = ($allJobOutput | Where-Object { $_ -notlike 'EXITCODE:*' })
        } else {
            $global:LASTEXITCODE = 0
            $ExcessiveOutput = $allJobOutput
        }

        # Display the output with prefixes, preserving line breaks. Exclude the redundant second half of the output.
        $output = Write-ConsoleOutput -Output $ExcessiveOutput -Prefix "`t`t$OutputPrefix" -First ($ExcessiveOutput.Count / 2) -PassThru -NoConsoleOutput:$NoConsoleOutput

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
