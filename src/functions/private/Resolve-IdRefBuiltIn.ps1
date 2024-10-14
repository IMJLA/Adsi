function Resolve-IdRefBuiltIn {

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

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Log messages which have not yet been written to disk
        [hashtable]$LogBuffer = ([hashtable]::Synchronized(@{})),

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName)

    )

    $Log = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        Buffer       = $LogBuffer
        WhoAmI       = $WhoAmI
    }

    # Some built-in groups such as BUILTIN\Users and BUILTIN\Administrators are not in the CIM class or translatable with the NTAccount.Translate() method
    # But they may have real DirectoryEntry objects
    # Try to find the DirectoryEntry object locally on the server
    $DirectoryPath = "$($AdsiServer.AdsiProvider)`://$ServerNetBIOS/$Name"
    $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath @GetDirectoryEntryParams @LoggingParams
    $SIDString = (Add-SidInfo -InputObject $DirectoryEntry -DomainsBySid $DomainsBySid @LoggingParams).SidString
    $Caption = "$ServerNetBIOS\$Name"
    $DomainDns = $AdsiServer.Dns
    $DomainCacheResult = Get-AdsiServer -Fqdn $DomainDns -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LogThis

    # Update the caches
    $Win32Acct = [PSCustomObject]@{
        SID     = $SIDString
        Caption = $Caption
        Domain  = $ServerNetBIOS
        Name    = $Name
    }

    # Update the caches
    $DomainCacheResult.WellKnownSidBySid[$IdentityReference] = $Win32Acct
    $DomainCacheResult.WellKnownSidByName[$NameFromSplit] = $Win32Acct
    $DomainsByFqdn[$DomainCacheResult.Dns] = $DomainCacheResult
    $DomainsByNetbios[$DomainCacheResult.Netbios] = $DomainCacheResult
    $DomainsBySid[$DomainCacheResult.Sid] = $DomainCacheResult

    return [PSCustomObject]@{
        IdentityReference        = $IdentityReference
        SIDString                = $SIDString
        IdentityReferenceNetBios = $Caption
        IdentityReferenceDns     = "$DomainDns\$Name"
    }

}
