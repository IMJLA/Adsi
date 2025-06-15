function Write-ConsoleOutput {

    <#
    .SYNOPSIS
    Writes output to console with optional prefixes and formatting control.

    .DESCRIPTION
    This function handles console output with ANSI color support, line prefixing,
    and output limiting capabilities. It preserves original formatting while allowing
    customization of display options.

    .EXAMPLE
    Write-ConsoleOutput -Output $commandOutput -Prefix "`t`t"

    .EXAMPLE
    $result = Write-ConsoleOutput -Output $data -First 10 -PassThru
    #>

    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Using Console.WriteLine to preserve ANSI color codes from command output')]

    param(

        # The output content to display (array of strings or objects)
        $Output,

        # Optional prefix to add to each line of output

        [string]$Prefix = '',

        # Limit output to the first N items from the array

        [int]$First = 0,

        # Return the processed output for further pipeline processing

        [switch]$PassThru,

        # Skip console output and only return data when PassThru is specified

        [switch]$NoConsoleOutput

    )

    $WriteToConsole = -not $NoConsoleOutput
    if ($output) {
        $rawOutput = ($output -join "`n") -replace "`r`n", "`n" -replace "`r", "`n"
        $LineNumber = 0
        $linesToOutput = foreach ($line in $rawOutput -split "`n") {
            $LineNumber++
            if ($PSBoundParameters.ContainsKey('First') -and $LineNumber -gt $First) {
                if ($WriteToConsole) {
                    #Write a blank line at the end for better readability
                    [Console]::WriteLine()
                }
                return
            }
            if ($line.Trim()) {
                if ($WriteToConsole) {
                    [Console]::WriteLine("$Prefix$line")
                }
                $line
            } else {
                if ($WriteToConsole) {
                    [Console]::WriteLine('')
                }
                ''
            }
        }

        if ($PassThru) {
            return $linesToOutput
        }

    }

}
