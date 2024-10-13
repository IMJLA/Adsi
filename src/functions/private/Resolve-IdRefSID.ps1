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
        [string]$DebugOutputStream = 'Debug'

    )

    $Log = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        Buffer       = $LogBuffer
        WhoAmI       = $WhoAmI
    }

    $LogThis = @{
        ThisHostname      = $ThisHostname
        DebugOutputStream = $DebugOutputStream
        LogBuffer         = $LogBuffer
        WhoAmI            = $WhoAmI
    }

    # The SID of the domain is everything up to (but not including) the last hyphen
    $DomainSid = $IdentityReference.Substring(0, $IdentityReference.LastIndexOf("-"))
    Write-LogMsg @Log -Text "[System.Security.Principal.SecurityIdentifier]::new('$IdentityReference').Translate([System.Security.Principal.NTAccount]) # For '$IdentityReference'"
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
        Write-LogMsg @Log -Text " # Unexpectedly could not translate SID to NTAccount using the [SecurityIdentifier]::Translate method: $($_.Exception.Message.Replace('Exception calling "Translate" with "1" argument(s): ','')) # For '$IdentityReference'"
        $Log['Type'] = $DebugOutputStream

    }

    Write-LogMsg @Log -Text " # Translated NTAccount name is '$NTAccount' # For '$IdentityReference'"

    # Search the cache of domains, first by SID, then by NetBIOS name
    $DomainCacheResult = $DomainsBySID[$DomainSid]

    if ($DomainCacheResult) {
        # Write-LogMsg @Log -Text " # Domain SID cache hit for '$DomainSid' # For '$IdentityReference'"
    } else {

        #Write-LogMsg @Log -Text " # Domain SID cache miss for '$DomainSid' # For '$IdentityReference'"
        $split = $NTAccount -split '\\'
        $DomainFromSplit = $split[0]

        if (

            $DomainFromSplit.Contains(' ') -or
            $DomainFromSplit.Contains('BUILTIN\')

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

            #Write-LogMsg @Log -Text " # Add '$Caption' to the 'Win32_AccountByCaption' cache for '$ServerNetBIOS' # For '$IdentityReference'"
            #$CimCache[$ServerNetBIOS]['Win32_AccountByCaption'][$Caption] = $Win32Acct

            #Write-LogMsg @Log -Text " # Add '$IdentityReference' to the 'Win32_AccountBySID' cache for '$ServerNetBIOS' # For '$IdentityReference'"
            #$CimCache[$ServerNetBIOS]['Win32_AccountBySID'][$IdentityReference] = $Win32Acct

        } else {
            $DomainNetBIOS = $DomainFromSplit
        }

    }

    if ($DomainCacheResult) {

        $DomainNetBIOS = $DomainCacheResult.Netbios
        $DomainDns = $DomainCacheResult.Dns

    } else {

        Write-LogMsg @Log -Text " # Domain SID '$DomainSid' is unknown. Domain NetBIOS is '$DomainNetBIOS' # For '$IdentityReference'"
        $DomainDns = ConvertTo-Fqdn -NetBIOS $DomainNetBIOS -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LogThis
        $DomainCacheResult = Get-AdsiServer -Fqdn $DomainDns -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LogThis

    }

    if (-not $DomainCacheResult) {
        $DomainCacheResult = $AdsiServer
    }

    if ($Win32Acct) {
        # Update the caches
        $DomainCacheResult.WellKnownSidBySid[$IdentityReference] = $Win32Acct
        $DomainCacheResult.WellKnownSidByName[$NameFromSplit] = $Win32Acct
        $DomainsByFqdn[$DomainCacheResult.Dns] = $DomainCacheResult
        $DomainsByNetbios[$DomainCacheResult.Netbios] = $DomainCacheResult
        $DomainsBySid[$DomainCacheResult.Sid] = $DomainCacheResult
    }

    if ($NTAccount) {

        # Recursively call this function to resolve the new IdentityReference we have
        $ResolveIdentityReferenceParams = @{
            IdentityReference   = $NTAccount
            AdsiServer          = $DomainCacheResult
            AdsiServersByDns    = $AdsiServersByDns
            DirectoryEntryCache = $DirectoryEntryCache
            DomainsBySID        = $DomainsBySID
            DomainsByNetbios    = $DomainsByNetbios
            DomainsByFqdn       = $DomainsByFqdn
            ThisHostName        = $ThisHostName
            ThisFqdn            = $ThisFqdn
            LogBuffer           = $LogBuffer
            CimCache            = $CimCache
            WhoAmI              = $WhoAmI
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
