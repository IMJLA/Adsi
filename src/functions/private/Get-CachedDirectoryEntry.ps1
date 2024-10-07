function Get-CachedDirectoryEntry {

    # Search the cache of CIM instances and well-known SIDs for the DirectoryEntry

    param (

        <#
    Path to the directory object to retrieve
    Defaults to the root of the current domain
    #>
        [string]$DirectoryPath = (([System.DirectoryServices.DirectorySearcher]::new()).SearchRoot.Path),

        # Cache of CIM sessions and instances for this specific server to reduce connections and queries
        [hashtable]$CimServer = ([hashtable]::Synchronized(@{})),

        [hashtable]$Log,

        [string]$Server,

        [string]$AccountName,

        # Hashtable with known domain FQDNs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        # This is not actually used but is here so the parameter can be included in a splat shared with other functions
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        [hashtable]$SidTypeMap = (Get-SidTypeMap)

    )

    <#
    The WinNT provider only throws an error if you try to retrieve certain accounts/identities
    We will create own dummy objects instead of performing the query
    #>
    if ($CimServer) {

        #Write-LogMsg @Log -Text " # CIM server cache hit for '$Server' # for '$DirectoryPath'"
        $ID = "$Server\$AccountName"
        $CimCacheResult = $CimServer['Win32_AccountByCaption'][$ID]

        if ($CimCacheResult) {

            #Write-LogMsg @Log -Text " # Win32_AccountByCaption CIM instance cache hit for '$ID' on '$Server' # for '$DirectoryPath'"

            $FakeDirectoryEntry = @{
                InputObject   = $CimCacheResult
                DirectoryPath = $DirectoryPath
            }

            if ($CimCacheResult.SIDType) {
                $FakeDirectoryEntry['SchemaClassName'] = $SidTypeMap[[int]$CimCacheResult.SIDType]
            }

            New-FakeDirectoryEntry @FakeDirectoryEntry

        } else {

            Write-LogMsg @Log -Text " # Win32_AccountByCaption CIM instance cache miss for '$ID' on '$Server' # for '$DirectoryPath'"
            $CimCacheResult = $CimServer['Win32_ServiceBySID'][$ID]

            if ($CimCacheResult) {

                #Write-LogMsg @Log -Text " # Win32_ServiceBySID CIM instance cache hit for '$ID' on '$Server' # for '$DirectoryPath'"

                $FakeDirectoryEntry = @{
                    InputObject   = $CimCacheResult
                    DirectoryPath = $DirectoryPath
                }

                if ($CimCacheResult.SIDType) {
                    $FakeDirectoryEntry['SchemaClassName'] = $SidTypeMap[[int]$CimCacheResult.SIDType]
                }

                New-FakeDirectoryEntry @FakeDirectoryEntry

            } else {

                Write-LogMsg @Log -Text " # Win32_ServiceBySID CIM instance cache miss for '$ID' on '$Server' # for '$DirectoryPath'"
                $DomainCacheResult = $DomainsByFqdn[$Server]

                if ($DomainCacheResult) {

                    $SIDCacheResult = $DomainCacheResult.WellKnownSIDBySID[$ID]

                    if ($SIDCacheResult) {

                        #Write-LogMsg @Log -Text " # Well-known SID by SID cache hit for '$ID' on host with FQDN '$Server' # for '$DirectoryPath'"
                        New-FakeDirectoryEntry -DirectoryPath $DirectoryPath @SIDCacheResult

                    } else {

                        Write-LogMsg @Log -Text " # Well-known SID by SID cache miss for '$ID' on host with FQDN '$Server' # for '$DirectoryPath'"
                        $NameCacheResult = $DomainCacheResult.WellKnownSIDByName[$AccountName]

                        if ($NameCacheResult) {

                            #Write-LogMsg @Log -Text " # Well-known SID by name cache hit for '$AccountName' on host with FQDN '$Server' # for '$DirectoryPath'"
                            New-FakeDirectoryEntry -DirectoryPath $DirectoryPath @NameCacheResult

                        } else {

                            Write-LogMsg @Log -Text " # Well-known SID by name cache miss for '$AccountName' on host with FQDN '$Server' # for '$DirectoryPath'"

                        }
                    }

                } else {

                    $DomainCacheResult = $DomainsByNetbios[$Server]

                    if ($DomainCacheResult) {

                        $SIDCacheResult = $DomainCacheResult.WellKnownSIDBySID[$ID]

                        if ($SIDCacheResult) {

                            #Write-LogMsg @Log -Text " # Well-known SID by SID cache hit for '$ID' on host with NetBIOS '$Server' # for '$DirectoryPath'"
                            New-FakeDirectoryEntry -DirectoryPath $DirectoryPath @SIDCacheResult

                        } else {

                            Write-LogMsg @Log -Text " # Well-known SID by SID cache miss for '$ID' on host with NetBIOS '$Server' # for '$DirectoryPath'"
                            $NameCacheResult = $DomainCacheResult.WellKnownSIDByName[$AccountName]

                            if ($NameCacheResult) {

                                #Write-LogMsg @Log -Text " # Well-known SID by name cache hit for '$AccountName' on host with NetBIOS '$Server' # for '$DirectoryPath'"
                                New-FakeDirectoryEntry -DirectoryPath $DirectoryPath @NameCacheResult

                            } else {
                                Write-LogMsg @Log -Text " # Well-known SID by name cache miss for '$AccountName' on host with NetBIOS '$Server' # for '$DirectoryPath'"
                            }
                        }
                    } else {

                        $DomainCacheResult = $DomainsBySid[$Server]

                        if ($DomainCacheResult) {

                            $SIDCacheResult = $DomainCacheResult.WellKnownSIDBySID[$ID]

                            if ($SIDCacheResult) {

                                #Write-LogMsg @Log -Text " # Well-known SID by SID cache hit for '$ID' on host with SID '$Server' # for '$DirectoryPath'"
                                New-FakeDirectoryEntry -DirectoryPath $DirectoryPath @SIDCacheResult

                            } else {

                                Write-LogMsg @Log -Text " # Well-known SID by SID cache miss for '$ID' on host with SID '$Server' # for '$DirectoryPath'"
                                $NameCacheResult = $DomainCacheResult.WellKnownSIDByName[$AccountName]

                                if ($NameCacheResult) {

                                    #Write-LogMsg @Log -Text " # Well-known SID by name cache hit for '$AccountName' on host with SID '$Server' # for '$DirectoryPath'"
                                    New-FakeDirectoryEntry -DirectoryPath $DirectoryPath @NameCacheResult

                                } else {
                                    Write-LogMsg @Log -Text " # Well-known SID by name cache miss for '$AccountName' on host with SID '$Server' # for '$DirectoryPath'"
                                }

                            }

                        }

                    }

                }

            }

        }

    } else {
        Write-LogMsg @Log -Text " # CIM server cache miss for '$Server' # for '$DirectoryPath'"
    }
}
