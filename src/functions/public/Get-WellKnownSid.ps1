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
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param (
        [Parameter(ValueFromPipeline)]
        [string[]]$CimServerName
    )
    process {
        ForEach ($ThisServer in $CimServerName) {
            if ($ThisServer -eq (hostname) -or $ThisServer -eq 'localhost' -or $ThisServer -eq '127.0.0.1' -or [string]::IsNullOrEmpty($ThisServer)) {
                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-WellKnownSid`t`$CimSession = New-CimSession"
                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-WellKnownSid`tGet-CimInstance -ClassName Win32_Account -CimSession `$CimSession"
                $CimSession = New-CimSession
                $ThisServer = hostname
            } else {
                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-WellKnownSid`t`$CimSession = New-CimSession -ComputerName '$ThisServer'"
                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-WellKnownSid`tGet-CimInstance -ClassName Win32_Account -CimSession `$CimSession"
                $CimSession = New-CimSession -ComputerName $ThisServer
            }

            Get-CimInstance -ClassName Win32_Account -CimSession $CimSession

            Remove-CimSession -CimSession $CimSession
        }
    }
}
