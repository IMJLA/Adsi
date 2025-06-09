function ConvertTo-DomainNetBIOS {

    <#
    .SYNOPSIS
    Converts a domain FQDN to its NetBIOS name.

    .DESCRIPTION
    Retrieves the NetBIOS name for a specified domain FQDN by checking the cache or querying
    the directory service. For LDAP providers, it retrieves domain information from the directory.
    For non-LDAP providers, it extracts the first part of the FQDN before the first period.

    .EXAMPLE
    ConvertTo-DomainNetBIOS -DomainFQDN 'contoso.com' -Cache $Cache

    Converts the fully qualified domain name 'contoso.com' to its NetBIOS name by automatically
    determining the appropriate method based on available information. The function will check the
    cache first to avoid unnecessary directory queries.

    .EXAMPLE
    ConvertTo-DomainNetBIOS -DomainFQDN 'contoso.com' -AdsiProvider 'LDAP' -Cache $Cache

    Converts the fully qualified domain name 'contoso.com' to its NetBIOS name using the LDAP provider
    specifically, which provides more accurate results in an Active Directory environment by querying
    the domain controller directly.

    .INPUTS
    None. Pipeline input is not accepted.

    .OUTPUTS
    System.String. The NetBIOS name of the domain.
    #>

    param (

        # Fully Qualified Domain Name (FQDN) to convert to NetBIOS name
        [string]$DomainFQDN,

        # ADSI provider to use (LDAP or WinNT)
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