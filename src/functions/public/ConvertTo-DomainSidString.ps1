function ConvertTo-DomainSidString {
    param (

        # Domain DNS name to convert to the domain's SID
        [Parameter(Mandatory)]
        [string]$DomainDnsName,

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

    $CacheResult = $DomainsByFqdn[$DomainDnsName]
    if ($CacheResult) {
        return $CacheResult.Sid
    }

    $DomainDirectoryEntry = Get-DirectoryEntry -DirectoryPath "LDAP://$DomainDnsName" -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
    try {
        $null = $DomainDirectoryEntry.RefreshCache('objectSid')
    } catch {
        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tConvertTo-DomainSidString`tLDAP Domain: '$DomainDnsName' - $($_.Exception.Message)"
        continue
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

    Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tConvertTo-DomainSidString`t[System.Security.Principal.SecurityIdentifier]::new($SidByteArray, 0).ToString()"
    $DomainSid = [System.Security.Principal.SecurityIdentifier]::new($SidByteArray, 0).ToString()

    if ($DomainSid) {
        return $DomainSid
    } else {
        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tConvertTo-DomainSidString`t # LDAP Domain: '$DomainDnsName' has an invalid SID - $($_.Exception.Message)"
    }

}
