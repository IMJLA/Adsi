function ConvertTo-DomainNetBIOS {

    param (

        [string]$DomainFQDN,

        [string]$AdsiProvider,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $DomainCacheResult = $null
    $TryGetValueResult = $Cache.Value['DomainByFqdn'].Value.TryGetValue($DomainFQDN, [ref]$DomainCacheResult)

    if ($TryGetValueResult) {

        #Write-LogMsg -Text " # Domain FQDN cache hit for '$DomainFQDN'" -Cache $Cache
        return $DomainCacheResult.Netbios

    }

    if ($AdsiProvider -eq 'LDAP') {

        $DirectoryPath = "LDAP://$DomainFQDN/rootDSE"
        Write-LogMsg -Text "`$RootDSE = Get-DirectoryEntry -DirectoryPath '$DirectoryPath' -Cache `$Cache # Domain FQDN cache miss for '$DomainFQDN'" -Cache $Cache
        $RootDSE = Get-DirectoryEntry -DirectoryPath $DirectoryPath -Cache $Cache
        Write-LogMsg -Text "`$RootDSE.InvokeGet('defaultNamingContext')" -Cache $Cache
        $DomainDistinguishedName = $RootDSE.InvokeGet('defaultNamingContext')
        Write-LogMsg -Text "`$RootDSE.InvokeGet('configurationNamingContext')" -Cache $Cache
        $ConfigurationDN = $rootDSE.InvokeGet('configurationNamingContext')
        $DirectoryPath = "LDAP://$DomainFQDN/cn=partitions,$ConfigurationDN"
        Write-LogMsg -Text "Get-DirectoryEntry -DirectoryPath '$DirectoryPath' -Cache `$Cache" -Cache $Cache
        $partitions = Get-DirectoryEntry -DirectoryPath $DirectoryPath -Cache $Cache

        ForEach ($Child In $Partitions.Children) {

            If ($Child.nCName -contains $DomainDistinguishedName) {
                return $Child.nETBIOSName
            }

        }

    } else {

        $LengthOfNetBIOSName = $DomainFQDN.IndexOf('.')

        if ($LengthOfNetBIOSName -eq -1) {
            $DomainFQDN
        } else {
            $DomainFQDN.Substring(0, $LengthOfNetBIOSName)
        }

    }

}
