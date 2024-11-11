function Get-CachedDirectoryEntry {

    # Search the cache of CIM instances and well-known SIDs for the DirectoryEntry

    param (

        <#
        Path to the directory object to retrieve
        Defaults to the root of the current domain
        #>
        [string]$DirectoryPath = (([System.DirectoryServices.DirectorySearcher]::new()).SearchRoot.Path),

        [string]$Server,

        [string]$AccountName,

        [hashtable]$SidTypeMap = (Get-SidTypeMap),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    #$Log = @{ ThisHostname = $ThisHostname ; Type = $DebugOutputStream ; Buffer = $Cache.Value['LogBuffer'] ; WhoAmI = $WhoAmI }

    <#
    The WinNT provider only throws an error if you try to retrieve certain accounts/identities
    We will create own dummy objects instead of performing the query
    #>
    $ID = "$Server\$AccountName"
    $DomainCacheResult = $null
    $TryGetValueResult = $Cache.Value['DomainByFqdn'].Value.TryGetValue($Server, [ref]$DomainCacheResult)

    if ($TryGetValueResult) {

        $SIDCacheResult = $DomainCacheResult.WellKnownSIDBySID[$ID]

        if ($SIDCacheResult) {

            #Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Known SID cache hit on this server."

            if ($SIDCacheResult.SIDType) {
                New-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $SIDCacheResult -SchemaClassName $SidTypeMap[[int]$SIDCacheResult.SIDType]
            } else {
                New-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $SIDCacheResult
            }


        } else {

            #Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Known SID cache miss on this server."
            $NameCacheResult = $DomainCacheResult.WellKnownSIDByName[$AccountName]

            if ($NameCacheResult) {

                #Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Name '$AccountName' # Known Name cache hit on this server."

                if ($NameCacheResult.SIDType) {
                    New-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $NameCacheResult -SchemaClassName $SidTypeMap[[int]$NameCacheResult.SIDType]
                } else {
                    New-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $NameCacheResult
                }

            } else {
                #Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Name '$AccountName' # Known Name cache miss on this server."
            }
        }

    } else {

        $DomainCacheResult = $null
        $TryGetValueResult = $Cache.Value['DomainByNetbios'].Value.TryGetValue($Server, [ref]$DomainCacheResult)

        if ($TryGetValueResult) {

            $SIDCacheResult = $DomainCacheResult.WellKnownSIDBySID[$ID]

            if ($SIDCacheResult) {

                #Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Known SID cache hit on this server."

                if ($SIDCacheResult.SIDType) {
                    New-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $SIDCacheResult -SchemaClassName $SidTypeMap[[int]$SIDCacheResult.SIDType]
                } else {
                    New-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $SIDCacheResult
                }

            } else {

                #Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Known SID cache miss on this server."
                $NameCacheResult = $DomainCacheResult.WellKnownSIDByName[$AccountName]

                if ($NameCacheResult) {

                    #Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Name '$AccountName' # Known Name cache hit on this server."Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Well-known SID by name cache hit for '$AccountName' on host with NetBIOS '$Server'"

                    if ($NameCacheResult.SIDType) {
                        New-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $NameCacheResult -SchemaClassName $SidTypeMap[[int]$NameCacheResult.SIDType]
                    } else {
                        New-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $NameCacheResult
                    }

                } else {
                    #Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Name '$AccountName' # Known Name cache miss on this server."
                }

            }

        } else {

            $DomainCacheResult = $null
            $TryGetValueResult = $Cache.Value['DomainBySid'].Value.TryGetValue($Server, [ref]$DomainCacheResult)

            if ($TryGetValueResult) {

                $SIDCacheResult = $DomainCacheResult.WellKnownSIDBySID[$ID]

                if ($SIDCacheResult) {

                    #Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Known SID cache hit on this server."
                    New-FakeDirectoryEntry -DirectoryPath $DirectoryPath @SIDCacheResult

                } else {

                    #Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Known SID cache miss on this server."
                    $NameCacheResult = $DomainCacheResult.WellKnownSIDByName[$AccountName]

                    if ($NameCacheResult) {

                        #Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Name '$AccountName' # Known Name cache hit on this server."Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Well-known SID by name cache hit for '$AccountName' on host with NetBIOS '$Server'"
                        New-FakeDirectoryEntry -DirectoryPath $DirectoryPath @NameCacheResult

                    } else {
                        #Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Name '$AccountName' # Known Name cache miss on this server."
                    }

                }

            }

        }

    }

}
