function Get-DirectoryEntry {
    <#
        .SYNOPSIS
        Use Active Directory Service Interfaces to retrieve an object from a directory
        .DESCRIPTION
        Retrieve a directory entry using either the WinNT or LDAP provider for ADSI
        .INPUTS
        None. Pipeline input is not accepted.
        .OUTPUTS
        [System.DirectoryServices.DirectoryEntry] where possible
        [PSCustomObject] for security principals with no directory entry
        .EXAMPLE
        Get-DirectoryEntry
        distinguishedName : {DC=ad,DC=contoso,DC=com}
        Path              : LDAP://DC=ad,DC=contoso,DC=com

        As the current user on a domain-joined computer, bind to the current domain and retrieve the DirectoryEntry for the root of the domain
        .EXAMPLE
        Get-DirectoryEntry
        distinguishedName :
        Path              : WinNT://ComputerName

        As the current user on a workgroup computer, bind to the local system and retrieve the DirectoryEntry for the root of the directory
    #>
    [OutputType([System.DirectoryServices.DirectoryEntry], [PSCustomObject])]
    [CmdletBinding()]
    param (

        <#
        Path to the directory object to retrieve
        Defaults to the root of the current domain
        #>
        [string]$DirectoryPath = (([System.DirectoryServices.DirectorySearcher]::new()).SearchRoot.Path),

        <#
        Credentials to use to bind to the directory
        Defaults to the credentials of the current user
        #>
        [pscredential]$Credential,

        # Properties of the target object to retrieve
        [string[]]$PropertiesToLoad,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        <#
        Hashtable containing cached directory entries so they don't have to be retrieved from the directory again
        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain FQDNs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        # This is not actually used but is here so the parameter can be included in a splat shared with other functions
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Log messages which have not yet been written to disk
        [hashtable]$LogBuffer = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug'

    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        Buffer       = $LogBuffer
        WhoAmI       = $WhoAmI
    }

    $LoggingParams = @{
        ThisHostname = $ThisHostname
        LogBuffer    = $LogBuffer
        WhoAmI       = $WhoAmI
    }

    $SidTypes = Get-SidTypeMap
    $SplitDirectoryPath = Split-DirectoryPath -DirectoryPath $DirectoryPath
    $AccountName = $SplitDirectoryPath['AccountName']
    $Server = $SplitDirectoryPath['Server']
    $CimServer = $CimCache[$Server]

    <#
    The WinNT provider only throws an error if you try to retrieve certain accounts/identities
    We will create own dummy objects instead of performing the query
    #>
    if ($CimServer) {

        Write-LogMsg @LogParams -Text " # CIM server cache hit for '$Server'"
        $ID = "$Server\$AccountName"
        $CimCacheResult = $CimServer['Win32_AccountByCaption'][$ID]

        if ($CimCacheResult) {

            Write-LogMsg @LogParams -Text " # Win32_AccountByCaption CIM instance cache hit for '$ID' on '$Server'"

            $FakeDirectoryEntry = @{
                'Description'   = $CimCacheResult.Description
                'SID'           = $CimCacheResult.SID
                'DirectoryPath' = $DirectoryPath
            }

            if ($CimCacheResult.SIDType) {
                $FakeDirectoryEntry['SchemaClassName'] = $SidTypes[[int]$CimCacheResult.SIDType]
            }

            $DirectoryEntry = New-FakeDirectoryEntry @FakeDirectoryEntry

        } else {

            Write-LogMsg @LogParams -Text " # Win32_AccountByCaption CIM instance cache miss for '$ID' on '$Server'"
            $DomainCacheResult = $DomainsByFqdn[$Server]

            if ($DomainCacheResult) {

                if (-not $DomainCacheResult['WellKnownSIDBySID']) { pause }
                if (-not $DomainCacheResult['WellKnownSIDByName']) { pause }

                $SIDCacheResult = $DomainCacheResult['WellKnownSIDBySID'][$ID]

                if ($SIDCacheResult) {

                    Write-LogMsg @LogParams -Text " # Well-known SID by SID cache hit for '$ID' on host with FQDN '$Server'"
                    $DirectoryEntry = New-FakeDirectoryEntry -DirectoryPath $DirectoryPath @SIDCacheResult

                } else {

                    Write-LogMsg @LogParams -Text " # Well-known SID by SID cache miss for '$ID' on host with FQDN '$Server'"
                    $NameCacheResult = $DomainCacheResult['WellKnownSIDByName'][$AccountName]

                    if ($NameCacheResult) {

                        Write-LogMsg @LogParams -Text " # Well-known SID by name cache hit for '$AccountName' on host with FQDN '$Server'"
                        $DirectoryEntry = New-FakeDirectoryEntry -DirectoryPath $DirectoryPath @NameCacheResult

                    } else {

                        Write-LogMsg @LogParams -Text " # Well-known SID by name cache miss for '$AccountName' on host with FQDN '$Server'"

                    }
                }

            } else {

                $DomainCacheResult = $DomainsByNetbios[$Server]

                if ($DomainCacheResult) {

                    if (-not $DomainCacheResult['WellKnownSIDBySID']) { pause }
                    if (-not $DomainCacheResult['WellKnownSIDByName']) { pause }

                    $SIDCacheResult = $DomainCacheResult['WellKnownSIDBySID'][$ID]

                    if ($SIDCacheResult) {

                        Write-LogMsg @LogParams -Text " # Well-known SID by SID cache hit for '$ID' on host with NetBIOS '$Server'"
                        $DirectoryEntry = New-FakeDirectoryEntry -DirectoryPath $DirectoryPath @SIDCacheResult

                    } else {

                        Write-LogMsg @LogParams -Text " # Well-known SID by SID cache miss for '$ID' on host with NetBIOS '$Server'"
                        $NameCacheResult = $DomainCacheResult['WellKnownSIDByName'][$AccountName]

                        if ($NameCacheResult) {

                            Write-LogMsg @LogParams -Text " # Well-known SID by name cache hit for '$AccountName' on host with NetBIOS '$Server'"
                            $DirectoryEntry = New-FakeDirectoryEntry -DirectoryPath $DirectoryPath @NameCacheResult

                        } else {
                            Write-LogMsg @LogParams -Text " # Well-known SID by name cache miss for '$AccountName' on host with NetBIOS '$Server'"
                        }
                    }
                } else {

                    $DomainCacheResult = $DomainsBySid[$Server]

                    if ($DomainCacheResult) {

                        if (-not $DomainCacheResult['WellKnownSIDBySID']) { pause }
                        if (-not $DomainCacheResult['WellKnownSIDByName']) { pause }

                        $SIDCacheResult = $DomainCacheResult['WellKnownSIDBySID'][$ID]

                        if ($SIDCacheResult) {

                            Write-LogMsg @LogParams -Text " # Well-known SID by SID cache hit for '$ID' on host with SID '$Server'"
                            $DirectoryEntry = New-FakeDirectoryEntry -DirectoryPath $DirectoryPath @SIDCacheResult

                        } else {

                            Write-LogMsg @LogParams -Text " # Well-known SID by SID cache miss for '$ID' on host with SID '$Server'"
                            $NameCacheResult = $DomainCacheResult['WellKnownSIDByName'][$AccountName]

                            if ($NameCacheResult) {

                                Write-LogMsg @LogParams -Text " # Well-known SID by name cache hit for '$AccountName' on host with SID '$Server'"
                                $DirectoryEntry = New-FakeDirectoryEntry -DirectoryPath $DirectoryPath @NameCacheResult

                            } else {
                                Write-LogMsg @LogParams -Text " # Well-known SID by name cache miss for '$AccountName' on host with SID '$Server'"
                            }

                        }

                    }

                }

            }

        }

    } else {
        Write-LogMsg @LogParams -Text " # CIM server cache miss for '$Server'"
    }

    if ($null -eq $DirectoryEntry) {

        switch -regex ($DirectoryPath) {

            # Workgroup computers do not return a DirectoryEntry with a SearchRoot Path so this ends up being an empty string
            # This is also invoked when DirectoryPath is null for any reason
            # We will return a WinNT object representing the local computer's WinNT directory
            '^$' {
                Write-LogMsg @LogParams -Text "'$ThisHostname' does not seem to be domain-joined since the SearchRoot Path is empty. Defaulting to WinNT provider for localhost instead."

                $CimParams = @{
                    CimCache          = $CimCache
                    ComputerName      = $ThisFqdn
                    DebugOutputStream = $DebugOutputStream
                    ThisFqdn          = $ThisFqdn
                }

                $Workgroup = (Get-CachedCimInstance -ClassName 'Win32_ComputerSystem' -KeyProperty Name @CimParams @LoggingParams).Workgroup
                $DirectoryPath = "WinNT://$Workgroup/$ThisHostname"
                Write-LogMsg @LogParams -Text "[System.DirectoryServices.DirectoryEntry]::new('$DirectoryPath')"

                if ($Credential) {
                    $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath, $($Credential.UserName), $($Credential.GetNetworkCredential().password))
                } else {
                    $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath)
                }

                $SampleUser = @(
                    $DirectoryEntry.PSBase.Children |
                    Where-Object -FilterScript { $_.schemaclassname -eq 'user' }
                )[0] |
                Add-SidInfo -DomainsBySid $DomainsBySid @LoggingParams

                $DirectoryEntry |
                Add-Member -MemberType NoteProperty -Name 'Domain' -Value $SampleUser.Domain -Force
                break

            }

            # Otherwise the DirectoryPath is an LDAP path or a WinNT path (treated the same at this stage)
            default {

                Write-LogMsg @LogParams -Text "[System.DirectoryServices.DirectoryEntry]::new('$DirectoryPath')"

                if ($Credential) {
                    $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath, $($Credential.UserName), $($Credential.GetNetworkCredential().password))
                } else {
                    $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath)
                }

                break

            }

        }

    }

    if ($null -eq $DirectoryEntryCache[$DirectoryPath]) {

        #Write-LogMsg @LogParams -Text "DirectoryEntryCache miss for '$DirectoryPath'"
        $DirectoryEntryCache[$DirectoryPath] = $DirectoryEntry

    } else {

        #Write-LogMsg @LogParams -Text "DirectoryEntryCache hit for '$DirectoryPath'"
        $DirectoryEntry = $DirectoryEntryCache[$DirectoryPath]

    }

    if ($PropertiesToLoad) {

        try {

            # If the $DirectoryPath was invalid, this line will return an error
            $null = $DirectoryEntry.RefreshCache($PropertiesToLoad)

        } catch {

            $LogParams['Type'] = 'Warning' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat

            # Ensure that the error message appears on 1 line
            # Use .Trim() to remove leading and trailing whitespace
            # Use -replace to remove an errant line break in the following specific error I encountered: The following exception occurred while retrieving member "RefreshCache": "The group name could not be found.`r`n"
            Write-LogMsg @LogParams -Text " # '$DirectoryPath' could not be retrieved. Error: $($_.Exception.Message.Trim().Replace('The following exception occurred while retrieving member "RefreshCache": ','').Replace('"',''))" # -replace '\s"',' "')"

            return

        }

    }

    return $DirectoryEntry

}
