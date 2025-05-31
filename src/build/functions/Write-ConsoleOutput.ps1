Function Write-ConsoleOutput {
    param (
        [string[]]$Output,
        [string]$Prefix,
        [int]$First
    )
    if ($output) {
        $rawOutput = ($output -join "`n") -replace "`r`n", "`n" -replace "`r", "`n"
        $LineNumber = 0
        foreach ($line in $rawOutput -split "`n") {
            $LineNumber++
            if ($PSBoundParameters.ContainsKey('First') -and $LineNumber -gt $First) {
                return
            }
            if ($line.Trim()) {
                [Console]::WriteLine("$Prefix$line")
            } else {
                [Console]::WriteLine('')
            }
        }
    }
}
