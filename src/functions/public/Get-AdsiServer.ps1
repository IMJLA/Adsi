function Get-AdsiServer {
    <#
        .SYNOPSIS
        Get information about a directory server including the ADSI provider it hosts and its well-known SIDs
        .DESCRIPTION
        Uses the ADSI provider to query the server using LDAP first, then WinNT upon failure
        Uses WinRM to query the CIM class Win32_SystemAccount for well-known SIDs
        .INPUTS
        [System.String]$AdsiServer
        .OUTPUTS
        [PSCustomObject] with AdsiProvider and WellKnownSIDs properties
        .EXAMPLE
        Get-AdsiServer -AdsiServer localhost

        Find the ADSI provider of the local computer
        .EXAMPLE
        Get-AdsiServer -AdsiServer 'ad.contoso.com'

        Find the ADSI provider of the AD domain 'ad.contoso.com'
    #>
    [OutputType([System.String])]

    param (

        # IP address or hostname of the directory server whose ADSI provider type to determine
        [Parameter(ValueFromPipeline)]
        [string[]]$AdsiServer,

        # Cache of known directory servers to reduce duplicate queries
        [hashtable]$KnownServers = [hashtable]::Synchronized(@{})

    )
    process {
        ForEach ($ThisServer in $AdsiServer) {
            if (!($KnownServers[$ThisServer])) {
                $AdsiProvider = Find-AdsiProvider -AdsiServer $ThisServer
                $WellKnownSIDs = Get-WellKnownSid -AdsiServer $ThisServer
                $KnownServers[$ThisServer] = [pscustomobject]@{
                    AdsiProvider  = $AdsiProvider
                    WellKnownSIDs = $WellKnownSIDs
                }
            }
            $KnownServers[$ThisServer]
        }
    }
}
