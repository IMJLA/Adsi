function Resolve-IdRefCached {

    [OutputType([PSCustomObject])]
    param (

        # IdentityReference from an Access Control Entry
        # Expecting either a SID (S-1-5-18) or an NT account name (CONTOSO\User)
        [Parameter(Mandatory)]
        [string]$IdentityReference,

        # Object from Get-AdsiServer representing the directory server and its attributes
        [PSObject]$AdsiServer,

        # NetBIOS name of the ADSI server
        [string]$ServerNetBIOS = $AdsiServer.Netbios,

        # Name of the IdentityReference with the DOMAIN\ prefix removed
        [string]$Name,

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

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

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Output from Get-KnownSidHashTable
        [hashtable]$WellKnownSidBySid = (Get-KnownSidHashTable),

        # Output from Get-KnownCaptionHashTable
        [hashtable]$WellKnownSidByCaption = (Get-KnownCaptionHashTable -WellKnownSidBySid $WellKnownSidBySid)

    )

    $Log = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        Buffer       = $LogBuffer
        WhoAmI       = $WhoAmI
    }

    $ErrorActionPreference = $Stop
    try { $CacheResult = $CimCache[$ServerNetBIOS]['Win32_AccountBySID'][$IdentityReference] } catch { pause }

    if ($CacheResult) {

        #Write-LogMsg @Log -Text " # Win32_AccountBySID CIM instance cache hit for '$IdentityReference' on '$ServerNetBios'"

        return [PSCustomObject]@{
            IdentityReference        = $IdentityReference
            SIDString                = $CacheResult.SID
            IdentityReferenceNetBios = "$ServerNetBIOS\$($CacheResult.Name)"
            IdentityReferenceDns     = "$($AdsiServer.Dns)\$($CacheResult.Name)"
        }

    } else {
        Write-LogMsg @Log -Text " # Win32_AccountBySID CIM instance cache miss for '$IdentityReference' on '$ServerNetBIOS'"
    }

    $CacheResult = $WellKnownSidBySid[$IdentityReference]

    if ($CacheResult) {

        # IdentityReference is a well-known SID

        # Write-LogMsg @Log -Text " # Known SID cache hit for '$IdentityReference' on '$ServerNetBIOS'"
        $Name = $CacheResult['Name']
        $Caption = "$ServerNetBIOS\$Name"

        # Update the caches
        $Win32Acct = [PSCustomObject]@{
            SID     = $IdentityReference
            Caption = $Caption
            Domain  = $ServerNetBIOS
            Name    = $Name
        }

        Write-LogMsg @Log -Text " # Add '$Caption' to the 'Win32_AccountByCaption' cache for '$ServerNetBIOS'"
        $CimCache[$ServerNetBIOS]['Win32_AccountByCaption'][$Caption] = $Win32Acct

        Write-LogMsg @Log -Text " # Add '$IdentityReference' to the 'Win32_AccountBySID' cache for '$ServerNetBIOS'"
        $CimCache[$ServerNetBIOS]['Win32_AccountBySID'][$IdentityReference] = $Win32Acct

        return [PSCustomObject]@{
            IdentityReference        = $IdentityReference
            SIDString                = $IdentityReference
            IdentityReferenceNetBios = $Caption
            IdentityReferenceDns     = "$($AdsiServer.Dns)\$Name"
        }

    } else {
        Write-LogMsg @Log -Text " # Known SID cache miss for '$IdentityReference' on '$ServerNetBIOS'"
    }

    $CacheResult = $WellKnownSidByCaption[$IdentityReference]

    if ($CacheResult) {

        # IdentityReference is a well-known NT Account caption

        # Write-LogMsg @Log -Text " # Known NTAccount caption hit for '$IdentityReference' on '$ServerNetBIOS'"
        $Name = $CacheResult['Name']
        $Caption = "$ServerNetBIOS\$Name"

        # Update the caches
        $Win32Acct = [PSCustomObject]@{
            SID     = $CacheResult['SID']
            Caption = $Caption
            Domain  = $ServerNetBIOS
            Name    = $Name
        }

        Write-LogMsg @Log -Text " # Add '$Caption' to the 'Win32_AccountByCaption' cache for '$ServerNetBIOS'"
        $CimCache[$ServerNetBIOS]['Win32_AccountByCaption'][$Caption] = $Win32Acct

        Write-LogMsg @Log -Text " # Add '$IdentityReference' to the 'Win32_AccountBySID' cache for '$ServerNetBIOS'"
        $CimCache[$ServerNetBIOS]['Win32_AccountBySID'][$IdentityReference] = $Win32Acct

        return [PSCustomObject]@{
            IdentityReference        = $IdentityReference
            SIDString                = $CacheResult['SID']
            IdentityReferenceNetBios = $Caption
            IdentityReferenceDns     = "$($AdsiServer.Dns)\$Name"
        }

    } else {
        Write-LogMsg @Log -Text " # Known NTAccount caption cache miss for '$IdentityReference' on '$ServerNetBIOS'"
    }

    $CacheResult = Get-KnownSid -SID $IdentityReference

    if ($CacheResult['NTAccount'] -ne $CacheResult['SID']) {

        Write-LogMsg @Log -Text " # Capability SID pattern hit for '$IdentityReference' on '$ServerNetBIOS'"
        $Name = $CacheResult['Name']
        $Caption = "$ServerNetBIOS\$Name"

        # Update the caches
        $Win32Acct = [PSCustomObject]@{
            SID     = $CacheResult['SID']
            Caption = $Caption
            Domain  = $ServerNetBIOS
            Name    = $Name
        }

        Write-LogMsg @Log -Text " # Add '$Caption' to the 'Win32_AccountByCaption' cache for '$ServerNetBIOS'"
        $CimCache[$ServerNetBIOS]['Win32_AccountByCaption'][$Caption] = $Win32Acct

        Write-LogMsg @Log -Text " # Add '$IdentityReference' to the 'Win32_AccountBySID' cache for '$ServerNetBIOS'"
        $CimCache[$ServerNetBIOS]['Win32_AccountBySID'][$IdentityReference] = $Win32Acct

        return [PSCustomObject]@{
            IdentityReference        = $IdentityReference
            SIDString                = $CacheResult['SID']
            IdentityReferenceNetBios = $Caption
            IdentityReferenceDns     = "$($AdsiServer.Dns)\$($CacheResult['Name'])"
        }

    } else {
        Write-LogMsg @Log -Text " # Capability SID pattern miss for '$IdentityReference' on '$ServerNetBIOS'"
    }

    $LoggingParams = @{
        ThisHostname = $ThisHostname
        LogBuffer    = $LogBuffer
        WhoAmI       = $WhoAmI
    }

    if (-not [string]::IsNullOrEmpty($Name)) {

        # A Win32_Account's Caption property is a NetBIOS-resolved NTAccount caption / IdentityReference
        # NT Authority\SYSTEM would be SERVER123\SYSTEM as a Win32_Account on a server with hostname server123
        # This could also match on a domain account since those can be returned as Win32_Account, not sure if that will be a bug or what
        $CacheResult = $CimCache[$ServerNetBIOS]['Win32_AccountByCaption']["$ServerNetBIOS\$Name"]

        if ($CacheResult) {

            # Write-LogMsg @Log -Text " # Win32_AccountByCaption CIM instance cache hit for '$ServerNetBIOS\$Name' on '$ServerNetBIOS'"

            if ($ServerNetBIOS -eq $CacheResult.Domain) {
                $DomainDns = $AdsiServer.Dns
            }

            if (-not $DomainDns) {

                $DomainCacheResult = $DomainsByNetbios[$CacheResult.Domain]

                if ($DomainCacheResult) {

                    # Write-LogMsg @Log -Text " # Domain NetBIOS cache hit for '$($CacheResult.Domain)'"
                    $DomainDns = $DomainCacheResult.Dns

                } else {
                    Write-LogMsg @Log -Text " # Domain NetBIOS cache miss for '$($CacheResult.Domain)'"
                }

            }

            if (-not $DomainDns) {

                $DomainDns = ConvertTo-Fqdn -NetBIOS $ServerNetBIOS -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LoggingParams
                $DomainDn = $DomainsByNetbios[$ServerNetBIOS].DistinguishedName

            }

            return [PSCustomObject]@{
                IdentityReference        = $IdentityReference
                SIDString                = $CacheResult.SID
                IdentityReferenceNetBios = "$ServerNetBIOS\$($CacheResult.Name)"
                IdentityReferenceDns     = "$DomainDns\$($CacheResult.Name)"
            }

        } else {
            Write-LogMsg @Log -Text " # Win32_AccountByCaption CIM instance cache miss for '$ServerNetBIOS\$Name' on '$ServerNetBIOS'"
        }

    }

    $CacheResult = $CimCache[$ServerNetBIOS]['Win32_AccountByCaption']["$ServerNetBIOS\$IdentityReference"]

    if ($CacheResult) {

        # IdentityReference is an NT Account Name without a \, and has been cached from this server
        # Write-LogMsg @Log -Text " # Win32_AccountByCaption CIM instance cache hit for '$ServerNetBIOS\$IdentityReference' on '$ServerNetBIOS'"

        return [PSCustomObject]@{
            IdentityReference        = $IdentityReference
            SIDString                = $CacheResult.SID
            IdentityReferenceNetBios = "$ServerNetBIOS\$($CacheResult.Name)"
            IdentityReferenceDns     = "$($AdsiServer.Dns)\$($CacheResult.Name)"
        }

    } else {
        Write-LogMsg @Log -Text " # Win32_AccountByCaption CIM instance cache miss for '$ServerNetBIOS\$IdentityReference' on '$ServerNetBIOS'"
    }

}
