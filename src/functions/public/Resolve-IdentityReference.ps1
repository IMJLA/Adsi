function Resolve-IdentityReference {

    <#
    .SYNOPSIS
    Use ADSI to lookup info about IdentityReferences from Access Control Entries that came from Discretionary Access Control Lists
    .DESCRIPTION
    Based on the IdentityReference proprety of each Access Control Entry:
    Resolve SID to NT account name and vise-versa
    Resolve well-known SIDs
    Resolve generic defaults like 'NT AUTHORITY' and 'BUILTIN' to the applicable computer or domain name
    .INPUTS
    None. Pipeline input is not accepted.
    .OUTPUTS
    [PSCustomObject] with IdentityReferenceNetBios,IdentityReferenceDns, and SIDString properties (each strings)
    .EXAMPLE
    Resolve-IdentityReference -IdentityReference 'BUILTIN\Administrator' -AdsiServer (Get-AdsiServer 'localhost')

    Get information about the local Administrator account
    #>

    [OutputType([PSCustomObject])]
    param (

        # IdentityReference from an Access Control Entry
        # Expecting either a SID (S-1-5-18) or an NT account name (CONTOSO\User)
        [Parameter(Mandatory)]
        [string]$IdentityReference,

        # Object from Get-AdsiServer representing the directory server and its attributes
        [PSObject]$AdsiServer,

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache known servers to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$AdsiServersByDns = [hashtable]::Synchronized(@{}),

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

    $LogParams = @{
        ThisHostname = $ThisHostname
        LogBuffer    = $LogBuffer
        WhoAmI       = $WhoAmI
    }

    # Many Well-Known SIDs cannot be translated with the Translate method
    # Instead Get-AdsiServer used CIM to find instances of the Win32_Account class on the server
    # and update the Win32_AccountBySID and Win32_AccountByCaption caches
    # and Get-KnownSidHashTable and Get-KnownSID are hard-coded with additional well-known SIDs
    # Search the caches now

    $ServerNetBIOS = $AdsiServer.Netbios
    $split = $IdentityReference.Split('\')
    $Name = $split[1]
    $splat2a = @{ WellKnownSidBySid = $WellKnownSidBySid ; WellKnownSidByCaption = $WellKnownSidByCaption }
    $splat4a = @{ DomainsByFqdn = $DomainsByFqdn }
    $splat5b = @{ AdsiServer = $AdsiServer; ServerNetBIOS = $ServerNetBIOS }
    $splat5d = @{ Name = $Name }
    $splat5c = @{ DirectoryEntryCache = $DirectoryEntryCache; DomainsByNetbios = $DomainsByNetbios; ThisFqdn = $ThisFqdn }
    $splat5a = @{ DebugOutputStream = $DebugOutputStream }
    $splat7a = @{ DomainsBySid = $DomainsBySid }
    $splat6a = @{ CimCache = $CimCache; IdentityReference = $IdentityReference }
    $splat2b = @{ LogParams = $LogParams }
    $GetDirectoryEntryParams = @{ DirectoryEntryCache = $DirectoryEntryCache; DomainsByNetbios = $DomainsByNetbios; DomainsBySid = $DomainsBySid }
    $splat2c = @{ GetDirectoryEntryParams = $GetDirectoryEntryParams }

    $CacheResult = Resolve-IdRefCached @splat2a @LogParams @splat4a @splat5b @splat5d @splat5c @splat6a @splat7a @splat5a
    if ($CacheResult) { return $CacheResult }

    # If no match was found in any cache, the path forward depends on the IdentityReference
    switch -Wildcard ($IdentityReference) {

        "S-1-*" {
            $Resolved = Resolve-IdRefSID -AdsiServersByDns $AdsiServersByDns @splat4a @splat5b @splat5c @splat6a @splat7a @splat5a @LogParams
            return $Resolved
        }

        "NT SERVICE\*" {
            $Resolved = Resolve-IdRefSvc @splat4a @splat5b @splat5d @splat5c @splat6a @splat7a @splat5a @LogParams
            return $Resolved
        }

        "APPLICATION PACKAGE AUTHORITY\*" {
            $Resolved = Resolve-IdRefAppPkg @splat2a @splat5d @splat5c @splat6a @splat7a @splat4a @splat5b
            return $Resolved
        }

        "BUILTIN\*" {
            $Resolved = Resolve-IdRefBuiltIn @splat2c @splat5b @splat5a@splat6a @splat7a @splat5d @LogParams
            return $Resolved
        }

    }

    # The IdentityReference is an NTAccount
    # Translate NTAccount to SID

    if ($ServerNetBIOS) {

        # Start by determining the domain DN and DNS name
        $DomainNetBIOSCacheResult = $DomainsByNetbios[$ServerNetBIOS]

        if ($DomainNetBIOSCacheResult) {
            # Write-LogMsg @Log -Text " # Domain NetBIOS cache hit for '$($ServerNetBIOS)'."
        } else {

            Write-LogMsg @Log -Text " # Domain NetBIOS cache miss for '$($ServerNetBIOS)'."
            $DomainNetBIOSCacheResult = Get-AdsiServer -Netbios $ServerNetBIOS -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LogParams
            $DomainsByNetbios[$ServerNetBIOS] = $ServerNetBIOSCacheResult

        }

        $DomainDn = $DomainNetBIOSCacheResult.DistinguishedName
        $DomainDns = $DomainNetBIOSCacheResult.Dns

        # Try to resolve the account against the server the Access Control Entry came from (which may or may not be the directory server for the account)
        $SIDString = ConvertTo-SidString -ServerNetBIOS $ServerNetBIOS -Name $Name -DebugOutputStream $DebugOutputStream -Log $Log

        if (-not $SIDString) {

            # Try to resolve the account against the domain indicated in its NT Account Name
            # Add this domain to our list of known domains
            $SIDString = Resolve-IdRefSearchDir -DomainDn $DomainDn -Log $Log @splat2b @Cached_Search_Svc @splat5c @splat6a @splat7a @splat5a @splat5d

        }

        if (-not $SIDString) {

            # Try to find the DirectoryEntry object directly on the server
            $SIDString = Resolve-IdRefGetDirEntry @splat2b @splat2c @splat5b @splat5d @splat7a

        }

        # This covers unresolved SIDs for deleted accounts, broken domain trusts, etc.
        if ( '' -eq "$Name" ) {

            $Name = $IdentityReference
            Write-LogMsg @Log -Text " # No name could be parsed for '$IdentityReference'"

        } else {
            Write-LogMsg @Log -Text " # Name parsed is '$Name' for '$IdentityReference'"
        }

        return [PSCustomObject]@{
            IdentityReference        = $IdentityReference
            SIDString                = $SIDString
            IdentityReferenceNetBios = "$ServerNetBIOS\$Name" #-replace "^$ThisHostname\\", "$ThisHostname\" # to correct capitalization in a PS5-friendly way
            IdentityReferenceDns     = "$DomainDns\$Name"
        }

    }

}
