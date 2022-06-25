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
        [string[]]$AdsiServer

    )
    process {
        ForEach ($ThisServer in $AdsiServer) {
            $AdsiProvider = $null
            $AdsiPath = "LDAP://$ThisServer"
            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tFind-AdsiProvider`t[System.DirectoryServices.DirectoryEntry]::Exists('$AdsiPath')"
            try {
                $null = [System.DirectoryServices.DirectoryEntry]::Exists($AdsiPath)
                $AdsiProvider = 'LDAP'
            } catch { Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tFind-AdsiProvider`t$ThisServer is not an LDAP server" }
            if (!$AdsiProvider) {
                $AdsiPath = "WinNT://$ThisServer"
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tFind-AdsiProvider`t[System.DirectoryServices.DirectoryEntry]::Exists('$AdsiPath')"
                try {
                    $null = [System.DirectoryServices.DirectoryEntry]::Exists($AdsiPath)
                    $AdsiProvider = 'WinNT'
                } catch {
                    Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tFind-AdsiProvider`t$ThisServer is not a WinNT server"
                }
            }
            if (!$AdsiProvider) {
                $AdsiProvider = 'none'
            }
        }
        $AdsiProvider
    }
}
