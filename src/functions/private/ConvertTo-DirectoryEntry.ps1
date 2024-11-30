function ConvertTo-DirectoryEntry {

    param (
        $CachedWellKnownSID,
        $DomainNetBIOS,
        $AccountProperty,
        $SamAccountNameOrSid,
        $AccessControlEntries,
        $LogSuffixComment,
        $IdentityReference,
        $CurrentDomain,
        $DomainDn,
        [ref]$Cache
    )

    if ($CachedWellKnownSID) {

        $FakeDirectoryEntryParams = @{
            DirectoryPath = "WinNT://$DomainNetBIOS/$($CachedWellKnownSID.Name)"
            InputObject   = $CachedWellKnownSID
        }

        $DirectoryEntry = New-FakeDirectoryEntry @FakeDirectoryEntryParams
        if ($DirectoryEntry) { return $DirectoryEntry }

    }

    $Log = @{ 'Cache' = $Cache ; 'Suffix' = $LogSuffixComment }

    #Write-LogMsg @Log -Text " # Known SID cache miss" -Cache $Cache

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

    $DirectoryParams = @{ Cache = $Cache ; PropertiesToLoad = $PropertiesToLoad }
    $SearchSplat = @{ PropertiesToLoad = $PropertiesToLoad }

    if (

        $null -ne $SamAccountNameOrSid -and
        @($AccessControlEntries.AdsiProvider)[0] -eq 'LDAP'

    ) {

        #Write-LogMsg @Log -Text " # LDAP security principal detected" -Cache $Cache
        $DomainNetbiosCacheResult = $Cache.Value['DomainByNetbios'].Value[$DomainNetBIOS]

        if ($DomainNetbiosCacheResult) {

            #Write-LogMsg @Log -Text " # Domain NetBIOS cache hit for '$DomainNetBIOS'" -Cache $Cache
            $DomainDn = $DomainNetbiosCacheResult.DistinguishedName
            $SearchSplat['DirectoryPath'] = "LDAP://$($DomainNetbiosCacheResult.Dns)/$DomainDn"

        } else {

            #Write-LogMsg @Log -Text " # Domain NetBIOS cache miss for '$DomainNetBIOS'" -Cache $Cache

            if ( -not [string]::IsNullOrEmpty($DomainNetBIOS) ) {
                $DomainDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -Cache $Cache
            }

            $SearchSplat['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath "LDAP://$DomainNetBIOS" -Cache $Cache

        }

        # Search the domain for the principal
        $SearchSplat['Filter'] = "(samaccountname=$SamAccountNameOrSid)"
        Write-LogMsg @Log -Text 'Search-Directory' -Expand $DirectoryParams, $SearchSplat -MapKeyName 'LogCacheMap'

        try {
            $DirectoryEntry = Search-Directory @DirectoryParams @SearchSplat
        } catch {

            $StartingLogType = $Cache.Value['LogType'].Value
            $Cache.Value['LogType'].Value = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
            Write-LogMsg @Log -Text " # Unsuccessful directory search`: $($_.Exception.Message.Trim())"
            $Cache.Value['LogType'].Value = $StartingLogType
            return

        }

        if ($DirectoryEntry) { return $DirectoryEntry }

    } elseif (
        $IdentityReference.Substring(0, $IdentityReference.LastIndexOf('-') + 1) -eq $CurrentDomain.SIDString
    ) {

        #Write-LogMsg @Log -Text " # Detected an unresolved SID from the current domain"

        # Get the distinguishedName and netBIOSName of the current domain.  This also determines whether the domain is online.
        $DomainDN = $CurrentDomain.distinguishedName.Value
        $DomainFQDN = ConvertTo-Fqdn -DistinguishedName $DomainDN -Cache $Cache
        $SearchSplat['DirectoryPath'] = "LDAP://$DomainFQDN/cn=partitions,cn=configuration,$DomainDn"
        $SearchSplat['Filter'] = "(&(objectcategory=crossref)(dnsroot=$DomainFQDN)(netbiosname=*))"
        $SearchSplat['PropertiesToLoad'] = 'netbiosname'
        Write-LogMsg @Log -Text 'Search-Directory' -Expand $DirectoryParams, $SearchSplat -MapKeyName 'LogCacheMap'
        $DomainCrossReference = Search-Directory @DirectoryParams @SearchSplat

        if ($DomainCrossReference.Properties ) {

            #Write-LogMsg @Log -Text " # The domain '$DomainFQDN' is online" -Cache $Cache
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
        Write-LogMsg @Log -Text 'Search-Directory' -Expand $DirectoryParams, $SearchSplat -MapKeyName 'LogCacheMap'

        try {
            $DirectoryEntry = Search-Directory @DirectoryParams @SearchSplat
        } catch {

            $StartingLogType = $Cache.Value['LogType'].Value
            $Cache.Value['LogType'].Value = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
            Write-LogMsg @Log -Text " # Unsuccessful directory search`: $($_.Exception.Message.Trim())" -Cache $Cache
            $Cache.Value['LogType'].Value = $StartingLogType
            return

        }

        if ($DirectoryEntry) { return $DirectoryEntry }

    }

    #Write-LogMsg @Log -Text " # Detected a local security principal or unresolved SID" -Cache $Cache

    if ($null -eq $SamAccountNameOrSid) { $SamAccountNameOrSid = $IdentityReference }

    if ($SamAccountNameOrSid -like 'S-1-*') {

        if ($DomainNetBIOS -in 'APPLICATION PACKAGE AUTHORITY', 'BUILTIN', 'NT SERVICE') {

            #Write-LogMsg @Log -Text " # Detected a Capability SID or Service SID which could not be resolved to a friendly name" -Cache $Cache

            $Known = Get-KnownSid -SID $SamAccountNameOrSid

            $FakeDirectoryEntryParams = @{
                DirectoryPath = "WinNT://$DomainNetBIOS/$SamAccountNameOrSid"
                InputObject   = $Known
            }

            $DirectoryEntry = New-FakeDirectoryEntry @FakeDirectoryEntryParams
            return $DirectoryEntry

        }

        #Write-LogMsg @Log -Text " # Detected an unresolved SID" -Cache $Cache

        # The SID of the domain is the SID of the user minus the last block of numbers
        $DomainSid = $SamAccountNameOrSid.Substring(0, $SamAccountNameOrSid.LastIndexOf('-'))

        # Determine if SID belongs to current domain
        #if ($DomainSid -eq $CurrentDomain.SIDString) {
        #Write-LogMsg @Log -Text " # '$($IdentityReference)' belongs to the current domain.  Could be a deleted user.  ?possibly a foreign security principal corresponding to an offline trusted domain or deleted user in the trusted domain?" -Cache $Cache
        #} else {
        #Write-LogMsg @Log -Text " # '$($IdentityReference)' does not belong to the current domain. Could be a local security principal or belong to an unresolvable domain." -Cache $Cache
        #}

        # Lookup other information about the domain using its SID as the key
        $DomainObject = $Cache.Value['DomainBySid'].Value[$DomainSid]

        if ($DomainObject) {

            $DirectoryPath = "WinNT://$($DomainObject.Dns)/Users"
            $DomainNetBIOS = $DomainObject.Netbios
            $DomainDN = $DomainObject.DistinguishedName

        } else {

            $DirectoryPath = "WinNT://$DomainNetBIOS/Users"
            $DomainDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -Cache $Cache

        }

        Write-LogMsg @Log -Text "`$UsersGroup = Get-DirectoryEntry -DirectoryPath '$DirectoryPath'" -Expand $DirectoryParams -MapKeyName 'LogCacheMap'

        try {
            $UsersGroup = Get-DirectoryEntry -DirectoryPath $DirectoryPath @DirectoryParams
        } catch {

            $StartingLogType = $Cache.Value['LogType'].Value
            $Cache.Value['LogType'].Value = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
            Write-LogMsg @Log -Text " # Couldn't get '$($DirectoryPath)' using PSRemoting. Error: $_" -Cache $Cache
            $Cache.Value['LogType'].Value = $StartingLogType
            return

        }

        Write-LogMsg @Log -Text "Get-WinNTGroupMember -DirectoryEntry `$UsersGroup -Cache `$Cache"
        $MembersOfUsersGroup = Get-WinNTGroupMember -DirectoryEntry $UsersGroup -Cache $Cache

        $DirectoryEntry = $MembersOfUsersGroup |
        Where-Object -FilterScript {
            ($SamAccountNameOrSid -eq $([System.Security.Principal.SecurityIdentifier]::new([byte[]]$_.Properties['objectSid'], 0)))
        }

        return $DirectoryEntry

    }

    #Write-LogMsg @Log -Text " # Detected a local security principal" -Cache $Cache
    $DomainNetbiosCacheResult = $Cache.Value['DomainByNetbios'].Value[$DomainNetBIOS]

    if ($DomainNetbiosCacheResult) {
        $DirectoryPath = "WinNT://$($DomainNetbiosCacheResult.Dns)/$SamAccountNameOrSid"
    } else {
        $DirectoryPath = "WinNT://$DomainNetBIOS/$SamAccountNameOrSid"
    }

    Write-LogMsg @Log -Text "Get-DirectoryEntry -DirectoryPath '$DirectoryPath'" -Expand $DirectoryParams -MapKeyName 'LogCacheMap'

    try {
        $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath @DirectoryParams
    } catch {

        $StartingLogType = $Cache.Value['LogType'].Value
        $Cache.Value['LogType'].Value = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
        Write-LogMsg @Log -Text " # '$DirectoryPath' Couldn't be resolved. Error: $($_.Exception.Message.Trim())" -Cache $Cache
        $Cache.Value['LogType'].Value = $StartingLogType
        return

    }

    if ($DirectoryEntry) { return $DirectoryEntry }

}
