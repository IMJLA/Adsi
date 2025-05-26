function ConvertTo-DomainSidString {

    <#
    .SYNOPSIS
    Converts a domain DNS name to its corresponding SID string.

    .DESCRIPTION
    Retrieves the security identifier (SID) string for a specified domain DNS name using either
    cached values or by querying the directory service. It supports both LDAP and WinNT providers
    and can fall back to local server resolution methods when needed.

    .EXAMPLE
    ConvertTo-DomainSidString -DomainDnsName 'contoso.com' -Cache $Cache

    Converts the DNS domain name 'contoso.com' to its corresponding domain SID string by
    automatically determining the best ADSI provider to use and utilizing the cache to avoid
    redundant directory queries.

    .EXAMPLE
    ConvertTo-DomainSidString -DomainDnsName 'contoso.com' -AdsiProvider 'LDAP' -Cache $Cache

    Converts the DNS domain name 'contoso.com' to its corresponding domain SID string by
    explicitly using the LDAP provider, which can be more efficient when you already know
    the appropriate provider to use.

    .INPUTS
    None. Pipeline input is not accepted.

    .OUTPUTS
    System.String. The SID string of the specified domain.
    #>

    param (

        # Domain DNS name to convert to the domain's SID
        [Parameter(Mandatory)]
        [string]$DomainDnsName,

        <#
        AdsiProvider (WinNT or LDAP) of the servers associated with the provided FQDNs or NetBIOS names

        This parameter can be used to reduce calls to Find-AdsiProvider

        Useful when that has been done already but the DomainsByFqdn and DomainsByNetbios caches have not been updated yet
        #>
        [string]$AdsiProvider,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $Log = @{ Cache = $Cache ; Suffix = " # for domain FQDN '$DomainDnsName'" }
    $CacheResult = $null
    $null = $Cache.Value['DomainByFqdn'].Value.TryGetValue($DomainDnsName, [ref]$CacheResult)

    if ($CacheResult.Sid) {

        #Write-LogMsg @Log -Text " # Domain FQDN cache hit"
        return $CacheResult.Sid

    }
    #Write-LogMsg @Log -Text " # Domain FQDN cache miss"

    if (
        -not $AdsiProvider -or
        $AdsiProvider -eq 'LDAP'
    ) {

        Write-LogMsg @Log -Text "Get-DirectoryEntry -DirectoryPath 'LDAP://$DomainDnsName' -Cache `$Cache"
        $DomainDirectoryEntry = Get-DirectoryEntry -DirectoryPath "LDAP://$DomainDnsName" -Cache $Cache

        try {
            $null = $DomainDirectoryEntry.RefreshCache('objectSid')
        } catch {

            Write-LogMsg @Log -Text "Find-LocalAdsiServerSid -ComputerName '$DomainDnsName' -Cache `$Cache # LDAP connection failed - $($_.Exception.Message.Replace("`r`n",' ').Trim()) -Cache `$Cache"
            $DomainSid = Find-LocalAdsiServerSid -ComputerName $DomainDnsName -Cache $Cache
            return $DomainSid

        }

    } else {

        Write-LogMsg @Log -Text "Find-LocalAdsiServerSid -ComputerName '$DomainDnsName' -Cache `$Cache"
        $DomainSid = Find-LocalAdsiServerSid -ComputerName $DomainDnsName -Cache $Cache
        return $DomainSid

    }

    $DomainSid = $null

    if ($DomainDirectoryEntry.Properties) {

        $objectSIDProperty = $DomainDirectoryEntry.Properties['objectSid']

        if ($objectSIDProperty.Value) {
            $SidByteArray = [byte[]]$objectSIDProperty.Value
        } else {
            $SidByteArray = [byte[]]$objectSIDProperty
        }

    } else {
        $SidByteArray = [byte[]]$DomainDirectoryEntry.objectSid
    }

    Write-LogMsg @Log -Text "[System.Security.Principal.SecurityIdentifier]::new([byte[]]@($($SidByteArray -join ',')), 0).ToString()"
    $DomainSid = [System.Security.Principal.SecurityIdentifier]::new($SidByteArray, 0).ToString()

    if ($DomainSid) {
        return $DomainSid
    } else {

        $StartingLogType = $Cache.Value['LogType'].Value
        $Cache.Value['LogType'].Value = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
        Write-LogMsg @Log -Text ' # Could not find valid SID for LDAP Domain'
        $Cache.Value['LogType'].Value = $StartingLogType

    }

}
