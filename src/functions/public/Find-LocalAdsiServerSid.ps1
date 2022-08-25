function Find-LocalAdsiServerSid {
    param (
        [string]$ComputerName,
        [string]$ThisHostname = (HOSTNAME.EXE),
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName)
    )
    Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tFind-LocalAdsiServerSid`tGet-Win32UserAccount -ComputerName '$ComputerName'"
    $Win32UserAccounts = Get-Win32UserAccount -ComputerName $ComputerName -ThisHostname $ThisHostname -ThisFqdn $ThisFqdn
    if (-not $Win32UserAccounts) {
        return
    }
    [string]$LocalAccountSID = @($Win32UserAccounts.SID)[0]
    return $LocalAccountSID.Substring(0, $LocalAccountSID.LastIndexOf("-"))
}
