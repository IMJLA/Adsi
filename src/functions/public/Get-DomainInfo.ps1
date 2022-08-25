function Get-DomainInfo {
    param (
        [string]$DomainDn,
        [string]$DomainDnsName,
        [string]$DomainNetBIOS,
        [string]$DomainSID,

        # Cache of known directory servers to reduce duplicate queries
        [hashtable]$AdsiServersByDns = [hashtable]::Synchronized(@{}),

        <#
        Hashtable containing cached directory entries so they don't have to be retrieved from the directory again

        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{}))
    )

    if ($PSBoundParameters.ContainsKey('DomainNetBIOS')) {
        $OutputObject = $DomainsByNetbios[$DomainNetbios]
        if ($OutputObject) {
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-DomainInfo`t # Domain NetBIOS cache hit for '$DomainNetbios'"
            return $OutputObject
        }
        Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-DomainInfo`t # Domain NetBIOS cache hit for '$DomainNetbios'"
        $DomainDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -DomainsByNetbios $DomainsByNetbios
        if ($DomainDn) {
            $DomainDnsName = ConvertTo-Fqdn -DistinguishedName $DomainDn
        } else {
            $CimSession = New-CimSession -ComputerName $DomainNetBIOS
            $ParentDomainDnsName = (Get-CimInstance -CimSession $CimSession -ClassName CIM_ComputerSystem).domain
            if ($ParentDomainDnsName -eq 'WORKGROUP' -or $null -eq $ParentDomainDnsName) {
                $ParentDomainDnsName = (Get-DnsClientGlobalSetting -CimSession $CimSession).SuffixSearchList[0]
            }
            $DomainDnsName = "$DomainNetBIOS.$ParentDomainDnsName"
        }
        $DomainSid = ConvertTo-DomainSidString -DomainDnsName $DomainDnsName -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
    }

    if ($PSBoundParameters.ContainsKey('DomainDnsName')) {
        $OutputObject = $DomainsByFqdn[$DomainDnsName]
        if ($OutputObject) {
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-DomainInfo`t # Domain FQDN cache hit for '$DomainDnsName'"
            return $OutputObject
        }
        Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-DomainInfo`t # Domain FQDN cache miss for '$DomainDnsName'"
        Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-DomainInfo`tConvertTo-DistinguishedName -DomainFQDN '$DomainDnsName'"
        $DomainDn = ConvertTo-DistinguishedName -DomainFQDN $DomainDnsName
        Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-DomainInfo`tConvertTo-DomainSidString -DomainDnsName '$DomainDnsName'"
        $DomainSid = ConvertTo-DomainSidString -DomainDnsName $DomainDnsName -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
        Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-DomainInfo`tConvertTo-DomainNetBIOS -DomainFQDN '$DomainDnsName'"
        $DomainNetBIOS = ConvertTo-DomainNetBIOS -DomainFQDN $DomainDnsName -AdsiServersByDns $AdsiServersByDns -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
    }

    $OutputObject = [PSCustomObject]@{
        Dns               = $DomainDnsName
        NetBIOS           = $DomainNetBIOS
        SID               = $DomainSid
        DistinguishedName = $DomainDn
    }

    $DomainsBySID[$OutputObject.SID] = $OutputObject
    $DomainsByNetbios[$DomainNetbios] = $OutputObject
    $DomainsByFqdn[$DomainDnsName] = $OutputObject

    return $OutputObject
}
