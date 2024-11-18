function Resolve-IdRefSID {

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

        <#
        Dictionary to cache known servers to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$AdsiServersByDns = [hashtable]::Synchronized(@{}),

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

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $Log = @{ ThisHostname = $ThisHostname ; Type = $DebugOutputStream ; Buffer = $Cache.Value['LogBuffer'] ; WhoAmI = $WhoAmI }
    $LogThis = @{ ThisHostname = $ThisHostname ; Cache = $Cache ; WhoAmI = $WhoAmI ; DebugOutputStream = $DebugOutputStream }
    $CachedWellKnownSID = Find-CachedWellKnownSID -IdentityReference $IdentityReference -DomainNetBIOS $ServerNetBIOS -DomainByNetbios $Cache.Value['DomainByNetbios']
    $KnownSid = Get-KnownSid -SID $IdentityReference

    if ($CachedWellKnownSID) {

        #Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # Well-known SID match"
        $NTAccount = $CachedWellKnownSID.IdentityReferenceNetBios
        $DomainNetBIOS = $ServerNetBIOS
        $DomainDns = ConvertTo-Fqdn -NetBIOS $DomainNetBIOS -ThisFqdn $ThisFqdn @LogThis
        $DomainCacheResult = Get-AdsiServer -Fqdn $DomainDns -ThisFqdn $ThisFqdn @LogThis
        $done = $true

    } else {
        $KnownSid = Get-KnownSid -SID $IdentityReference
    }

    if ($KnownSid) {

        #Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # Known SID pattern match"
        $NTAccount = $KnownSid.NTAccount
        $DomainNetBIOS = $ServerNetBIOS
        $DomainDns = ConvertTo-Fqdn -NetBIOS $DomainNetBIOS -ThisFqdn $ThisFqdn @LogThis
        $DomainCacheResult = Get-AdsiServer -Fqdn $DomainDns -ThisFqdn $ThisFqdn @LogThis
        $done = $true

    }

    if (-not $done) {

        #Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # No match with known SID patterns"
        # The SID of the domain is everything up to (but not including) the last hyphen
        $DomainSid = $IdentityReference.Substring(0, $IdentityReference.LastIndexOf('-'))
        Write-LogMsg @Log -Text "[System.Security.Principal.SecurityIdentifier]::new('$IdentityReference').Translate([System.Security.Principal.NTAccount])"
        $SecurityIdentifier = [System.Security.Principal.SecurityIdentifier]::new($IdentityReference)

        try {

            <#
                This .Net method makes it impossible to redirect the error stream directly
                Wrapping it in a scriptblock (which is then executed with &) fixes the problem
                I don't understand exactly why
                The scriptblock will evaluate null if the SID cannot be translated, and the error stream redirection supresses the error (except in the transcript which catches it)
            #>
            $NTAccount = & { $SecurityIdentifier.Translate([System.Security.Principal.NTAccount]).Value } 2>$null

        } catch {

            $Log['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
            Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # Unexpectedly could not translate SID to NTAccount using the [SecurityIdentifier]::Translate method: $($_.Exception.Message.Replace('Exception calling "Translate" with "1" argument(s): ',''))"
            $Log['Type'] = $DebugOutputStream

        }

    }

    #Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # Translated NTAccount caption is '$NTAccount'"
    $DomainsBySid = $Cache.Value['DomainBySid']

    # Search the cache of domains, first by SID, then by NetBIOS name
    if (-not $DomainCacheResult) {
        $DomainCacheResult = $null
        $TryGetValueResult = $DomainsBySid.Value.TryGetValue($DomainSid, [ref]$DomainCacheResult)
    }

    $DomainsByNetbios = $Cache.Value['DomainByNetbios']

    if (-not $TryGetValueResult) {

        #Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # Domain SID cache miss for '$DomainSid'"
        $split = $NTAccount -split '\\'
        $DomainFromSplit = $split[0]

        if (

            $DomainFromSplit.Contains(' ') -or
            $DomainFromSplit -eq 'BUILTIN'

        ) {

            $NameFromSplit = $split[1]
            $DomainNetBIOS = $ServerNetBIOS
            $Caption = "$ServerNetBIOS\$NameFromSplit"

            # This will be used to update the caches
            $Win32Acct = [PSCustomObject]@{
                SID     = $IdentityReference
                Caption = $Caption
                Domain  = $ServerNetBIOS
                Name    = $NameFromSplit
            }

        } else {
            $DomainNetBIOS = $DomainFromSplit
        }

        $DomainCacheResult = $null
        $TryGetValueResult = $DomainsByNetbios.Value.TryGetValue($DomainNetBIOS, [ref]$DomainCacheResult)

    }

    if ($DomainCacheResult) {

        $DomainNetBIOS = $DomainCacheResult.Netbios
        $DomainDns = $DomainCacheResult.Dns

    } else {

        #Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # Domain SID '$DomainSid' is unknown. Domain NetBIOS is '$DomainNetBIOS'"
        $DomainDns = ConvertTo-Fqdn -NetBIOS $DomainNetBIOS -ThisFqdn $ThisFqdn @LogThis
        $DomainCacheResult = Get-AdsiServer -Fqdn $DomainDns -ThisFqdn $ThisFqdn @LogThis

    }

    if (-not $DomainCacheResult) {
        $DomainCacheResult = $AdsiServer
    }

    # Update the caches
    if ($Win32Acct) {
        $DomainCacheResult.WellKnownSidBySid[$IdentityReference] = $Win32Acct
        $DomainCacheResult.WellKnownSidByName[$NameFromSplit] = $Win32Acct
        $AddOrUpdateScriptblock = { param($key, $val) $val }
        $null = $Cache.Value['DomainByFqdn'].Value.AddOrUpdate( $DomainCacheResult.Dns, $DomainCacheResult, $AddOrUpdateScriptblock )
        $null = $DomainsByNetbios.Value.AddOrUpdate( $DomainCacheResult.Netbios, $DomainCacheResult, $AddOrUpdateScriptblock )
        $null = $DomainsBySid.Value.AddOrUpdate( $DomainCacheResult.Sid, $DomainCacheResult, $AddOrUpdateScriptblock )
    }

    if ($NTAccount) {

        # Recursively call this function to resolve the new IdentityReference we have
        $ResolveIdentityReferenceParams = @{
            Cache             = $Cache
            IdentityReference = $NTAccount
            AdsiServer        = $DomainCacheResult
            AdsiServersByDns  = $AdsiServersByDns
            ThisHostName      = $ThisHostName
            ThisFqdn          = $ThisFqdn
            WhoAmI            = $WhoAmI
        }

        $Resolved = Resolve-IdentityReference @ResolveIdentityReferenceParams

    } else {

        $Resolved = [PSCustomObject]@{
            IdentityReference        = $IdentityReference
            SIDString                = $IdentityReference
            IdentityReferenceNetBios = "$DomainNetBIOS\$IdentityReference"
            IdentityReferenceDns     = "$DomainDns\$IdentityReference"
        }

    }

    return $Resolved

}
