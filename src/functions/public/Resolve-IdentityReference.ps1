
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
        [PSCustomObject] with UnresolvedIdentityReference and SIDString properties (each strings)
        .EXAMPLE
        Resolve-IdentityReference -IdentityReference 'BUILTIN\Administrator' -ServerName 'localhost' -AdsiServer (Get-AdsiServer 'localhost')

        Get information about the local Administrator account
    #>
    [OutputType([PSCustomObject])]
    param (
        # IdentityReference from an Access Control Entry
        # Expecting either a SID (S-1-5-18) or an NT account name (CONTOSO\User)
        [Parameter(Mandatory)]
        [string]$IdentityReference,

        # Name of the directory server to use to resolve the IdentityReference
        [string]$ServerName,

        # Object from Get-AdsiServer representing the directory server and its attributes
        [PSObject]$AdsiServer,

        [hashtable]$KnownDomains = [hashtable]::Synchronized(@{}),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        [hashtable]$Win32AccountsBySID = ([hashtable]::Synchronized(@{})),

        [hashtable]$Win32AccountsByCaption = ([hashtable]::Synchronized(@{})),

        [hashtable]$DomainsBySID = ([hashtable]::Synchronized(@{})),

        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache known servers to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$AdsiServersByDns = [hashtable]::Synchronized(@{})
    )

    $ThisHostName = hostname
    if ($AdsiServer.AdsiProvider -eq 'LDAP') {
        $ServerNetBIOS = ConvertTo-LDAPDomainNetBIOS -DomainFQDN $AdsiServer.ServerName -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -AdsiServersByDns $AdsiServersByDns -DomainsByNetbios $DomainsByNetbios
    } else {
        $ServerNetBIOS = ($AdsiServer.ServerName -split '\.')[0]
    }

    $split = $IdentityReference.Split('\')
    $DomainNetBIOS = $split[0]
    $DomainNetBIOS = $ServerNetBIOS
    $Name = $split[1]

    # Many Well-Known SIDs cannot be translated with the Translate method
    # Instead we have used CIM to collect information on instances of the Win32_Account class from the AdsiServer
    # This has been done by Get-AdsiServer and it updated the Win32AccountsBySID and Win32AccountsByCaption caches
    # Search the caches now
    $CacheResult = $Win32AccountsBySID["$ServerNetBIOS\$IdentityReference"]
    if ($CacheResult) {
        #IdentityReference is a SID, and has been cached from this server
        Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t# Win32_Account SID cache hit for '$ServerNetBIOS\$IdentityReference'"
        return [PSCustomObject]@{
            IdentityReferenceOriginal   = $IdentityReference
            # IdentityReferenceNameUnresolved below is not available, the Win32_Account instances in the cache are already resolved to the NetBios domain names
            IdentityReferenceUnresolved = $null # Could parse SID to get this?
            SIDString                   = $CacheResult.SID
            IdentityReferenceNetBios    = $CacheResult.Caption
            IdentityReferenceDns        = "$($AdsiServer.ServerName)\$($CacheResult.Name)"
        }
    } else {
        Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t# Win32_Account SID cache miss for '$ServerNetBIOS\$IdentityReference'"
    }
    if ($Name) {
        # Win32_Account provides a NetBIOS-resolved IdentityReference
        # NT Authority\SYSTEM on would be SERVER123\SYSTEM as a Win32_Account on a server with hostname server123
        # This could also match on a domain account since those can be returned as Win32_Account, not sure if that will be a bug or what
        $CacheResult = $Win32AccountsByCaption["$ServerNetBIOS\$ServerNetBIOS\$Name"]
        if ($CacheResult) {
            # IdentityReference is an NT Account Name, and has been cached from this server
            Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t# Win32_Account caption cache hit for '$ServerNetBIOS\$ServerNetBIOS\$Name'"
            if ($ServerNetBIOS -eq $CacheResult.Domain) {
                $DomainDns = $AdsiServer.ServerName
            }
            if (-not $DomainDns) {
                $DomainCacheResult = $DomainsByNetbios[$CacheResult.Domain]
                if ($DomainCacheResult) {
                    $DomainDns = $DomainCacheResult.Dns
                }
            }
            if (-not $DomainDns) {
                $DomainDns = ConvertTo-Fqdn -NetBIOS $DomainNetBIOS -KnownDomains $KnownDomains -DomainsByNetbios $DomainsByNetbios
                $DomainDn = $KnownDomains[$DomainNetBIOS]
            }

            return [PSCustomObject]@{
                IdentityReferenceOriginal   = $IdentityReference
                # IdentityReferenceNameUnresolved below is not available, the Win32_Account instances in the cache are already resolved to the NetBios domain names
                IdentityReferenceUnresolved = $IdentityReference
                SIDString                   = $CacheResult.SID
                IdentityReferenceNetBios    = $CacheResult.Caption
                IdentityReferenceDns        = "$DomainDns\$($CacheResult.Name)"
            }
        } else {
            Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t# Win32_Account caption cache miss for '$ServerNetBIOS\$ServerNetBIOS\$Name'"
        }
    }
    $CacheResult = $Win32AccountsByCaption["$ServerNetBIOS\$IdentityReference"]
    if ($CacheResult) {
        # IdentityReference is an NT Account Name, and has been cached from this server
        Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t# Win32_Account caption cache hit for '$ServerNetBIOS\$IdentityReference'"
        return [PSCustomObject]@{
            IdentityReferenceOriginal   = $IdentityReference
            # IdentityReferenceNameUnresolved below is not available, the Win32_Account instances in the cache are already resolved to the NetBios domain names
            IdentityReferenceUnresolved = $null
            SIDString                   = $CacheResult.SID
            IdentityReferenceNetBios    = $CacheResult.Caption
            IdentityReferenceDns        = "$($AdsiServer.ServerName)\$($CacheResult.Name)"
        }
    } else {
        Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t# Win32_Account caption cache miss for '$ServerNetBIOS\$IdentityReference'"
    }

    switch -Wildcard ($IdentityReference) {
        "S-1-*" {
            # IdentityReference is a SID (Revision 1)

            # Constricted a SecurityIdentifier object based on the SID
            Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t[System.Security.Principal.SecurityIdentifier]::new('$IdentityReference')"
            $SecurityIdentifier = [System.Security.Principal.SecurityIdentifier]::new($IdentityReference)

            <#
            Use the SecurityIdentifier.Translate() method to translate the SID to an NT Account name
                This .Net method makes it impossible to redirect the error stream directly
                Wrapping it in a scriptblock (which is then executed with &) fixes the problem
                I don't understand exactly why
                The scriptblock will evaluate null if the SID cannot be translated, and the error stream redirection supresses the error
            #>
            Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t[System.Security.Principal.SecurityIdentifier]::new('$IdentityReference').Translate([System.Security.Principal.NTAccount])"
            $UnresolvedIdentityReference = & { $SecurityIdentifier.Translate([System.Security.Principal.NTAccount]).Value } 2>$null

            # The SID of the domain is everything up to (but not including) the last hyphen
            $DomainSid = $IdentityReference.Substring(0, $IdentityReference.LastIndexOf("-"))

            # Search the cache of domains (TrustedDomainSidNameMap)
            $DomainCacheResult = $DomainsBySID[$DomainSid]
            if (-not $DomainCacheResult) {
                $split = $UnresolvedIdentityReference -split '\\'
                $DomainCacheResult = $DomainsByNetbios[$split[0]]
                Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t# Domain SID cache miss for '$DomainSid'"
            } else {
                Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t# Domain SID cache hit for '$DomainSid'"
            }
            if ($DomainCacheResult) {
                $DomainNetBIOS = $DomainCacheResult.Netbios
                $DomainDns = $DomainCacheResult.Dns
            } else {
                Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t# Domain SID '$DomainSid' is unknown."
                $DomainNetBIOS = $split[0]
                Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t# Translated NTAccount name for '$IdentityReference' is '$UnresolvedIdentityReference'"
                $DomainDns = ConvertTo-Fqdn -NetBIOS $DomainNetBIOS -KnownDomains $KnownDomains -DomainsByNetbios $DomainsByNetbios
            }
            $AdsiServer = Get-AdsiServer -AdsiServer $DomainDns -AdsiServersByDns $AdsiServersByDns

            # Recursively call this function to resolve the new IdentityReference we have
            $ResolveIdentityReferenceParams = @{
                IdentityReference      = $UnresolvedIdentityReference
                ServerName             = $DomainDns
                AdsiServer             = $AdsiServer
                Win32AccountsBySID     = $Win32AccountsBySID
                Win32AccountsByCaption = $Win32AccountsByCaption
                DirectoryEntryCache    = $DirectoryEntryCache
                DomainsBySID           = $DomainsBySID
                DomainsByNetbios       = $DomainsByNetbios
            }
            $Resolved = Resolve-IdentityReference @ResolveIdentityReferenceParams

            if ( -not $UnresolvedIdentityReference ) {
                $Resolved = [PSCustomObject]@{
                    IdentityReferenceOriginal   = $IdentityReference
                    IdentityReferenceUnresolved = $IdentityReference
                    SIDString                   = $IdentityReference
                    IdentityReferenceNetBios    = "$DomainNetBIOS\$IdentityReference"
                    IdentityReferenceDns        = "$DomainDns\$IdentityReference"
                }
            }

            return $Resolved

        }
        "NT SERVICE\*" {
            # Some of them are services (yes services can have SIDs, notably this includes TrustedInstaller but it is also common with SQL)
            if ($ServerNetBIOS -eq $ThisHostName) {
                Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`tsc.exe showsid $Name"
                [string[]]$ScResult = & sc.exe showsid $Name
            } else {
                Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`tInvoke-Command -ComputerName $ServerNetBIOS -ScriptBlock { & sc.exe showsid `$args[0] } -ArgumentList $Name"
                [string[]]$ScResult = Invoke-Command -ComputerName $ServerNetBIOS -ScriptBlock { & sc.exe showsid $args[0] } -ArgumentList $Name
            }
            $ScResultProps = @{}

            $ScResult |
            ForEach-Object {
                $Prop, $Value = ($_ -split ':').Trim()
                $ScResultProps[$Prop] = $Value
            }

            $SIDString = $ScResultProps['SERVICE SID']
            $Caption = $IdentityReference -replace 'NT SERVICE', $ServerNetBIOS

            $DomainCacheResult = $DomainsByNetbios[$ServerNetBIOS]
            if ($DomainCacheResult) {
                $DomainDns = $DomainCacheResult.Dns
            }
            if (-not $DomainDns) {
                $DomainDns = ConvertTo-Fqdn -NetBIOS $ServerNetBIOS -KnownDomains $KnownDomains -DomainsByNetbios $DomainsByNetbios
            }

            # Update the caches
            $Win32Acct = [PSCustomObject]@{
                SID     = $SIDString
                Caption = $Caption
                Domain  = $ServerNetBIOS
                Name    = $Name
            }
            $Win32AccountsByCaption["$ServerNetBIOS\$Caption"] = $Win32Acct
            $Win32AccountsBySID["$ServerNetBIOS\$SIDString"] = $Win32Acct

            return [PSCustomObject]@{
                IdentityReferenceOriginal   = $IdentityReference
                IdentityReferenceUnresolved = $IdentityReference
                SIDString                   = $SIDString
                IdentityReferenceNetBios    = $Caption
                IdentityReferenceDns        = "$DomainDns\$Name"
            }
        }
        "BUILTIN\*" {
            # Some built-in groups such as BUILTIN\Users and BUILTIN\Administrators are not in the CIM class or translatable with the NTAccount.Translate() method
            # But they may have real DirectoryEntry objects
            # Try to find the DirectoryEntry object locally on the server
            $DirectoryPath = "$($AdsiServer.AdsiProvider)`://$ServerNetBIOS/$Name"
            $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios
            $SIDString = (Add-SidInfo -InputObject $DirectoryEntry -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios).SidString
            $Caption = $IdentityReference -replace 'BUILTIN', $ServerNetBIOS
            $DomainDns = $AdsiServer.ServerName

            # Update the caches
            $Win32Acct = [PSCustomObject]@{
                SID     = $SIDString
                Caption = $Caption
                Domain  = $ServerNetBIOS
                Name    = $Name
            }
            $Win32AccountsByCaption["$ServerNetBIOS\$Caption"] = $Win32Acct
            $Win32AccountsBySID["$ServerNetBIOS\$SIDString"] = $Win32Acct

            return [PSCustomObject]@{
                IdentityReferenceOriginal   = $IdentityReference
                IdentityReferenceUnresolved = $IdentityReference
                SIDString                   = $SIDString
                IdentityReferenceNetBios    = $Caption
                IdentityReferenceDns        = "$DomainDns\$Name"
            }
        }
    }

    # The IdentityReference is an NTAccount
    # Resolve NTAccount to SID
    # Start by determining the domain


    if (
        -not $KnownDomains[$DomainNetBIOS] -and
        -not [string]::IsNullOrEmpty($DomainNetBIOS)
    ) {
        $KnownDomains[$DomainNetBIOS] = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -DomainsByNetbios $DomainsByNetbios
        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tResolve-IdentityReference`t# Cache miss for domain $($DomainNetBIOS).  Adding its Distinguished Name to dictionary of known domains for future lookup"
    }

    $DomainDn = $KnownDomains[$DomainNetBIOS]
    $DomainDns = ConvertTo-Fqdn -DistinguishedName $DomainDn -DomainsByNetbios $DomainsByNetbios

    # Try to resolve the account against the server the Access Control Entry came from (which may or may not be the directory server for the account)
    Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t[System.Security.Principal.NTAccount]::new('$ServerNetBIOS', '$Name')"
    $NTAccount = [System.Security.Principal.NTAccount]::new($ServerNetBIOS, $Name)
    Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t[System.Security.Principal.NTAccount]::new('$ServerNetBIOS', '$Name').Translate([System.Security.Principal.SecurityIdentifier])"
    $SIDString = & { $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]) } 2>$null

    if (-not $SIDString) {
        # Try to resolve the account against the domain indicated in its NT Account Name (which may or may not be the correct ADSI server for the account, it won't be if it's NT AUTHORITY\SYSTEM for example)
        Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t[System.Security.Principal.NTAccount]::new('$DomainNetBIOS', '$Name')"
        $NTAccount = [System.Security.Principal.NTAccount]::new($DomainNetBIOS, $Name)
        Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t[System.Security.Principal.NTAccount]::new('$DomainNetBIOS', '$Name').Translate([System.Security.Principal.SecurityIdentifier])"
        $SIDString = & { $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]) } 2>$null
    } else {
        $DomainNetBIOS = $ServerNetBIOS
    }

    if (-not $SIDString) {
        # Try to resolve the account against the domain indicated in its NT Account Name
        # Add this domain to our list of known domains
        try {
            $SearchPath = Add-DomainFqdnToLdapPath -DirectoryPath "LDAP://$DomainDn" -DomainsByNetbios $DomainsByNetbios
            $DirectoryEntry = Search-Directory -DirectoryEntryCache $DirectoryEntryCache -DirectoryPath $SearchPath -Filter "(samaccountname=$Name)" -PropertiesToLoad @('objectClass', 'distinguishedName', 'name', 'grouptype', 'description', 'managedby', 'member', 'objectClass', 'Department', 'Title') -DomainsByNetbios $DomainsByNetbios
            $SIDString = (Add-SidInfo -InputObject $DirectoryEntry -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios).SidString
        } catch {
            Write-Warning "$(Get-Date -Format s)`t$(hostname)`tResolve-IdentityReference`t$($StartingIdentityName) could not be resolved against its directory"
            Write-Warning "$(Get-Date -Format s)`t$(hostname)`tResolve-IdentityReference`t$($_.Exception.Message)"
        }
    }

    if (-not $SIDString) {

        # Try to find the DirectoryEntry object directly on the server
        $DirectoryPath = "$($AdsiServer.AdsiProvider)`://$ServerNetBIOS/$Name"
        $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios
        $SIDString = (Add-SidInfo -InputObject $DirectoryEntry -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios).SidString

    }

    if ($SIDString) {
        $DomainNetBIOS = $ServerNetBIOS
    }

    # This covers unresolved SIDs for deleted accounts, broken domain trusts, etc.
    if ( '' -eq "$Name" ) {
        $Name = $IdentityReference
        Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t# An identity reference girl has no name ($Name)"
    } else {
        Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t# '$IdentityReference' is named '$Name'"
    }

    return [PSCustomObject]@{
        IdentityReferenceOriginal   = $IdentityReference
        IdentityReferenceUnresolved = $IdentityReference
        SIDString                   = $SIDString
        IdentityReferenceNetBios    = "$DomainNetBios\$Name"
        IdentityReferenceDns        = "$DomainDns\$Name"
    }

}
