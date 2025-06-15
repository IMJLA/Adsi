function Get-CachedDirectoryEntry {

    <#
        Path to the directory object to retrieve
        Defaults to the root of the current domain
        #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Get-CachedDirectoryEntry')]

    param (

        <#

        Path to the directory object to retrieve
        Defaults to the root of the current domain
        #>

        [string]$DirectoryPath = (([System.DirectoryServices.DirectorySearcher]::new()).SearchRoot.Path),

        [string]$Server,

        [string]$AccountName,

        [hashtable]$SidTypeMap = (Get-SidTypeMap),

        # In-process cache to reduce calls to other processes or to disk

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
