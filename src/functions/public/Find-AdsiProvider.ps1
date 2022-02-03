function Find-AdsiProvider {
    param (
        [string]$AdsiServer,

        [hashtable]$KnownServers = [hashtable]::Synchronized(@{})
    )
    $AdsiProvider = $null
    if ($KnownServers[$AdsiServer]) {
        $AdsiProvider = $KnownServers[$AdsiServer]
    } else {
        try {
            $null = [System.DirectoryServices.DirectoryEntry]::Exists("LDAP://$AdsiServer")
            $AdsiProvider = 'LDAP'
        } catch {}
        if (!$AdsiProvider) {
            try {
                $null = [System.DirectoryServices.DirectoryEntry]::Exists("WinNT://$AdsiServer")
                $AdsiProvider = 'WinNT'
            } catch {}
        }
        if (!$AdsiProvider) {
            $AdsiProvider = 'none'
        }
        $KnownServers[$AdsiServer] = $AdsiProvider
    }
    Write-Output $AdsiProvider
}
