function Get-CachedDirectoryEntry {

    <#
    .SYNOPSIS
        Retrieves a cached directory entry from well-known SID and domain caches.

    .DESCRIPTION
        The Get-CachedDirectoryEntry function searches through various in-memory caches to find
        directory entries for a given server and account name combination. It searches through:
        - Domain cache by FQDN
        - Domain cache by NetBIOS name
        - Domain cache by SID

        For each domain cache, it looks for matches in:
        - Well-known SID cache by SID (Server\AccountName format)
        - Well-known SID cache by Name (AccountName only)

        When a match is found, it converts the cached result to a fake directory entry object
        that can be used in place of an actual DirectoryEntry object, improving performance
        by avoiding expensive directory service calls.

    .EXAMPLE
        $cache = @{ DomainByFqdn = @{}; DomainByNetbios = @{}; DomainBySid = @{} }
        $entry = Get-CachedDirectoryEntry -DirectoryPath "LDAP://DC=contoso,DC=com" -Server "contoso.com" -AccountName "Administrator" -Cache ([ref]$cache)

        Searches for a cached directory entry for the Administrator account on contoso.com domain.

    .EXAMPLE
        $sidTypeMap = Get-SidTypeMap
        $entry = Get-CachedDirectoryEntry -Server "WORKGROUP01" -AccountName "Guest" -SidTypeMap $sidTypeMap -Cache ([ref]$domainCache)

        Searches for a cached directory entry for the Guest account using a custom SID type mapping.

    .INPUTS
        None. This function does not accept pipeline input.

    .OUTPUTS
        System.DirectoryServices.DirectoryEntry
        Returns a fake directory entry object if found in cache, otherwise returns nothing.

    .NOTES
        This function is designed for performance optimization by avoiding repeated directory
        service queries for well-known accounts and previously resolved entries.

        The function searches caches in the following order:
        1. DomainByFqdn cache
        2. DomainByNetbios cache
        3. DomainBySid cache

        For each domain cache, it first searches by SID (Server\AccountName), then by Name (AccountName).

    .LINK
        Get-SidTypeMap

    .LINK
        ConvertTo-FakeDirectoryEntry
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Get-CachedDirectoryEntry')]

    param (

        # Path to the directory object to retrieve. Defaults to the root of the current domain if not specified.
        [string]$DirectoryPath = (([System.DirectoryServices.DirectorySearcher]::new()).SearchRoot.Path),

        # Server name (FQDN, NetBIOS, or SID) to search for in the domain caches.
        [string]$Server,

        # Account name to search for in the well-known SID caches.
        [string]$AccountName,

        # Hashtable mapping SID types to their corresponding schema class names. Used to determine the appropriate schema class for fake directory entries.
        [hashtable]$SidTypeMap = (Get-SidTypeMap),

        # In-process cache containing domain and well-known SID information. Passed by reference to reduce calls to other processes or to disk.
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    # Search the cache of CIM instances and well-known SIDs for the DirectoryEntry

    #>

    $ID = "$Server\$AccountName"
    $DomainCacheResult = $null
    $TryGetValueResult = $Cache.Value['DomainByFqdn'].Value.TryGetValue($Server, [ref]$DomainCacheResult)

    if ($TryGetValueResult) {

        $SIDCacheResult = $DomainCacheResult.WellKnownSIDBySID[$ID]

        if ($SIDCacheResult) {

            #Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Known SID cache hit on this server."

            if ($SIDCacheResult.SIDType) {
                ConvertTo-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $SIDCacheResult -SchemaClassName $SidTypeMap[[int]$SIDCacheResult.SIDType]
            } else {
                ConvertTo-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $SIDCacheResult
            }


        } else {

            #Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Known SID cache miss on this server."
            $NameCacheResult = $DomainCacheResult.WellKnownSIDByName[$AccountName]

            if ($NameCacheResult) {

                #Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Name '$AccountName' # Known Name cache hit on this server."

                if ($NameCacheResult.SIDType) {
                    ConvertTo-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $NameCacheResult -SchemaClassName $SidTypeMap[[int]$NameCacheResult.SIDType]
                } else {
                    ConvertTo-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $NameCacheResult
                }

            } else {
                #Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Name '$AccountName' # Known Name cache miss on this server."
            }
        }

    } else {

        $DomainCacheResult = $null
        $TryGetValueResult = $Cache.Value['DomainByNetbios'].Value.TryGetValue($Server, [ref]$DomainCacheResult)

        if ($TryGetValueResult) {

            $SIDCacheResult = $DomainCacheResult.WellKnownSIDBySID[$ID]

            if ($SIDCacheResult) {

                #Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Known SID cache hit on this server."

                if ($SIDCacheResult.SIDType) {
                    ConvertTo-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $SIDCacheResult -SchemaClassName $SidTypeMap[[int]$SIDCacheResult.SIDType]
                } else {
                    ConvertTo-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $SIDCacheResult
                }

            } else {

                #Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Known SID cache miss on this server."
                $NameCacheResult = $DomainCacheResult.WellKnownSIDByName[$AccountName]

                if ($NameCacheResult) {

                    #Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Name '$AccountName' # Known Name cache hit on this server."Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Well-known SID by name cache hit for '$AccountName' on host with NetBIOS '$Server'"

                    if ($NameCacheResult.SIDType) {
                        ConvertTo-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $NameCacheResult -SchemaClassName $SidTypeMap[[int]$NameCacheResult.SIDType]
                    } else {
                        ConvertTo-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $NameCacheResult
                    }

                } else {
                    #Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Name '$AccountName' # Known Name cache miss on this server."
                }

            }

        } else {

            $DomainCacheResult = $null
            $TryGetValueResult = $Cache.Value['DomainBySid'].Value.TryGetValue($Server, [ref]$DomainCacheResult)

            if ($TryGetValueResult) {

                $SIDCacheResult = $DomainCacheResult.WellKnownSIDBySID[$ID]

                if ($SIDCacheResult) {

                    #Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Known SID cache hit on this server."
                    ConvertTo-FakeDirectoryEntry -DirectoryPath $DirectoryPath @SIDCacheResult

                } else {

                    #Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Known SID cache miss on this server."
                    $NameCacheResult = $DomainCacheResult.WellKnownSIDByName[$AccountName]

                    if ($NameCacheResult) {

                        #Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Name '$AccountName' # Known Name cache hit on this server."Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Well-known SID by name cache hit for '$AccountName' on host with NetBIOS '$Server'"
                        ConvertTo-FakeDirectoryEntry -DirectoryPath $DirectoryPath @NameCacheResult

                    } else {
                        #Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Name '$AccountName' # Known Name cache miss on this server."
                    }

                }

            }

        }

    }

}
