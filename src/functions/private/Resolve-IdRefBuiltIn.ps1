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

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $LogThis = @{ ThisHostname = $ThisHostname ; Cache = $Cache ; WhoAmI = $WhoAmI ; DebugOutputStream = $DebugOutputStream }

    # Some built-in groups such as BUILTIN\Users and BUILTIN\Administrators are not in the CIM class or translatable with the NTAccount.Translate() method
    # But they may have real DirectoryEntry objects
    # Try to find the DirectoryEntry object locally on the server
    $DirectoryPath = "$($AdsiServer.AdsiProvider)`://$ServerNetBIOS/$Name"

    if ($Name.Substring(0, 4) -eq 'S-1-') {

        $SIDString = $Name
        $Caption = $IdentityReference

    } else {

        $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath -ThisFqdn $ThisFqdn @LogThis
        $SIDString = (Add-SidInfo -InputObject $DirectoryEntry @LogThis).SidString
        $Caption = "$ServerNetBIOS\$Name"

    }

    $DomainDns = $AdsiServer.Dns
    $DomainCacheResult = Get-AdsiServer -Fqdn $DomainDns -ThisFqdn $ThisFqdn @LogThis

    # Update the caches
    $Win32Acct = [PSCustomObject]@{
        SID     = $SIDString
        Caption = $Caption
        Domain  = $ServerNetBIOS
        Name    = $Name
    }

    # Update the caches
    $DomainCacheResult.WellKnownSidBySid[$SIDString] = $Win32Acct
    $DomainCacheResult.WellKnownSidByName[$Name] = $Win32Acct
    $null = $Cache.Value['DomainByFqdn'].Value.AddOrUpdate( $DomainCacheResult.Dns, $DomainCacheResult, { param($key, $val) $val } )
    $null = $Cache.Value['DomainByNetbios'].Value.AddOrUpdate( $DomainCacheResult.Netbios, $DomainCacheResult, { param($key, $val) $val } )
    $null = $Cache.Value['DomainsBySid'].Value.AddOrUpdate( $DomainCacheResult.Sid, $DomainCacheResult, { param($key, $val) $val } )

    return [PSCustomObject]@{
        IdentityReference        = $IdentityReference
        SIDString                = $SIDString
        IdentityReferenceNetBios = $Caption
        IdentityReferenceDns     = "$DomainDns\$Name"
    }

}
