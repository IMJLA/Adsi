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

        Defaults to a thread-safe dictionary with string keys and object values
        #>
        [ref]$DirectoryEntryCache = ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()),

        <#
        Dictionary to cache known servers to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$AdsiServersByDns = [hashtable]::Synchronized(@{}),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [ref]$DomainsByNetbios = ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [ref]$DomainsBySid = ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [ref]$DomainsByFqdn = ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()),

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

    $KnownSid = Get-KnownSid -SID $IdentityReference

    if ($KnownSid) {

        #Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # Known SID pattern match"
        $NTAccount = $KnownSid.NTAccount
        $DomainNetBIOS = $ServerNetBIOS
        $DomainDns = ConvertTo-Fqdn -NetBIOS $DomainNetBIOS -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LogThis
        $DomainCacheResult = Get-AdsiServer -Fqdn $DomainDns -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LogThis

    } else {

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

    # Search the cache of domains, first by SID, then by NetBIOS name
    if (-not $DomainCacheResult) {
        $DomainCacheResult = $null
        $TryGetValueResult = $DomainsBySid.Value.TryGetValue($DomainSid, [ref]$DomainCacheResult)
    }

    if (-not $TryGetValueResult) {

        #Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # Domain SID cache miss for '$DomainSid'"
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
        $DomainDns = ConvertTo-Fqdn -NetBIOS $DomainNetBIOS -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LogThis
        $DomainCacheResult = Get-AdsiServer -Fqdn $DomainDns -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LogThis

    }

    if (-not $DomainCacheResult) {
        $DomainCacheResult = $AdsiServer
    }

    # Update the caches
    if ($Win32Acct) {
        $DomainCacheResult.WellKnownSidBySid[$IdentityReference] = $Win32Acct
        $DomainCacheResult.WellKnownSidByName[$NameFromSplit] = $Win32Acct
        $DomainsByFqdn.Value.AddOrUpdate( $DomainCacheResult.Dns, $DomainCacheResult, { param($key, $val) $val } )
        $DomainsByNetbios.Value.AddOrUpdate( $DomainCacheResult.Netbios, $DomainCacheResult, { param($key, $val) $val } )
        $DomainsBySid.Value.AddOrUpdate( $DomainCacheResult.Sid, $DomainCacheResult, { param($key, $val) $val } )
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
