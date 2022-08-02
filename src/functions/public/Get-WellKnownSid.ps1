function Get-WellKnownSid {
    <#
        .SYNOPSIS
        Use CIM to get well-known SIDs
        .DESCRIPTION
        Use WinRM to query the CIM namespace root/cimv2 for instances of the Win32_Account class
        .INPUTS
        [System.String]$CimServerName
        .OUTPUTS
        [Microsoft.Management.Infrastructure.CimInstance] for each instance of the Win32_Account class in the root/cimv2 namespace
        .EXAMPLE
        Get-WellKnownSid

        Get the well-known SIDs on the current computer
        .EXAMPLE
        Get-WellKnownSid -CimServerName 'server123'

        Get the well-known SIDs on the remote computer 'server123'
    #>
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param (
        [Parameter(ValueFromPipeline)]
        [string[]]$CimServerName
    )
    process {
        ForEach ($ThisServer in $CimServerName) {
            if ($ThisServer -eq (hostname) -or $ThisServer -eq 'localhost' -or $ThisServer -eq '127.0.0.1' -or [string]::IsNullOrEmpty($ThisServer)) {
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-WellKnownSid`tNew-CimSession"
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-WellKnownSid`tGet-CimInstance -ClassName Win32_Account"
                $CimSession = New-CimSession
            } else {
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-WellKnownSid`tNew-CimSession -ComputerName '$ThisServer'"
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-WellKnownSid`tGet-CimInstance -ClassName Win32_Account -ComputerName '$ThisServer'"
                $CimSession = New-CimSession -ComputerName $ThisServer
            }
            $Results = @{}
            Get-CimInstance -ClassName Win32_Account -CimSession $CimSession |
            ForEach-Object {
                $Results[$_.Name] = $_
            }
            $Results
            Remove-CimSession -CimSession $CimSession
        }
    }
}
