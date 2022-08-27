function New-AdsiServerCimSession {
    param (

        # Name of the computer to start a CIM session on
        [string]$ComputerName,

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages
    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = 'Debug'
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    if ($ComputerName -eq $ThisHostName) {
        Write-LogMsg @LogParams -Text "`$CimSession = New-CimSession # for '$ComputerName'"
        New-CimSession
    } else {
        Write-LogMsg @LogParams -Text "`$CimSession = New-CimSession -ComputerName '$ComputerName' # for '$ComputerName'"
        New-CimSession -ComputerName $ComputerName
    }

}
