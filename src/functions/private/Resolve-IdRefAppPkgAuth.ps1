function Resolve-IdRefAppPkgAuth {

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
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output from Get-KnownSidHashTable
        [hashtable]$WellKnownSidBySid = (Get-KnownSidHashTable),

        # Output from Get-KnownCaptionHashTable
        [hashtable]$WellKnownSidByCaption = (Get-KnownCaptionHashTable -WellKnownSidBySid $WellKnownSidBySid)

    )

    <#
    These SIDs cannot be resolved from the NTAccount name:
        PS C:> [System.Security.Principal.SecurityIdentifier]::new('S-1-15-2-1').Translate([System.Security.Principal.NTAccount]).Translate([System.Security.Principal.SecurityIdentifier])
        MethodInvocationException: Exception calling "Translate" with "1" argument(s): "Some or all identity references could not be translated."

    Even though resolving the reverse direction works:
        PS C:> [System.Security.Principal.SecurityIdentifier]::new('S-1-15-2-1').Translate([System.Security.Principal.NTAccount])

        Value
        -----
        APPLICATION PACKAGE AUTHORITY\ALL APPLICATION PACKAGES
    So we will instead hardcode a map of SIDs
    #>
    $Known = $WellKnownSidByCaption[$IdentityReference]

    if ($Known) {
        $SIDString = $Known['SID']
    } else {
        $SIDString = $IdentityReference
    }

    $Caption = "$ServerNetBIOS\$Name"

    $DomainCacheResult = $DomainsByNetbios[$ServerNetBIOS]

    if ($DomainCacheResult) {
        $DomainDns = $DomainCacheResult.Dns
    }

    if (-not $DomainDns) {
        $DomainDns = ConvertTo-Fqdn -NetBIOS $ServerNetBIOS -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LoggingParams
    }

    # Update the caches
    $Win32Acct = [PSCustomObject]@{
        SID     = $SIDString
        Caption = $Caption
        Domain  = $ServerNetBIOS
        Name    = $Name
    }

    Write-LogMsg @LogParams -Text " # Add '$Caption' to the 'Win32_AccountByCaption' cache for '$ServerNetBIOS'"
    $CimCache[$ServerNetBIOS]['Win32_AccountByCaption'][$Caption] = $Win32Acct
    Write-LogMsg @LogParams -Text " # Add '$SIDString' to the 'Win32_AccountBySID' cache for '$ServerNetBIOS'"
    $CimCache[$ServerNetBIOS]['Win32_AccountBySID'][$SIDString] = $Win32Acct

    return [PSCustomObject]@{
        IdentityReference        = $IdentityReference
        SIDString                = $SIDString
        IdentityReferenceNetBios = $Caption
        IdentityReferenceDns     = "$DomainDns\$Name"
    }

}
