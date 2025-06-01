Function Write-ConsoleOutput {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Console output is the primary purpose of this function, and Console.WriteLine preserves ANSI color codes')]
    param (
        [string[]]$Output,
        [string]$Prefix,
        [int]$First,
        [switch]$PassThru,
        [switch]$NoConsoleOutput
    )
    $WriteToConsole = -not $NoConsoleOutput
    if ($output) {
        $rawOutput = ($output -join "`n") -replace "`r`n", "`n" -replace "`r", "`n"
        $LineNumber = 0
        $linesToOutput = foreach ($line in $rawOutput -split "`n") {
            $LineNumber++
            if ($PSBoundParameters.ContainsKey('First') -and $LineNumber -gt $First) {
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
        if ($WriteToConsole) {
            #Write a blank line at the end for better readability
            [Console]::WriteLine()
        }
        if ($PassThru) {
            return $linesToOutput
        }
    }

}
