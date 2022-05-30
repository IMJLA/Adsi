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
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$AdsiServer,

        # Cache of known directory servers to reduce duplicate queries
        [hashtable]$KnownServers = [hashtable]::Synchronized(@{})

    )
    process {
        ForEach ($ThisServer in $AdsiServer) {
            $AdsiProvider = $null
            if ($KnownServers[$ThisServer]) {
                $AdsiProvider = $KnownServers[$ThisServer]
            } else {
                try {
                    $null = [System.DirectoryServices.DirectoryEntry]::Exists("LDAP://$ThisServer")
                    $AdsiProvider = 'LDAP'
                } catch { Write-Debug "$ThisServer is not an LDAP server" }
                if (!$AdsiProvider) {
                    try {
                        $null = [System.DirectoryServices.DirectoryEntry]::Exists("WinNT://$ThisServer")
                        $AdsiProvider = 'WinNT'
                    } catch {
                        Write-Debug "$ThisServer is not a WinNT server"
                    }
                }
                if (!$AdsiProvider) {
                    $AdsiProvider = 'none'
                }
                $KnownServers[$ThisServer] = $AdsiProvider
            }
            Write-Output $AdsiProvider
        }
    }
}
