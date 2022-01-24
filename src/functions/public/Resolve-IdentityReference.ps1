function Resolve-IdentityReference {
    param (
        [psobject[]]$AccessControlEntry,

        [hashtable]$KnownServers = [hashtable]::Synchronized(@{})
    )
    begin {}
    process {
        ForEach ($ThisACE in $AccessControlEntry) {
            $ThisServer = $null
            $AdsiProvider = $null
            $ThisServer = $ThisACE.Path -split '\\' | Where-Object {$_ -ne ''} | Select-Object -First 1
            $ResolvedIdentityReference = $ThisACE.IdentityReference -replace 'NT AUTHORITY',$ThisServer -replace 'BUILTIN',$ThisServer

            $ThisServer = $ResolvedIdentityReference -split '\\' | Where-Object {$_ -ne ''} | Select-Object -First 1
            $AdsiProvider = Find-AdsiProvider -AdsiServer $ThisServer -KnownServers $KnownServers
            $ThisACE | Add-Member -PassThru -Force -NotePropertyMembers @{
                ResolvedIdentityReference = $ResolvedIdentityReference
                AdsiProvider = $AdsiProvider
            }
        }
    }
    end {}
}