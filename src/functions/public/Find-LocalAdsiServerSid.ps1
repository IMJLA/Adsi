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

        # Log messages which have not yet been written to disk
        [hashtable]$LogBuffer = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug'

    )

    $Log = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        Buffer       = $LogBuffer
        WhoAmI       = $WhoAmI
    }

    $CimParams = @{
        CimCache          = $CimCache
        ComputerName      = $ThisHostName
        DebugOutputStream = $DebugOutputStream
        LogBuffer         = $LogBuffer
        ThisFqdn          = $ThisFqdn
        ThisHostname      = $ThisHostname
        WhoAmI            = $WhoAmI
        Query             = "SELECT SID FROM Win32_UserAccount WHERE LocalAccount = 'True' AND SID LIKE 'S-1-5-21-%-500'"
        KeyProperty       = 'SID'
    }

    Write-LogMsg @Log -Text 'Get-CachedCimInstance' -Expand $CimParams
    $LocalAdminAccount = Get-CachedCimInstance @CimParams

    if (-not $LocalAdminAccount) {
        return
    }

    return $LocalAdminAccount.SID.Substring(0, $LocalAdminAccount.SID.LastIndexOf("-"))

}
