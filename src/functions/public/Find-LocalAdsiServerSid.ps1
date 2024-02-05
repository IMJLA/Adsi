function Find-LocalAdsiServerSid {

    param (

        # Name of the computer to query via CIM
        [string]$ComputerName,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug'

    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    $CimParams = @{
        CimCache          = $CimCache
        ComputerName      = $ThisHostName
        DebugOutputStream = $DebugOutputStream
        LogMsgCache       = $LogMsgCache
        ThisFqdn          = $ThisFqdn
        ThisHostname      = $ThisHostname
        WhoAmI            = $WhoAmI
    }

    #Write-LogMsg @LogParams -Text "Get-Win32UserAccount -ComputerName '$ComputerName'"
    #$Win32UserAccounts = Get-Win32UserAccount -ComputerName $ComputerName -ThisFqdn $ThisFqdn @LoggingParams

    Write-LogMsg @LogParams -Text "Get-CachedCimInstance -Query `"SELECT SID FROM Win32_UserAccount WHERE LocalAccount = 'True'`""
    $Win32UserAccounts = Get-CachedCimInstance -Query "SELECT SID FROM Win32_UserAccount WHERE LocalAccount = 'True'" @CimParams

    if (-not $Win32UserAccounts) {
        return
    }
    [string]$LocalAccountSID = @($Win32UserAccounts.SID)[0]
    return $LocalAccountSID.Substring(0, $LocalAccountSID.LastIndexOf("-"))
}
