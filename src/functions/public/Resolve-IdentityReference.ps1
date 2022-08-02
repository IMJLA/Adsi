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

        [hashtable]$Win32AccountsByCaption = ([hashtable]::Synchronized(@{}))
    )

    $ThisHostName = hostname

    $CacheResult = $Win32AccountsBySID["$ServerName\$IdentityReference"]
    if ($CacheResult) {
        #IdentityReference is a SID, and has been cached from this server
        return [PSCustomObject]@{
            SIDString                   = $CacheResult.SID
            UnresolvedIdentityReference = $CacheResult.Caption # This is actually resolved but good enough for now maybe? Can parse SID to get the unresolved format
        }
    }
    $CacheResult = $Win32AccountsByCaption["$ServerName\$IdentityReference"]
    if ($CacheResult) {
        # IdentityReference is an NT Account Name, and has been cached from this server
        return [PSCustomObject]@{
            SIDString                   = $CacheResult.SID
            UnresolvedIdentityReference = $IdentityReference
        }
    }

    switch -Wildcard ($IdentityReference) {
        "S-1-*" {
            # IdentityReference is a SID

            # Constricted a SecurityIdentifier object based on the SID
            Write-Debug "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t[System.Security.Principal.SecurityIdentifier]::new('$IdentityReference')"
            $SecurityIdentifier = [System.Security.Principal.SecurityIdentifier]::new($IdentityReference)

            # Use the SecurityIdentifier.Translate() method to translate the SID to an NT Account name
            # This .Net method makes it impossible to redirect the error stream directly
            # Wrapping it in a scriptblock (which is then executed with &) fixes the problem
            # I don't understand exactly why
            # Anyway UnresolvedIdentityReference will be null if the SID cannot be translated
            Write-Debug "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t[System.Security.Principal.SecurityIdentifier]::new('$IdentityReference').Translate([System.Security.Principal.NTAccount])"
            $UnresolvedIdentityReference = & { $SecurityIdentifier.Translate([System.Security.Principal.NTAccount]).Value } 2>$null
            $Win32AccountsBySID["$ServerName\$IdentityReference"] = [PSCustomObject]@{
                SID     = $IdentityReference
                Caption = "$ServerName\$UnresolvedIdentityReference"
                Domain  = $ServerName
            }
            return [PSCustomObject]@{
                SIDString                   = $IdentityReference
                UnresolvedIdentityReference = $UnresolvedIdentityReference
            }

        }
        "NT SERVICE\*" {

            $split = $IdentityReference.Split('\')
            $domainNetbiosString = $split[0]
            $Name = $split[1]

            # Some of them are services (yes services can have SIDs, notably this includes TrustedInstaller but it is also common with SQL)
            if ($ServerName -eq $ThisHostName) {
                Write-Debug "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`tsc.exe showsid $Name"
                [string[]]$ScResult = & sc.exe showsid $Name
            } else {
                Write-Debug "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`tInvoke-Command -ComputerName $ServerName -ScriptBlock { & sc.exe showsid `$args[0] } -ArgumentList $Name"
                [string[]]$ScResult = Invoke-Command -ComputerName $ServerName -ScriptBlock { & sc.exe showsid $args[0] } -ArgumentList $Name
            }
            $ScResultProps = @{}

            $ScResult |
            ForEach-Object {
                $Prop, $Value = ($_ -split ':').Trim()
                $ScResultProps[$Prop] = $Value
            }

            $SIDString = $ScResultProps['SERVICE SID']

            $Win32AccountsByCaption["$ServerName\$IdentityReference"] = [PSCustomObject]@{
                SID     = $SIDString
                Caption = "$ServerName\$IdentityReference"
                Domain  = $ServerName
            }

            return [PSCustomObject]@{
                SIDString                   = $SIDString
                UnresolvedIdentityReference = $IdentityReference
            }
        }
        "BUILTIN\*" {
            # Some built-in groups such as BUILTIN\Users and BUILTIN\Administrators are not in the CIM class or translatable with the NTAccount.Translate() method
            # But they may have real DirectoryEntry objects
            # Try to find the DirectoryEntry object locally on the server
            $DirectoryPath = "$($AdsiServer.AdsiProvider)`://$ServerName/$Name"
            $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath -DirectoryEntryCache $DirectoryEntryCache
            $SIDString = (Add-SidInfo -InputObject $DirectoryEntry).SidString

            $Win32AccountsByCaption["$ServerName\$IdentityReference"] = [PSCustomObject]@{
                SID     = $SIDString
                Caption = "$ServerName\$IdentityReference"
                Domain  = $ServerName
            }

            return [PSCustomObject]@{
                UnresolvedIdentityReference = $IdentityReference
                SIDString                   = $SIDString
            }
        }
    }

    # The IdentityReference is an NTAccount
    # Resolve NTAccount to SID
    # Start by determining the domain
    $split = $IdentityReference.Split('\')
    $domainNetbiosString = $split[0]
    $Name = $split[1]

    # Well-Known SIDs cannot be translated with the Translate method so instead we will have used CIM to collect information on well-known SIDs
    $SIDString = $AdsiServer.WellKnownSIDs[$Name].SID
    if (-not $SIDString) {
        if (
            -not $KnownDomains[$domainNetbiosString] -and
            -not [string]::IsNullOrEmpty($domainNetbiosString)
        ) {
            $KnownDomains[$domainNetbiosString] = ConvertTo-DistinguishedName -Domain $domainNetbiosString
            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tResolve-IdentityReference`tCache miss for domain $($domainNetbiosString).  Adding its Distinguished Name to dictionary of known domains for future lookup"
        }

        $DomainDn = $KnownDomains[$domainNetbiosString]
        $DomainFqdn = ConvertTo-Fqdn -DistinguishedName $DomainDn

        # Try to resolve the account locally against the server it came from (which may or may not be the correct ADSI server for the account)
        Write-Debug "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t[System.Security.Principal.NTAccount]::new('$ServerName','$Name')"
        $NTAccount = [System.Security.Principal.NTAccount]::new($ServerName, $Name)
        Write-Debug "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t[System.Security.Principal.NTAccount]::new('$ServerName','$Name').Translate([System.Security.Principal.SecurityIdentifier])"
        $SIDString = & { $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]) } 2>$null

        if (-not $SIDString) {
            # Try to resolve the account against the domain indicated in its NT Account Name
            # Add this domain to our list of known domains

            try {
                $SearchPath = "LDAP://$DomainDn" | Add-DomainFqdnToLdapPath
                $DirectoryEntry = Search-Directory -DirectoryEntryCache $DirectoryEntryCache -DirectoryPath $SearchPath -Filter "(samaccountname=$Name)" -PropertiesToLoad @('objectClass', 'distinguishedName', 'name', 'grouptype', 'description', 'managedby', 'member', 'objectClass', 'Department', 'Title')
                $SIDString = (Add-SidInfo -InputObject $DirectoryEntry).SidString
            } catch {
                Write-Warning "$(Get-Date -Format s)`t$(hostname)`tResolve-IdentityReference`t$($StartingIdentityName) could not be resolved against its directory"
                Write-Warning "$(Get-Date -Format s)`t$(hostname)`tResolve-IdentityReference`t$($_.Exception.Message)"
            }

            if (-not $SIDString) {

                # Try to find the DirectoryEntry object directly on the server
                $DirectoryPath = "$($AdsiServer.AdsiProvider)`://$ServerName/$Name"
                $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath -DirectoryEntryCache $DirectoryEntryCache
                $SIDString = (Add-SidInfo -InputObject $DirectoryEntry).SidString

            }
        }
    }

    return [PSCustomObject]@{
        UnresolvedIdentityReference = $IdentityReference
        SIDString                   = $SIDString
    }

}
