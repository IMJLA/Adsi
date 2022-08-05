function ConvertTo-LDAPDomainNetBIOS {
    param (
        [string]$DomainFQDN,

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

        # Cache of known directory servers to reduce duplicate queries
        [hashtable]$AdsiServersByDns = [hashtable]::Synchronized(@{}),

        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{}))

    )

    $DomainCacheResult = $DomainsByFqdn[$DomainFQDN]
    if ($DomainCacheResult) {
        return $DomainCacheResult.Netbios
    }

    $ThisHostName = HOSTNAME.EXE

    $AdsiServer = Get-AdsiServer -AdsiServer $DomainFQDN -AdsiServersByDns $AdsiServersByDns
    if ($AdsiServer.AdsiProvider -eq 'LDAP') {
        $RootDSE = Get-DirectoryEntry -DirectoryPath "LDAP://$DomainFQDN/rootDSE" -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios
        Write-Debug "  $(Get-Date -Format s)`t$ThisHostName`tConvertTo-LDAPDomainNetBIOS`t`$RootDSE.InvokeGet('defaultNamingContext')"
        $DomainDistinguishedName = $RootDSE.InvokeGet("defaultNamingContext")
        Write-Debug "  $(Get-Date -Format s)`t$ThisHostName`tConvertTo-LDAPDomainNetBIOS`t`$RootDSE.InvokeGet('configurationNamingContext')"
        $ConfigurationDN = $rootDSE.InvokeGet("configurationNamingContext")
        $partitions = Get-DirectoryEntry -DirectoryPath "LDAP://$DomainFQDN/cn=partitions,$ConfigurationDN" -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios

        ForEach ($Child In $Partitions.Children) {
            If ($Child.nCName -contains $DomainDistinguishedName) {
                return $Child.nETBIOSName
            }
        }
    } else {
        ($DomainFQDN -split '\.')[0]
    }

}
