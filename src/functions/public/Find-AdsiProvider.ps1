function Find-AdsiProvider {
    <#
        .SYNOPSIS
        Determine whether a directory server is an LDAP or a WinNT server
        .DESCRIPTION
        Uses the ADSI provider to attempt to query the server using LDAP first, then WinNT second
        .INPUTS
        [System.String] AdsiServer parameter.
        .OUTPUTS
        [System.String] Possible return values are:
            None
            LDAP
            WinNT
        .EXAMPLE
        Find-AdsiProvider -AdsiServer localhost

        Find the ADSI provider of the local computer
        .EXAMPLE
        Find-AdsiProvider -AdsiServer 'ad.contoso.com'

        Find the ADSI provider of the AD domain 'ad.contoso.com'
    #>
    [OutputType([System.String])]

    param (

        # IP address or hostname of the directory server whose ADSI provider type to determine
        [Parameter(ValueFromPipeline)]
        [string[]]$AdsiServer,

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug'

    )
    begin {

        $LogParams = @{
            ThisHostname = $ThisHostname
            Type         = $DebugOutputStream
            LogMsgCache  = $LogMsgCache
            WhoAmI       = $WhoAmI
        }

        $LoggingParams = @{
            LogMsgCache       = $LogMsgCache
            ThisHostname      = $ThisHostname
            DebugOutputStream = $DebugOutputStream
            WhoAmI            = $WhoAmI
        }

    }
    process {

        ForEach ($ThisServer in $AdsiServer) {

            $AdsiProvider = $null

            if (
                Get-CachedCimInstance -ComputerName $ThisServer -Namespace ROOT/StandardCimv2 -Query 'Select * From MSFT_NetTCPConnection Where LocalPort = 389' -KeyProperty LocalPort -CimCache $CimCache -ThisFqdn $ThisFqdn -ErrorAction Ignore @LoggingParams
            ) {
                $AdsiPath = "LDAP://$ThisServer"
                Write-LogMsg @LogParams -Text "[System.DirectoryServices.DirectoryEntry]::Exists('$AdsiPath')"
                try {
                    $null = [System.DirectoryServices.DirectoryEntry]::Exists($AdsiPath)
                    $AdsiProvider = 'LDAP'
                } catch { Write-LogMsg @LogParams -Text " # $ThisServer did not respond to LDAP" }
            }
            if (!$AdsiProvider) {
                $AdsiPath = "WinNT://$ThisServer"
                Write-LogMsg @LogParams -Text "[System.DirectoryServices.DirectoryEntry]::Exists('$AdsiPath')"
                try {
                    $null = [System.DirectoryServices.DirectoryEntry]::Exists($AdsiPath)
                    $AdsiProvider = 'WinNT'
                } catch {
                    Write-LogMsg @LogParams -Text " # $ThisServer did not respond to WinNT"
                }
            }
            if (!$AdsiProvider) {
                $AdsiPath = "LDAP://$ThisServer"
                Write-LogMsg @LogParams -Text "[System.DirectoryServices.DirectoryEntry]::Exists('$AdsiPath')"
                try {
                    $null = [System.DirectoryServices.DirectoryEntry]::Exists($AdsiPath)
                    $AdsiProvider = 'LDAP'
                } catch { Write-LogMsg @LogParams -Text " # $ThisServer did not respond to LDAP" }
            }
            if (!$AdsiProvider) {
                $AdsiProvider = 'none'
            }
        }
        $AdsiProvider
    }
}
