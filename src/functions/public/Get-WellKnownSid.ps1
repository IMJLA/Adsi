function Get-WellKnownSid {
    param (
        [Parameter(ValueFromPipeline)]
        [string[]]$AdsiServer
    )
    process {
        ForEach ($ThisServer in $AdsiServer) {
            if ($ThisServer -eq (hostname) -or $ThisServer -eq 'localhost' -or $ThisServer -eq '127.0.0.1') {
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tResolve-IdentityReference`tNew-CimSession"
                $CimSession = New-CimSession
            } else {
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tResolve-IdentityReference`tNew-CimSession -ComputerName '$ThisServer'"
                $CimSession = New-CimSession -ComputerName $ThisServer
            }
            Get-CimInstance -ClassName Win32_SystemAccount -CimSession $CimSession
            Remove-CimSession -CimSession $CimSession
        }
    }
}
