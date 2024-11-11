function Find-LocalAdsiServerSid {

    [OutputType([System.String])]

    param (

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        # Name of the computer to query via CIM
        [string]$ComputerName = $ThisHostName,

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $Log = @{ ThisHostname = $ThisHostname ; Type = $DebugOutputStream ; Buffer = $Cache.Value['LogBuffer'] ; WhoAmI = $WhoAmI }

    $CimParams = @{
        Cache             = $Cache
        ComputerName      = $ComputerName
        DebugOutputStream = $DebugOutputStream
        ThisFqdn          = $ThisFqdn
        ThisHostname      = $ThisHostname
        WhoAmI            = $WhoAmI
        Query             = "SELECT SID FROM Win32_UserAccount WHERE LocalAccount = 'True' AND SID LIKE 'S-1-5-21-%-500'"
        KeyProperty       = 'SID'
    }

    Write-LogMsg @Log -Text 'Get-CachedCimInstance' -Expand $CimParams -ExpandKeyMap @{ Cache = '$Cache' }
    $LocalAdminAccount = Get-CachedCimInstance @CimParams

    if (-not $LocalAdminAccount) {
        return
    }

    return $LocalAdminAccount.SID.Substring(0, $LocalAdminAccount.SID.LastIndexOf('-'))

}
