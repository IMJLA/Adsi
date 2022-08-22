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
        $DomainDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -DomainsByNetbios $DomainsByNetbios
        $DomainDnsName = ConvertTo-Fqdn -DistinguishedName $DomainDn
        $DomainSid = ConvertTo-DomainSidString -DomainDnsName $DomainDnsName -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
    }

    if ($PSBoundParameters.ContainsKey('DomainDnsName')) {
        $DomainDn = ConvertTo-DistinguishedName -DomainFQDN $DomainDnsName
        $DomainSid = ConvertTo-DomainSidString -DomainDnsName $DomainDnsName -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
        $DomainNetBIOS = ConvertTo-DomainNetBIOS -DomainDnsName $DomainDnsName -AdsiServersByDns $AdsiServersByDns -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
    }

    [PSCustomObject]@{
        Dns               = $DomainDnsName
        NetBios           = $DomainNetBIOS
        SID               = $DomainSid
        DistinguishedName = $DomainDn
    }

}
