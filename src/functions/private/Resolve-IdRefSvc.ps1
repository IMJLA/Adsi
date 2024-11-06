function Resolve-IdRefSvc {

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

        Defaults to a thread-safe dictionary with string keys and object values
        #>
        [ref]$DirectoryEntryCache = ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [Parameter(Mandatory)]
        [ref]$DomainsByNetbios,

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [Parameter(Mandatory)]
        [ref]$DomainsBySid,

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [Parameter(Mandatory)]
        [ref]$DomainsByFqdn,

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
        [Parameter(Mandatory)]
        [ref]$LogBuffer,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug'

    )

    $Log = @{ ThisHostname = $ThisHostname ; Type = $DebugOutputStream ; Buffer = $LogBuffer ; WhoAmI = $WhoAmI }
    $LogThis = @{ ThisHostname = $ThisHostname ; LogBuffer = $LogBuffer ; WhoAmI = $WhoAmI ; DebugOutputStream = $DebugOutputStream }
    $SIDString = ConvertTo-ServiceSID -ServiceName $Name
    $Caption = "$ServerNetBIOS\$Name"
    $DomainCacheResult = $null
    $TryGetValueResult = $DomainsByNetbios.Value.TryGetValue($ServerNetBIOS, [ref]$DomainCacheResult)

    if ($TryGetValueResult) {
        $DomainDns = $DomainCacheResult.Dns
    } else {

        Write-LogMsg @Log -Text " # Domain NetBIOS cache miss for '$ServerNetBIOS' # For '$IdentityReference'"
        $DomainDns = ConvertTo-Fqdn -NetBIOS $ServerNetBIOS -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LogThis
        $DomainCacheResult = Get-AdsiServer -Fqdn $DomainDns -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LogThis

    }

    # Update the caches
    $Win32Svc = [PSCustomObject]@{
        SID     = $SIDString
        Caption = $Caption
        Domain  = $ServerNetBIOS
        Name    = $Name
    }

    # Update the caches
    $DomainCacheResult.WellKnownSidBySid[$SIDString] = $Win32Svc
    $DomainCacheResult.WellKnownSidByName[$Name] = $Win32Svc
    $DomainsByFqdn.Value.AddOrUpdate( $DomainCacheResult.Dns, $DomainCacheResult, { param($key, $val) $val } )
    $DomainsByNetbios.Value.AddOrUpdate( $DomainCacheResult.Netbios, $DomainCacheResult, { param($key, $val) $val } )
    $DomainsBySid.Value.AddOrUpdate( $DomainCacheResult.Sid, $DomainCacheResult, { param($key, $val) $val } )

    return [PSCustomObject]@{
        IdentityReference        = $IdentityReference
        SIDString                = $SIDString
        IdentityReferenceNetBios = $Caption
        IdentityReferenceDns     = "$DomainDns\$Name"
    }

}
