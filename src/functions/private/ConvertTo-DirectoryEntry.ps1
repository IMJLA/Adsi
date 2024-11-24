function ConvertTo-DirectoryEntry {

    param (
        $CachedWellKnownSID,
        $DomainNetBIOS,
        $AccountProperty,
        $ThisFqdn,
        $SamAccountNameOrSid,
        $AccessControlEntries,
        $Log,
        $LogThis,
        $LogSuffix,
        $LogSuffixComment,
        $IdentityReference,
        $CurrentDomain,
        $DebugOutputStream,
        $DomainDn,
        [ref]$Cache
    )

    if ($CachedWellKnownSID) {

        $FakeDirectoryEntryParams = @{
            DirectoryPath = "WinNT://$DomainNetBIOS/$($CachedWellKnownSID.Name)"
            InputObject   = $CachedWellKnownSID
        }

        $DirectoryEntry = New-FakeDirectoryEntry @FakeDirectoryEntryParams
        return $DirectoryEntry

    }

    #Write-LogMsg @Log -Text " # Known SID cache miss $LogSuffix"

    [string[]]$PropertiesToLoad = $AccountProperty + @(
        'objectClass',
        'objectSid',
        'samAccountName',
        'distinguishedName',
        'name',
        'grouptype',
        'description',
        'member',
        'primaryGroupToken'
    )

    $DirectorySplat = @{ ThisFqdn = $ThisFqdn ; PropertiesToLoad = $PropertiesToLoad }
    $SearchSplat = @{ PropertiesToLoad = $PropertiesToLoad }

    if (

        $null -ne $SamAccountNameOrSid -and
        @($AccessControlEntries.AdsiProvider)[0] -eq 'LDAP'

    ) {

        #Write-LogMsg @Log -Text " # LDAP security principal detected $LogSuffix"
        $DomainNetbiosCacheResult = $Cache.Value['DomainByNetbios'].Value[$DomainNetBIOS]

        if ($DomainNetbiosCacheResult) {

            #Write-LogMsg @Log -Text " # Domain NetBIOS cache hit for '$DomainNetBIOS' $LogSuffix"
            $DomainDn = $DomainNetbiosCacheResult.DistinguishedName
            $SearchSplat['DirectoryPath'] = "LDAP://$($DomainNetbiosCacheResult.Dns)/$DomainDn"

        } else {

            #Write-LogMsg @Log -Text " # Domain NetBIOS cache miss for '$DomainNetBIOS' $LogSuffix"

            if ( -not [string]::IsNullOrEmpty($DomainNetBIOS) ) {
                $DomainDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -ThisFqdn $ThisFqdn @LogThis
            }

            $FqdnParams = @{
                DirectoryPath = "LDAP://$DomainNetBIOS"
                ThisFqdn      = $ThisFqdn
            }

            $SearchSplat['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath @FqdnParams @LogThis

        }

        # Search the domain for the principal
        $SearchSplat['Filter'] = "(samaccountname=$SamAccountNameOrSid)"
        Write-LogMsg @Log -Text 'Search-Directory' -Expand $DirectorySplat, $SearchSplat, $LogThis -Suffix $LogSuffixComment

        try {
            $DirectoryEntry = Search-Directory @DirectorySplat @SearchSplat @LogThis
        } catch {

            $Log['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
            Write-LogMsg @Log -Text " # Unsuccessful directory search $LogSuffix`: $($_.Exception.Message.Trim())"
            $Log['Type'] = $DebugOutputStream
            return

        }

        return $DirectoryEntry

    } elseif (
        $IdentityReference.Substring(0, $IdentityReference.LastIndexOf('-') + 1) -eq $CurrentDomain.SIDString
    ) {

        #Write-LogMsg @Log -Text " # Detected an unresolved SID from the current domain $LogSuffix"

        # Get the distinguishedName and netBIOSName of the current domain.  This also determines whether the domain is online.
        $DomainDN = $CurrentDomain.distinguishedName.Value
        $DomainFQDN = ConvertTo-Fqdn -DistinguishedName $DomainDN -ThisFqdn $ThisFqdn @LogThis
        $SearchSplat['DirectoryPath'] = "LDAP://$DomainFQDN/cn=partitions,cn=configuration,$DomainDn"
        $SearchSplat['Filter'] = "(&(objectcategory=crossref)(dnsroot=$DomainFQDN)(netbiosname=*))"
        $SearchSplat['PropertiesToLoad'] = 'netbiosname'
        Write-LogMsg @Log -Text 'Search-Directory' -Expand $DirectorySplat, $SearchSplat, $LogThis -Suffix $LogSuffixComment
        $DomainCrossReference = Search-Directory @DirectorySplat @SearchSplat @LogThis

        if ($DomainCrossReference.Properties ) {

            #Write-LogMsg @Log -Text " # The domain '$DomainFQDN' is online $LogSuffix"
            [string]$DomainNetBIOS = $DomainCrossReference.Properties['netbiosname']

            # TODO: The domain is online; see if any domain trusts have issues?
            #       Determine if SID is foreign security principal?

            # TODO: What if the foreign security principal exists but the corresponding domain trust is down?
            # Don't want to recommend deletion of the ACE in that case.

        }

        $SidObject = [System.Security.Principal.SecurityIdentifier]::new($IdentityReference)
        $SidBytes = [byte[]]::new($SidObject.BinaryLength)
        $null = $SidObject.GetBinaryForm($SidBytes, 0)
        $ObjectSid = ConvertTo-HexStringRepresentationForLDAPFilterString -SIDByteArray $SidBytes
        $SearchSplat['DirectoryPath'] = "LDAP://$DomainFQDN/$DomainDn"
        $SearchSplat['Filter'] = "(objectsid=$ObjectSid)"
        $SearchSplat['PropertiesToLoad'] = $PropertiesToLoad
        Write-LogMsg @Log -Text 'Search-Directory' -Expand $DirectorySplat, $SearchSplat, $LogThis -Suffix $LogSuffixComment

        try {
            $DirectoryEntry = Search-Directory @DirectorySplat @SearchSplat @LogThis
        } catch {

            $Log['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
            Write-LogMsg @Log -Text " # Unsuccessful directory search $LogSuffix`: $($_.Exception.Message.Trim())"
            $Log['Type'] = $DebugOutputStream
            return

        }

        return $DirectoryEntry

    }

    #Write-LogMsg @Log -Text " # Detected a local security principal or unresolved SID $LogSuffix"

    if ($null -eq $SamAccountNameOrSid) { $SamAccountNameOrSid = $IdentityReference }

    if ($SamAccountNameOrSid -like 'S-1-*') {

        if ($DomainNetBIOS -in 'APPLICATION PACKAGE AUTHORITY', 'BUILTIN', 'NT SERVICE') {

            #Write-LogMsg @Log -Text " # Detected a Capability SID or Service SID which could not be resolved to a friendly name $LogSuffix"

            $Known = Get-KnownSid -SID $SamAccountNameOrSid

            $FakeDirectoryEntryParams = @{
                DirectoryPath = "WinNT://$DomainNetBIOS/$SamAccountNameOrSid"
                InputObject   = $Known
            }

            $DirectoryEntry = New-FakeDirectoryEntry @FakeDirectoryEntryParams
            return $DirectoryEntry

        }

        #Write-LogMsg @Log -Text " # Detected an unresolved SID $LogSuffix"

        # The SID of the domain is the SID of the user minus the last block of numbers
        $DomainSid = $SamAccountNameOrSid.Substring(0, $SamAccountNameOrSid.LastIndexOf('-'))

        # Determine if SID belongs to current domain
        #if ($DomainSid -eq $CurrentDomain.SIDString) {
        #Write-LogMsg @Log -Text " # '$($IdentityReference)' belongs to the current domain.  Could be a deleted user.  ?possibly a foreign security principal corresponding to an offline trusted domain or deleted user in the trusted domain?"
        #} else {
        #Write-LogMsg @Log -Text " # '$($IdentityReference)' does not belong to the current domain. Could be a local security principal or belong to an unresolvable domain."
        #}

        # Lookup other information about the domain using its SID as the key
        $DomainObject = $Cache.Value['DomainBySid'].Value[$DomainSid]

        if ($DomainObject) {

            $DirectoryPath = "WinNT://$($DomainObject.Dns)/Users"
            $DomainNetBIOS = $DomainObject.Netbios
            $DomainDN = $DomainObject.DistinguishedName

        } else {

            $DirectoryPath = "WinNT://$DomainNetBIOS/Users"
            $DomainDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -ThisFqdn $ThisFqdn @LogThis

        }

        Write-LogMsg @Log -Text "`$UsersGroup = Get-DirectoryEntry -DirectoryPath '$DirectoryPath'" -Expand $DirectorySplat, $LogThis -ExpandKeyMap @{ Cache = '$Cache' } -Suffix $LogSuffixComment

        try {
            $UsersGroup = Get-DirectoryEntry -DirectoryPath $DirectoryPath @DirectorySplat @LogThis
        } catch {

            $Log['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
            Write-LogMsg @Log -Text " # Couldn't get '$($DirectoryPath)' using PSRemoting $LogSuffix. Error: $_"
            $Log['Type'] = $DebugOutputStream
            return

        }

        Write-LogMsg @Log -Text "Get-WinNTGroupMember -DirectoryEntry `$UsersGroup -ThisFqdn '$ThisFqdn'" -Expand $LogThis -ExpandKeyMap @{ Cache = '$Cache' } -Suffix $LogSuffixComment
        $MembersOfUsersGroup = Get-WinNTGroupMember -DirectoryEntry $UsersGroup -ThisFqdn $ThisFqdn @LogThis

        $DirectoryEntry = $MembersOfUsersGroup |
        Where-Object -FilterScript {
            ($SamAccountNameOrSid -eq $([System.Security.Principal.SecurityIdentifier]::new([byte[]]$_.Properties['objectSid'], 0)))
        }

        return $DirectoryEntry

    }

    #Write-LogMsg @Log -Text " # Detected a local security principal $LogSuffix"
    $DomainNetbiosCacheResult = $Cache.Value['DomainByNetbios'].Value[$DomainNetBIOS]

    if ($DomainNetbiosCacheResult) {
        $DirectoryPath = "WinNT://$($DomainNetbiosCacheResult.Dns)/$SamAccountNameOrSid"
    } else {
        $DirectoryPath = "WinNT://$DomainNetBIOS/$SamAccountNameOrSid"
    }

    Write-LogMsg @Log -Text "Get-DirectoryEntry -DirectoryPath '$DirectoryPath'" -Expand $DirectorySplat, $LogThis -Suffix $LogSuffixComment

    try {

        $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath @DirectorySplat @LogThis
        return $DirectoryEntry

    } catch {

        $Log['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
        Write-LogMsg @Log -Text " # '$DirectoryPath' Couldn't be resolved $LogSuffix. Error: $($_.Exception.Message.Trim())"
        $Log['Type'] = $DebugOutputStream
        return

    }

}
