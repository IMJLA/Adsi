function Get-Win32UserAccount {
    param (
        [string]$ComputerName,
        [string]$ThisHostname = (HOSTNAME.EXE),
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName(($ThisHostName)).HostName)
    )
    if (
        $ComputerName -eq $ThisHostname -or
        $ComputerName -eq "$ThisHostname." -or
        $ComputerName -eq $ThisFqdn
    ) {
        Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-Win32UserAccount`tGet-CimInstance -Query `"SELECT SID FROM Win32_UserAccount WHERE LocalAccount = 'True'`""
        Get-CimInstance -Query "SELECT SID FROM Win32_UserAccount WHERE LocalAccount = 'True'"
    } else {
        Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-Win32UserAccount`tGet-CimInstance -ComputerName $ComputerName -Query `"SELECT SID FROM Win32_UserAccount WHERE LocalAccount = 'True'`""
        # If an Active Directory domain is targeted there are no local accounts and CIM connectivity is not expected
        # Suppress errors and return nothing in that case
        Get-CimInstance -ComputerName $ComputerName -Query "SELECT SID FROM Win32_UserAccount WHERE LocalAccount = 'True'" -ErrorAction SilentlyContinue
    }
}
