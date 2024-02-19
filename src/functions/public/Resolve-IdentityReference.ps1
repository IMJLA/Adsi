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

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug'

    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    $LoggingParams = @{
        ThisHostname = $ThisHostname
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    $GetDirectoryEntryParams = @{
        DirectoryEntryCache = $DirectoryEntryCache
        DomainsByNetbios    = $DomainsByNetbios
        DomainsBySid        = $DomainsBySid
    }

    $ServerNetBIOS = $AdsiServer.Netbios

    # Many Well-Known SIDs cannot be translated with the Translate method
    # Instead we have used CIM to collect information on instances of the Win32_Account class from the AdsiServer
    # This has been done by Get-AdsiServer and it updated the Win32_AccountBySID and Win32_AccountByCaption caches
    # Search the caches now
    $CacheResult = $CimCache[$ServerNetBIOS]['Win32_AccountBySID']["$ServerNetBIOS\$IdentityReference"]

    if ($CacheResult) {

        Write-LogMsg @LogParams -Text " # Win32_Account SID cache hit for '$ServerNetBIOS\$IdentityReference'"

        return [PSCustomObject]@{
            IdentityReference        = $IdentityReference
            SIDString                = $CacheResult.SID
            IdentityReferenceNetBios = $CacheResult.Caption -replace "^$ThisHostname\\", "$ThisHostname\" # required for ps 5.1 support
            #IdentityReferenceNetBios = $CacheResult.Caption.Replace("$ThisHostname\","$ThisHostname\",[System.StringComparison]::CurrentCultureIgnoreCase) # PS 7 more efficient
            IdentityReferenceDns     = "$($AdsiServer.Dns)\$($CacheResult.Name)"
        }

    } else {
        Write-LogMsg @LogParams -Text " # Win32_Account SID cache miss for '$ServerNetBIOS\$IdentityReference'"
    }

    $split = $IdentityReference.Split('\')
    $DomainNetBIOS = $ServerNetBIOS
    $Name = $split[1]

    if ($Name) {

        # A Win32_Account's Caption property is a NetBIOS-resolved IdentityReference
        # NT Authority\SYSTEM would be SERVER123\SYSTEM as a Win32_Account on a server with hostname server123
        # This could also match on a domain account since those can be returned as Win32_Account, not sure if that will be a bug or what
        $CacheResult = $CimCache[$ServerNetBIOS]['Win32_AccountByCaption']["$ServerNetBIOS\$Name"]

        if ($CacheResult) {

            Write-LogMsg @LogParams -Text " # Win32_Account caption cache hit for '$ServerNetBIOS\$ServerNetBIOS\$Name'"

            if ($ServerNetBIOS -eq $CacheResult.Domain) {
                $DomainDns = $AdsiServer.Dns
            }
            if (-not $DomainDns) {

                $DomainCacheResult = $DomainsByNetbios[$CacheResult.Domain]

                if ($DomainCacheResult) {
                    $DomainDns = $DomainCacheResult.Dns
                }

            }
            if (-not $DomainDns) {

                $DomainDns = ConvertTo-Fqdn -NetBIOS $DomainNetBIOS -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LoggingParams
                $DomainDn = $DomainsByNetbios[$DomainNetBIOS].DistinguishedName

            }

            return [PSCustomObject]@{
                IdentityReference        = $IdentityReference
                SIDString                = $CacheResult.SID
                IdentityReferenceNetBios = $CacheResult.Caption -replace "^$ThisHostname\\", "$ThisHostname\" # required for ps 5.1 support
                # PS 7 more efficient IdentityReferenceNetBios    = $CacheResult.Caption.Replace("$ThisHostname\","$ThisHostname\",[System.StringComparison]::CurrentCultureIgnoreCase)
                IdentityReferenceDns     = "$DomainDns\$($CacheResult.Name)"
            }

        } else {
            Write-LogMsg @LogParams -Text " # Win32_Account caption cache miss for '$ServerNetBIOS\$ServerNetBIOS\$Name'"
        }

    }

    $CacheResult = $CimCache[$ServerNetBIOS]['Win32_AccountByCaption']["$ServerNetBIOS\$IdentityReference"]

    if ($CacheResult) {

        # IdentityReference is an NT Account Name without a \, and has been cached from this server
        Write-LogMsg @LogParams -Text " # Win32_Account caption cache hit for '$ServerNetBIOS\$IdentityReference'"

        return [PSCustomObject]@{
            IdentityReference        = $IdentityReference
            SIDString                = $CacheResult.SID
            IdentityReferenceNetBios = $CacheResult.Caption -replace "^$ThisHostname\\", "$ThisHostname\" # required for ps 5.1 support
            # PS 7 more efficient IdentityReferenceNetBios    = $CacheResult.Caption.Replace("$ThisHostname\","$ThisHostname\",[System.StringComparison]::CurrentCultureIgnoreCase)
            IdentityReferenceDns     = "$($AdsiServer.Dns)\$($CacheResult.Name)"
        }

    } else {
        Write-LogMsg @LogParams -Text " # Win32_Account caption cache miss for '$ServerNetBIOS\$IdentityReference'"
    }

    # If no match was found in any cache, the path forward depends on the IdentityReference
    switch -Wildcard ($IdentityReference) {

        "S-1-*" {

            # IdentityReference is a Revision 1 SID

            <#
            Use the SecurityIdentifier.Translate() method to translate the SID to an NT Account name
                This .Net method makes it impossible to redirect the error stream directly
                Wrapping it in a scriptblock (which is then executed with &) fixes the problem
                I don't understand exactly why
                The scriptblock will evaluate null if the SID cannot be translated, and the error stream redirection supresses the error (except in the transcript which catches it)
            #>
            Write-LogMsg @LogParams -Text "[System.Security.Principal.SecurityIdentifier]::new('$IdentityReference').Translate([System.Security.Principal.NTAccount])"
            $SecurityIdentifier = [System.Security.Principal.SecurityIdentifier]::new($IdentityReference)
            $NTAccount = & { $SecurityIdentifier.Translate([System.Security.Principal.NTAccount]).Value } 2>$null
            Write-LogMsg @LogParams -Text " # Translated NTAccount name for '$IdentityReference' is '$NTAccount'"

            # The SID of the domain is everything up to (but not including) the last hyphen
            $DomainSid = $IdentityReference.Substring(0, $IdentityReference.LastIndexOf("-"))

            # Search the cache of domains, first by SID, then by NetBIOS name
            $DomainCacheResult = $DomainsBySID[$DomainSid]

            if ($DomainCacheResult) {
                Write-LogMsg @LogParams -Text " # Domain SID cache hit for '$DomainSid'"
            } else {

                Write-LogMsg @LogParams -Text " # Domain SID cache miss for '$DomainSid'"
                $split = $NTAccount -split '\\'
                $DomainFromSplit = $split[0]

                if (

                    $DomainFromSplit.Contains(' ') -or
                    $DomainFromSplit.Contains('BUILTIN\')

                ) {

                    $NameFromSplit = $split[1]
                    $DomainNetBIOS = $ServerNetBIOS
                    $Caption = "$ServerNetBIOS\$NameFromSplit"

                    # Update the caches
                    $Win32Acct = [PSCustomObject]@{
                        SID     = $IdentityReference
                        Caption = $Caption
                        Domain  = $ServerNetBIOS
                        Name    = $NameFromSplit
                    }

                    Write-LogMsg @LogParams -Text " # Add '$Caption' to the Win32_Account caption cache"
                    $CimCache[$ServerNetBIOS]['Win32_AccountByCaption'][$Caption] = $Win32Acct
                    Write-LogMsg @LogParams -Text " # Add '$ServerNetBIOS\$IdentityReference' to the Win32_Account SID cache"
                    $CimCache[$ServerNetBIOS]['Win32_AccountBySID']["$ServerNetBIOS\$IdentityReference"] = $Win32Acct

                } else {
                    $DomainNetBIOS = $DomainFromSplit
                }

                $DomainCacheResult = $DomainsByNetbios[$split[0]]

            }

            if ($DomainCacheResult) {

                $DomainNetBIOS = $DomainCacheResult.Netbios
                $DomainDns = $DomainCacheResult.Dns

            } else {

                Write-LogMsg @LogParams -Text " # Domain SID '$DomainSid' is unknown. Domain NetBIOS is '$DomainNetBIOS'"
                $DomainDns = ConvertTo-Fqdn -NetBIOS $DomainNetBIOS -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LoggingParams

            }

            $AdsiServer = Get-AdsiServer -Fqdn $DomainDns -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LoggingParams

            if ($NTAccount) {

                # Recursively call this function to resolve the new IdentityReference we have
                $ResolveIdentityReferenceParams = @{
                    IdentityReference   = $NTAccount
                    AdsiServer          = $AdsiServer
                    AdsiServersByDns    = $AdsiServersByDns
                    DirectoryEntryCache = $DirectoryEntryCache
                    DomainsBySID        = $DomainsBySID
                    DomainsByNetbios    = $DomainsByNetbios
                    DomainsByFqdn       = $DomainsByFqdn
                    ThisHostName        = $ThisHostName
                    ThisFqdn            = $ThisFqdn
                    LogMsgCache         = $LogMsgCache
                    CimCache            = $CimCache
                    WhoAmI              = $WhoAmI
                }

                $Resolved = Resolve-IdentityReference @ResolveIdentityReferenceParams

            } else {

                $Resolved = [PSCustomObject]@{
                    IdentityReference        = $IdentityReference
                    SIDString                = $IdentityReference
                    IdentityReferenceNetBios = $CacheResult.Caption -replace "^$ThisHostname\\", "$ThisHostname\" # required for ps 5.1 support
                    #IdentityReferenceNetBios    = $CacheResult.Caption.Replace("$ThisHostname\","$ThisHostname\",[System.StringComparison]::CurrentCultureIgnoreCase) # PS 7 more efficient
                    IdentityReferenceDns     = "$DomainDns\$IdentityReference"
                }

            }

            return $Resolved

        }
        "NT SERVICE\*" {
            # Some of them are services (yes services can have SIDs, notably this includes TrustedInstaller but it is also common with SQL)
            if ($ServerNetBIOS -eq $ThisHostName) {
                Write-LogMsg @LogParams -Text "sc.exe showsid $Name"
                [string[]]$ScResult = & sc.exe showsid $Name
            } else {
                Write-LogMsg @LogParams -Text "Invoke-Command -ComputerName $ServerNetBIOS -ScriptBlock { & sc.exe showsid `$args[0] } -ArgumentList $Name"
                [string[]]$ScResult = Invoke-Command -ComputerName $ServerNetBIOS -ScriptBlock { & sc.exe showsid $args[0] } -ArgumentList $Name
            }
            $ScResultProps = @{}

            $ScResult |
            ForEach-Object {
                $Prop, $Value = ($_ -split ':').Trim()
                $ScResultProps[$Prop] = $Value
            }

            $SIDString = $ScResultProps['SERVICE SID']
            $Caption = $IdentityReference -replace 'NT SERVICE', $ServerNetBIOS -replace "^$ThisHostname\\", "$ThisHostname\"

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

            Write-LogMsg @LogParams -Text " # Add '$Caption' to the Win32_Account caption cache"
            $CimCache[$ServerNetBIOS]['Win32_AccountByCaption'][$Caption] = $Win32Acct
            Write-LogMsg @LogParams -Text " # Add '$ServerNetBIOS\$SIDString' to the Win32_Account SID cache"
            $CimCache[$ServerNetBIOS]['Win32_AccountBySID']["$ServerNetBIOS\$SIDString"] = $Win32Acct

            return [PSCustomObject]@{
                IdentityReference        = $IdentityReference
                SIDString                = $SIDString
                IdentityReferenceNetBios = $Caption
                IdentityReferenceDns     = "$DomainDns\$Name"
            }
        }
        "APPLICATION PACKAGE AUTHORITY\*" {

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
            $KnownSIDs = @{ # https://learn.microsoft.com/en-us/windows/win32/secauthz/app-container-sid-constants
                'APPLICATION PACKAGE AUTHORITY\ALL APPLICATION PACKAGES'                                                   = 'S-1-15-2-1'
                'APPLICATION PACKAGE AUTHORITY\ALL RESTRICTED APPLICATION PACKAGES'                                        = 'S-1-15-2-2'

                # Capability SIDs introduced in Windows 8 https://learn.microsoft.com/en-us/windows/win32/secauthz/capability-sid-constants
                'APPLICATION PACKAGE AUTHORITY\Your Internet connection'                                                   = 'S-1-15-3-1'
                'APPLICATION PACKAGE AUTHORITY\Your Internet connection, including incoming connections from the Internet' = 'S-1-15-3-2'
                'APPLICATION PACKAGE AUTHORITY\Your home or work networks'                                                 = 'S-1-15-3-3'
                'APPLICATION PACKAGE AUTHORITY\Your pictures library'                                                      = 'S-1-15-3-4'
                'APPLICATION PACKAGE AUTHORITY\Your videos library'                                                        = 'S-1-15-3-5'
                'APPLICATION PACKAGE AUTHORITY\Your music library'                                                         = 'S-1-15-3-6'
                'APPLICATION PACKAGE AUTHORITY\Your documents library'                                                     = 'S-1-15-3-7'
                'APPLICATION PACKAGE AUTHORITY\Your Windows credentials'                                                   = 'S-1-15-3-8'
                'APPLICATION PACKAGE AUTHORITY\Software and hardware certificates or a smart card'                         = 'S-1-15-3-9'
                'APPLICATION PACKAGE AUTHORITY\Removable storage'                                                          = 'S-1-15-3-10'
                'APPLICATION PACKAGE AUTHORITY\Your Appointments'                                                          = 'S-1-15-3-11'
                'APPLICATION PACKAGE AUTHORITY\Your Contacts'                                                              = 'S-1-15-3-12'
            }
            $SIDString = $KnownSIDs[$IdentityReference]

            $Caption = $IdentityReference -replace 'APPLICATION PACKAGE AUTHORITY', $ServerNetBIOS -replace "^$ThisHostname\\", "$ThisHostname\"

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

            Write-LogMsg @LogParams -Text " # Add '$Caption' to the Win32_Account caption cache"
            $CimCache[$ServerNetBIOS]['Win32_AccountByCaption'][$Caption] = $Win32Acct
            Write-LogMsg @LogParams -Text " # Add '$ServerNetBIOS\$SIDString' to the Win32_Account SID cache"
            $CimCache[$ServerNetBIOS]['Win32_AccountBySID']["$ServerNetBIOS\$SIDString"] = $Win32Acct

            return [PSCustomObject]@{
                IdentityReference        = $IdentityReference
                SIDString                = $SIDString
                IdentityReferenceNetBios = $Caption
                IdentityReferenceDns     = "$DomainDns\$Name"
            }
        }
        "BUILTIN\*" {
            # Some built-in groups such as BUILTIN\Users and BUILTIN\Administrators are not in the CIM class or translatable with the NTAccount.Translate() method
            # But they may have real DirectoryEntry objects
            # Try to find the DirectoryEntry object locally on the server
            $DirectoryPath = "$($AdsiServer.AdsiProvider)`://$ServerNetBIOS/$Name"
            $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath @GetDirectoryEntryParams @LoggingParams
            $SIDString = (Add-SidInfo -InputObject $DirectoryEntry -DomainsBySid $DomainsBySid @LoggingParams).SidString
            $Caption = $IdentityReference -replace 'BUILTIN', $ServerNetBIOS -replace "^$ThisHostname\\", "$ThisHostname\"
            $DomainDns = $AdsiServer.Dns

            # Update the caches
            $Win32Acct = [PSCustomObject]@{
                SID     = $SIDString
                Caption = $Caption
                Domain  = $ServerNetBIOS
                Name    = $Name
            }

            Write-LogMsg @LogParams -Text " # Add '$Caption' to the Win32_Account caption cache"
            $CimCache[$ServerNetBIOS]['Win32_AccountByCaption'][$Caption] = $Win32Acct
            Write-LogMsg @LogParams -Text " # Add '$ServerNetBIOS\$SIDString' to the Win32_Account SID cache"
            $CimCache[$ServerNetBIOS]['Win32_AccountBySID']["$ServerNetBIOS\$SIDString"] = $Win32Acct

            return [PSCustomObject]@{
                IdentityReference        = $IdentityReference
                SIDString                = $SIDString
                IdentityReferenceNetBios = $Caption
                IdentityReferenceDns     = "$DomainDns\$Name"
            }
        }
    }

    # The IdentityReference is an NTAccount
    # Resolve NTAccount to SID
    # Start by determining the domain

    if (-not [string]::IsNullOrEmpty($DomainNetBIOS)) {
        $DomainNetBIOSCacheResult = $DomainsByNetbios[$DomainNetBIOS]
        if (-not $DomainNetBIOSCacheResult) {
            Write-LogMsg @LogParams -Text " # Domain NetBIOS cache miss for '$($DomainNetBIOS)'."
            $DomainNetBIOSCacheResult = Get-AdsiServer -Netbios $DomainNetBIOS -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LoggingParams
            $DomainsByNetbios[$DomainNetBIOS] = $DomainNetBIOSCacheResult

        } else {
            Write-LogMsg @LogParams -Text " # Domain NetBIOS cache hit for '$($DomainNetBIOS)'."
        }

        $DomainDn = $DomainNetBIOSCacheResult.DistinguishedName
        $DomainDns = $DomainNetBIOSCacheResult.Dns

        # Try to resolve the account against the server the Access Control Entry came from (which may or may not be the directory server for the account)
        Write-LogMsg @LogParams -Text "[System.Security.Principal.NTAccount]::new('$ServerNetBIOS', '$Name').Translate([System.Security.Principal.SecurityIdentifier])"
        $NTAccount = [System.Security.Principal.NTAccount]::new($ServerNetBIOS, $Name)
        $SIDString = & { $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]) } 2>$null

        if (-not $SIDString) {
            # Try to resolve the account against the domain indicated in its NT Account Name (which may or may not be the correct ADSI server for the account, it won't be if it's NT AUTHORITY\SYSTEM for example)
            Write-LogMsg @LogParams -Text "[System.Security.Principal.NTAccount]::new('$DomainNetBIOS', '$Name')"
            $NTAccount = [System.Security.Principal.NTAccount]::new($DomainNetBIOS, $Name)
            Write-LogMsg @LogParams -Text "[System.Security.Principal.NTAccount]::new('$DomainNetBIOS', '$Name').Translate([System.Security.Principal.SecurityIdentifier])"
            $SIDString = & { $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]) } 2>$null
        } else {
            $DomainNetBIOS = $ServerNetBIOS
        }

        if (-not $SIDString) {
            # Try to resolve the account against the domain indicated in its NT Account Name
            # Add this domain to our list of known domains
            try {
                $SearchPath = Add-DomainFqdnToLdapPath -DirectoryPath "LDAP://$DomainDn" -ThisFqdn $ThisFqdn -CimCache $CimCache @LoggingParams
                $SearchParams = @{
                    CimCache            = $CimCache
                    DebugOutputStream   = $DebugOutputStream
                    DirectoryEntryCache = $DirectoryEntryCache
                    DirectoryPath       = $SearchPath
                    DomainsByNetbios    = $DomainsByNetbios
                    Filter              = "(samaccountname=$Name)"
                    PropertiesToLoad    = @('objectClass', 'distinguishedName', 'name', 'grouptype', 'description', 'managedby', 'member', 'objectClass', 'Department', 'Title')
                    ThisFqdn            = $ThisFqdn
                }
                $DirectoryEntry = Search-Directory @SearchParams @LoggingParams
                $SIDString = (Add-SidInfo -InputObject $DirectoryEntry -DomainsBySid $DomainsBySid @LoggingParams).SidString
            } catch {
                $LogParams['Type'] = 'Warning' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat
                Write-LogMsg @LogParams -Text "'$IdentityReference' could not be resolved against its directory. Error: $($_.Exception.Message)"
                $LogParams['Type'] = $DebugOutputStream
            }
        }

        if (-not $SIDString) {

            # Try to find the DirectoryEntry object directly on the server
            $DirectoryPath = "$($AdsiServer.AdsiProvider)`://$ServerNetBIOS/$Name"
            $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath @GetDirectoryEntryParams @LoggingParams
            $SIDString = (Add-SidInfo -InputObject $DirectoryEntry -DomainsBySid $DomainsBySid @LoggingParams).SidString

        }

        if ($SIDString) {
            $DomainNetBIOS = $ServerNetBIOS
        }

        # This covers unresolved SIDs for deleted accounts, broken domain trusts, etc.
        if ( '' -eq "$Name" ) {
            $Name = $IdentityReference
            Write-LogMsg @LogParams -Text " # An IdentityReference girl has no name ($Name)"
        } else {
            Write-LogMsg @LogParams -Text " # '$IdentityReference' is named '$Name'"
        }

        return [PSCustomObject]@{
            IdentityReference        = $IdentityReference
            SIDString                = $SIDString
            IdentityReferenceNetBios = "$DomainNetBios\$Name" -replace "^$ThisHostname\\", "$ThisHostname\"
            IdentityReferenceDns     = "$DomainDns\$Name"
        }

    }
}
