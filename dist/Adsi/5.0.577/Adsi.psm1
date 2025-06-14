
#[NoRunspaceAffinity()] # Make this class thread-safe (requires PS 7+)
class FakeDirectoryEntry {

    <#
    Used in place of a DirectoryEntry for certain WinNT security principals that do not have objects in the directory
    The WinNT provider only throws an error if you try to retrieve certain accounts/identities
    #>

    [string]$Name
    [string]$Parent
    [string]$Path
    [type]$SchemaEntry
    [byte[]]$objectSid
    [string]$Description
    [hashtable]$Properties
    [string]$SchemaClassName

    FakeDirectoryEntry (
        [string]$DirectoryPath
    ) {

        $LastSlashIndex = $DirectoryPath.LastIndexOf('/')
        $StartIndex = $LastSlashIndex + 1
        $This.Name = $DirectoryPath.Substring($StartIndex, $DirectoryPath.Length - $StartIndex)
        $This.Parent = $DirectoryPath.Substring(0, $LastSlashIndex)
        $This.Path = $DirectoryPath
        $This.SchemaEntry = [System.DirectoryServices.DirectoryEntry]
        switch -Wildcard ($DirectoryPath) {
            '*/ALL APPLICATION PACKAGES' {
                $This.objectSid = ConvertTo-SidByteArray -SidString 'S-1-15-2-1'
                $This.Description = 'All applications running in an app package context. SECURITY_BUILTIN_PACKAGE_ANY_PACKAGE'
                $This.SchemaClassName = 'group'
                break
            }
            '*/ALL RESTRICTED APPLICATION PACKAGES' {
                $This.objectSid = ConvertTo-SidByteArray -SidString 'S-1-15-2-2'
                $This.Description = 'SECURITY_BUILTIN_PACKAGE_ANY_RESTRICTED_PACKAGE'
                $This.SchemaClassName = 'group'
                break
            }
            '*/ANONYMOUS LOGON' {
                $This.objectSid = ConvertTo-SidByteArray -SidString 'S-1-15-7'
                $This.Description = 'A user who has connected to the computer without supplying a user name and password. Not a member of Authenticated Users.'
                $This.SchemaClassName = 'user'
                break
            }
            '*/Authenticated Users' {
                $This.objectSid = ConvertTo-SidByteArray -SidString 'S-1-5-11'
                $This.Description = 'Any user who accesses the system through a sign-in process has the Authenticated Users identity.'
                $This.SchemaClassName = 'group'
                break
            }
            '*/CREATOR OWNER' {
                $This.objectSid = ConvertTo-SidByteArray -SidString 'S-1-3-0'
                $This.Description = 'A SID to be replaced by the SID of the user who creates a new object. This SID is used in inheritable ACEs.'
                $This.SchemaClassName = 'user'
                break
            }
            '*/Everyone' {
                $This.objectSid = ConvertTo-SidByteArray -SidString 'S-1-1-0'
                $This.Description = "A group that includes all users; aka 'World'."
                $This.SchemaClassName = 'group'
                break
            }
            '*/INTERACTIVE' {
                $This.objectSid = ConvertTo-SidByteArray -SidString 'S-1-5-4'
                $This.Description = 'Users who log on for interactive operation. This is a group identifier added to the token of a process when it was logged on interactively.'
                $This.SchemaClassName = 'group'
                break
            }
            '*/LOCAL SERVICE' {
                $This.objectSid = ConvertTo-SidByteArray -SidString 'S-1-5-19'
                $This.Description = 'A local service account'
                $This.SchemaClassName = 'user'
                break
            }
            '*/NETWORK SERVICE' {
                $This.objectSid = ConvertTo-SidByteArray -SidString 'S-1-5-20'
                $This.Description = 'A network service account'
                $This.SchemaClassName = 'user'
                break
            }
            '*/SYSTEM' {
                $This.objectSid = ConvertTo-SidByteArray -SidString 'S-1-5-18'
                $This.Description = 'By default, the SYSTEM account is granted Full Control permissions to all files on an NTFS volume'
                $This.SchemaClassName = 'user'
                break
            }
            '*/TrustedInstaller' {
                $This.objectSid = ConvertTo-SidByteArray -SidString 'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'
                $This.Description = 'Most of the operating system files are owned by the TrustedInstaller security identifier (SID)'
                $This.SchemaClassName = 'user'
                break
            }
        }

        $This.Properties = @{
            Name            = $This.Name
            Description     = $This.Description
            objectSid       = $This.objectSid
            SchemaClassName = $This.SchemaClassName
        }
    }

    [void]RefreshCache([string[]]$Nonsense) {}
    [void]Invoke([string]$Nonsense) {}

}
function ConvertFrom-AppCapabilitySid {

    <#
    .SYNOPSIS

    Converts an app capability SID to a friendly representation.

    .DESCRIPTION
    Translates security identifiers (SIDs) of the form S-1-15-3-xxx, which represent app capability SIDs,
    into user-friendly objects with information about the capability.

    App capability SIDs are present in the token of apps running in an app container, and they encode
    the app capabilities possessed by the app. The rules for Mandatory Integrity Control specify that
    objects default to allowing write access only to medium integrity level (IL) or higher.
    Granting access to these app capability SIDs permits access from apps running at low IL, provided
    they possess the matching capability.

    # https://devblogs.microsoft.com/oldnewthing/20220503-00/?p=106557
    SIDs of the form S-1-15-3-xxx are app capability SIDs.
    These SIDs are present in the token of apps running in an app container, and they encode the app capabilities possessed by the app.
    The rules for Mandatory Integrity Control say that objects default to allowing write access only to medium integrity level (IL) or higher.
    Granting access to these app capability SIDs permit access from apps running at low IL, provided they possess the matching capability.

    Autogenerated
    S-1-15-3-x1-x2-x3-x4    device capability
    S-1-15-3-1024-x1-x2-x3-x4-x5-x6-x7-x8    app capability

    You can sort of see how these assignments evolved.
    At first, the capability RIDs were assigned by an assigned numbers authority, so anybody who wanted a capability had to apply for a number.
    After about a dozen of these, the assigned numbers team (probably just one person) realized that this had the potential to become a real bottleneck, so they switched to an autogeneration mechanism, so that people who needed a capability SID could just generate their own.
    For device capabilities, the four 32-bit decimal digits represent the 16 bytes of the device interface GUID.
    Let’s decode this one: S-1-15-3-787448254-1207972858-3558633622-1059886964.

    787448254    1207972858    3558633622    1059886964 # Starting format is four 32-bit decimal numbers
    0x2eef81be    0x480033fa    0xd41c7096    0x3f2c9774 # Convert each number to hexadeximal.
    be 81 ef 2e    fa 33 00 48    96 70 1c d4    74 97 2c 3f # Split each number into 4 bytes then reverse. WHY?
    2eef81be    33fa 4800    96 70 1c d4    74 97 2c 3f
    {2eef81be-    33fa-4800-    96 70-1c d4 74 97 2c 3f}

    And we recognize {2eef81be-33fa-4800-9670-1cd474972c3f} as DEVINTERFACE_AUDIO_CAPTURE, so this is the microphone device capability.
    For app capabilities, the eight 32-bit decimal numbers represent the 32 bytes of the SHA256 hash of the capability name.
    You can programmatically generate these app capability SIDs by calling Derive­Capability­Sids­From­Name.

    .EXAMPLE
    ConvertFrom-AppCapabilitySid -SID 'S-1-15-3-1'

    .INPUTS
    System.String

    .OUTPUTS
    PSCustomObject with SID information and friendly names.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertFrom-AppCapabilitySid')]

    param (

        [string]$SID

    )

    $KnownDeviceInterfaceGuids = @{
        'BFA794E4-F964-4FDB-90F6-51056BFE4B44' = [PSCustomObject]@{
            'SID'             = $SID
            'SchemaClassName' = 'group'
            'Description'     = 'Apps with Location Services access (device capability {BFA794E4-F964-4FDB-90F6-51056BFE4B44})'
            'Name'            = 'Location services'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Location services'
        }
        'E5323777-F976-4f5b-9B55-B94699C46E44' = [PSCustomObject]@{
            'SID'             = $SID
            'SchemaClassName' = 'group'
            'Description'     = 'Apps with Camera access (device capability {E5323777-F976-4f5b-9B55-B94699C46E44})'
            'Name'            = 'Your camera'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your camera'
        }
        '2EEF81BE-33FA-4800-9670-1CD474972C3F' = [PSCustomObject]@{
            'SID'             = $SID
            'SchemaClassName' = 'group'
            'Description'     = 'Apps with Microphone access (device capability {2EEF81BE-33FA-4800-9670-1CD474972C3F})'
            'Name'            = 'Your microphone'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your microphone'
        }
        '52079E78-A92B-413F-B213-E8FE35712E72' = [PSCustomObject]@{
            'SID'             = $SID
            'SchemaClassName' = 'group'
            'Description'     = 'Apps with Notifications access (device capability {52079E78-A92B-413F-B213-E8FE35712E72})'
            'Name'            = 'Your notifications'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your notifications'
        }
        'C1D23ACC-752B-43E5-8448-8D0E519CD6D6' = [PSCustomObject]@{
            'SID'             = $SID
            'SchemaClassName' = 'group'
            'Description'     = 'Apps with Account Information access (name, picture, etc.) (device capability {C1D23ACC-752B-43E5-8448-8D0E519CD6D6})'
            'Name'            = 'Your account information'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your account information'
        }
        '7D7E8402-7C54-4821-A34E-AEEFD62DED93' = [PSCustomObject]@{
            'SID'             = $SID
            'SchemaClassName' = 'group'
            'Description'     = 'Apps with Contacts access (device capability {7D7E8402-7C54-4821-A34E-AEEFD62DED93})'
            'Name'            = 'Your contacts'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your contacts'
        }
        'D89823BA-7180-4B81-B50C-7E471E6121A3' = [PSCustomObject]@{
            'SID'             = $SID
            'SchemaClassName' = 'group'
            'Description'     = 'Apps with Calendar access (device capability {D89823BA-7180-4B81-B50C-7E471E6121A3})'
            'Name'            = 'Your calendar'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your calendar'
        }
        '8BC668CF-7728-45BD-93F8-CF2B3B41D7AB' = [PSCustomObject]@{
            'SID'             = $SID
            'SchemaClassName' = 'group'
            'Description'     = 'Apps with Call History access (device capability {8BC668CF-7728-45BD-93F8-CF2B3B41D7AB})'
            'Name'            = 'Your call history'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your call history'
        }
        '9231CB4C-BF57-4AF3-8C55-FDA7BFCC04C5' = [PSCustomObject]@{
            'SID'             = $SID
            'SchemaClassName' = 'group'
            'Description'     = 'Apps with access to read and send Email (device capability {9231CB4C-BF57-4AF3-8C55-FDA7BFCC04C5})'
            'Name'            = 'Email'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Email'
        }
        '21157C1F-2651-4CC1-90CA-1F28B02263F6' = [PSCustomObject]@{
            'SID'             = $SID
            'SchemaClassName' = 'group'
            'Description'     = 'Apps with access to read and send SMS and MMS messages (device capability {21157C1F-2651-4CC1-90CA-1F28B02263F6})'
            'Name'            = 'Messages (text or MMS)' #c_media.inf
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Messages (text or MMS)'
        }
        'A8804298-2D5F-42E3-9531-9C8C39EB29CE' = [PSCustomObject]@{
            'SID'             = $SID
            'SchemaClassName' = 'group'
            'Description'     = 'Apps with access to control radios (device capability {A8804298-2D5F-42E3-9531-9C8C39EB29CE})'
            'Name'            = 'Radio control'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Radio control'
        }
        '9D9E0118-1807-4F2E-96E4-2CE57142E196' = [PSCustomObject]@{
            'SID'             = $SID
            'SchemaClassName' = 'group'
            'Description'     = 'Apps with Activity Sensor access (device capability {9D9E0118-1807-4F2E-96E4-2CE57142E196})'
            'Name'            = 'Your activity sensors'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your activity sensors'
        } #c_sensor.inf
        'B19F89AF-E3EB-444B-8DEA-202575A71599' = [PSCustomObject]@{
            'SID'             = $SID
            'SchemaClassName' = 'group'
            'Description'     = 'Apps with access to unknown device capability {B19F89AF-E3EB-444B-8DEA-202575A71599})'
            'Name'            = 'Unknown device capability from SettingsHandlers_Privacy.dll {B19F89AF-E3EB-444B-8DEA-202575A71599}'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Unknown device capability from SettingsHandlers_Privacy.dll {B19F89AF-E3EB-444B-8DEA-202575A71599}'
        } #SettingsHandlers_Privacy.dll
        'E6AD100E-5F4E-44CD-BE0F-2265D88D14F5' = [PSCustomObject]@{
            'SID'             = $SID
            'SchemaClassName' = 'group'
            'Description'     = 'Apps with access to unknown device capability {E6AD100E-5F4E-44CD-BE0F-2265D88D14F5})'
            'Name'            = 'Unknown device capability from LocationPermissions.dll {E6AD100E-5F4E-44CD-BE0F-2265D88D14F5}'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Unknown device capability from LocationPermissions.dll {E6AD100E-5F4E-44CD-BE0F-2265D88D14F5}'
        } #LocationPermissions.dll
        'E83AF229-8640-4D18-A213-E22675EBB2C3' = [PSCustomObject]@{
            'SID'             = $SID
            'SchemaClassName' = 'group'
            'Description'     = 'Apps with Custom Sensor access (device capability {E83AF229-8640-4D18-A213-E22675EBB2C3})'
            'Name'            = 'Custom Sensor device capability'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your custom sensors'
        } #c_sensor.inf
    }

    $Split = $SID.Split('-')
    switch ($Split.Count) {

        # Autogenerated device capability
        8 { $CountOf32BitNumbers = 4 ; break }

        # Autogenerated app capability which cannot be translated.
        13 {
            $Capability = $Split[5..12] -join '-'
            return [PSCustomObject]@{
                'SID'             = $SID
                'SchemaClassName' = 'group'
                'Description'     = "Apps w/ App Capability $Capability"
                'Name'            = $SID
                'NTAccount'       = "APPLICATION PACKAGE AUTHORITY\$SID"
            }
        }

        # NO MATCH
        default {
            return [PSCustomObject]@{
                'SID'             = $SID
                'SchemaClassName' = 'group'
                'Description'     = "Unknown App Capability $SID"
                'Name'            = $SID
                'NTAccount'       = "APPLICATION PACKAGE AUTHORITY\$SID"
            }
        }
    }
    $Substring = $SID
    $i = 0
    $ReversedDecimal = do {
        $Last = $Substring.LastIndexOf('-')
        $Substring.Substring($Last + 1, $Substring.Length - $Last - 1)
        $Substring = $Substring.Substring(0, $Last) ; $i++
    } while ($i -lt $CountOf32BitNumbers)
    $Bytes = For ($n = ($ReversedDecimal.Length - 1); $n -ge 0 ; $n = $n - 1 ) {
        $ThisNumber = $ReversedDecimal[$n]
        for ( $i = 3; $i -ge 0; $i-- ) {
            '{0:X2}' -f ($ThisNumber -band 0xff) #ugly and hard to read
            #[convert]::tostring(($ThisNumber -band 0xff), 16) # does not add leading zeroes
            $ThisNumber = $ThisNumber -shr 8
        }
    }

    $Guid = $Bytes[3], $Bytes[2], $Bytes[1], $Bytes[0], '-', $Bytes[5], $Bytes[4], '-', $Bytes[7], $Bytes[6], '-', $Bytes[8], $Bytes[9], '-', $($Bytes[10..15] -join '') -join ''

    $KnownGuid = $KnownDeviceInterfaceGuids[$Guid]
    if ($KnownGuid) {
        return $KnownGuid
    } else {
        return [PSCustomObject]@{
            'SID'             = $SID
            'Description'     = "Apps w/ access to app capability {$Guid}"
            'SchemaClassName' = 'group'
            'Name'            = $SID
            'DisplayName'     = $SID
            'SamAccountName'  = $SID
            'NTAccount'       = "APPLICATION PACKAGE AUTHORITY\$SID"
        }
    }
}
function ConvertFrom-ScShowSidResult {

    # Convert the results from sc.exe into an object

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertFrom-ScShowSidResult')]

    param (

        [string[]]$Result

    )

    $dict = @{}
    ForEach ($Line in $Result) {

        if ([string]::IsNullOrEmpty($Line)) {
            if ($dict.Keys.Count -ge 1) {
                [PSCustomObject]$dict
                $dict = @{}
                continue
            }
        } else {
            $Prop, $Value = ($Line -split ':').Trim()
            $dict[$Prop] = $Value
        }

    }
    if ($dict.Keys.Count -ge 1) {
        [PSCustomObject]$dict
    }
}
function ConvertTo-AccountCache {
    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertTo-AccountCache')]

    param (

        $Account,

        [ref]$SidCache,

        [ref]$NameCache

    )

    ForEach ($ThisAccount in $Account) {
        $SidCache.Value[$ThisAccount.SID] = $ThisAccount
        $NameCache.Value[$ThisAccount.Name] = $ThisAccount
    }

}
function ConvertTo-DirectoryEntry {

    <#
.SYNOPSIS

Converts identity information to a DirectoryEntry object.

.DESCRIPTION
Attempts to retrieve or create a DirectoryEntry object for an identity based on various
identification methods. It will use cached well-known SID information when available,
query directory services for LDAP or WinNT identities, handle unresolved SIDs, and create
fake directory entries for special cases like capability SIDs or service SIDs.

.EXAMPLE
ConvertTo-DirectoryEntry -IdentityReference "DOMAIN\User" -DomainNetBIOS "DOMAIN" -Cache $cacheRef

.INPUTS
None. Pipeline input is not accepted.

.OUTPUTS
System.DirectoryServices.DirectoryEntry or a custom object that mimics DirectoryEntry.
#>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertTo-DirectoryEntry')]

    param (

        $CachedWellKnownSID,

        $DomainNetBIOS,

        $AccountProperty,

        $SamAccountNameOrSid,

        $AceGuid,

        $LogSuffixComment,

        $IdentityReference,

        $DomainDn,

        [ref]$Cache

    )

    if ($CachedWellKnownSID) {

        $FakeDirectoryEntryParams = @{
            DirectoryPath = "WinNT://$DomainNetBIOS/$($CachedWellKnownSID.Name)"
            InputObject   = $CachedWellKnownSID
        }

        $DirectoryEntry = ConvertTo-FakeDirectoryEntry @FakeDirectoryEntryParams
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
    $SearchSplat = @{}
    $CurrentDomain = $Cache.Value['ThisParentDomain']
    $SampleAce = $Cache.Value['AceByGUID'].Value[@($AceGuid)[0]]

    if (

        $null -ne $SamAccountNameOrSid -and
        $SampleAce.AdsiProvider -eq 'LDAP'

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
        Write-LogMsg @Log -Text 'Search-Directory' -Expand $DirectoryParams, $SearchSplat -ExpansionMap $Cache.Value['LogCacheMap'].Value

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
        $IdentityReference.Substring(0, $IdentityReference.LastIndexOf('-') + 1) -eq $CurrentDomain.Value.SIDString
    ) {

        #Write-LogMsg @Log -Text " # Detected an unresolved SID from the current domain"

        # Get the distinguishedName and netBIOSName of the current domain.  This also determines whether the domain is online.
        $DomainDN = $CurrentDomain.Value.distinguishedName.Value
        $DomainFQDN = ConvertTo-Fqdn -DistinguishedName $DomainDN -Cache $Cache
        $SearchSplat['DirectoryPath'] = "LDAP://$DomainFQDN/cn=partitions,cn=configuration,$DomainDn"
        $SearchSplat['Filter'] = "(&(objectcategory=crossref)(dnsroot=$DomainFQDN)(netbiosname=*))"
        $SearchSplat['PropertiesToLoad'] = 'netbiosname'
        Write-LogMsg @Log -Text 'Search-Directory' -Expand $DirectoryParams, $SearchSplat -ExpansionMap $Cache.Value['LogCacheMap'].Value
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
        Write-LogMsg @Log -Text 'Search-Directory' -Expand $DirectoryParams, $SearchSplat -ExpansionMap $Cache.Value['LogCacheMap'].Value

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

            $DirectoryEntry = ConvertTo-FakeDirectoryEntry @FakeDirectoryEntryParams
            return $DirectoryEntry

        }

        #Write-LogMsg @Log -Text " # Detected an unresolved SID" -Cache $Cache

        # The SID of the domain is the SID of the user minus the last block of numbers
        $DomainSid = $SamAccountNameOrSid.Substring(0, $SamAccountNameOrSid.LastIndexOf('-'))

        # Determine if SID belongs to current domain
        #if ($DomainSid -eq $CurrentDomain.Value.SIDString) {
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

        Write-LogMsg @Log -Text "`$UsersGroup = Get-DirectoryEntry -DirectoryPath '$DirectoryPath'" -Expand $DirectoryParams -ExpansionMap $Cache.Value['LogCacheMap'].Value

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

        $DirectoryEntry = $MembersOfUsersGroup | Where-Object -FilterScript {
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

    Write-LogMsg @Log -Text "`$DirectoryEntry = Get-DirectoryEntry -DirectoryPath '$DirectoryPath'" -Expand $DirectoryParams -ExpansionMap $Cache.Value['LogCacheMap'].Value

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
function ConvertTo-PermissionPrincipal {

    <#
.SYNOPSIS

Converts directory entry information into a permission principal object.

.DESCRIPTION
Takes directory entry information along with domain and identity details to create a standardized
permission principal object that can be used throughout the permission analysis process.
This function populates a cache of permission principals that can be referenced by identity.
It handles both LDAP and WinNT directory providers and processes group membership information.

.EXAMPLE
ConvertTo-PermissionPrincipal -IdentityReference "DOMAIN\User" -DirectoryEntry $dirEntry -Cache $cacheRef

.INPUTS
System.DirectoryServices.DirectoryEntry

.OUTPUTS
None. This function populates the PrincipalById cache with permission principal objects.
#>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertTo-PermissionPrincipal')]

    param (

        $DomainDn,

        $DomainNetBIOS,

        $IdentityReference,

        $DirectoryEntry,

        $NoGroupMembers,

        $LogSuffixComment,

        $SamAccountNameOrSid,

        $AceGuid,

        # Properties of each Account to display on the report
        [string[]]$AccountProperty = @('DisplayName', 'Company', 'Department', 'Title', 'Description'),

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $Log = @{
        'Cache'  = $Cache
        'Suffix' = $LogSuffixComment
    }

    $PropertiesToAdd = @{
        'DomainDn'            = $DomainDn
        'DomainNetbios'       = $DomainNetBIOS
        'ResolvedAccountName' = $IdentityReference
    }

    # Add the bare minimum required properties
    $PropertiesToLoad = $AccountProperty + @(
        'distinguishedName',
        'grouptype',
        'member',
        'name',
        'objectClass',
        'objectSid',
        'primaryGroupToken',
        'samAccountName'
    )

    $PropertiesToLoad = $PropertiesToLoad |
        Sort-Object -Unique

    $PrincipalById = $Cache.Value['PrincipalById']

    if ($null -ne $DirectoryEntry) {

        ForEach ($Prop in $DirectoryEntry.PSObject.Properties.GetEnumerator().Name) {
            $null = ConvertTo-SimpleProperty -InputObject $DirectoryEntry -Property $Prop -PropertyDictionary $PropertiesToAdd
        }

        if ($DirectoryEntry.Name) {
            $AccountName = $DirectoryEntry.Name
        } else {

            if ($DirectoryEntry.Properties) {

                if ($DirectoryEntry.Properties['name'].Value) {
                    $AccountName = $DirectoryEntry.Properties['name'].Value
                } else {
                    $AccountName = $DirectoryEntry.Properties['name']
                }

            }

        }

        $PropertiesToAdd['ResolvedAccountName'] = "$DomainNetBIOS\$AccountName"

        # WinNT objects have a SchemaClassName property which is a string
        # LDAP objects have an objectClass property which is an ordered list of strings, the last being the class name of the object instance
        # ToDo: LDAP objects may have SchemaClassName too.  When/why?  Should I just request it always in the list of properties?
        # ToDo: Actually I should create an AdsiObjectType property of my own or something...don't expose the dependency
        if (-not $DirectoryEntry.SchemaClassName) {
            $PropertiesToAdd['SchemaClassName'] = @($DirectoryEntry.Properties['objectClass'])[-1] #untested but should work, last value should be the correct one https://learn.microsoft.com/en-us/windows/win32/ad/retrieving-the-objectclass-property
        }

        if ($NoGroupMembers -eq $false) {

            if (

                # WinNT DirectoryEntries do not contain an objectClass property
                # If this property exists it is an LDAP DirectoryEntry rather than WinNT
                $PropertiesToAdd.ContainsKey('objectClass')

            ) {

                # Retrieve the members of groups from the LDAP provider
                Write-LogMsg @Log -Text "Get-AdsiGroupMember -Group `$DirectoryEntry -Cache `$Cache # is an LDAP security principal $LogSuffix"
                $Members = (Get-AdsiGroupMember -Group $DirectoryEntry -PropertiesToLoad $PropertiesToLoad -Cache $Cache).FullMembers

            } else {

                #Write-LogMsg @Log -Text " # '$($DirectoryEntry.Path)' is a WinNT security principal $LogSuffix"

                if ( $DirectoryEntry.SchemaClassName -in @('group', 'SidTypeWellKnownGroup', 'SidTypeAlias')) {

                    Write-LogMsg @Log -Text "Get-WinNTGroupMember -DirectoryEntry `$DirectoryEntry -Cache `$Cache # is a WinNT group $LogSuffix"
                    $Members = Get-WinNTGroupMember -DirectoryEntry $DirectoryEntry -PropertiesToLoad $PropertiesToLoad -Cache $Cache

                }

            }

            # (Get-AdsiGroupMember).FullMembers or Get-WinNTGroupMember could return an array with null members so we must verify that is not true
            if ($Members) {

                $GroupMembers = ForEach ($ThisMember in $Members) {

                    if ($ThisMember.Domain) {

                        # Include specific desired properties
                        $OutputProperties = @{}

                    } else {

                        # Include specific desired properties
                        $OutputProperties = @{

                            Domain = [pscustomobject]@{
                                'Dns'     = $DomainNetBIOS
                                'Netbios' = $DomainNetBIOS
                                'Sid'     = @($SamAccountNameOrSid -split '-')[-1]
                            }

                        }

                    }

                    # Get any existing properties for inclusion later
                    $InputProperties = $ThisMember.PSObject.Properties.GetEnumerator().Name

                    # Include any existing properties found earlier
                    ForEach ($ThisProperty in $InputProperties) {
                        $null = ConvertTo-SimpleProperty -InputObject $ThisMember -Property $ThisProperty -PropertyDictionary $OutputProperties
                    }

                    if ($ThisMember.sAmAccountName) {
                        $ResolvedAccountName = "$($OutputProperties['Domain'].Netbios)\$($ThisMember.sAmAccountName)"
                    } else {
                        $ResolvedAccountName = "$($OutputProperties['Domain'].Netbios)\$($ThisMember.Name)"
                    }

                    $OutputProperties['ResolvedAccountName'] = $ResolvedAccountName
                    $PrincipalById.Value[$ResolvedAccountName] = [PSCustomObject]$OutputProperties

                    ForEach ($ACE in $AceGuid) {
                        Add-PermissionCacheItem -Cache $AceGuidByID -Key $ResolvedAccountName -Value $ACE -Type ([System.Guid])
                    }

                    $ResolvedAccountName

                }

            }

            #Write-LogMsg @Log -Text " # '$($DirectoryEntry.Path)' has $(($Members | Measure-Object).Count) members $LogSuffix"

        }

        $PropertiesToAdd['Members'] = $GroupMembers

    } else {

        $StartingLogType = $Cache.Value['LogType'].Value
        $Cache.Value['LogType'].Value = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
        Write-LogMsg @Log -Text " # No matching DirectoryEntry $LogSuffix"
        $Cache.Value['LogType'].Value = $StartingLogType

    }

    $PrincipalById.Value[$IdentityReference] = [PSCustomObject]$PropertiesToAdd

}
function ConvertTo-ServiceSID {

    <#
    .SYNOPSIS
    This script calculates the SID of a Virtual Service Account.
    .DESCRIPTION
    Virtual service accounts are used by Windows Server 2008 and later to isolate services without the
    complexity of password management and local accounts.  However, the SID for these accounts is not
    stored in the SAM database.  Instead, it is calculated based on the service name.  This script
    performs that calculation to arrive at the SID for a service account.  This same calculation
    can be preformed by the sc.exe ustility using "sc.exe showsid <service_name>".
    .LINK
    https://pcsxcetrasupport3.wordpress.com/2013/09/08/how-do-you-get-a-service-sid-from-a-service-name/
    .NOTES
        File Name  :
        Get-ServiceAccountSid.ps1
        Authors    :
            LandOfTheLostPass (www.reddit.com/u/LandOfTheLostPass)
        Version History:
            2016-10-06 - Inital Script Creation
    .EXAMPLE
    Get-ServiceAccountSid -ServiceName "MSSQLSERVER"
    .PARAMETER ServiceName
    The name of the service to calculate the sid for (case insensitive)
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertTo-ServiceSID')]
    [OutputType([string])]

    Param (

        [Parameter(position = 0, mandatory = $true)]
        [string]$ServiceName

    )

    #2: Convert service name to upper case.
    $UppercaseName = $ServiceName.ToUpper()

    #3: Get the Unicode bytes()  from the upper case service name.
    $nameBytes = [System.Text.Encoding]::Unicode.GetBytes($UppercaseName)

    #4: Run bytes() thru the sha1 hash function.
    $hashBytes = ([System.Security.Cryptography.SHA1]::Create()).ComputeHash($nameBytes, 0, $nameBytes.Length)

    #5: Reverse the byte() string returned from the SHA1 hash function (on Little Endian systems Not tested on Big Endian systems)
    [Array]::Reverse($hashBytes)
    [string[]]$hashString = $hashBytes | ForEach-Object { $_.ToString('X2') }

    #6: Split the reversed string into 5 blocks of 4 bytes each.
    $blocks = @()
    for ($i = 0; $i -lt 5; $i++) {

        #7: Convert each block of hex bytes() to Decimal
        $blocks += [Convert]::ToInt64("0x$([String]::Join([String]::Empty, $hashString, ($i * 4), 4))", 16)

    }

    #8: Reverse the Position of the blocks
    [Array]::Reverse($blocks)

    #9: Create the first part of the SID “S-1-5-80“
    #10: Tack on each block of Decimal strings with a “-“ in between each block that was converted and reversed.
    #11: Finally out put the complete SID for the service.
    return "S-1-5-80-$([String]::Join('-', $blocks))"

}
function ConvertTo-SidString {

    <#
.SYNOPSIS

Converts an NT account name to a SID string.

.DESCRIPTION
Attempts to translate an NT account name (domain\username format) to its corresponding Security Identifier (SID) string.
Uses the .NET Framework's NTAccount and SecurityIdentifier classes for the translation.

.EXAMPLE
ConvertTo-SidString -ServerNetBIOS 'CONTOSO' -Name 'Administrator' -Cache $cacheRef

.INPUTS
System.String

.OUTPUTS
System.Security.Principal.SecurityIdentifier
#>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertTo-SidString')]

    param (

        [string]$ServerNetBIOS,

        [string]$Name,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    # Try to resolve the account against the server the Access Control Entry came from (which may or may not be the directory server for the account)
    Write-LogMsg -Text "[System.Security.Principal.NTAccount]::new('$ServerNetBIOS', '$Name').Translate([System.Security.Principal.SecurityIdentifier])" -Cache $Cache
    $NTAccount = [System.Security.Principal.NTAccount]::new($ServerNetBIOS, $Name)

    try {
        & { $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]) } 2>$null
    } catch {

        $Log['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
        Write-LogMsg -Text " # '$ServerNetBIOS\$Name' could not be translated from NTAccount to SID: $($_.Exception.Message)" -Cache $Cache

    }

}
function Find-AdsiProvider {

    <#
        .SYNOPSIS

        Determine whether a directory server is an LDAP or a WinNT server
        .DESCRIPTION
        Uses CIM to look for open TCP port 389 indicating LDAP, otherwise assumes WinNT.
        If CIM is unavailable, uses the ADSI provider to attempt to query the server using LDAP first, then WinNT second.
        .INPUTS
        [System.String] AdsiServer parameter.
        .OUTPUTS
        [System.String] Possible return values are:
            None
            LDAP
            WinNT
        .EXAMPLE
        Find-AdsiProvider -AdsiServer localhost

        Find the ADSI provider of the local computer
        .EXAMPLE
        Find-AdsiProvider -AdsiServer 'ad.contoso.com'

        Find the ADSI provider of the AD domain 'ad.contoso.com'
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Find-AdsiProvider')]
    [OutputType([System.String])]

    param (

        # IP address or hostname of the directory server whose ADSI provider type to determine
        [string]$AdsiServer,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $CommandParameters = @{
        Cache        = $Cache
        ComputerName = $AdsiServer
        ErrorAction  = 'Ignore'
        KeyProperty  = 'LocalPort'
        Namespace    = 'ROOT/StandardCimv2'
        Query        = 'Select * From MSFT_NetTCPConnection Where LocalPort = 389'
    }

    Write-LogMsg -Text 'Get-CachedCimInstance' -Expand $CommandParameters -ExpansionMap $Cache.Value['LogCacheMap'].Value -Cache $Cache
    $CimInstance = Get-CachedCimInstance @CommandParameters

    if ($Cache.Value['CimCache'].Value[$AdsiServer].Value.TryGetValue( 'CimFailure' , [ref]$null )) {
        ###Write-LogMsg -Text " # CIM connection failure # for '$AdsiServer'" -Cache $Cache
        $TestResult = Test-AdsiProvider -AdsiServer $AdsiServer -Cache $Cache
        return $TestResult
    }

    if ($CimInstance) {
        return 'LDAP'
    } else {
        return 'WinNT'
    }

}
function Find-CachedWellKnownSID {
    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Find-CachedWellKnownSID')]

    param (

        [Parameter(Mandatory)]
        [ref]$DomainByNetbios,

        [string]$IdentityReference,

        [string]$DomainNetBIOS

    )

    $DomainNetbiosCacheResult = $null
    $TryGetValueResult = $DomainByNetbios.Value.TryGetValue($DomainNetBIOS, [ref]$DomainNetbiosCacheResult)

    if ($TryGetValueResult) {

        ForEach ($Cache in 'WellKnownSidBySid', 'WellKnownSIDByName') {

            if ($DomainNetbiosCacheResult.$Cache) {

                $WellKnownSidCacheResult = $DomainNetbiosCacheResult.$Cache[$IdentityReference]

                if ($WellKnownSidCacheResult) {

                    $Properties = @{
                        IdentityReference        = $IdentityReference
                        SIDString                = $WellKnownSidCacheResult.SID
                        IdentityReferenceNetBios = "$DomainNetBIOS\$($WellKnownSidCacheResult.Name)"
                        IdentityReferenceDns     = "$($DomainNetbiosCacheResult.Dns)\$($WellKnownSidCacheResult.Name)"
                    }

                    ForEach ($Prop in $WellKnownSidCacheResult.PSObject.Properties.GetEnumerator().Name) {
                        $Properties[$Prop] = $WellKnownSidCacheResult.$Prop
                    }

                    return [PSCustomObject]$Properties

                } else {
                    #Write-LogMsg @LogParams -Text " # '$Cache' cache miss for '$IdentityReference' on '$DomainNetBIOS'"
                }

            } else {
                #Write-LogMsg @LogParams -Text " # No '$Cache' cache found for '$DomainNetBIOS'"
            }

        }

    } else {
        #Write-LogMsg @LogParams -Text " # Domain NetBIOS cache miss for '$DomainNetBIOS'"
    }

}
function Find-WinNTGroupMember {

    <#
    .SYNOPSIS
        Finds and categorizes LDAP and WinNT group members from a WinNT group's COM objects.

    .DESCRIPTION
        The Find-WinNTGroupMember function processes COM objects from the IADsGroup::Members method
        to identify and categorize group members. It converts COM objects into directory paths and
        uses contextual information to determine whether each member represents an LDAP or WinNT
        group member.

        The function analyzes the ADSI provider for each member's domain and categorizes them
        accordingly:
        - LDAP members are added to domain-specific LDAP queries for efficient batch processing
        - WinNT members are collected for individual WinNT provider access
        - Unknown providers default to WinNT for compatibility

        This categorization allows the calling code to optimize directory queries by grouping
        LDAP members into batch queries while handling WinNT members individually.

    .EXAMPLE
        $out = @{ 'LDAP://domain.com' = @(); 'WinNTMembers' = @() }
        Find-WinNTGroupMember -DirectoryEntry $groupEntry -ComObject $members -Out $out -Cache ([ref]$cache)

        This example processes group members and categorizes them into the output hashtable.

    .EXAMPLE
        $members = $group.Invoke('Members')
        $results = @{}
        Find-WinNTGroupMember -DirectoryEntry $group -ComObject $members -Out $results -LogSuffix 'from local group' -Cache ([ref]$cache)

        This example shows processing members with a custom log suffix for tracking.

    .INPUTS
        System.DirectoryServices.DirectoryEntry
        System.Object (COM Objects)
        System.Collections.Hashtable
        System.String

    .OUTPUTS
        None. The function modifies the passed hashtable reference to categorize members.

    .NOTES
        Author: IMJLA
        This function is part of the ADSI module for Active Directory and WinNT group processing.

        The function handles several scenarios:
        - LDAP domain members are collected into SAM account name queries
        - WinNT local members are stored as resolved directory paths
        - Unknown providers are logged as warnings and treated as WinNT
        - Well-known SID authorities are resolved to computer names

        Performance considerations:
        - Uses caching to reduce repeated ADSI server lookups
        - Groups LDAP queries for batch processing efficiency
        - Resolves SID authorities once per member

    .LINK
        https://IMJLA.github.io/Adsi/docs/en-US/Find-WinNTGroupMember

    .LINK
        Get-AdsiServer

    .LINK
        Split-DirectoryPath
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Find-WinNTGroupMember')]

    param (

        # DirectoryEntry [System.DirectoryServices.DirectoryEntry] of the WinNT group whose members to get
        $DirectoryEntry,

        # COM Objects representing the DirectoryPaths of the group members
        $ComObject,

        # Hashtable to store categorized results with keys for LDAP queries and WinNT members
        [hashtable]$Out,

        # String to append to log messages for context and debugging
        [string]$LogSuffix,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    ForEach ($DirectoryMember in $ComObject) {

        # Convert the ComObjects into DirectoryEntry objects.
        $DirectoryPath = Invoke-ComObject -ComObject $DirectoryMember -Property 'ADsPath'

        $Log = @{ 'Cache' = $Cache ; 'Suffix' = " # for member of WinNT group; member path '$DirectoryPath' $LogSuffix" }

        # Split the DirectoryPath into its constituent components.
        $DirectorySplit = Split-DirectoryPath -DirectoryPath $DirectoryPath
        $MemberName = $DirectorySplit['Account']

        # Resolve well-known SID authorities to the name of the computer the DirectoryEntry came from.
        Resolve-SidAuthority -DirectorySplit $DirectorySplit -DirectoryEntry $DirectoryEntry
        $ResolvedDirectoryPath = $DirectorySplit['ResolvedDirectoryPath']
        $MemberDomainNetbios = $DirectorySplit['ResolvedDomain']
        Write-LogMsg @Log -Text "Get-AdsiServer -Netbios '$MemberDomainNetbios' -Cache `$Cache"
        $AdsiServer = Get-AdsiServer -Netbios $MemberDomainNetbios -Cache $Cache

        if ($AdsiServer) {

            if ($AdsiServer.AdsiProvider -eq 'LDAP') {

                #Write-LogMsg @Log -Text " # ADSI provider is LDAP for domain NetBIOS '$MemberDomainNetbios'"
                $Out["LDAP://$($AdsiServer.Dns)"] += "(samaccountname=$MemberName)"

            } elseif ($AdsiServer.AdsiProvider -eq 'WinNT') {

                #Write-LogMsg @Log -Text " # ADSI provider is WinNT for domain NetBIOS '$MemberDomainNetbios'"
                $Out['WinNTMembers'] += $ResolvedDirectoryPath

            } else {

                $StartingLogType = $Cache.Value['LogType'].Value
                $Cache.Value['LogType'].Value = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
                Write-LogMsg @Log -Text " # Could not find ADSI provider. WinNT will be assumed # for domain NetBIOS '$MemberDomainNetbios'"
                $Cache.Value['LogType'].Value = $StartingLogType

            }

        } else {

            $StartingLogType = $Cache.Value['LogType'].Value
            $Cache.Value['LogType'].Value = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
            Write-LogMsg @Log -Text " # Could not find ADSI server to find ADSI provider. WinNT will be assumed # for domain NetBIOS '$MemberDomainNetbios'"
            $Cache.Value['LogType'].Value = $StartingLogType

        }

    }

}
function Get-CachedDirectoryEntry {

    <#
    .SYNOPSIS
        Search the cache of CIM instances and well-known SIDs for the DirectoryEntry

    .DESCRIPTION
        The Get-CachedDirectoryEntry function searches through various in-memory caches to find
        directory entries for a given server and account name combination. It searches through:
        - Domain cache by FQDN
        - Domain cache by NetBIOS name
        - Domain cache by SID

        For each domain cache, it looks for matches in:
        - Well-known SID cache by SID (Server\AccountName format)
        - Well-known SID cache by Name (AccountName only)

        When a match is found, it converts the cached result to a fake directory entry object
        that can be used in place of an actual DirectoryEntry object, improving performance
        by avoiding expensive directory service calls.

    .EXAMPLE
        $cache = @{ DomainByFqdn = @{}; DomainByNetbios = @{}; DomainBySid = @{} }
        $entry = Get-CachedDirectoryEntry -DirectoryPath "LDAP://DC=contoso,DC=com" -Server "contoso.com" -AccountName "Administrator" -Cache ([ref]$cache)

        Searches for a cached directory entry for the Administrator account on contoso.com domain.

    .EXAMPLE
        $sidTypeMap = Get-SidTypeMap
        $entry = Get-CachedDirectoryEntry -Server "WORKGROUP01" -AccountName "Guest" -SidTypeMap $sidTypeMap -Cache ([ref]$domainCache)

        Searches for a cached directory entry for the Guest account using a custom SID type mapping.

    .INPUTS
        None. This function does not accept pipeline input.

    .OUTPUTS
        System.DirectoryServices.DirectoryEntry
        Returns a fake directory entry object if found in cache, otherwise returns nothing.

    .NOTES
        This function is designed for performance optimization by avoiding repeated directory
        service queries for well-known accounts and previously resolved entries.

        The function searches caches in the following order:
        1. DomainByFqdn cache
        2. DomainByNetbios cache
        3. DomainBySid cache

        For each domain cache, it first searches by SID (Server\AccountName), then by Name (AccountName).

    .LINK
        Get-SidTypeMap

    .LINK
        ConvertTo-FakeDirectoryEntry
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Get-CachedDirectoryEntry')]

    param (

        # Path to the directory object to retrieve. Defaults to the root of the current domain if not specified.
        [string]$DirectoryPath = (([System.DirectoryServices.DirectorySearcher]::new()).SearchRoot.Path),

        # Server name (FQDN, NetBIOS, or SID) to search for in the domain caches.
        [string]$Server,

        # Account name to search for in the well-known SID caches.
        [string]$AccountName,

        # Hashtable mapping SID types to their corresponding schema class names. Used to determine the appropriate schema class for fake directory entries.
        [hashtable]$SidTypeMap = (Get-SidTypeMap),

        # In-process cache containing domain and well-known SID information. Passed by reference to reduce calls to other processes or to disk.
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $ID = "$Server\$AccountName"
    $DomainCacheResult = $null
    $TryGetValueResult = $Cache.Value['DomainByFqdn'].Value.TryGetValue($Server, [ref]$DomainCacheResult)

    if ($TryGetValueResult) {

        $SIDCacheResult = $DomainCacheResult.WellKnownSIDBySID[$ID]

        if ($SIDCacheResult) {

            #Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Known SID cache hit on this server."

            if ($SIDCacheResult.SIDType) {
                ConvertTo-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $SIDCacheResult -SchemaClassName $SidTypeMap[[int]$SIDCacheResult.SIDType]
            } else {
                ConvertTo-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $SIDCacheResult
            }


        } else {

            #Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Known SID cache miss on this server."
            $NameCacheResult = $DomainCacheResult.WellKnownSIDByName[$AccountName]

            if ($NameCacheResult) {

                #Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Name '$AccountName' # Known Name cache hit on this server."

                if ($NameCacheResult.SIDType) {
                    ConvertTo-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $NameCacheResult -SchemaClassName $SidTypeMap[[int]$NameCacheResult.SIDType]
                } else {
                    ConvertTo-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $NameCacheResult
                }

            } else {
                #Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Name '$AccountName' # Known Name cache miss on this server."
            }
        }

    } else {

        $DomainCacheResult = $null
        $TryGetValueResult = $Cache.Value['DomainByNetbios'].Value.TryGetValue($Server, [ref]$DomainCacheResult)

        if ($TryGetValueResult) {

            $SIDCacheResult = $DomainCacheResult.WellKnownSIDBySID[$ID]

            if ($SIDCacheResult) {

                #Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Known SID cache hit on this server."

                if ($SIDCacheResult.SIDType) {
                    ConvertTo-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $SIDCacheResult -SchemaClassName $SidTypeMap[[int]$SIDCacheResult.SIDType]
                } else {
                    ConvertTo-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $SIDCacheResult
                }

            } else {

                #Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Known SID cache miss on this server."
                $NameCacheResult = $DomainCacheResult.WellKnownSIDByName[$AccountName]

                if ($NameCacheResult) {

                    #Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Name '$AccountName' # Known Name cache hit on this server."Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Well-known SID by name cache hit for '$AccountName' on host with NetBIOS '$Server'"

                    if ($NameCacheResult.SIDType) {
                        ConvertTo-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $NameCacheResult -SchemaClassName $SidTypeMap[[int]$NameCacheResult.SIDType]
                    } else {
                        ConvertTo-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $NameCacheResult
                    }

                } else {
                    #Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Name '$AccountName' # Known Name cache miss on this server."
                }

            }

        } else {

            $DomainCacheResult = $null
            $TryGetValueResult = $Cache.Value['DomainBySid'].Value.TryGetValue($Server, [ref]$DomainCacheResult)

            if ($TryGetValueResult) {

                $SIDCacheResult = $DomainCacheResult.WellKnownSIDBySID[$ID]

                if ($SIDCacheResult) {

                    #Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Known SID cache hit on this server."
                    ConvertTo-FakeDirectoryEntry -DirectoryPath $DirectoryPath @SIDCacheResult

                } else {

                    #Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Known SID cache miss on this server."
                    $NameCacheResult = $DomainCacheResult.WellKnownSIDByName[$AccountName]

                    if ($NameCacheResult) {

                        #Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Name '$AccountName' # Known Name cache hit on this server."Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Well-known SID by name cache hit for '$AccountName' on host with NetBIOS '$Server'"
                        ConvertTo-FakeDirectoryEntry -DirectoryPath $DirectoryPath @NameCacheResult

                    } else {
                        #Write-LogMsg -Cache $Cache -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Name '$AccountName' # Known Name cache miss on this server."
                    }

                }

            }

        }

    }

}
function Get-DirectoryEntryParentName {

    <#
    .SYNOPSIS
        Extracts the parent name from a DirectoryEntry object.

    .DESCRIPTION
        The Get-DirectoryEntryParentName function retrieves the name of the parent container
        from a DirectoryEntry object. This function handles different scenarios where the
        DirectoryEntry.Parent property might be presented as either a DirectoryEntry object
        with properties or as a string path.

        The function first attempts to access the Parent.Name property directly. If that
        fails or returns null, it falls back to parsing the parent path string by finding
        the last forward slash and extracting the substring that follows it.

        This dual approach ensures compatibility with different representations of the
        DirectoryEntry.Parent property that may occur in different execution contexts
        (such as debugging in VS Code versus console execution).

    .EXAMPLE
        $directoryEntry = [ADSI]"LDAP://CN=Users,DC=contoso,DC=com"
        $parentName = Get-DirectoryEntryParentName -DirectoryEntry $directoryEntry

        This example gets the parent name of a specific LDAP directory entry.

    .EXAMPLE
        $user = Get-ADUser -Identity "jdoe"
        $userEntry = [ADSI]"LDAP://$($user.DistinguishedName)"
        $parentName = Get-DirectoryEntryParentName -DirectoryEntry $userEntry

        This example demonstrates getting the parent container name for a user object.

    .EXAMPLE
        $entries = Get-ChildItem "LDAP://CN=Users,DC=contoso,DC=com"
        $entries | ForEach-Object { Get-DirectoryEntryParentName -DirectoryEntry $_ }

        This example shows processing multiple directory entries to get their parent names.

    .INPUTS
        System.DirectoryServices.DirectoryEntry
        A DirectoryEntry object from which to extract the parent name.

    .OUTPUTS
        System.String
        The name of the parent container or organizational unit.

    .NOTES
        Author: Your Name
        Version: 1.0.0

        This function addresses a specific issue where DirectoryEntry.Parent behavior
        can vary between execution contexts:
        - In VS Code debugger: Shows as DirectoryEntry with accessible properties
        - In console execution: May appear as a string representation

        The function includes error handling for both scenarios to ensure reliable
        operation regardless of the execution environment.

        Performance considerations:
        - Primary method (Parent.Name) is fastest when available
        - Fallback string parsing adds minimal overhead
        - No external dependencies or network calls

    .LINK
        https://IMJLA.github.io/Adsi/docs/en-US/Get-DirectoryEntryParentName

    .LINK
        System.DirectoryServices.DirectoryEntry
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Get-DirectoryEntryParentName')]

    param (

        # The DirectoryEntry object from which to extract the parent name. This can be any valid DirectoryEntry object that has a Parent property, such as LDAP directory entries, Active Directory objects, or other directory service entries.
        $DirectoryEntry

    )

    if ($DirectoryEntry.Parent.Name) {

        return $DirectoryEntry.Parent.Name

    } else {

        $LastIndexOf = $DirectoryEntry.Parent.LastIndexOf('/')
        return $DirectoryEntry.Parent.Substring($LastIndexOf + 1, $DirectoryEntry.Parent.Length - $LastIndexOf - 1)

    }

}
function Get-SidTypeMap {

    <#
    .SYNOPSIS
    Returns a mapping of SID type numbers to their string representations.

    .DESCRIPTION
    The Get-SidTypeMap function provides a mapping between the numeric SID type values
    and their corresponding string representations. This is useful for translating
    SID type codes returned by various APIs to human-readable format.

    .EXAMPLE
    $sidTypeMap = Get-SidTypeMap
    $sidTypeMap[1]  # Returns 'user'

    .INPUTS
    None. This function does not accept pipeline input.

    .OUTPUTS
    [System.Collections.Hashtable] A hashtable mapping SID type numbers to string representations.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Get-SidTypeMap')]
    [OutputType([System.Collections.Hashtable])]

    param()

    return @{
        1 = 'user' #'SidTypeUser'
        2 = 'group' #'SidTypeGroup'
        3 = 'SidTypeDomain'
        4 = 'SidTypeAlias'
        5 = 'group' #'SidTypeWellKnownGroup'
        6 = 'SidTypeDeletedAccount'
        7 = 'SidTypeInvalid'
        8 = 'SidTypeUnknown'
        9 = 'computer' #'SidTypeComputer'
    }
}
function Invoke-IADsGroupMembersMethod {

    <#
        .SYNOPSIS

        Get members of a group from the WinNT provider
        .DESCRIPTION
        Get members of a group from the WinNT provider
        Convert them from COM objects into usable DirectoryEntry objects

        Assembly: System.DirectoryServices.dll
        Namespace: System.DirectoryServices
        DirectoryEntry.Invoke(String, Object[]) Method
        Calls a method on the native Active Directory Domain Services object
        https://docs.microsoft.com/en-us/dotnet/api/system.directoryservices.directoryentry.invoke?view=dotnet-plat-ext-6.0

        I am using it to call the IADsGroup::Members method
        The IADsGroup programming interface is part of the iads.h header
        The iads.h header is part of the ADSI component of the Win32 API
        The IADsGroup::Members method retrieves a collection of the immediate members of the group.
        The collection does not include the members of other groups that are nested within the group.
        The default implementation of this method uses LsaLookupSids to query name information for the group members.
        LsaLookupSids has a maximum limitation of 20480 SIDs it can convert, therefore that limitation also applies to this method.
        Returns a pointer to an IADsMembers interface pointer that receives the collection of group members. The caller must release this interface when it is no longer required.
        https://docs.microsoft.com/en-us/windows/win32/api/iads/nf-iads-iadsgroup-members
        The IADsMembers::Members method would use the same provider but I have chosen not to implement that here
        Recursion through nested groups can be handled outside of Get-WinNTGroupMember for now
        Maybe that could be a feature in the future
        https://docs.microsoft.com/en-us/windows/win32/adsi/adsi-object-model-for-winnt-providers?redirectedfrom=MSDN
        .INPUTS
        [System.DirectoryServices.DirectoryEntry]$DirectoryEntry
        .OUTPUTS
        [System.DirectoryServices.DirectoryEntry] for each group member
        .EXAMPLE
        [System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrators') | Get-WinNTGroupMember

        Get members of the local Administrators group
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Invoke-IADsGroupMembersMethod')]
    [OutputType([System.DirectoryServices.DirectoryEntry])]

    param (

        # DirectoryEntry [System.DirectoryServices.DirectoryEntry] of the WinNT group whose members to get
        [Parameter(ValueFromPipeline)]
        $DirectoryEntry

    )

    process {

        ForEach ($ThisDirectoryEntry in $DirectoryEntry) {
            # Invoke the Members method to get the group members
            & { $ThisDirectoryEntry.Invoke('Members') 2>$null }
        }

    }

}
function Invoke-ScShowSid {

    # Invoke sc.exe showsid

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Invoke-ScShowSid')]

    param (

        [string]$ServiceName,

        [string]$ComputerName,

        [string]$ThisHostName,

        [string]$ThisFqdn,

        [hashtable]$Log

    )

    if (
        $ComputerName -eq $ThisFqdn -or
        $ComputerName -eq $ThisHostName -or
        $ComputerName -eq 'localhost' -or
        $ComputerName -eq '127.0.0.1'
    ) {

        Write-LogMsg @Log -Text "& sc.exe showsid $ServiceName"
        & sc.exe showsid $ServiceName

    } else {

        Write-LogMsg @Log -Text "Invoke-Command -ComputerName $ComputerName -ScriptBlock { & sc.exe showsid `$args[0] } -ArgumentList $ServiceName"
        Invoke-Command -ComputerName $ComputerName -ScriptBlock { & sc.exe showsid $args[0] } -ArgumentList $ServiceName

    }

}
function Resolve-IdRefAppPkgAuth {

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

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Resolve-IdRefAppPkgAuth')]
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

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $Caption = "$ServerNetBIOS\$Name"
    $DomainCacheResult = $null

    $DomainsByNetbios = $Cache.Value['DomainByNetbios']
    $TryGetValueResult = $DomainsByNetbios.Value.TryGetValue($ServerNetBIOS, [ref]$DomainCacheResult)


    $Known = $Cache.Value['WellKnownSidByCaption'].Value[$IdentityReference]

    if ($null -eq $Known) {
        $Known = $DomainCacheResult.WellKnownSidByName[$Name]
    }

    $AccountProperties = @{}

    if ($null -ne $Known) {

        $SIDString = $Known.SID

        ForEach ($Prop in $Known.PSObject.Properties.GetEnumerator().Name) {
            $AccountProperties[$Prop] = $Known.$Prop
        }

    } else {
        $SIDString = $Name
    }

    if ($TryGetValueResult) {
        $DomainDns = $DomainCacheResult.Dns
    } else {

        Write-LogMsg -Text "ConvertTo-Fqdn -NetBIOS '$ServerNetBIOS' -Cache `$Cache # cache miss # IdentityReference '$IdentityReference' # Domain NetBIOS '$ServerNetBIOS'" -Cache $Cache
        $DomainDns = ConvertTo-Fqdn -NetBIOS $ServerNetBIOS -Cache $Cache
        Write-LogMsg -Text "Get-AdsiServer -Fqdn '$ServerNetBIOS' -Cache `$Cache # cache miss # IdentityReference '$IdentityReference' # Domain NetBIOS '$ServerNetBIOS'" -Cache $Cache
        $DomainCacheResult = Get-AdsiServer -Fqdn $DomainDns -Cache $Cache

    }

    $AccountProperties['SID'] = $SIDString
    $AccountProperties['Caption'] = $Caption
    $AccountProperties['Domain'] = $ServerNetBIOS
    $AccountProperties['Name'] = $Name
    $AccountProperties['IdentityReference'] = $IdentityReference
    $AccountProperties['SIDString'] = $SIDString
    $AccountProperties['IdentityReferenceNetBios'] = $Caption
    $AccountProperties['IdentityReferenceDns'] = "$DomainDns\$Name"
    $Win32Acct = [PSCustomObject]$AccountProperties

    # Update the caches
    $DomainCacheResult.WellKnownSidBySid[$SIDString] = $Win32Acct
    $DomainCacheResult.WellKnownSidByName[$Name] = $Win32Acct
    $Cache.Value['DomainByFqdn'].Value[$DomainCacheResult.Dns] = $DomainCacheResult
    $Cache.Value['DomainByNetbios'].Value[$DomainCacheResult.Netbios] = $DomainCacheResult
    $Cache.Value['DomainBySid'].Value[$DomainCacheResult.Sid] = $DomainCacheResult

    return $Win32Acct

}
function Resolve-IdRefBuiltIn {
    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Resolve-IdRefBuiltIn')]
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

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    # Some built-in groups such as BUILTIN\Users and BUILTIN\Administrators are not in the CIM class or translatable with the NTAccount.Translate() method
    # But they may have real DirectoryEntry objects
    # Try to find the DirectoryEntry object locally on the server
    $DirectoryPath = "$($AdsiServer.AdsiProvider)`://$ServerNetBIOS/$Name"

    if ($Name.Substring(0, 4) -eq 'S-1-') {

        $SIDString = $Name
        $Caption = $IdentityReference

    } else {

        Write-LogMsg -Text "Get-DirectoryEntry -DirectoryPath '$DirectoryPath' -Cache `$Cache" -Cache $Cache
        $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath -Cache $Cache
        $SIDString = (Add-SidInfo -InputObject $DirectoryEntry -DomainsBySid $Cache.Value['DomainBySid']).SidString
        $Caption = "$ServerNetBIOS\$Name"

    }

    $DomainDns = $AdsiServer.Dns
    $DomainCacheResult = Get-AdsiServer -Fqdn $DomainDns -Cache $Cache

    # Update the caches
    $Win32Acct = [PSCustomObject]@{
        SID     = $SIDString
        Caption = $Caption
        Domain  = $ServerNetBIOS
        Name    = $Name
    }

    # Update the caches
    $DomainCacheResult.WellKnownSidBySid[$SIDString] = $Win32Acct
    $DomainCacheResult.WellKnownSidByName[$Name] = $Win32Acct
    $Cache.Value['DomainByFqdn'].Value[$DomainCacheResult.Dns] = $DomainCacheResult
    $Cache.Value['DomainByNetbios'].Value[$DomainCacheResult.Netbios] = $DomainCacheResult
    $Cache.Value['DomainBySid'].Value[$DomainCacheResult.Sid] = $DomainCacheResult

    return [PSCustomObject]@{
        IdentityReference        = $IdentityReference
        SIDString                = $SIDString
        IdentityReferenceNetBios = $Caption
        IdentityReferenceDns     = "$DomainDns\$Name"
    }

}
function Resolve-IdRefCached {
    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Resolve-IdRefCached')]
    [OutputType([PSCustomObject])]

    param (

        # IdentityReference from an Access Control Entry
        # Expecting either a SID (S-1-5-18) or an NT account name (CONTOSO\User)
        [Parameter(Mandatory)]
        [string]$IdentityReference,

        # Object from Get-AdsiServer representing the directory server and its attributes
        [PSObject]$AdsiServer,

        # NetBIOS name of the ADSI server
        [string]$ServerNetBIOS = $AdsiServer.Netbios

    )

    ForEach ($Cache in 'WellKnownSidBySid', 'WellKnownSIDByName') {

        if ($AdsiServer.$Cache) {

            #Write-LogMsg @Log -Text " # '$Cache' cache exists for '$ServerNetBIOS' for '$IdentityReference'"
            $CacheResult = $AdsiServer.$Cache[$IdentityReference]

            if ($CacheResult) {

                #Write-LogMsg @Log -Text " # '$Cache' cache hit on '$ServerNetBIOS': $($CacheResult.Name) for '$IdentityReference'"

                return [PSCustomObject]@{
                    IdentityReference        = $IdentityReference
                    SIDString                = $CacheResult.SID
                    IdentityReferenceNetBios = "$ServerNetBIOS\$($CacheResult.Name)"
                    IdentityReferenceDns     = "$($AdsiServer.Dns)\$($CacheResult.Name)"
                }

            } else {
                #Write-LogMsg @Log -Text " # '$Cache' cache miss on '$ServerNetBIOS' for '$IdentityReference'"
            }

        } else {
            #Write-LogMsg @Log -Text " # No '$Cache' cache for '$ServerNetBIOS' for '$IdentityReference'"
        }

    }

}
function Resolve-IdRefGetDirEntry {
    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Resolve-IdRefGetDirEntry')]
    [OutputType([string])]

    param (

        # Object from Get-AdsiServer representing the directory server and its attributes
        [PSObject]$AdsiServer,

        [string]$ServerNetBIOS,

        [string]$Name,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $DirectoryPath = "$($AdsiServer.AdsiProvider)`://$ServerNetBIOS/$Name"
    Write-LogMsg -Text "Get-DirectoryEntry -DirectoryPath '$DirectoryPath' -Cache `$Cache" -Cache $Cache
    $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath -Cache $Cache
    $DirectoryEntryWithSidInfo = Add-SidInfo -InputObject $DirectoryEntry -DomainsBySid $Cache.Value['DomainBySid']
    return $DirectoryEntryWithSidInfo.SidString

}
function Resolve-IdRefSearchDir {
    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Resolve-IdRefSearchDir')]
    [OutputType([string])]

    param (

        # IdentityReference from an Access Control Entry
        # Expecting either a SID (S-1-5-18) or an NT account name (CONTOSO\User)
        [Parameter(Mandatory)]
        [string]$IdentityReference,

        [string]$Name,

        [string]$DomainDn,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $SearchPath = Add-DomainFqdnToLdapPath -DirectoryPath "LDAP://$DomainDn" -Cache $Cache

    $SearchParams = @{
        'Cache'            = $Cache
        'DirectoryPath'    = $SearchPath
        'Filter'           = "(samaccountname=$Name)"
        'PropertiesToLoad' = $AccountProperty + @('objectClass', 'distinguishedName', 'name', 'grouptype', 'member', 'objectClass')
    }

    try {
        $DirectoryEntry = Search-Directory @SearchParams
    } catch {

        $Log['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
        Write-LogMsg -Text "'$IdentityReference' could not be resolved against its directory. Error: $($_.Exception.Message)" -Cache $Cache
        $Log['Type'] = $LogThis['DebugOutputStream']

    }

    $DirectoryEntryWithSidInfo = Add-SidInfo -InputObject $DirectoryEntry -DomainsBySid $LogThis['Cache'].Value['DomainBySid']
    return $DirectoryEntryWithSidInfo.SidString

}
function Resolve-IdRefSID {

    <#
                This .Net method makes it impossible to redirect the error stream directly
                Wrapping it in a scriptblock (which is then executed with &) fixes the problem
                I don't understand exactly why

                The scriptblock will evaluate null if the SID cannot be translated, and the error stream redirection supresses the error (except in the transcript which catches it)
            #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Resolve-IdRefSID')]
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

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache,

        # Properties of each Account to display on the report
        [string[]]$AccountProperty = @('DisplayName', 'Company', 'Department', 'Title', 'Description')

    )

    $CachedWellKnownSID = Find-CachedWellKnownSID -IdentityReference $IdentityReference -DomainNetBIOS $ServerNetBIOS -DomainByNetbios $Cache.Value['DomainByNetbios']
    $AccountProperties = @{}

    if ($CachedWellKnownSID) {

        ForEach ($Prop in $CachedWellKnownSID.PSObject.Properties.GetEnumerator().Name) {
            $AccountProperties[$Prop] = $CachedWellKnownSID.$Prop
        }

        #Write-LogMsg -Text " # IdentityReference '$IdentityReference' # Well-known SID match" -Cache $Cache
        $NTAccount = $CachedWellKnownSID.IdentityReferenceNetBios
        $DomainNetBIOS = $ServerNetBIOS
        $DomainDns = ConvertTo-Fqdn -NetBIOS $DomainNetBIOS -Cache $Cache
        $DomainCacheResult = Get-AdsiServer -Fqdn $DomainDns -Cache $Cache
        $done = $true

    } else {
        $KnownSid = Get-KnownSid -SID $IdentityReference
    }

    if ($KnownSid) {

        ForEach ($Prop in $KnownSid.PSObject.Properties.GetEnumerator().Name) {
            $AccountProperties[$Prop] = $KnownSid.$Prop
        }

        #Write-LogMsg -Text " # IdentityReference '$IdentityReference' # Known SID pattern match" -Cache $Cache
        $NTAccount = $KnownSid.NTAccount
        $DomainNetBIOS = $ServerNetBIOS
        $DomainDns = ConvertTo-Fqdn -NetBIOS $DomainNetBIOS -Cache $Cache
        $DomainCacheResult = Get-AdsiServer -Fqdn $DomainDns -Cache $Cache
        $done = $true

    }

    if (-not $done) {


        #Write-LogMsg -Text " # IdentityReference '$IdentityReference' # No match with known SID patterns" -Cache $Cache
        # The SID of the domain is everything up to (but not including) the last hyphen
        $DomainSid = $IdentityReference.Substring(0, $IdentityReference.LastIndexOf('-'))
        Write-LogMsg -Text "[System.Security.Principal.SecurityIdentifier]::new('$IdentityReference').Translate([System.Security.Principal.NTAccount])" -Cache $Cache
        $SecurityIdentifier = [System.Security.Principal.SecurityIdentifier]::new($IdentityReference)

        try {


            $NTAccount = & { $SecurityIdentifier.Translate([System.Security.Principal.NTAccount]).Value } 2>$null

        } catch {

            $StartingLogType = $Cache.Value['LogType'].Value
            $Cache.Value['LogType'].Value = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
            Write-LogMsg -Text " # IdentityReference '$IdentityReference' # Unexpectedly could not translate SID to NTAccount using the [SecurityIdentifier]::Translate method: $($_.Exception.Message.Replace('Exception calling "Translate" with "1" argument(s): ',''))" -Cache $Cache
            $Cache.Value['LogType'].Value = $StartingLogType

        }

    }

    #Write-LogMsg -Text " # IdentityReference '$IdentityReference' # Translated NTAccount caption is '$NTAccount'" -Cache $Cache
    $DomainsBySid = $Cache.Value['DomainBySid']

    # Search the cache of domains, first by SID, then by NetBIOS name
    if (-not $DomainCacheResult) {
        $DomainCacheResult = $null
        $TryGetValueResult = $DomainsBySid.Value.TryGetValue($DomainSid, [ref]$DomainCacheResult)
    }

    $DomainsByNetbios = $Cache.Value['DomainByNetbios']

    if (-not $TryGetValueResult) {

        #Write-LogMsg -Text " # IdentityReference '$IdentityReference' # Domain SID cache miss for '$DomainSid'" -Cache $Cache
        $split = $NTAccount -split '\\'
        $DomainFromSplit = $split[0]

        if (

            $DomainFromSplit.Contains(' ') -or
            $DomainFromSplit -eq 'BUILTIN'

        ) {

            $NameFromSplit = $split[1]
            $DomainNetBIOS = $ServerNetBIOS
            $Caption = "$ServerNetBIOS\$NameFromSplit"
            $AccountProperties['SID'] = $IdentityReference
            $AccountProperties['Caption'] = $Caption
            $AccountProperties['Domain'] = $ServerNetBIOS
            $AccountProperties['Name'] = $NameFromSplit

            # This will be used to update the caches
            $Win32Acct = [PSCustomObject]$AccountProperties

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

        #Write-LogMsg -Text " # IdentityReference '$IdentityReference' # Domain SID '$DomainSid' is unknown. Domain NetBIOS is '$DomainNetBIOS'" -Cache $Cache
        $DomainDns = ConvertTo-Fqdn -NetBIOS $DomainNetBIOS -Cache $Cache
        $DomainCacheResult = Get-AdsiServer -Fqdn $DomainDns -Cache $Cache

    }

    if (-not $DomainCacheResult) {
        $DomainCacheResult = $AdsiServer
    }

    # Update the caches
    if ($Win32Acct) {
        $DomainCacheResult.WellKnownSidBySid[$IdentityReference] = $Win32Acct
        $DomainCacheResult.WellKnownSidByName[$NameFromSplit] = $Win32Acct
        # TODO are these next 3 lines necessary or are the values already updated thanks to references?
        $Cache.Value['DomainByFqdn'].Value[$DomainCacheResult.Dns] = $DomainCacheResult
        $DomainsByNetbios.Value[$DomainCacheResult.Netbios] = $DomainCacheResult
        $DomainsBySid.Value[$DomainCacheResult.Sid] = $DomainCacheResult
    }

    if ($NTAccount) {

        # Recursively call this function to resolve the new IdentityReference we have
        $ResolveIdentityReferenceParams = @{
            AccountProperty   = $AccountProperty
            Cache             = $Cache
            IdentityReference = $NTAccount
            AdsiServer        = $DomainCacheResult
        }

        $Resolved = Resolve-IdentityReference @ResolveIdentityReferenceParams

    } else {

        if ($Win32Acct) {

            $AccountProperties['IdentityReference'] = $IdentityReference
            $AccountProperties['SIDString'] = $IdentityReference
            $AccountProperties['IdentityReferenceNetBios'] = "$DomainNetBIOS\$IdentityReference"
            $AccountProperties['IdentityReferenceDns'] = "$DomainDns\$IdentityReference"
            $Resolved = [PSCustomObject]$AccountProperties

        } else {

            $Resolved = [PSCustomObject]@{
                IdentityReference        = $IdentityReference
                SIDString                = $IdentityReference
                IdentityReferenceNetBios = "$DomainNetBIOS\$IdentityReference"
                IdentityReferenceDns     = "$DomainDns\$IdentityReference"
            }

        }

    }

    return $Resolved

}
function Resolve-IdRefSvc {
    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Resolve-IdRefSvc')]
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

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $SIDString = ConvertTo-ServiceSID -ServiceName $Name
    $Caption = "$ServerNetBIOS\$Name"
    $DomainCacheResult = $null
    $DomainsByNetbios = $Cache.Value['DomainByNetbios']
    $TryGetValueResult = $DomainsByNetbios.Value.TryGetValue($ServerNetBIOS, [ref]$DomainCacheResult)

    if ($TryGetValueResult) {
        $DomainDns = $DomainCacheResult.Dns
    } else {

        Write-LogMsg -Text " # Domain NetBIOS cache miss for '$ServerNetBIOS' # For '$IdentityReference'" -Cache $Cache
        $DomainDns = ConvertTo-Fqdn -NetBIOS $ServerNetBIOS -Cache $Cache
        $DomainCacheResult = Get-AdsiServer -Fqdn $DomainDns -Cache $Cache

    }

    # Update the caches
    $Win32Svc = [PSCustomObject]@{
        SID     = $SIDString
        Caption = $Caption
        Domain  = $ServerNetBIOS
        Name    = $Name
    }

    # Update the caches
    $DomainCacheResult.WellKnownSidBySid[$SIDString] = $Win32Svc
    $DomainCacheResult.WellKnownSidByName[$Name] = $Win32Svc
    $Cache.Value['DomainByFqdn'].Value[$DomainCacheResult.Dns] = $DomainCacheResult
    $DomainsByNetbios.Value[$DomainCacheResult.Netbios] = $DomainCacheResult
    $Cache.Value['DomainBySid'].Value[$DomainCacheResult.Sid] = $DomainCacheResult

    return [PSCustomObject]@{
        IdentityReference        = $IdentityReference
        SIDString                = $SIDString
        IdentityReferenceNetBios = $Caption
        IdentityReferenceDns     = "$DomainDns\$Name"
    }

}
function Resolve-SidAuthority {

    <#
    .SYNOPSIS

    Resolves SID authority names to their proper representation.

    .DESCRIPTION
    Replaces well-known SID authorities in directory paths with the appropriate parent name.
    Used to ensure consistent representation of security identifiers across different directory services.

    .EXAMPLE
    Resolve-SidAuthority -DirectorySplit $pathComponents -DirectoryEntry $entry -Cache $Cache

    .INPUTS
    System.Collections.Hashtable

    .OUTPUTS
    None. Modifies the DirectorySplit hashtable directly by adding 'ResolvedDomain' and 'ResolvedDirectoryPath' keys.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Resolve-SidAuthority')]

    param (

        # A DirectoryPath which has been split on the / character then parsed into a dictionary of constituent components
        # Must have a Domain key
        [hashtable]$DirectorySplit,

        # DirectoryEntry [System.DirectoryServices.DirectoryEntry] object whose Parent's Name will be used as the replacement Authority.
        $DirectoryEntry,

        # Well-Known local SID authorities to replace with the computer name in the InputObject string.
        [hashtable]$AuthoritiesToReplaceWithParentName = @{
            'APPLICATION PACKAGE AUTHORITY' = $null

            'BUILTIN'                       = $null
            'CREATOR SID AUTHORITY'         = $null
            'LOCAL SID AUTHORITY'           = $null
            'Non-unique Authority'          = $null
            'NT AUTHORITY'                  = $null
            'NT SERVICE'                    = $null
            'NT VIRTUAL MACHINE'            = $null
            'NULL SID AUTHORITY'            = $null
            'WORLD SID AUTHORITY'           = $null
        }

    )

    $Domain = $DirectorySplit['Domain']

    # Replace the well-known SID authorities with the computer name
    if ($AuthoritiesToReplaceWithParentName.ContainsKey($Domain)) {

        # This function may be unnecessary.  See comments of the private function for details.
        $ParentName = Get-DirectoryEntryParentName -DirectoryEntry $DirectoryEntry
        $DirectorySplit['ResolvedDomain'] = $ParentName
        $DirectorySplit['ResolvedDirectoryPath'] = $DirectorySplit['DirectoryPath'].Replace($Domain, $ParentName)

    } else {

        $DirectorySplit['ResolvedDomain'] = $Domain
        $DirectorySplit['ResolvedDirectoryPath'] = $DirectorySplit['DirectoryPath']

    }

}
function Split-DirectoryPath {

    <#
    .EXAMPLE
        Split-DirectoryPath -DirectoryPath 'WinNT://WORKGROUP/COMPUTER/Administrator'
        Split-DirectoryPath -DirectoryPath 'WinNT://COMPUTER/Administrator'
        Split-DirectoryPath -DirectoryPath 'WinNT://WORKGROUP/COMPUTER/Administrator'
        Split-DirectoryPath -DirectoryPath 'WinNT://DOMAIN/COMPUTER/Administrator'
        Split-DirectoryPath -DirectoryPath 'WinNT://DOMAIN/OU1/COMPUTER/Administrator'
        Split-DirectoryPath -DirectoryPath 'WinNT://DOMAIN/OU1/OU2/COMPUTER/Administrator'
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Split-DirectoryPath')]
    [OutputType([System.Collections.Hashtable])]

    param (

        [string]$DirectoryPath

    )

    $Split = $DirectoryPath.Split('/')

    # Extra segments an account's Directory Path indicate that the account's domain is a child domain.
    if ($Split.Count -gt 4) {

        $ParentDomain = $Split[2]

        if ($Split.Count -gt 5) {
            $Middle = $Split[3..($Split.Count - 3)]
        } else {
            $Middle = $null
        }

    } else {
        $ParentDomain = $null
    }

    return @{
        DirectoryPath = $DirectoryPath # Not currently in use by dependent functions
        Account       = $Split[ ( $Split.Count - 1 ) ]
        Domain        = $Split[ ( $Split.Count - 2 ) ]
        ParentDomain  = $ParentDomain # Not currently in use by dependent functions
        Middle        = $Middle # Not currently in use by dependent functions
    }

}
function Test-AdsiProvider {

    <#
    .SYNOPSIS

    Determine whether a directory server is an LDAP or a WinNT server
    .DESCRIPTION
    Uses the ADSI provider to attempt to query the server using LDAP first, then WinNT second
    .INPUTS
    [System.String] AdsiServer parameter.
    .OUTPUTS
    [System.String] Possible return values are:
        LDAP
        WinNT
    .EXAMPLE
    Test-AdsiProvider -AdsiServer localhost

    Find the ADSI provider of the local computer
    .EXAMPLE
    Test-AdsiProvider -AdsiServer 'ad.contoso.com'

    Find the ADSI provider of the AD domain 'ad.contoso.com'
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Test-AdsiProvider')]
    [OutputType([System.String])]

    param (

        # IP address or hostname of the directory server whose ADSI provider type to determine
        [string]$AdsiServer,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $Log = @{ 'Cache' = $Cache }
    $AdsiPath = "LDAP://$AdsiServer"
    Write-LogMsg @Log -Text "[System.DirectoryServices.DirectoryEntry]::Exists('$AdsiPath') # for '$AdsiServer'"

    try {
        $null = [System.DirectoryServices.DirectoryEntry]::Exists($AdsiPath)
        return 'LDAP'
    } catch { Write-LogMsg @Log -Text " # No response to LDAP # for '$AdsiServer'" }

    $AdsiPath = "WinNT://$AdsiServer"
    Write-LogMsg @Log -Text "[System.DirectoryServices.DirectoryEntry]::Exists('$AdsiPath') # for '$AdsiServer'"

    try {
        $null = [System.DirectoryServices.DirectoryEntry]::Exists($AdsiPath)
        return 'WinNT'
    } catch {
        Write-LogMsg @Log -Text " # No response to WinNT. # for '$AdsiServer'"
    }

}
function Add-DomainFqdnToLdapPath {

    <#
    .SYNOPSIS

    Add a domain FQDN to an LDAP directory path as the server address so the new path can be used for remote queries
    .DESCRIPTION
    Uses RegEx to:
        - Match the Domain Components from the Distinguished Name in the LDAP directory path
        - Convert the Domain Components to an FQDN
        - Insert them into the directory path as the server address
    .INPUTS
    [System.String]$DirectoryPath
    .OUTPUTS
    [System.String] Complete LDAP directory path including server address
    .EXAMPLE
    Add-DomainFqdnToLdapPath -DirectoryPath 'LDAP://CN=user1,OU=UsersOU,DC=ad,DC=contoso,DC=com' -Cache $Cache

    Completes the partial LDAP path 'LDAP://CN=user1,OU=UsersOU,DC=ad,DC=contoso,DC=com' to
    'LDAP://ad.contoso.com/CN=user1,OU=UsersOU,DC=ad,DC=contoso,DC=com' with the domain FQDN added as the
    server address. This is crucial for making remote LDAP queries to specific domain controllers, especially
    when working in multi-domain environments or when connecting to trusted domains.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Add-DomainFqdnToLdapPath')]
    [OutputType([System.String])]

    param (

        # Incomplete LDAP directory path containing a distinguishedName but lacking a server address
        [Parameter(ValueFromPipeline)]
        [string[]]$DirectoryPath,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    begin {
        $DomainRegEx = '(?i)DC=\w{1,}?\b'
    }

    process {

        ForEach ($ThisPath in $DirectoryPath) {

            if ($ThisPath.Substring(0, 7) -eq 'LDAP://') {

                $RegExMatches = $null
                $RegExMatches = [regex]::Matches($ThisPath, $DomainRegEx)

                if ($RegExMatches) {

                    $DomainDN = $null
                    $DomainFqdn = $null
                    $RegExMatches = ForEach ($Match in $RegExMatches) { $Match.Value }
                    $DomainDN = $RegExMatches -join ','
                    $DomainFqdn = ConvertTo-Fqdn -DistinguishedName $DomainDN -Cache $Cache
                    $DomainLdapPath = "LDAP://$DomainFqdn/"

                    if ($ThisPath.Substring(0, $DomainLdapPath.Length) -eq $DomainLdapPath) {

                        #Write-LogMsg -Text " # Domain FQDN already found in the directory path: '$ThisPath'" -Cache $Cache
                        $ThisPath

                    } else {
                        $ThisPath.Replace( 'LDAP://', $DomainLdapPath )
                    }
                } else {

                    #Write-LogMsg -Text " # Domain DN not found in the directory path: '$ThisPath'" -Cache $Cache
                    $ThisPath

                }

            } else {

                #Write-LogMsg -Text " # Not an expected directory path: '$ThisPath'" -Cache $Cache
                $ThisPath

            }

        }

    }

}
function Add-SidInfo {

    <#
    .SYNOPSIS

    Add some useful properties to a DirectoryEntry object for easier access
    .DESCRIPTION
    Add SidString, Domain, and SamAccountName NoteProperties to a DirectoryEntry
    .INPUTS
    [System.DirectoryServices.DirectoryEntry] or a [PSCustomObject] imitation. InputObject parameter.  Must contain the objectSid property.
    .OUTPUTS
    [System.DirectoryServices.DirectoryEntry] or a [PSCustomObject] imitation. Whatever was input, but with three extra properties added now.
    .EXAMPLE
    [System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrator') | Add-SidInfo
    distinguishedName :
    Path              : WinNT://localhost/Administrator

    The output object's default format is not modified so with default formatting it appears identical to the original.
    Upon closer inspection it now has SidString, Domain, and SamAccountName properties.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Add-SidInfo')]
    [OutputType([System.DirectoryServices.DirectoryEntry[]], [PSCustomObject[]])]

    param (

        # Expecting a [System.DirectoryServices.DirectoryEntry] from the LDAP or WinNT providers, or a [PSCustomObject] imitation from Get-DirectoryEntry.
        # Must contain the objectSid property
        [Parameter(ValueFromPipeline)]
        $InputObject,

        # In-process cache to reduce calls to other processes or to disk
        [ref]$DomainsBySid

    )

    process {

        ForEach ($Object in $InputObject) {

            $SID = $null
            [string]$SamAccountName = $Object.SamAccountName
            $DomainObject = $null

            if ($null -eq $Object) {
                continue
            }

            if ($Object.objectSid.Value) {

                # With WinNT directory entries for the root (WinNT://localhost), objectSid is a method rather than a property
                # So we need to filter out those instances here to avoid this error:
                # The following exception occurred while retrieving the string representation for method "objectSid":
                # "Object reference not set to an instance of an object."
                if ( $Object.objectSid.Value.GetType().FullName -ne 'System.Management.Automation.PSMethod' ) {
                    [string]$SID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]$Object.objectSid.Value, 0)
                }

            } elseif ($Object.objectSid) {

                # With WinNT directory entries for the root (WinNT://localhost), objectSid is a method rather than a property
                # So we need to filter out those instances here to avoid this error:
                # The following exception occurred while retrieving the string representation for method "objectSid":
                # "Object reference not set to an instance of an object."
                if ($Object.objectSid.GetType().FullName -ne 'System.Management.Automation.PSMethod') {
                    [string]$SID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]$Object.objectSid, 0)
                }

            } elseif ($Object.Properties) {

                if ($Object.Properties['objectSid'].Value) {
                    [string]$SID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]$Object.Properties['objectSid'].Value, 0)
                } elseif ($Object.Properties['objectSid']) {
                    [string]$SID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]($Object.Properties['objectSid'] | ForEach-Object { $_ }), 0)
                }

                if ($Object.Properties['samaccountname']) {
                    $SamAccountName = $Object.Properties['samaccountname']
                } else {

                    #DirectoryEntries from the WinNT provider for local accounts do not have a samaccountname attribute so we use name instead
                    $SamAccountName = $Object.Properties['name']

                }

            } elseif ($Object.Domain.Sid) {

                if ($null -eq $SID) {
                    [string]$SID = $Object.Domain.Sid
                }

                $DomainObject = $Object.Domain

            }

            if (-not $DomainObject) {

                # The SID of the domain is the SID of the user minus the last block of numbers
                $DomainSid = $SID.Substring(0, $Sid.LastIndexOf('-'))

                # Lookup other information about the domain using its SID as the key
                $DomainObject = $null
                $null = $DomainsBySid.Value.TryGetValue($DomainSid, [ref]$DomainObject)

            }

            Add-Member -InputObject $Object -PassThru -Force @{
                SidString      = $SID
                Domain         = $DomainObject
                SamAccountName = $SamAccountName
            }

        }

    }

}
function ConvertFrom-DirectoryEntry {

    <#
    .SYNOPSIS

    Convert a DirectoryEntry to a PSCustomObject
    .DESCRIPTION
    Recursively convert every property into a string, or a PSCustomObject (whose properties are all strings, or more PSCustomObjects)
    This obfuscates the troublesome PropertyCollection and PropertyValueCollection and Hashtable aspects of working with ADSI
    .EXAMPLE
    $DirEntry = [System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrator')
    ConvertFrom-DirectoryEntry -DirectoryEntry $DirEntry

    Converts the DirectoryEntry for the local Administrator account into a PowerShell custom object with simplified
    property values. This makes it easier to work with the object in PowerShell and avoids the complexity of
    DirectoryEntry property collections, which can be difficult to access and manipulate directly.
    .INPUTS
    [System.DirectoryServices.DirectoryEntry]
    .OUTPUTS
    [PSCustomObject]
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertFrom-DirectoryEntry')]

    param (

        # DirectoryEntry objects to convert to PSCustomObjects
        [Parameter(
            Position = 0
        )]
        [System.DirectoryServices.DirectoryEntry[]]$DirectoryEntry

    )

    ForEach ($ThisDirectoryEntry in $DirectoryEntry) {

        $OutputObject = @{}

        ForEach ($Prop in $ThisDirectoryEntry.PSObject.Properties.GetEnumerator().Name) {

            $null = ConvertTo-SimpleProperty -InputObject $ThisDirectoryEntry -Property $Prop -PropertyDictionary $OutputObject

        }

        [PSCustomObject]$OutputObject

    }

}
function ConvertFrom-PropertyValueCollectionToString {

    <#
    .SYNOPSIS

    Convert a PropertyValueCollection to a string
    .DESCRIPTION
    Useful when working with System.DirectoryServices and some other namespaces
    .INPUTS
    None. Pipeline input is not accepted.
    .OUTPUTS
    [System.String]

    Returns a string representation of the PropertyValueCollection's value.
    .EXAMPLE
    $DirectoryEntry = [adsi]("WinNT://$(hostname)")
    $DirectoryEntry.Properties.Keys |
    ForEach-Object {
        ConvertFrom-PropertyValueCollectionToString -PropertyValueCollection $DirectoryEntry.Properties[$_]
    }

    For each property in a DirectoryEntry, convert its corresponding PropertyValueCollection to a string
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertFrom-PropertyValueCollectionToString')]

    param (

        # This PropertyValueCollection will be converted to a string
        [System.DirectoryServices.PropertyValueCollection]$PropertyValueCollection

    )

    if ($null -ne $PropertyValueCollection.Value) {
        $SubType = $PropertyValueCollection.Value.GetType().FullName
    }

    switch ($SubType) {
        'System.Byte[]' { ConvertTo-DecStringRepresentation -ByteArray $PropertyValueCollection.Value ; break }
        default { "$($PropertyValueCollection.Value)" }
    }

}
function ConvertFrom-ResolvedID {

    <#
    .SYNOPSIS

    Use ADSI to collect more information about the IdentityReference in NTFS Access Control Entries
    .DESCRIPTION
    Recursively retrieves group members and detailed information about them
    Use caching to reduce duplicate directory queries
    .INPUTS
    [System.Object]$IdentityReference
    .OUTPUTS
    [System.Object] The input object is returned with additional properties added:
        DirectoryEntry
        DomainDn
        DomainNetBIOS
        ObjectType
        Members (if the DirectoryEntry is a group).

    .EXAMPLE
    (Get-Acl).Access |
    Resolve-IdentityReference |
    Group-Object -Property IdentityReferenceResolved |
    ConvertFrom-ResolvedID

    Incomplete example but it shows the chain of functions to generate the expected input for this function.
    This example gets the ACL for an important folder, resolves each identity reference in the access entries,
    groups them by the resolved identity reference, and then converts each unique identity to a detailed
    principal object. This provides comprehensive information about each security principal including their
    directory entry, domain information, and group membership details, which is essential for thorough
    permission analysis and reporting.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertFrom-ResolvedID')]
    [OutputType([void])]

    param (

        # The NTFS AccessControlEntry object(s), grouped by their IdentityReference property
        # TODO: Use System.Security.Principal.NTAccount instead
        [string]$IdentityReference,

        # Do not get group members
        [switch]$NoGroupMembers,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache,

        # Properties of each Account to display on the report
        [string[]]$AccountProperty = @('DisplayName', 'Company', 'Department', 'Title', 'Description')

    )

    if ( -not $Cache.Value['PrincipalById'].Value[ $IdentityReference ] ) {

        $LogSuffix = "for resolved Identity Reference '$IdentityReference'"
        $LogSuffixComment = " # $LogSuffix"
        $Log = @{ 'Cache' = $Cache ; 'Suffix' = $LogSuffixComment }
        Write-LogMsg @Log -Text "`$AceGuids = `$Cache.Value['AceGuidByID'].Value['$IdentityReference'] # ADSI Principal cache miss"
        $AceGuidByID = $Cache.Value['AceGuidByID']
        $AceGuids = $AceGuidByID.Value[ $IdentityReference ]
        $split = $IdentityReference.Split('\')
        $DomainNetBIOS = $split[0]
        $SamAccountNameOrSid = $split[1]
        Write-LogMsg @Log -Text "`$CachedWellKnownSID = Find-CachedWellKnownSID -IdentityReference '$SamAccountNameOrSid' -DomainNetBIOS '$DomainNetBIOS' -DomainByNetbios `$Cache.Value['DomainByNetbios']"
        $CachedWellKnownSID = Find-CachedWellKnownSID -IdentityReference $SamAccountNameOrSid -DomainNetBIOS $DomainNetBIOS -DomainByNetbios $Cache.Value['DomainByNetbios']
        $DomainDn = $null

        $CommonSplat = @{
            'AceGuid'             = $AceGuids
            'AccountProperty'     = $AccountProperty
            'Cache'               = $Cache
            'DomainDn'            = $DomainDn
            'DomainNetBIOS'       = $DomainNetBIOS
            'IdentityReference'   = $IdentityReference
            'LogSuffixComment'    = $LogSuffixComment
            'SamAccountNameOrSid' = $SamAccountNameOrSid
        }

        $DirectoryEntryConversion = @{
            'CachedWellKnownSID' = $CachedWellKnownSID
        }

        Write-LogMsg @Log -Text '$DirectoryEntry = ConvertTo-DirectoryEntry' -Expand $DirectoryEntryConversion, $CommonSplat -ExpansionMap $Cache.Value['LogWellKnownMap'].Value
        $DirectoryEntry = ConvertTo-DirectoryEntry @DirectoryEntryConversion @CommonSplat

        $PermissionPrincipalConversion = @{
            'DirectoryEntry' = $DirectoryEntry
            'NoGroupMembers' = $NoGroupMembers
        }

        Write-LogMsg @Log -Text 'ConvertTo-PermissionPrincipal' -Expand $PermissionPrincipalConversion, $CommonSplat -ExpansionMap $Cache.Value['LogDirEntryMap'].Value
        ConvertTo-PermissionPrincipal @PermissionPrincipalConversion @CommonSplat

    }

}
function ConvertFrom-ResultPropertyValueCollectionToString {

    <#
    .SYNOPSIS

    Convert a ResultPropertyValueCollection to a string
    .DESCRIPTION
    Useful when working with System.DirectoryServices and some other namespaces
    .INPUTS
    None. Pipeline input is not accepted.
    .OUTPUTS
    [System.String]
    .EXAMPLE
    $DirectoryEntry = [adsi]("WinNT://$(hostname)")
    $DirectoryEntry.Properties.Keys |
    ForEach-Object {
        ConvertFrom-PropertyValueCollectionToString -PropertyValueCollection $DirectoryEntry.Properties[$_]
    }

    For each property in a DirectoryEntry, convert its corresponding PropertyValueCollection to a string
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertFrom-ResultPropertyValueCollectionToString')]

    param (

        # ResultPropertyValueCollection object to convert to a string
        [System.DirectoryServices.ResultPropertyValueCollection]$ResultPropertyValueCollection

    )

    if ($null -ne $ResultPropertyValueCollection.Value) {
        $SubType = $ResultPropertyValueCollection.Value.GetType().FullName
    }

    switch ($SubType) {
        'System.Byte[]' { ConvertTo-DecStringRepresentation -ByteArray $ResultPropertyValueCollection.Value ; break }
        default { "$($ResultPropertyValueCollection.Value)" }
    }

}
function ConvertFrom-SearchResult {

    <#
    .SYNOPSIS

    Convert a SearchResult to a PSCustomObject
    .DESCRIPTION
    Recursively convert every property into a string, or a PSCustomObject (whose properties are all strings, or more PSCustomObjects)
    This obfuscates the troublesome ResultPropertyCollection and ResultPropertyValueCollection and Hashtable aspects of working with ADSI searches
    .INPUTS
    System.DirectoryServices.SearchResult[]

    Accepts SearchResult objects from a directory search via the pipeline.
    .OUTPUTS
    PSCustomObject

    Returns PSCustomObject instances with simplified properties.
    .EXAMPLE
    $DirectorySearcher = [System.DirectoryServices.DirectorySearcher]::new("LDAP://DC=contoso,DC=com")
    $DirectorySearcher.Filter = "(objectClass=user)"
    $SearchResults = $DirectorySearcher.FindAll()
    $SearchResults | ConvertFrom-SearchResult

    Performs a search in Active Directory for all user objects, then converts each SearchResult
    into a PSCustomObject with simplified properties. This makes it easier to work with the
    search results in PowerShell by flattening complex nested property collections into
    regular object properties.
    .NOTES
    # TODO: There is a faster way than Select-Object, just need to dig into the default formatting of SearchResult to see how to get those properties
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertFrom-SearchResult')]

    param (

        # SearchResult objects to convert to PSCustomObjects
        [Parameter(
            Position = 0,
            ValueFromPipeline
        )]
        [System.DirectoryServices.SearchResult[]]$SearchResult

    )

    process {

        ForEach ($ThisSearchResult in $SearchResult) {

            $OutputObject = @{}

            # Enumerate the keys of the ResultPropertyCollection
            ForEach ($ThisProperty in $ThisSearchResult.Properties.Keys) {
                $null = ConvertTo-SimpleProperty -InputObject $ThisSearchResult.Properties -Property $ThisProperty -PropertyDictionary $ThisObject
            }

            # We will allow any existing properties to override members of the ResultPropertyCollection
            ForEach ($ThisProperty in $ThisSearchResult.PSObject.Properties.GetEnumerator().Name) {
                $null = ConvertTo-SimpleProperty -InputObject $ThisSearchResult -Property $ThisProperty -PropertyDictionary $OutputObject
            }

            [PSCustomObject]$OutputObject

        }

    }

}
function ConvertFrom-SidString {

    <#
    .SYNOPSIS

    Converts a SID string to a DirectoryEntry object.

    .DESCRIPTION
    Attempts to resolve a security identifier (SID) string to its corresponding DirectoryEntry object
    by querying the directory service using the LDAP provider. This function is not currently in use
    by the Export-Permission module.

    .EXAMPLE
    ConvertFrom-SidString -SID 'S-1-5-21-3165297888-301567370-576410423-1103' -Cache $Cache

    Attempts to convert a SID string representing a user or group to its corresponding DirectoryEntry object
    by searching Active Directory using the LDAP provider. This allows you to obtain detailed information
    about a security principal when you only have its SID string representation.

    .INPUTS
    System.String

    .OUTPUTS
    System.DirectoryServices.DirectoryEntry

    .NOTES
    This function is not currently in use by Export-Permission
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertFrom-SidString')]

    param (

        # Security Identifier (SID) string to convert to a DirectoryEntry
        [string]$SID,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    #[OutputType([System.Security.Principal.NTAccount])]


    #[System.Security.Principal.SecurityIdentifier]::new($SID)
    # Only works if SID is in the current domain...otherwise SID not found
    $DirectoryPath = "LDAP://<SID=$SID>"
    Write-LogMsg -Text "Get-DirectoryEntry -DirectoryPath '$DirectoryPath' -Cache `$Cache" -Cache $Cache
    Get-DirectoryEntry -DirectoryPath $DirectoryPath -Cache $Cache

}
function ConvertTo-DecStringRepresentation {

    <#
    .SYNOPSIS

    Convert a byte array to a string representation of its decimal format
    .DESCRIPTION
    Uses the custom format operator -f to format each byte as a string decimal representation
    .INPUTS
    [System.Byte[]]$ByteArray
    .OUTPUTS
    [System.String] Array of strings representing the byte array's decimal values
    .EXAMPLE
    ConvertTo-DecStringRepresentation -ByteArray $Bytes

    Convert the binary SID $Bytes to a decimal string representation
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertTo-DecStringRepresentation')]
    [OutputType([System.String])]

    param (

        # Byte array.  Often the binary format of an objectSid or LoginHours
        [byte[]]$ByteArray

    )

    $ByteArray |
        ForEach-Object {
            '{0}' -f $_
        }

}
function ConvertTo-DistinguishedName {

    <#
    .SYNOPSIS

    Convert a domain NetBIOS name to its distinguishedName
    .DESCRIPTION
    https://docs.microsoft.com/en-us/windows/win32/api/iads/nn-iads-iadsnametranslate
    .INPUTS
    [System.String]$Domain
    .OUTPUTS
    [System.String] distinguishedName of the domain
    .EXAMPLE
    ConvertTo-DistinguishedName -Domain 'CONTOSO' -Cache $Cache

    Resolves the NetBIOS domain name 'CONTOSO' to its distinguished name format 'DC=ad,DC=contoso,DC=com'.
    This conversion is necessary when constructing LDAP queries that require the domain in distinguished
    name format, particularly when working with Active Directory objects across different domains or forests.
    The function utilizes Windows API calls to perform accurate name translation.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertTo-DistinguishedName')]
    [OutputType([System.String])]

    param (

        # NetBIOS name of the domain
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'NetBIOS')]
        [string[]]$Domain,

        # FQDN of the domain
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'FQDN')]
        [string[]]$DomainFQDN,

        # Type of initialization to be performed
        # Will be translated to the corresponding integer for use as the lnSetType parameter of the IADsNameTranslate::Init method (iads.h)
        # https://docs.microsoft.com/en-us/windows/win32/api/iads/ne-iads-ads_name_inittype_enum
        [string]$InitType = 'ADS_NAME_INITTYPE_GC',

        # Format of the name of the directory object that will be used for the input
        # Will be translated to the corresponding integer for use as the lnSetType parameter of the IADsNameTranslate::Set method (iads.h)
        # https://docs.microsoft.com/en-us/windows/win32/api/iads/ne-iads-ads_name_type_enum
        [string]$InputType = 'ADS_NAME_TYPE_NT4',

        # Format of the name of the directory object that will be used for the output
        # Will be translated to the corresponding integer for use as the lnSetType parameter of the IADsNameTranslate::Get method (iads.h)
        # https://docs.microsoft.com/en-us/windows/win32/api/iads/ne-iads-ads_name_type_enum
        [string]$OutputType = 'ADS_NAME_TYPE_1779',

        <#

        AdsiProvider (WinNT or LDAP) of the servers associated with the provided FQDNs or NetBIOS names



        This parameter can be used to reduce calls to Find-AdsiProvider

        Useful when that has been done already but the DomainByFqdn and DomainByNetbios caches have not been updated yet
        #>

        [string]$AdsiProvider,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    begin {

        $DomainByNetbios = $Cache.Value['DomainByNetbios']
        $DomainByFqdn = $Cache.Value['DomainByFqdn']

        # Declare constants for these Windows enums
        # We need to because PowerShell makes it hard to directly use the Win32 API and read the enum definition
        # Use hashtables instead of enums since this use case is so simple
        $ADS_NAME_INITTYPE_dict = @{
            ADS_NAME_INITTYPE_DOMAIN = 1 #Initializes a NameTranslate object by setting the domain that the object binds to.
            ADS_NAME_INITTYPE_SERVER = 2 #Initializes a NameTranslate object by setting the server that the object binds to.
            ADS_NAME_INITTYPE_GC     = 3 #Initializes a NameTranslate object by locating the global catalog that the object binds to.
        }

        $ADS_NAME_TYPE_dict = @{
            ADS_NAME_TYPE_1779                    = 1 #Name format as specified in RFC 1779. For example, "CN=Jeff Smith,CN=users,DC=Fabrikam,DC=com".
            ADS_NAME_TYPE_CANONICAL               = 2 #Canonical name format. For example, "Fabrikam.com/Users/Jeff Smith".
            ADS_NAME_TYPE_NT4                     = 3 #Account name format used in Windows. For example, "Fabrikam\JeffSmith".
            ADS_NAME_TYPE_DISPLAY                 = 4 #Display name format. For example, "Jeff Smith".
            ADS_NAME_TYPE_DOMAIN_SIMPLE           = 5 #Simple domain name format. For example, "JeffSmith@Fabrikam.com".
            ADS_NAME_TYPE_ENTERPRISE_SIMPLE       = 6 #Simple enterprise name format. For example, "JeffSmith@Fabrikam.com".
            ADS_NAME_TYPE_GUID                    = 7 #Global Unique Identifier format. For example, "{95ee9fff-3436-11d1-b2b0-d15ae3ac8436}".
            ADS_NAME_TYPE_UNKNOWN                 = 8 #Unknown name type. The system will estimate the format. This element is a meaningful option only with the IADsNameTranslate.Set or the IADsNameTranslate.SetEx method, but not with the IADsNameTranslate.Get or IADsNameTranslate.GetEx method.
            ADS_NAME_TYPE_USER_PRINCIPAL_NAME     = 9 #User principal name format. For example, "JeffSmith@Fabrikam.com".
            ADS_NAME_TYPE_CANONICAL_EX            = 10 #Extended canonical name format. For example, "Fabrikam.com/Users Jeff Smith".
            ADS_NAME_TYPE_SERVICE_PRINCIPAL_NAME  = 11 #Service principal name format. For example, "www/www.fabrikam.com@fabrikam.com".
            ADS_NAME_TYPE_SID_OR_SID_HISTORY_NAME = 12 #A SID string, as defined in the Security Descriptor Definition Language (SDDL), for either the SID of the current object or one from the object SID history. For example, "O:AOG:DAD:(A;;RPWPCCDCLCSWRCWDWOGA;;;S-1-0-0)"
        }

        $ChosenInitType = $ADS_NAME_INITTYPE_dict[$InitType]
        $ChosenInputType = $ADS_NAME_TYPE_dict[$InputType]
        $ChosenOutputType = $ADS_NAME_TYPE_dict[$OutputType]

    }

    process {

        ForEach ($ThisDomain in $Domain) {

            $DomainCacheResult = $null
            $TryGetValueResult = $DomainByNetbios.Value.TryGetValue($ThisDomain, [ref]$DomainCacheResult)

            if ($TryGetValueResult) {

                #Write-LogMsg -Text " # Domain NetBIOS cache hit for '$ThisDomain'" -Cache $Cache
                $DomainCacheResult.DistinguishedName

            } else {

                #Write-LogMsg -Text " # Domain NetBIOS cache miss for '$ThisDomain'. Available keys: $($Cache.Value['DomainByNetbios'].Value.Keys -join ',')"
                Write-LogMsg -Text "`$IADsNameTranslateComObject = New-Object -comObject 'NameTranslate' # For '$ThisDomain'" -Cache $Cache
                $IADsNameTranslateComObject = New-Object -ComObject 'NameTranslate'
                Write-LogMsg -Text "`$IADsNameTranslateInterface = `$IADsNameTranslateComObject.GetType() # For '$ThisDomain'" -Cache $Cache
                $IADsNameTranslateInterface = $IADsNameTranslateComObject.GetType()
                Write-LogMsg -Text "`$null = `$IADsNameTranslateInterface.InvokeMember('Init', 'InvokeMethod', `$Null, `$IADsNameTranslateComObject, ($ChosenInitType, `$Null)) # For '$ThisDomain'" -Cache $Cache

                # Handle errors for this method
                #    Exception calling "InvokeMember" with "5" argument(s): "The specified domain either does not exist or could not be contacted. (0x8007054B)"
                try {
                    $null = $IADsNameTranslateInterface.InvokeMember('Init', 'InvokeMethod', $Null, $IADsNameTranslateComObject, ($ChosenInitType, $Null))
                } catch {

                    Write-LogMsg -Text " #Error: $($_.Exception.Message) # For $ThisDomain" -Cache $Cache
                    continue

                }

                # For a non-domain-joined system there is no DistinguishedName for the domain
                # Suppress errors when calling these next 2 methods
                #     Exception calling "InvokeMember" with "5" argument(s): "Name translation: Could not find the name or insufficient right to see name. (Exception from HRESULT: 0x80072116)"
                Write-LogMsg -Text "`$null = `$IADsNameTranslateInterface.InvokeMember('Set', 'InvokeMethod', `$Null, `$IADsNameTranslateComObject, ($ChosenInputType, '$ThisDomain\')) # For '$ThisDomain'" -Cache $Cache
                $null = { $IADsNameTranslateInterface.InvokeMember('Set', 'InvokeMethod', $Null, $IADsNameTranslateComObject, ($ChosenInputType, "$ThisDomain\")) } 2>$null
                #     Exception calling "InvokeMember" with "5" argument(s): "Unspecified error (Exception from HRESULT: 0x80004005 (E_FAIL))"
                Write-LogMsg -Text "`$IADsNameTranslateInterface.InvokeMember('Get', 'InvokeMethod', `$Null, `$IADsNameTranslateComObject, $ChosenOutputType) # For '$ThisDomain'" -Cache $Cache
                $null = { $null = { $IADsNameTranslateInterface.InvokeMember('Get', 'InvokeMethod', $Null, $IADsNameTranslateComObject, $ChosenOutputType) } 2>$null } 2>$null

            }

        }

        ForEach ($ThisDomain in $DomainFQDN) {

            $DomainCacheResult = $null
            $TryGetValueResult = $DomainByFqdn.Value.TryGetValue($ThisDomain, [ref]$DomainCacheResult)

            if ($TryGetValueResult) {

                #Write-LogMsg -Text " # Domain FQDN cache hit for '$ThisDomain'" -Cache $Cache
                $DomainCacheResult.DistinguishedName

            } else {

                #Write-LogMsg -Text " # Domain FQDN cache miss for '$ThisDomain'" -Cache $Cache

                if (-not $PSBoundParameters.ContainsKey('AdsiProvider')) {
                    $AdsiProvider = Find-AdsiProvider -AdsiServer $ThisDomain -Cache $Cache
                }

                if ($AdsiProvider -ne 'WinNT') {
                    "dc=$($ThisDomain.Replace('.', ',dc='))"
                }

            }

        }

    }

}
function ConvertTo-DomainNetBIOS {

    <#
    .SYNOPSIS
    Converts a domain FQDN to its NetBIOS name.

    .DESCRIPTION
    Retrieves the NetBIOS name for a specified domain FQDN by checking the cache or querying
    the directory service. For LDAP providers, it retrieves domain information from the directory.
    For non-LDAP providers, it extracts the first part of the FQDN before the first period.

    .EXAMPLE
    ConvertTo-DomainNetBIOS -DomainFQDN 'contoso.com' -Cache $Cache

    Converts the fully qualified domain name 'contoso.com' to its NetBIOS name by automatically
    determining the appropriate method based on available information. The function will check the
    cache first to avoid unnecessary directory queries.

    .EXAMPLE
    ConvertTo-DomainNetBIOS -DomainFQDN 'contoso.com' -AdsiProvider 'LDAP' -Cache $Cache

    Converts the fully qualified domain name 'contoso.com' to its NetBIOS name using the LDAP provider
    specifically, which provides more accurate results in an Active Directory environment by querying
    the domain controller directly.

    .INPUTS
    None. Pipeline input is not accepted.

    .OUTPUTS
    System.String. The NetBIOS name of the domain.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertTo-DomainNetBIOS')]
    [OutputType([string])]

    param (

        # Fully Qualified Domain Name (FQDN) to convert to NetBIOS name
        [string]$DomainFQDN,

        # ADSI provider to use (LDAP or WinNT)
        [string]$AdsiProvider,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $DomainCacheResult = $null
    $TryGetValueResult = $Cache.Value['DomainByFqdn'].Value.TryGetValue($DomainFQDN, [ref]$DomainCacheResult)

    if ($TryGetValueResult) {

        #Write-LogMsg -Text " # Domain FQDN cache hit for '$DomainFQDN'" -Cache $Cache
        return $DomainCacheResult.Netbios

    }

    if ($AdsiProvider -eq 'LDAP') {

        $DirectoryPath = "LDAP://$DomainFQDN/rootDSE"
        Write-LogMsg -Text "`$RootDSE = Get-DirectoryEntry -DirectoryPath '$DirectoryPath' -Cache `$Cache # Domain FQDN cache miss for '$DomainFQDN'" -Cache $Cache
        $RootDSE = Get-DirectoryEntry -DirectoryPath $DirectoryPath -Cache $Cache
        Write-LogMsg -Text "`$RootDSE.InvokeGet('defaultNamingContext')" -Cache $Cache
        $DomainDistinguishedName = $RootDSE.InvokeGet('defaultNamingContext')
        Write-LogMsg -Text "`$RootDSE.InvokeGet('configurationNamingContext')" -Cache $Cache
        $ConfigurationDN = $rootDSE.InvokeGet('configurationNamingContext')
        $DirectoryPath = "LDAP://$DomainFQDN/cn=partitions,$ConfigurationDN"
        Write-LogMsg -Text "Get-DirectoryEntry -DirectoryPath '$DirectoryPath' -Cache `$Cache" -Cache $Cache
        $partitions = Get-DirectoryEntry -DirectoryPath $DirectoryPath -Cache $Cache

        ForEach ($Child In $Partitions.Children) {

            If ($Child.nCName -contains $DomainDistinguishedName) {
                return $Child.nETBIOSName
            }

        }

    } else {

        $LengthOfNetBIOSName = $DomainFQDN.IndexOf('.')

        if ($LengthOfNetBIOSName -eq -1) {
            $DomainFQDN
        } else {
            $DomainFQDN.Substring(0, $LengthOfNetBIOSName)
        }

    }

}
function ConvertTo-DomainSidString {

    <#
    .SYNOPSIS

    Converts a domain DNS name to its corresponding SID string.

    .DESCRIPTION
    Retrieves the security identifier (SID) string for a specified domain DNS name using either
    cached values or by querying the directory service. It supports both LDAP and WinNT providers
    and can fall back to local server resolution methods when needed.

    .EXAMPLE
    ConvertTo-DomainSidString -DomainDnsName 'contoso.com' -Cache $Cache

    Converts the DNS domain name 'contoso.com' to its corresponding domain SID string by
    automatically determining the best ADSI provider to use and utilizing the cache to avoid
    redundant directory queries.

    .EXAMPLE
    ConvertTo-DomainSidString -DomainDnsName 'contoso.com' -AdsiProvider 'LDAP' -Cache $Cache

    Converts the DNS domain name 'contoso.com' to its corresponding domain SID string by
    explicitly using the LDAP provider, which can be more efficient when you already know
    the appropriate provider to use.

    .INPUTS
    None. Pipeline input is not accepted.

    .OUTPUTS
    System.String. The SID string of the specified domain.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertTo-DomainSidString')]

    param (

        # Domain DNS name to convert to the domain's SID
        [Parameter(Mandatory)]
        [string]$DomainDnsName,

        <#
        AdsiProvider (WinNT or LDAP) of the servers associated with the provided FQDNs or NetBIOS names

        This parameter can be used to reduce calls to Find-AdsiProvider

        Useful when that has been done already but the DomainsByFqdn and DomainsByNetbios caches have not been updated yet
        #>

        [string]$AdsiProvider,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $Log = @{ Cache = $Cache ; Suffix = " # for domain FQDN '$DomainDnsName'" }
    $CacheResult = $null
    $null = $Cache.Value['DomainByFqdn'].Value.TryGetValue($DomainDnsName, [ref]$CacheResult)

    if ($CacheResult.Sid) {

        #Write-LogMsg @Log -Text " # Domain FQDN cache hit"
        return $CacheResult.Sid

    }
    #Write-LogMsg @Log -Text " # Domain FQDN cache miss"

    if (
        -not $AdsiProvider -or
        $AdsiProvider -eq 'LDAP'
    ) {

        Write-LogMsg @Log -Text "Get-DirectoryEntry -DirectoryPath 'LDAP://$DomainDnsName' -Cache `$Cache"
        $DomainDirectoryEntry = Get-DirectoryEntry -DirectoryPath "LDAP://$DomainDnsName" -Cache $Cache

        try {
            $null = $DomainDirectoryEntry.RefreshCache('objectSid')
        } catch {

            Write-LogMsg @Log -Text "Find-LocalAdsiServerSid -ComputerName '$DomainDnsName' -Cache `$Cache # LDAP connection failed - $($_.Exception.Message.Replace("`r`n",' ').Trim()) -Cache `$Cache"
            $DomainSid = Find-LocalAdsiServerSid -ComputerName $DomainDnsName -Cache $Cache
            return $DomainSid

        }

    } else {

        Write-LogMsg @Log -Text "Find-LocalAdsiServerSid -ComputerName '$DomainDnsName' -Cache `$Cache"
        $DomainSid = Find-LocalAdsiServerSid -ComputerName $DomainDnsName -Cache $Cache
        return $DomainSid

    }

    $DomainSid = $null

    if ($DomainDirectoryEntry.Properties) {

        $objectSIDProperty = $DomainDirectoryEntry.Properties['objectSid']

        if ($objectSIDProperty.Value) {
            $SidByteArray = [byte[]]$objectSIDProperty.Value
        } else {
            $SidByteArray = [byte[]]$objectSIDProperty
        }

    } else {
        $SidByteArray = [byte[]]$DomainDirectoryEntry.objectSid
    }

    Write-LogMsg @Log -Text "[System.Security.Principal.SecurityIdentifier]::new([byte[]]@($($SidByteArray -join ',')), 0).ToString()"
    $DomainSid = [System.Security.Principal.SecurityIdentifier]::new($SidByteArray, 0).ToString()

    if ($DomainSid) {
        return $DomainSid
    } else {

        $StartingLogType = $Cache.Value['LogType'].Value
        $Cache.Value['LogType'].Value = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
        Write-LogMsg @Log -Text ' # Could not find valid SID for LDAP Domain'
        $Cache.Value['LogType'].Value = $StartingLogType

    }

}
function ConvertTo-FakeDirectoryEntry {

    <#
    .SYNOPSIS

    Creates a fake DirectoryEntry object for security principals that don't have objects in the directory.

    .DESCRIPTION
    Used in place of a DirectoryEntry for certain WinNT security principals that do not have objects in the directory.
    The WinNT provider only throws an error if you try to retrieve certain accounts/identities.
    This function creates a PSCustomObject that mimics a DirectoryEntry with the necessary properties.

    .EXAMPLE
    ConvertTo-FakeDirectoryEntry -DirectoryPath "WinNT://BUILTIN/Everyone" -SID "S-1-1-0"

    Creates a fake DirectoryEntry object for the well-known "Everyone" security principal with the SID "S-1-1-0",
    which can be used for permission analysis when a real DirectoryEntry object cannot be retrieved.

    .INPUTS
    None. Pipeline input is not accepted.

    .OUTPUTS
    PSCustomObject. A custom object that mimics a DirectoryEntry with properties such as Name, Description,
    SchemaClassName, and objectSid.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertTo-FakeDirectoryEntry')]

    param (

        # Full directory path for the fake entry in the format "Provider://Domain/Name"
        [string]$DirectoryPath,

        # Security Identifier (SID) string for the fake entry
        [string]$SID,

        # Description of the security principal
        [string]$Description,

        # Schema class name (e.g., 'user', 'group', 'computer')
        [string]$SchemaClassName,

        # Optional input object containing additional properties to include in the fake directory entry
        $InputObject,

        # Account names known to be impossible to resolve to a Directory Entry (currently based on testing on a non-domain-joined PC)
        [hashtable]$NameAllowList = @{
            'ALL APPLICATION PACKAGES'            = $null
            'ALL RESTRICTED APPLICATION PACKAGES' = $null
            'ANONYMOUS LOGON'                     = $null
            'Authenticated Users'                 = $null
            'BATCH'                               = $null
            'BUILTIN'                             = $null
            'CREATOR GROUP'                       = $null
            'CREATOR GROUP SERVER'                = $null
            'CREATOR OWNER'                       = $null
            'CREATOR OWNER SERVER'                = $null
            'DIALUP'                              = $null
            'ENTERPRISE DOMAIN CONTROLLERS'       = $null
            'Everyone'                            = $null
            'INTERACTIVE'                         = $null
            'internetExplorer'                    = $null
            'IUSR'                                = $null
            'LOCAL'                               = $null
            'LOCAL SERVICE'                       = $null
            'NETWORK'                             = $null
            'NETWORK SERVICE'                     = $null
            'OWNER RIGHTS'                        = $null
            'PROXY'                               = $null
            'RDS Endpoint Servers'                = $null
            'RDS Management Servers'              = $null
            'RDS Remote Access Servers'           = $null
            'REMOTE INTERACTIVE LOGON'            = $null
            'RESTRICTED'                          = $null
            'SELF'                                = $null
            'SERVICE'                             = $null
            'SYSTEM'                              = $null
            'TERMINAL SERVER USER'                = $null
        },

        # These are retrievable via the WinNT ADSI Provider which enables group member retrival so we don't want to return fake directory entries
        [hashtable]$NameBlockList = @{
            'Access Control Assistance Operators' = $null
            'Administrators'                      = $null
            'Backup Operators'                    = $null
            'Cryptographic Operators'             = $null
            'DefaultAccount'                      = $null
            'Distributed COM Users'               = $null
            'Event Log Readers'                   = $null
            'Guests'                              = $null
            'Hyper-V Administrators'              = $null
            'IIS_IUSRS'                           = $null
            'Network Configuration Operators'     = $null
            'Performance Log Users'               = $null
            'Performance Monitor Users'           = $null
            'Power Users'                         = $null
            'Remote Desktop Users'                = $null
            'Remote Management Users'             = $null
            'Replicator'                          = $null
            'System Managed Accounts Group'       = $null
            'Users'                               = $null
            'WinRMRemoteWMIUsers__'               = $null
        }

    )

    $LastSlashIndex = $DirectoryPath.LastIndexOf('/')
    $StartIndex = $LastSlashIndex + 1
    $Name = $DirectoryPath.Substring($StartIndex, $DirectoryPath.Length - $StartIndex)

    if (
        $InputObject.SidType -eq 4 -or
        $InputObject.SidType -eq 5
    ) {

        if (-not $NameAllowList.ContainsKey($Name)) {
            return
        }

    }

    if (
        $NameBlockList.ContainsKey($Name)
    ) {
        return $null
    }

    $Parent = $DirectoryPath.Substring(0, $LastSlashIndex)
    $SchemaEntry = [System.DirectoryServices.DirectoryEntry]

    $Properties = @{
        Name            = $Name
        Description     = $Description
        SamAccountName  = $Name
        SchemaClassName = $SchemaClassName
    }

    ForEach ($Prop in $InputObject.PSObject.Properties.GetEnumerator().Name) {
        $Properties[$Prop] = $InputObject.$Prop
    }

    $SID = $Properties['SID']
    if ($SID) {
        $Properties['objectSid'] = ConvertTo-SidByteArray -SidString $SID
    } else {
        $Properties['objectSid'] = $null
    }

    $TopLevelOnlyProperties = @{
        Parent      = $Parent
        Path        = $DirectoryPath
        SchemaEntry = $SchemaEntry
        Properties  = $Properties
    }

    $AllProperties = $Properties + $TopLevelOnlyProperties
    $Object = [PSCustomObject]$AllProperties
    Add-Member -InputObject $Object -Name RefreshCache -MemberType ScriptMethod -Value {}
    Add-Member -InputObject $Object -Name Invoke -MemberType ScriptMethod -Value {}
    return $Object

}
function ConvertTo-Fqdn {

    <#
    .SYNOPSIS

    Convert a domain distinguishedName name or NetBIOS name to its FQDN
    .DESCRIPTION
    For the DistinguishedName parameter, uses PowerShell's -replace operator to perform the conversion
    For the NetBIOS parameter, uses ConvertTo-DistinguishedName to convert from NetBIOS to distinguishedName, then recursively calls this function to get the FQDN
    .INPUTS
    [System.String]$DistinguishedName
    .OUTPUTS
    [System.String] FQDN version of the distinguishedName
    .EXAMPLE
    ConvertTo-Fqdn -DistinguishedName 'DC=ad,DC=contoso,DC=com' -Cache $Cache

    Converts the domain distinguishedName 'DC=ad,DC=contoso,DC=com' to its FQDN format 'ad.contoso.com'.
    This is essential when working with LDAP directory paths that need to be converted to readable domain
    names or when constructing proper LDAP paths that require the FQDN of the domain for remote connections.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertTo-Fqdn')]
    [OutputType([System.String])]

    param (

        # distinguishedName of the domain
        [Parameter(
            ParameterSetName = 'DistinguishedName',
            ValueFromPipeline
        )]
        [string[]]$DistinguishedName,

        # NetBIOS name of the domain
        [Parameter(

            ParameterSetName = 'NetBIOS',
            ValueFromPipeline
        )]
        [string[]]$NetBIOS,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    process {

        ForEach ($DN in $DistinguishedName) {
            $DN.Replace( ',DC=', '.' ).Replace( 'DC=', '' )
        }

        $DomainsByNetbios = $Cache.Value['DomainByNetbios']

        ForEach ($ThisNetBios in $NetBIOS) {

            $DomainObject = $null
            $TryGetValueResult = $DomainsByNetbios.Value.TryGetValue($ThisNetBios, [ref]$DomainObject)

            if (
                -not $TryGetValueResult -and
                -not [string]::IsNullOrEmpty($ThisNetBios)
            ) {

                #Write-LogMsg -Text " # Domain NetBIOS cache miss for '$ThisNetBios' -Cache `$Cache" -Cache $Cache
                $DomainObject = Get-AdsiServer -Netbios $ThisNetBios -Cache $Cache

            }

            $DomainObject.Dns

        }

    }

}
function ConvertTo-HexStringRepresentation {

    <#
    .SYNOPSIS

    Convert a SID from byte array format to a string representation of its hexadecimal format
    .DESCRIPTION
    Uses the custom format operator -f to format each byte as a string hex representation
    .INPUTS
    [System.Byte[]]$SIDByteArray
    .OUTPUTS
    [System.String] SID as an array of strings representing the byte array's hexadecimal values
    .EXAMPLE
    ConvertTo-HexStringRepresentation -SIDByteArray $Bytes

    Convert the binary SID $Bytes to a hexadecimal string representation
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertTo-HexStringRepresentation')]
    [OutputType([System.String[]])]

    param (

        # SID
        [byte[]]$SIDByteArray

    )

    $SIDHexString = $SIDByteArray |
        ForEach-Object {
            '{0:X}' -f $_
        }
    return $SIDHexString
}
function ConvertTo-HexStringRepresentationForLDAPFilterString {

    <#
    .SYNOPSIS

    Convert a SID from byte array format to a string representation of its hexadecimal format, properly formatted for an LDAP filter string
    .DESCRIPTION
    Uses the custom format operator -f to format each byte as a string hex representation
    .INPUTS
    [System.Byte[]]$SIDByteArray
    .OUTPUTS
    [System.String] SID as an array of strings representing the byte array's hexadecimal values
    .EXAMPLE
    ConvertTo-HexStringRepresentationForLDAPFilterString -SIDByteArray $Bytes

    Convert the binary SID $Bytes to a hexadecimal string representation, formatted for use in an LDAP filter string
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertTo-HexStringRepresentationForLDAPFilterString')]
    [OutputType([System.String])]

    param (

        # SID to convert to a hex string
        [byte[]]$SIDByteArray

    )

    $Hexes = $SIDByteArray |
        ForEach-Object {
            '{0:X}' -f $_
        } |
        ForEach-Object {
            if ($_.Length -eq 2) {
                $_
            } else {
                "0$_"
            }
        }
    "\$($Hexes -join '\')"
}
function ConvertTo-SidByteArray {

    <#
    .SYNOPSIS

    Convert a SID from a string to binary format (byte array)
    .DESCRIPTION
    Uses the GetBinaryForm method of the [System.Security.Principal.SecurityIdentifier] class
    .INPUTS
    [System.String]$SidString
    .OUTPUTS
    [System.Byte] SID a a byte array
    .EXAMPLE
    ConvertTo-SidByteArray -SidString 'S-1-5-32-544'

    Converts the SID string for the built-in Administrators group ('S-1-5-32-544') to a byte array
    representation, which is required when working with directory services that expect SIDs in binary format.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertTo-SidByteArray')]
    [OutputType([System.Byte[]])]

    param (

        # SID to convert to binary
        [Parameter(ValueFromPipeline)]
        [string[]]$SidString

    )

    process {
        ForEach ($ThisSID in $SidString) {
            $SID = [System.Security.Principal.SecurityIdentifier]::new($ThisSID)
            [byte[]]$Bytes = [byte[]]::new($SID.BinaryLength)
            $SID.GetBinaryForm($Bytes, 0)
            $Bytes
        }
    }
}
function Expand-AdsiGroupMember {

    <#
    .SYNOPSIS

    Use the LDAP provider to add information about group members to a DirectoryEntry of a group for easier access
    .DESCRIPTION
    Recursively retrieves group members and detailed information about them
    Specifically gets the SID, and resolves foreign security principals to their DirectoryEntry from the trusted domain
    .INPUTS
    [System.DirectoryServices.DirectoryEntry]$DirectoryEntry
    .OUTPUTS
    [System.DirectoryServices.DirectoryEntry] Returned with member info added now (if the DirectoryEntry is a group).
    .EXAMPLE
    [System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrators') |
    Get-AdsiGroupMember |
    Expand-AdsiGroupMember

    Retrieves the members of the local Administrators group and then expands each member with additional
    information such as SID and domain information. Foreign security principals from trusted domains are
    resolved to their actual DirectoryEntry objects from the appropriate domain.
    .EXAMPLE
    [System.DirectoryServices.DirectoryEntry]::new('LDAP://ad.contoso.com/CN=Administrators,CN=BuiltIn,DC=ad,DC=contoso,DC=com') |
    Get-AdsiGroupMember |
    Expand-AdsiGroupMember -Cache $Cache

    Retrieves the members of the domain Administrators group and then expands each member with additional
    information such as SID and domain information. Foreign security principals from trusted domains are
    resolved to their actual DirectoryEntry objects from the appropriate domain.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Expand-AdsiGroupMember')]
    [OutputType([System.DirectoryServices.DirectoryEntry])]

    param (

        # Expecting a DirectoryEntry from the LDAP or WinNT providers, or a PSObject imitation from Get-DirectoryEntry
        [parameter(ValueFromPipeline)]
        $DirectoryEntry,

        # Properties of the group members to retrieve
        [string[]]$PropertiesToLoad = @('distinguishedName', 'groupType', 'member', 'name', 'objectClass', 'objectSid', 'primaryGroupToken', 'samAccountName'),

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    begin {

        $Log = @{ Cache = $Cache }
        $DomainSidRef = $Cache.Value['DomainBySid']
        $DomainBySid = $DomainSidRef.Value

        # Add the bare minimum required properties
        $PropertiesToLoad = $PropertiesToLoad + @(
            'distinguishedName',
            'grouptype',
            'member',
            'name',
            'objectClass',
            'objectSid',
            'primaryGroupToken',
            'samAccountName'
        )

        $PropertiesToLoad = $PropertiesToLoad |
            Sort-Object -Unique

        # The DomainBySid cache must be populated with trusted domains in order to translate foreign security principals
        if ( $DomainBySid.Keys.Count -lt 1 ) {

            Write-LogMsg @Log -Text '# No domains in the DomainBySid cache'

            ForEach ($TrustedDomain in (Get-TrustedDomain -Cache $Cache)) {
                #Write-LogMsg @Log -Text "Get-AdsiServer -Fqdn $($TrustedDomain.DomainFqdn)"
                $null = Get-AdsiServer -Fqdn $TrustedDomain.DomainFqdn -Cache $Cache
            }

        } else {
            #Write-LogMsg @Log -Text '# Valid DomainBySid cache found'
        }

        $i = 0

    }

    process {

        ForEach ($Entry in $DirectoryEntry) {

            $i++
            $Principal = $null
            $Suffix = " # for DirectoryEntry with path '$($Entry.Path)'"
            $Log['Suffix'] = $Suffix
            #Write-LogMsg @Log -Text "Status: Using ADSI to get info on group member $i`: $($Entry.Name)"

            if ($Entry.objectClass -contains 'foreignSecurityPrincipal') {

                if ($Entry.distinguishedName.Value -match '(?>^CN=)(?<SID>[^,]*)') {

                    #The SID of the domain is the SID of the user minus the last block of numbers
                    [string]$SID = $Matches.SID
                    $DomainSid = $SID.Substring(0, $Sid.LastIndexOf('-'))
                    $Domain = $null
                    $null = $DomainBySid.Value.TryGetValue($DomainSid, [ref]$Domain)
                    $Log['Suffix'] = " # foreignSecurityPrincipal's distinguishedName points to a SID $Suffix"
                    $DirectoryPath = "LDAP://$($Domain.Dns)/<SID=$SID>"
                    Write-LogMsg @Log -Text "`$Principal = Get-DirectoryEntry -DirectoryPath '$DirectoryPath' -Cache `$Cache"
                    $Principal = Get-DirectoryEntry -DirectoryPath $DirectoryPath -Cache $Cache

                    try {

                        Write-LogMsg @Log -Text "`$Principal.RefreshCache('$($PropertiesToLoad -join "','")')"
                        $null = $Principal.RefreshCache($PropertiesToLoad)

                    } catch {

                        $Principal = $Entry
                        Write-LogMsg @Log -Text " # SID '$SID' could not be retrieved from domain '$Domain'"

                    }

                    # Recursively enumerate group members
                    if ($Principal.properties['objectClass'].Value -contains 'group') {

                        $Log['Suffix'] = " # '$($Principal.properties['name'])' is a group in '$Domain' $Suffix"
                        Write-LogMsg @Log -Text "`$AdsiGroupWithMembers = Get-AdsiGroupMember -Group `$Principal -PropertiesToLoad @('$($PropertiesToLoad -join "','")') -Cache `$Cache"
                        $AdsiGroupWithMembers = Get-AdsiGroupMember -Group $Principal -PropertiesToLoad $PropertiesToLoad -Cache $Cache
                        $Log['Suffix'] = " # for $(@($AdsiGroupWithMembers.FullMembers).Count) members $Suffix"
                        Write-LogMsg @Log -Text "`$Principal = Expand-AdsiGroupMember -DirectoryEntry `$AdsiGroupWithMembers.FullMembers -PropertiesToLoad @('$($PropertiesToLoad -join "','")') -Cache `$Cache"
                        $Principal = Expand-AdsiGroupMember -DirectoryEntry $AdsiGroupWithMembers.FullMembers -PropertiesToLoad $PropertiesToLoad -Cache $Cache

                    }

                }

            } else {
                $Principal = $Entry
            }

            Write-LogMsg @Log -Text "Add-SidInfo -InputObject `$Principal -DomainsBySid [ref]`$Cache.Value['DomainBySid']"
            Add-SidInfo -InputObject $Principal -DomainsBySid $DomainSidRef

        }

    }

}
function Expand-WinNTGroupMember {

    <#
    .SYNOPSIS

    Use the LDAP provider to add information about group members to a DirectoryEntry of a group for easier access
    .DESCRIPTION
    Recursively retrieves group members and detailed information about them
    .INPUTS
    [System.DirectoryServices.DirectoryEntry]$DirectoryEntry
    .OUTPUTS
    [System.DirectoryServices.DirectoryEntry] Returned with member info added now (if the DirectoryEntry is a group).
    .EXAMPLE
    [System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrators') | Get-WinNTGroupMember | Expand-WinNTGroupMember

    Retrieves the members of the local Administrators group and then expands each member by adding
    additional information such as SID, domain information, and group membership details if the member
    is itself a group. This provides a complete hierarchical view of permissions.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Expand-WinNTGroupMember')]
    [OutputType([System.DirectoryServices.DirectoryEntry])]

    param (

        # Expecting a DirectoryEntry from the WinNT provider, or a PSObject imitation from Get-DirectoryEntry
        [Parameter(ValueFromPipeline)]
        $DirectoryEntry,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache,

        # Properties of each Account to display on the report
        [string[]]$AccountProperty = @('DisplayName', 'Company', 'Department', 'Title', 'Description')

    )

    begin {

        $Log = @{ 'Cache' = $Cache }
        $DomainBySid = [ref]$Cache.Value['DomainBySid']

        # Add the bare minimum required properties
        $PropertiesToLoad = $AccountProperty + @(
            'distinguishedName',
            'grouptype',
            'member',
            'name',
            'objectClass',
            'objectSid',
            'primaryGroupToken',
            'samAccountName'
        )

        $PropertiesToLoad = $PropertiesToLoad |
            Sort-Object -Unique

        $AdsiGroupSplat = @{
            'Cache'            = $Cache
            'PropertiesToLoad' = $PropertiesToLoad
        }

    }

    process {

        ForEach ($ThisEntry in $DirectoryEntry) {

            $ThisPath = $ThisEntry.Path
            $AdsiGroupSplat['DirectoryPath'] = $ThisPath
            $Suffix = " # for DirectoryEntry '$ThisPath'"
            $Log['Suffix'] = $Suffix

            if ( -not $ThisEntry.Properties ) {

                $StartingLogType = $Cache.Value['LogType'].Value
                $Cache.Value['LogType'].Value = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
                Write-LogMsg @Log -Text " # '$ThisEntry' has no properties"
                $Cache.Value['LogType'].Value = $StartingLogType

            } elseif ($ThisEntry.Properties['objectClass'] -contains 'group') {

                $Log['Suffix'] = " # Is an ADSI group $Suffix"
                Write-LogMsg @Log -Text "`$AdsiGroup = Get-AdsiGroup" -Expand $AdsiGroupSplat -ExpansionMap $Cache.Value['LogCacheMap'].Value
                $AdsiGroup = Get-AdsiGroup @AdsiGroupSplat
                $Log['Suffix'] = " # for $(@($AdsiGroup.FullMembers).Count) members $Suffix"
                Write-LogMsg @Log -Text "Add-SidInfo -InputObject `$AdsiGroup.FullMembers -DomainsBySid [ref]`$Cache.Value['DomainBySid']"
                Add-SidInfo -InputObject $AdsiGroup.FullMembers -DomainsBySid $DomainBySid

            } else {

                if ($ThisEntry.SchemaClassName -eq 'group') {

                    #Write-LogMsg @Log -Text " # Is a WinNT group"

                    if ($ThisEntry.GetType().FullName -eq 'System.Collections.Hashtable') {

                        $Log['Suffix'] = " # Is a special group with no direct memberships $Suffix"
                        Write-LogMsg @Log -Text "Add-SidInfo -InputObject `$ThisEntry -DomainsBySid [ref]`$Cache.Value['DomainBySid']"
                        Add-SidInfo -InputObject $ThisEntry -DomainsBySid $DomainBySid

                    }

                } else {

                    $Log['Suffix'] = " # Is a user account $Suffix"
                    Write-LogMsg @Log -Text "Add-SidInfo -InputObject `$ThisEntry -DomainsBySid [ref]`$Cache.Value['DomainBySid']"
                    Add-SidInfo -InputObject $ThisEntry -DomainsBySid $DomainBySid

                }

            }

        }

    }

}
function Find-LocalAdsiServerSid {

    <#
    .SYNOPSIS

        Finds the SID prefix of the local server by querying the built-in administrator account.
    .DESCRIPTION
        This function queries the local computer or a remote computer via CIM to find the SID
        of the built-in administrator account (RID 500), then extracts and returns the server's
        SID prefix by removing the RID portion. This is useful for identifying the server's
        unique domain identifier in Active Directory environments.
    .INPUTS
        None. Pipeline input is not accepted.
    .OUTPUTS
        System.String

        Returns the SID prefix of the specified computer or local computer.
    .EXAMPLE
        Find-LocalAdsiServerSid -ComputerName "DC01" -Cache $Cache

        Retrieves the SID prefix for the computer "DC01" by querying the built-in Administrator
        account and removing the RID portion. This domain SID prefix can be used to identify
        the domain and construct SIDs for domain users and groups.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Find-LocalAdsiServerSid')]
    [OutputType([System.String])]

    param (

        # Name of the computer to query via CIM
        [string]$ComputerName = (HOSTNAME.EXE),

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $CimParams = @{
        Cache        = $Cache
        ComputerName = $ComputerName
        Query        = "SELECT SID FROM Win32_UserAccount WHERE LocalAccount = 'True' AND SID LIKE 'S-1-5-21-%-500'"
        KeyProperty  = 'SID'
    }

    Write-LogMsg -Text 'Get-CachedCimInstance' -Expand $CimParams -ExpansionMap $Cache.Value['LogCacheMap'].Value -Cache $Cache
    $LocalAdminAccount = Get-CachedCimInstance @CimParams

    if (-not $LocalAdminAccount) {
        return
    }

    return $LocalAdminAccount.SID.Substring(0, $LocalAdminAccount.SID.LastIndexOf('-'))

}
function Get-AdsiGroup {

    <#
    .SYNOPSIS

    Get the directory entries for a group and its members using ADSI
    .DESCRIPTION
    Uses the ADSI components to search a directory for a group, then get its members
    Both the WinNT and LDAP providers are supported
    .INPUTS
    None. Pipeline input is not accepted.
    .OUTPUTS
    [System.DirectoryServices.DirectoryEntry] for each group memeber
    .EXAMPLE
    Get-AdsiGroup -DirectoryPath 'WinNT://WORKGROUP/localhost' -GroupName Administrators -Cache $Cache

    Retrieves the local Administrators group from the specified computer using the WinNT provider,
    and returns all member accounts as DirectoryEntry objects. This allows for complete analysis
    of local group memberships including nested groups and domain accounts that have been added to
    local groups.

    .EXAMPLE
    Get-AdsiGroup -GroupName Administrators -Cache $Cache

    On a domain-joined computer, retrieves the domain's Administrators group and all of its members.
    On a workgroup computer, retrieves the local Administrators group and its members. This automatic
    detection simplifies scripts that need to work in both domain and workgroup environments.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Get-AdsiGroup')]
    [OutputType([System.DirectoryServices.DirectoryEntry])]

    param (

        <#
        Path to the directory object to retrieve
        Defaults to the root of the current domain
        #>
        [string]$DirectoryPath = (([System.DirectoryServices.DirectorySearcher]::new()).SearchRoot.Path),

        # Name (CN or Common Name) of the group to retrieve
        [string]$GroupName,

        # Properties of the group members to retrieve
        [string[]]$PropertiesToLoad = @('distinguishedName', 'groupType', 'member', 'name', 'objectClass', 'objectSid', 'primaryGroupToken', 'samAccountName'),

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]

        [ref]$Cache

    )

    $Log = @{ 'Cache' = $Cache ; 'Suffix' = " # for ADSI group '$GroupName'" }

    $GroupParams = @{
        'Cache'            = $Cache
        'DirectoryPath'    = $DirectoryPath
        'PropertiesToLoad' = $PropertiesToLoad
    }

    $GroupMemberParams = @{
        'Cache'            = $Cache
        'PropertiesToLoad' = $PropertiesToLoad
    }

    # Add the bare minimum required properties
    $PropertiesToLoad = $PropertiesToLoad + @(
        'distinguishedName',
        'grouptype',
        'member',
        'name',
        'objectClass',
        'objectSid',
        'primaryGroupToken',
        'samAccountName'
    )

    $PropertiesToLoad = $PropertiesToLoad |
        Sort-Object -Unique

    switch -Regex ($DirectoryPath) {
        '^WinNT' {
            $GroupParams['DirectoryPath'] = "$DirectoryPath/$GroupName"
            Write-LogMsg @Log -Text 'Get-DirectoryEntry' -Expand $GroupParams -ExpansionMap $Cache.Value['LogCacheMap'].Value
            $GroupMemberParams['DirectoryEntry'] = Get-DirectoryEntry @GroupParams
            Write-LogMsg @Log -Text 'Get-WinNTGroupMember' -Expand $GroupMemberParams -ExpansionMap $Cache.Value['LogCacheMap'].Value
            $FullMembers = Get-WinNTGroupMember @GroupMemberParams
            break
        }
        '^$' {
            # This is expected for a workgroup computer
            $GroupParams['DirectoryPath'] = "WinNT://localhost/$GroupName"
            Write-LogMsg @Log -Text 'Get-DirectoryEntry' -Expand $GroupParams -ExpansionMap $Cache.Value['LogCacheMap'].Value
            $GroupMemberParams['DirectoryEntry'] = Get-DirectoryEntry @GroupParams
            Write-LogMsg @Log -Text 'Get-WinNTGroupMember' -Expand $GroupMemberParams -ExpansionMap $Cache.Value['LogCacheMap'].Value
            $FullMembers = Get-WinNTGroupMember @GroupMemberParams
            break
        }
        default {

            if ($GroupName) {
                $GroupParams['Filter'] = "(&(objectClass=group)(cn=$GroupName))"
            } else {
                $GroupParams['Filter'] = '(objectClass=group)'
            }

            Write-LogMsg @Log -Text 'Search-Directory' -Expand $GroupParams -ExpansionMap $Cache.Value['LogCacheMap'].Value
            $GroupMemberParams['Group'] = Search-Directory @GroupParams
            Write-LogMsg @Log -Text 'Get-AdsiGroupMember' -Expand $GroupMemberParams -ExpansionMap $Cache.Value['LogCacheMap'].Value
            $FullMembers = Get-AdsiGroupMember @GroupMemberParams
        }

    }

    return $FullMembers

}
function Get-AdsiGroupMember {

    <#
    .SYNOPSIS

    Get members of a group from the LDAP provider
    .DESCRIPTION
    Use ADSI to get members of a group from the LDAP provider
    Return the group's DirectoryEntry plus a FullMembers property containing the member DirectoryEntries
    .INPUTS
    [System.DirectoryServices.DirectoryEntry]$DirectoryEntry
    .OUTPUTS
    [System.DirectoryServices.DirectoryEntry] plus a FullMembers property
    .EXAMPLE
    [System.DirectoryServices.DirectoryEntry]::new('LDAP://ad.contoso.com/CN=Administrators,CN=BuiltIn,DC=ad,DC=contoso,DC=com') |
    Get-AdsiGroupMember -Cache $Cache

    Retrieves all members of the domain's Administrators group, including both direct members and those
    who inherit membership through their primary group. The function returns the original group DirectoryEntry
    object with an added FullMembers property containing all member DirectoryEntry objects. This
    approach ensures proper resolution of all group memberships regardless of how they are assigned.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Get-AdsiGroupMember')]
    [OutputType([System.DirectoryServices.DirectoryEntry])]

    param (

        # Directory entry of the LDAP group whose members to get
        [Parameter(ValueFromPipeline)]
        $Group,

        # Properties of the group members to find in the directory
        [string[]]$PropertiesToLoad = @('distinguishedName', 'groupType', 'member', 'name', 'objectClass', 'objectSid', 'primaryGroupToken', 'samAccountName'),

        <#
        Perform a non-recursive search of the memberOf attribute

        Otherwise the search will be recursive by default
        #>

        [switch]$NoRecurse,

        <#
        Search the primaryGroupId attribute only

        Ignore the memberOf attribute
        #>

        [switch]$PrimaryGroupOnly,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    begin {

        $Log = @{ Cache = $Cache }
        $PathRegEx = '(?<Path>LDAP:\/\/[^\/]*)'
        $DomainRegEx = '(?i)DC=\w{1,}?\b'

        # Add the bare minimum required properties
        $PropertiesToLoad = $PropertiesToLoad + @(
            'distinguishedName',
            'grouptype',
            'member',
            'name',
            'objectClass',
            'objectSid',
            'primaryGroupToken',
            'samAccountName'
        )

        $PropertiesToLoad = $PropertiesToLoad |
            Sort-Object -Unique

        $SearchParams = @{
            Cache            = $Cache
            PropertiesToLoad = $PropertiesToLoad
        }

    }

    process {

        foreach ($ThisGroup in $Group) {

            $Log['Suffix'] = " # for ADSI group named '$($ThisGroup.Properties.name)'"

            if (-not $ThisGroup.Properties['primaryGroupToken']) {
                $ThisGroup.RefreshCache('primaryGroupToken')
            }

            # The memberOf attribute does not reflect a user's Primary Group membership so the primaryGroupId attribute must be searched
            $primaryGroupIdFilter = "(primaryGroupId=$($ThisGroup.Properties['primaryGroupToken']))"

            if ($PrimaryGroupOnly) {
                $SearchParams['Filter'] = $primaryGroupIdFilter
            } else {

                if ($NoRecurse) {

                    # Non-recursive search of the memberOf attribute
                    $MemberOfFilter = "(memberOf=$($ThisGroup.Properties['distinguishedname']))"

                } else {

                    # Recursive search of the memberOf attribute
                    $MemberOfFilter = "(memberOf:1.2.840.113556.1.4.1941:=$($ThisGroup.Properties['distinguishedname']))"

                }

                $SearchParams['Filter'] = "(|$MemberOfFilter$primaryGroupIdFilter)"
            }

            if ($ThisGroup.Path -match $PathRegEx) {

                $SearchParams['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath $Matches.Path -Cache $Cache

                if ($ThisGroup.Path -match $DomainRegEx) {

                    $Domain = ([regex]::Matches($ThisGroup.Path, $DomainRegEx) | ForEach-Object { $_.Value }) -join ','
                    $SearchParams['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath "LDAP://$Domain" -Cache $Cache

                } else {
                    $SearchParams['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath $ThisGroup.Path -Cache $Cache
                }

            } else {
                $SearchParams['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath $ThisGroup.Path -Cache $Cache
            }

            Write-LogMsg @Log -Text 'Search-Directory' -Expand $SearchParams -ExpansionMap $Cache.Value['LogCacheMap'].Value
            $GroupMemberSearch = Search-Directory @SearchParams
            #Write-LogMsg @Log -Text " # '$($GroupMemberSearch.Count)' results for Search-Directory -DirectoryPath '$($SearchParams['DirectoryPath'])' -Filter '$($SearchParams['Filter'])'"

            if ($GroupMemberSearch.Count -gt 0) {

                $DirectoryEntryParams = @{
                    Cache            = $Cache
                    PropertiesToLoad = $PropertiesToLoad
                }

                $CurrentADGroupMembers = [System.Collections.Generic.List[System.DirectoryServices.DirectoryEntry]]::new()

                $MembersThatAreGroups = $GroupMemberSearch |
                    Where-Object -FilterScript { $_.Properties['objectClass'] -contains 'group' }

                $DirectoryEntryParams = @{
                    Cache            = $Cache
                    PropertiesToLoad = $PropertiesToLoad
                }

                if ($MembersThatAreGroups.Count -gt 0) {

                    $FilterBuilder = [System.Text.StringBuilder]::new('(|')

                    ForEach ($ThisMember in $MembersThatAreGroups) {
                        $null = $FilterBuilder.Append("(primaryGroupId=$($ThisMember.Properties['primaryGroupToken'])))")
                    }

                    $null = $FilterBuilder.Append(')')
                    $PrimaryGroupFilter = $FilterBuilder.ToString()
                    $SearchParams['Filter'] = $PrimaryGroupFilter
                    Write-LogMsg @Log -Text 'Search-Directory' -Expand $SearchParams -ExpansionMap $Cache.Value['LogCacheMap'].Value
                    $PrimaryGroupMembers = Search-Directory @SearchParams

                    ForEach ($ThisMember in $PrimaryGroupMembers) {

                        $FQDNPath = Add-DomainFqdnToLdapPath -DirectoryPath $ThisMember.Path -Cache $Cache
                        $DirectoryEntry = $null
                        Write-LogMsg @Log -Text "Get-DirectoryEntry -DirectoryPath '$FQDNPath'" -Expand $DirectoryEntryParams -ExpansionMap $Cache.Value['LogCacheMap'].Value
                        $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $FQDNPath @DirectoryEntryParams

                        if ($DirectoryEntry) {
                            $null = $CurrentADGroupMembers.Add($DirectoryEntry)
                        }

                    }

                }

                ForEach ($ThisMember in $GroupMemberSearch) {

                    $FQDNPath = Add-DomainFqdnToLdapPath -DirectoryPath $ThisMember.Path -Cache $Cache
                    $DirectoryEntry = $null
                    Write-LogMsg @Log -Text "Get-DirectoryEntry -DirectoryPath '$FQDNPath'" -Expand $DirectoryEntryParams -ExpansionMap $Cache.Value['LogCacheMap'].Value
                    $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $FQDNPath @DirectoryEntryParams

                    if ($DirectoryEntry) {
                        $null = $CurrentADGroupMembers.Add($DirectoryEntry)
                    }

                }

            } else {
                $CurrentADGroupMembers = $null
            }

            Write-LogMsg @Log -Text "Expand-AdsiGroupMember -DirectoryEntry `$CurrentADGroupMembers -Cache `$Cache # for $(@($CurrentADGroupMembers).Count) members"
            $ProcessedGroupMembers = Expand-AdsiGroupMember -DirectoryEntry $CurrentADGroupMembers -PropertiesToLoad $PropertiesToLoad -Cache $Cache
            Add-Member -InputObject $ThisGroup -MemberType NoteProperty -Name FullMembers -Value $ProcessedGroupMembers -Force -PassThru

        }

    }

}
function Get-AdsiServer {

    <#
    .SYNOPSIS

    Get information about a directory server including the ADSI provider it hosts and its well-known SIDs
    .DESCRIPTION
    Uses the ADSI provider to query the server using LDAP first, then WinNT upon failure
    Uses WinRM to query the CIM class Win32_SystemAccount for well-known SIDs
    .INPUTS
    [System.String]$Fqdn
    .OUTPUTS
    [PSCustomObject] with AdsiProvider and WellKnownSidBySid properties
    .EXAMPLE
    Get-AdsiServer -Fqdn localhost -Cache $Cache

    Retrieves information about the local computer's directory service, determining whether it uses
    the LDAP or WinNT provider, and collects information about well-known security identifiers (SIDs).
    This is essential for consistent identity resolution on the local system when analyzing permissions.

    .EXAMPLE
    Get-AdsiServer -Fqdn 'ad.contoso.com' -Cache $Cache

    Connects to the domain controller for 'ad.contoso.com', determines it uses the LDAP provider,
    and retrieves domain-specific information including SIDs, NetBIOS name, and distinguished name.
    This enables proper identity resolution for domain accounts when working with permissions across systems.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Get-AdsiServer')]
    [OutputType([System.String])]

    param (

        # IP address or hostname of the directory server whose ADSI provider type to determine
        [Parameter(ValueFromPipeline)]
        [string[]]$Fqdn,

        # NetBIOS name of the ADSI server whose information to determine
        [string[]]$Netbios,

        # Remove the CIM session used to get ADSI server information
        [switch]$RemoveCimSession,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    begin {

        $Log = @{ Cache = $Cache }
        $DomainsByFqdn = $Cache.Value['DomainByFqdn']
        $DomainsByNetbios = $Cache.Value['DomainByNetbios']
        $DomainsBySid = $Cache.Value['DomainBySid']
        $WellKnownSidBySid = $Cache.Value['WellKnownSidBySid']
        $WellKnownSidByName = $Cache.Value['WellKnownSidByName']

    }

    process {

        ForEach ($DomainFqdn in $Fqdn) {

            $Log['Suffix'] = " # for domain FQDN '$DomainFqdn'"
            $OutputObject = $null
            $TryGetValueResult = $DomainsByFqdn.Value.TryGetValue($DomainFqdn, [ref]$OutputObject)

            if ($TryGetValueResult) {

                #Write-LogMsg @Log -Text " # Domain FQDN cache hit"
                if ($OutputObject.AdsiProvider) {
                    $OutputObject
                    continue
                }

            }

            $TryGetValueResult = $DomainsByNetbios.Value.TryGetValue($DomainFqdn, [ref]$OutputObject)

            if ($TryGetValueResult) {

                #Write-LogMsg @Log -Text " # Domain NetBIOS cache hit"
                if ($OutputObject.AdsiProvider) {
                    $OutputObject
                    continue
                }

            }

            Write-LogMsg @Log -Text "Find-AdsiProvider -AdsiServer '$DomainFqdn' -Cache `$Cache # Domain FQDN cache miss"
            $AdsiProvider = Find-AdsiProvider -AdsiServer $DomainFqdn -Cache $Cache

            if ($null -eq $AdsiProvider) {
                $StartingLogType = $Cache.Value['LogType'].Value
                $Cache.Value['LogType'].Value = 'Warning'
                Write-LogMsg @Log -Text ' # Could not find the ADSI provider'
                $Log['Type'] = $Cache.Value['LogType'].Value
                continue
            }

            Write-LogMsg @Log -Text "ConvertTo-DistinguishedName -DomainFQDN '$DomainFqdn' -AdsiProvider '$AdsiProvider' -Cache `$Cache"
            $DomainDn = ConvertTo-DistinguishedName -DomainFQDN $DomainFqdn -AdsiProvider $AdsiProvider -Cache $Cache

            Write-LogMsg @Log -Text "ConvertTo-DomainSidString -DomainDnsName '$DomainFqdn' -Cache `$Cache"
            $DomainSid = ConvertTo-DomainSidString -DomainDnsName $DomainFqdn -AdsiProvider $AdsiProvider -Cache $Cache

            Write-LogMsg @Log -Text "ConvertTo-DomainNetBIOS -DomainFQDN '$DomainFqdn' -AdsiProvider '$AdsiProvider' -Cache `$Cache"
            $DomainNetBIOS = ConvertTo-DomainNetBIOS -DomainFQDN $DomainFqdn -AdsiProvider $AdsiProvider -Cache $Cache

            Write-LogMsg @Log -Text "Get-CachedCimInstance -ComputerName '$DomainFqdn' -Query 'Select * from Win32_Account Where LocalAccount = TRUE' -KeyProperty 'Caption' -CacheByProperty @() -Cache `$Cache"
            $Win32Accounts = Get-CachedCimInstance -ComputerName $DomainFqdn -Query 'Select * from Win32_Account Where LocalAccount = TRUE' -KeyProperty 'Caption' -CacheByProperty @() -Cache $Cache

            Write-LogMsg @Log -Text "`$Win32Services = Get-CachedCimInstance -ComputerName '$DomainFqdn' -ClassName 'Win32_Service' -KeyProperty 'Name' -CacheByProperty @() -Cache `$Cache"
            $Win32Services = Get-CachedCimInstance -ComputerName $DomainFqdn -ClassName 'Win32_Service' -KeyProperty 'Name' -CacheByProperty @() -Cache $Cache

            Write-LogMsg @Log -Text "Resolve-ServiceNameToSID -InputObject `$Win32Services"
            $ResolvedWin32Services = Resolve-ServiceNameToSID -InputObject $Win32Services

            ConvertTo-AccountCache -Account $Win32Accounts -SidCache $WellKnownSidBySid -NameCache $WellKnownSidByName
            ConvertTo-AccountCache -Account $ResolvedWin32Services -SidCache $WellKnownSidBySid -NameCache $WellKnownSidByName

            $OutputObject = [PSCustomObject]@{
                DistinguishedName  = $DomainDn
                Dns                = $DomainFqdn
                Sid                = $DomainSid
                Netbios            = $DomainNetBIOS
                AdsiProvider       = $AdsiProvider
                WellKnownSidBySid  = $WellKnownSidBySid.Value
                WellKnownSidByName = $WellKnownSidByName.Value
            }

            $DomainsByFqdn.Value[$DomainFqdn] = $OutputObject
            $DomainsByNetbios.Value[$DomainNetBIOS] = $OutputObject
            $DomainsBySid.Value[$DomainSid] = $OutputObject
            $OutputObject

        }

        ForEach ($DomainNetbios in $Netbios) {

            $Log['Suffix'] = " # for domain NetBIOS '$DomainNetbios'"
            $OutputObject = $null
            $TryGetValueResult = $DomainsByNetbios.Value.TryGetValue($DomainNetbios, [ref]$OutputObject)

            if ($TryGetValueResult) {

                #Write-LogMsg @Log -Text " # Domain NetBIOS cache hit"
                if ($OutputObject.AdsiProvider) {
                    $OutputObject
                    continue
                }

            }

            $TryGetValueResult = $DomainsByFqdn.Value.TryGetValue($DomainNetbios, [ref]$OutputObject)

            if ($TryGetValueResult) {

                #Write-LogMsg @Log -Text " # Domain NetBIOS cache hit"
                if ($OutputObject.AdsiProvider) {
                    $OutputObject
                    continue
                }

            }

            Write-LogMsg @Log -Text "`$CimSession = Get-CachedCimSession -ComputerName '$DomainNetbios' -Cache `$Cache # Domain NetBIOS cache miss"
            $CimSession = Get-CachedCimSession -ComputerName $DomainNetbios -Cache $Cache

            Write-LogMsg @Log -Text "Find-AdsiProvider -AdsiServer '$DomainNetbios' -Cache `$Cache"
            $AdsiProvider = Find-AdsiProvider -AdsiServer $DomainNetbios -Cache $Cache

            if ($null -eq $AdsiProvider) {
                $StartingLogType = $Cache.Value['LogType'].Value
                $Cache.Value['LogType'].Value = 'Warning'
                Write-LogMsg @Log -Text " # Could not find the ADSI provider for '$DomainDnsName'"
                $Cache.Value['LogType'].Value = $StartingLogType
                continue
            }

            Write-LogMsg @Log -Text "ConvertTo-DistinguishedName -Domain '$DomainNetBIOS' -Cache `$Cache"
            $DomainDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -Cache $Cache

            if ($DomainDn) {

                Write-LogMsg @Log -Text "ConvertTo-Fqdn -DistinguishedName '$DomainDn' -Cache `$Cache"
                $DomainDnsName = ConvertTo-Fqdn -DistinguishedName $DomainDn -Cache $Cache

            } else {

                Write-LogMsg @Log -Text "Get-ParentDomainDnsName -DomainNetbios '$DomainNetBIOS' -CimSession `$CimSession -Cache `$Cache"
                $ParentDomainDnsName = Get-ParentDomainDnsName -DomainNetbios $DomainNetBIOS -CimSession $CimSession -Cache $Cache
                $DomainDnsName = "$DomainNetBIOS.$ParentDomainDnsName"

            }

            Write-LogMsg @Log -Text "ConvertTo-DomainSidString -DomainDnsName '$DomainDnsName' -AdsiProvider '$AdsiProvider' -Cache `$Cache"
            $DomainSid = ConvertTo-DomainSidString -DomainDnsName $DomainDnsName -AdsiProvider $AdsiProvider -Cache $Cache

            Write-LogMsg @Log -Text "Get-CachedCimInstance -ComputerName '$DomainDnsName' -Query 'Select * from Win32_Account Where LocalAccount = TRUE' -KeyProperty 'Caption' -CacheByProperty @() -Cache `$Cache"
            $Win32Accounts = Get-CachedCimInstance -ComputerName $DomainDnsName -Query 'Select * from Win32_Account Where LocalAccount = TRUE' -KeyProperty 'Caption' -CacheByProperty @() -Cache $Cache

            Write-LogMsg @Log -Text "`$Win32Services = Get-CachedCimInstance -ComputerName '$DomainDnsName' -ClassName 'Win32_Service' -KeyProperty 'Name' -CacheByProperty @() -Cache `$Cache"
            $Win32Services = Get-CachedCimInstance -ComputerName $DomainDnsName -ClassName 'Win32_Service' -KeyProperty 'Name' -CacheByProperty @() -Cache $Cache

            Write-LogMsg @Log -Text "Resolve-ServiceNameToSID -InputObject `$Win32Services"
            $ResolvedWin32Services = Resolve-ServiceNameToSID -InputObject $Win32Services

            ConvertTo-AccountCache -Account $Win32Accounts -SidCache $WellKnownSidBySid -NameCache $WellKnownSidByName
            ConvertTo-AccountCache -Account $ResolvedWin32Services -SidCache $WellKnownSidBySid -NameCache $WellKnownSidByName

            if ($RemoveCimSession) {
                Remove-CimSession -CimSession $CimSession
            }

            $OutputObject = [PSCustomObject]@{
                DistinguishedName  = $DomainDn
                Dns                = $DomainDnsName
                Sid                = $DomainSid # TODO : This should be a sid object since there is a sidstring property but downstream consumers first need to be updated to use sidstring
                SidString          = $DomainSid
                Netbios            = $DomainNetBIOS
                AdsiProvider       = $AdsiProvider
                Win32Accounts      = $Win32Accounts
                Win32Services      = $ResolvedWin32Services
                WellKnownSidBySid  = $WellKnownSidBySid.Value
                WellKnownSidByName = $WellKnownSidByName.Value
            }

            $DomainsByFqdn.Value[$DomainDnsName] = $OutputObject
            $DomainsByNetbios.Value[$DomainNetBIOS] = $OutputObject
            $DomainsBySid.Value[$DomainSid] = $OutputObject
            $OutputObject

        }

    }

}
function Get-CurrentDomain {

    <#
    .SYNOPSIS

    Use ADSI to get the current domain
    .DESCRIPTION
    Works only on domain-joined systems, otherwise returns nothing
    .INPUTS
    None. Pipeline input is not accepted.
    .OUTPUTS
    [System.DirectoryServices.DirectoryEntry] The current domain

    .EXAMPLE
    Get-CurrentDomain -Cache $Cache

    Retrieves the current domain of the computer running the script as a DirectoryEntry object.
    On domain-joined systems, this returns the Active Directory domain. On workgroup computers,
    it returns the local computer as the domain. The function caches the result to improve
    performance in subsequent operations involving the current domain.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Get-CurrentDomain')]
    [OutputType([System.DirectoryServices.DirectoryEntry])]

    param (

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $ComputerName = $Cache.Value['ThisHostname'].Value
    $Suffix = " # for the computer running the script, named '$ComputerName'"
    Write-LogMsg -Text "Get-CachedCimInstance -ComputerName $ComputerName -ClassName 'Win32_ComputerSystem' -KeyProperty 'Name' -Cache `$Cache$Suffix" -Cache $Cache
    $Comp = Get-CachedCimInstance -ComputerName $ComputerName -ClassName 'Win32_ComputerSystem' -KeyProperty 'Name' -Cache $Cache

    if ($Comp.Domain -eq 'WORKGROUP') {

        Write-LogMsg -Text "Get-AdsiServer -Fqdn '$ComputerName' -Cache `$Cache" -Cache $Cache -Suffix " # is not domain-joined$Suffix"
        Get-AdsiServer -Fqdn $ComputerName -Cache $Cache
        $Cache.Value['ThisParentDomain'] = [ref]$Cache.Value['DomainByFqdn'].Value[$ComputerName]

    } else {

        Write-LogMsg -Text "Get-AdsiServer -Fqdn '$($Comp.Domain))' -Cache `$Cache" -Cache $Cache -Suffix " # is either domain-joined or joined to a custom-named workgroup$Suffix"
        Get-AdsiServer -Fqdn $Comp.Domain -Cache $Cache
        $Cache.Value['ThisParentDomain'] = [ref]$Cache.Value['DomainByFqdn'].Value[$Comp.Domain]

    }

}
function Get-DirectoryEntry {

    <#
    .SYNOPSIS
    Use Active Directory Service Interfaces to retrieve an object from a directory
    .DESCRIPTION
    Retrieve a directory entry using either the WinNT or LDAP provider for ADSI
    .INPUTS
    None. Pipeline input is not accepted.
    .OUTPUTS
    [System.DirectoryServices.DirectoryEntry] where possible
    [PSCustomObject] for security principals with no directory entry
    .EXAMPLE
    Get-DirectoryEntry
    distinguishedName : {DC=ad,DC=contoso,DC=com}
    Path              : LDAP://DC=ad,DC=contoso,DC=com

    As the current user on a domain-joined computer, bind to the current domain and retrieve the DirectoryEntry for the root of the domain
    .EXAMPLE
    Get-DirectoryEntry
    distinguishedName :
    Path              : WinNT://ComputerName

    As the current user on a workgroup computer, bind to the local system and retrieve the DirectoryEntry for the root of the directory
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Get-DirectoryEntry')]
    [OutputType([System.DirectoryServices.DirectoryEntry], [PSCustomObject])]


    param (

        <#
        Path to the directory object to retrieve
        Defaults to the root of the current domain
        #>
        [string]$DirectoryPath = (([System.DirectoryServices.DirectorySearcher]::new()).SearchRoot.Path),

        <#
        Credentials to use to bind to the directory
        Defaults to the credentials of the current user
        #>

        [pscredential]$Credential,

        # Properties of the target object to retrieve
        [string[]]$PropertiesToLoad,

        # Mapping of SID types to descriptions used for converting security identifiers
        [hashtable]$SidTypeMap = (Get-SidTypeMap),

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]

        [ref]$Cache

    )

    $Log = @{ Cache = $Cache }
    $CacheResult = $null
    $DirectoryEntryByPath = $Cache.Value['DirectoryEntryByPath']
    $TryGetValueResult = $DirectoryEntryByPath.Value.TryGetValue($DirectoryPath, [ref]$CacheResult)

    if ($TryGetValueResult) {

        #Write-LogMsg @Log -Text " # DirectoryEntryByPath hit # for '$DirectoryPath'"
        return $CacheResult

    }

    #Write-LogMsg @Log -Text " # DirectoryEntryByPath miss # for '$DirectoryPath'"
    $SplitDirectoryPath = Split-DirectoryPath -DirectoryPath $DirectoryPath
    $Server = $SplitDirectoryPath['Domain']

    $CacheSearch = @{
        AccountName   = $SplitDirectoryPath['Account']
        Cache         = $Cache
        DirectoryPath = $DirectoryPath
        Server        = $Server
        SidTypeMap    = $SidTypeMap
    }

    $DirectoryEntry = Get-CachedDirectoryEntry @CacheSearch

    if ($null -eq $DirectoryEntry) {

        if ([string]::IsNullOrEmpty($DirectoryPath)) {

            # Workgroup computers do not return a DirectoryEntry with a SearchRoot Path so this ends up being an empty string
            # This is also invoked when DirectoryPath is null for any reason
            # We will return a WinNT object representing the local computer's WinNT directory
            $ThisHostName = $Cache.Value['ThisHostName'].Value
            Write-LogMsg @Log -Text " # The SearchRoot Path is empty, indicating '$ThisHostName' is not domain-joined. Defaulting to WinNT provider for localhost instead. # for DirectoryPath '$DirectoryPath'"

            $CimParams = @{
                Cache        = $Cache
                ComputerName = $Cache.Value['ThisFqdn'].Value
            }

            $Workgroup = (Get-CachedCimInstance -ClassName 'Win32_ComputerSystem' -KeyProperty 'Name' @CimParams).Workgroup
            $DirectoryPath = "WinNT://$Workgroup/$ThisHostname"
            Write-LogMsg @Log -Text "[System.DirectoryServices.DirectoryEntry]::new('$DirectoryPath')"

            if ($Credential) {

                $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new(
                    $DirectoryPath,
                    $($Credential.UserName),
                    $($Credential.GetNetworkCredential().password)
                )

            } else {
                $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath)
            }

            $SampleUser = @(
                $DirectoryEntry.PSBase.Children |
                    Where-Object -FilterScript { $_.schemaclassname -eq 'user' }
                )[0] |
                    Add-SidInfo -DomainsBySid [ref]$Cache.Value['DomainBySid']

            $DirectoryEntry |
                Add-Member -MemberType NoteProperty -Name 'Domain' -Value $SampleUser.Domain -Force

        } else {

            # Otherwise the DirectoryPath is an LDAP path or a WinNT path (treated the same at this stage)
            Write-LogMsg @Log -Text "[System.DirectoryServices.DirectoryEntry]::new('$DirectoryPath')"

            if ($Credential) {
                $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new(
                    $DirectoryPath,
                    $($Credential.UserName),
                    $($Credential.GetNetworkCredential().password)
                )
            } else {
                $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath)
            }

        }

    }

    if ($PropertiesToLoad) {

        try {

            # If the $DirectoryPath was invalid, this line will return an error
            $null = $DirectoryEntry.RefreshCache($PropertiesToLoad)

        } catch {

            $Log['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually

            # Ensure that the error message appears on 1 line
            # Use .Trim() to remove leading and trailing whitespace
            # Removed because I think .Trim() does it:
            # -replace '\s"',' "')" to remove an errant line break in the following specific error I encountered:
            # The following exception occurred while retrieving member "RefreshCache": "The group name could not be found.`r`n"
            $UpdatedMsg = $_.Exception.Message.Trim().Replace('The following exception occurred while retrieving member "RefreshCache": ', '').Replace('"', '')
            Write-LogMsg @Log -Text " # '$DirectoryPath' could not be retrieved. Error: $UpdatedMsg"
            return

        }

    }

    $DirectoryEntryByPath.Value[$DirectoryPath] = $DirectoryEntry
    return $DirectoryEntry

}
function Get-KnownCaptionHashTable {

    <#
    .SYNOPSIS
        Creates a hashtable of well-known SIDs indexed by their NT Account names (captions).
    .DESCRIPTION
        This function takes a hashtable of well-known SIDs (indexed by SID) and
        transforms it into a new hashtable where the keys are the NT Account names
        (captions) of the SIDs. This makes it easier to look up SID information when
        you have the account name representation rather than the SID itself.
    .INPUTS
        System.Collections.Hashtable

        A hashtable containing SID strings as keys and information objects as values.
    .OUTPUTS
        System.Collections.Hashtable

        Returns a hashtable with NT Account names as keys and SID information objects as values.
    .EXAMPLE
        $sidBySid = Get-KnownSidHashTable
        $sidByCaption = Get-KnownCaptionHashTable -WellKnownSidBySid $sidBySid
        $systemInfo = $sidByCaption['NT AUTHORITY\SYSTEM']

        Creates a hashtable of well-known SIDs indexed by their NT Account names and retrieves
        information about the SYSTEM account. This is useful when you need to look up SID
        information by NT Account name rather than by SID string.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Get-KnownCaptionHashTable')]
    [OutputType([System.Collections.Hashtable])]

    param (

        # Hashtable of well-known Security Identifiers (SIDs) with their properties
        [hashtable]$WellKnownSidBySid = (Get-KnownSidHashTable)

    )

    $WellKnownSidByCaption = @{}

    ForEach ($KnownSID in $WellKnownSidBySid.Keys) {

        $Known = $WellKnownSidBySid[$KnownSID]
        $WellKnownSidByCaption[$Known.NTAccount] = $Known

    }

    return $WellKnownSidByCaption

}
function Get-KnownSid {

    <#
    .SYNOPSIS
    Retrieves information about well-known security identifiers (SIDs).

    .DESCRIPTION
    Gets information about well-known security identifiers (SIDs) based on patterns and common formats.
    Uses Microsoft documentation references for SID information:
    - https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/81d92bba-d22b-4a8c-908a-554ab29148ab
    - https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-identifiers

    .INPUTS
    System.String

    A SID string that identifies a well-known security principal.

    .OUTPUTS
    PSCustomObject with properties such as Description, DisplayName, Name, NTAccount, SamAccountName, SchemaClassName, and SID.

    .EXAMPLE
    Get-KnownSid -SID 'S-1-5-32-544'

    Returns information about the built-in Administrators group.

    .EXAMPLE
    Get-KnownSid -SID 'S-1-5-18'

    Returns information about the Local System account.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Get-KnownSid')]
    [OutputType([System.Collections.Hashtable])]

    param (

        # Security Identifier (SID) string to retrieve information for
        [string]$SID

    )

    $StartingPatterns = @{

        'S-1-5-80-' = {
            [PSCustomObject]@{
                'Description'     = "Service $SID"
                'DisplayName'     = $SID
                'SamAccountName'  = $SID
                'Name'            = $SID
                'NTAccount'       = "NT SERVICE\$SID"
                'SchemaClassName' = 'service'
                'SID'             = $SID
            }
        }

        'S-1-15-2-' = {
            [PSCustomObject]@{
                'Description'     = "App Container $SID"
                'DisplayName'     = $SID
                'SamAccountName'  = $SID
                'Name'            = $SID
                'NTAccount'       = "APPLICATION PACKAGE AUTHORITY\$SID"
                'SchemaClassName' = 'user'
                'SID'             = $SID
            }
        }

        'S-1-15-3-' = {
            ConvertFrom-AppCapabilitySid -SID $SID
        }

        'S-1-5-32-' = {
            [PSCustomObject]@{
                'Description'     = "BuiltIn $SID"
                'DisplayName'     = $SID
                'SamAccountName'  = $SID
                'Name'            = $SID
                'NTAccount'       = "BUILTIN\$SID"
                'SchemaClassName' = 'user'
                'SID'             = $SID
            }
        }

    }

    #if ($SID.Length -lt 9) { Pause } # This should not happen; any such SIDs should have ben found first by Find-CachedWellKnownSid. Pausing for now for debug. ToDo: make this more robust based on dynamic string length detection after it stops highlighting my issues with Find-CachedWellKnownSid.
    $TheNine = $SID.Substring(0, 9)
    $Match = $StartingPatterns[$TheNine]

    if ($Match) {
        $result = Invoke-Command -ScriptBlock $Match
        return $result
    }

    switch -Wildcard ($SID) {

        'S-1-5-*-500' {
            return [PSCustomObject]@{
                'Description'     = "A built-in user account for the system administrator to administer the computer/domain. Every computer has a local Administrator account and every domain has a domain Administrator account. The Administrator account is the first account created during operating system installation. The account can't be deleted, disabled, or locked out, but it can be renamed. By default, the Administrator account is a member of the Administrators group, and it can't be removed from that group."
                'DisplayName'     = 'Administrator'
                'SamAccountName'  = 'Administrator'
                'Name'            = 'Administrator'
                'NTAccount'       = 'BUILTIN\Administrator'
                'SchemaClassName' = 'user'
                'SID'             = $SID
            }
        }

        'S-1-5-*-501' {
            return [PSCustomObject]@{
                'Description'     = "A user account for people who don't have individual accounts. Every computer has a local Guest account, and every domain has a domain Guest account. By default, Guest is a member of the Everyone and the Guests groups. The domain Guest account is also a member of the Domain Guests and Domain Users groups. Unlike Anonymous Logon, Guest is a real account, and it can be used to sign in interactively. The Guest account doesn't require a password, but it can have one."
                'DisplayName'     = 'Guest'
                'SamAccountName'  = 'Guest'
                'Name'            = 'Guest'
                'NTAccount'       = 'BUILTIN\Guest'
                'SchemaClassName' = 'user'
                'SID'             = $SID
            }
        }

        'S-1-5-*-502' {
            return [PSCustomObject]@{
                'Description'     = "Kerberos Ticket-Generating Ticket account: a user account that's used by the Key Distribution Center (KDC) service. The account exists only on domain controllers."
                'DisplayName'     = 'KRBTGT'
                'SamAccountName'  = 'KRBTGT'
                'Name'            = 'KRBTGT'
                'NTAccount'       = 'BUILTIN\KRBTGT'
                'SchemaClassName' = 'user'
                'SID'             = $SID
            }
        }

        'S-1-5-*-512' {
            return [PSCustomObject]@{
                'Description'     = "A global group with members that are authorized to administer the domain. By default, the Domain Admins group is a member of the Administrators group on all computers that have joined the domain, including domain controllers. Domain Admins is the default owner of any object that's created in the domain's Active Directory by any member of the group. If members of the group create other objects, such as files, the default owner is the Administrators group."
                'DisplayName'     = 'Domain Admins'
                'SamAccountName'  = 'Domain Admins'
                'Name'            = 'Domain Admins'
                'NTAccount'       = 'BUILTIN\Domain Admins'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-513' {
            return [PSCustomObject]@{
                'Description'     = 'A global group that includes all users in a domain. When you create a new User object in Active Directory, the user is automatically added to this group.'
                'DisplayName'     = 'Domain Users'
                'SamAccountName'  = 'Domain Users'
                'Name'            = 'Domain Users'
                'NTAccount'       = 'BUILTIN\Domain Users'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-514' {
            return [PSCustomObject]@{
                'Description'     = "A global group that, by default, has only one member: the domain's built-in Guest account."
                'DisplayName'     = 'Domain Guests'
                'SamAccountName'  = 'Domain Guests'
                'Name'            = 'Domain Guests'
                'NTAccount'       = 'BUILTIN\Domain Guests'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-515' {
            return [PSCustomObject]@{
                'Description'     = 'A global group that includes all computers that have joined the domain, excluding domain controllers.'
                'DisplayName'     = 'Domain Computers'
                'SamAccountName'  = 'Domain Computers'
                'Name'            = 'Domain Computers'
                'NTAccount'       = 'BUILTIN\Domain Computers'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-516' {
            return [PSCustomObject]@{
                'Description'     = 'A global group that includes all domain controllers in the domain. New domain controllers are added to this group automatically.'
                'DisplayName'     = 'Domain Controllers'
                'SamAccountName'  = 'Domain Controllers'
                'Name'            = 'Domain Controllers'
                'NTAccount'       = 'BUILTIN\Domain Controllers'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-517' {
            return [PSCustomObject]@{
                'Description'     = 'A global group that includes all computers that host an enterprise certification authority. Cert Publishers are authorized to publish certificates for User objects in Active Directory.'
                'DisplayName'     = 'Cert Publishers'
                'SamAccountName'  = 'Cert Publishers'
                'Name'            = 'Cert Publishers'
                'NTAccount'       = 'BUILTIN\Cert Publishers'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-518' {
            return [PSCustomObject]@{
                'Description'     = "A group that exists only in the forest root domain. It's a universal group if the domain is in native mode, and it's a global group if the domain is in mixed mode. The Schema Admins group is authorized to make schema changes in Active Directory. By default, the only member of the group is the Administrator account for the forest root domain."
                'DisplayName'     = 'Schema Admins'
                'SamAccountName'  = 'Schema Admins'
                'Name'            = 'Schema Admins'
                'NTAccount'       = 'BUILTIN\Schema Admins'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-519' {
            return [PSCustomObject]@{
                'Description'     = "A group that exists only in the forest root domain. It's a universal group if the domain is in native mode, and it's a global group if the domain is in mixed mode. The Enterprise Admins group is authorized to make changes to the forest infrastructure, such as adding child domains, configuring sites, authorizing DHCP servers, and installing enterprise certification authorities. By default, the only member of Enterprise Admins is the Administrator account for the forest root domain. The group is a default member of every Domain Admins group in the forest."
                'DisplayName'     = 'Enterprise Admins'
                'SamAccountName'  = 'Enterprise Admins'
                'Name'            = 'Enterprise Admins'
                'NTAccount'       = 'BUILTIN\Enterprise Admins'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-520' {
            return [PSCustomObject]@{
                'Description'     = "A global group that's authorized to create new Group Policy Objects in Active Directory. By default, the only member of the group is Administrator. Objects that are created by members of Group Policy Creator Owners are owned by the individual user who creates them. In this way, the Group Policy Creator Owners group is unlike other administrative groups (such as Administrators and Domain Admins). Objects that are created by members of these groups are owned by the group rather than by the individual."
                'DisplayName'     = 'Group Policy Creator Owners'
                'SamAccountName'  = 'Group Policy Creator Owners'
                'Name'            = 'Group Policy Creator Owners'
                'NTAccount'       = 'BUILTIN\Group Policy Creator Owners'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-521' {
            return [PSCustomObject]@{
                'Description'     = 'A global group that includes all read-only domain controllers.'
                'DisplayName'     = 'Read-only Domain Controllers'
                'SamAccountName'  = 'Read-only Domain Controllers'
                'Name'            = 'Read-only Domain Controllers'
                'NTAccount'       = 'BUILTIN\Read-only Domain Controllers'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-522' {
            return [PSCustomObject]@{
                'Description'     = 'A global group that includes all domain controllers in the domain that can be cloned.'
                'DisplayName'     = 'Clonable Controllers'
                'SamAccountName'  = 'Clonable Controllers'
                'Name'            = 'Clonable Controllers'
                'NTAccount'       = 'BUILTIN\Clonable Controllers'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-525' {
            return [PSCustomObject]@{
                'Description'     = 'A global group that is afforded additional protections against authentication security threats.'
                'DisplayName'     = 'Protected Users'
                'SamAccountName'  = 'Protected Users'
                'Name'            = 'Protected Users'
                'NTAccount'       = 'BUILTIN\Protected Users'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-526' {
            return [PSCustomObject]@{
                'Description'     = 'This group is intended for use in scenarios where trusted external authorities are responsible for modifying this attribute. Only trusted administrators should be made a member of this group.'
                'DisplayName'     = 'Key Admins'
                'SamAccountName'  = 'Key Admins'
                'Name'            = 'Key Admins'
                'NTAccount'       = 'BUILTIN\Key Admins'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-527' {
            return [PSCustomObject]@{
                'Description'     = 'This group is intended for use in scenarios where trusted external authorities are responsible for modifying this attribute. Only trusted enterprise administrators should be made a member of this group.'
                'DisplayName'     = 'Enterprise Key Admins'
                'SamAccountName'  = 'Enterprise Key Admins'
                'Name'            = 'Enterprise Key Admins'
                'NTAccount'       = 'BUILTIN\Enterprise Key Admins'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-553' {
            return [PSCustomObject]@{
                'Description'     = 'A local domain group. By default, this group has no members. Computers that are running the Routing and Remote Access service are added to the group automatically. Members have access to certain properties of User objects, such as Read Account Restrictions, Read Logon Information, and Read Remote Access Information.'
                'DisplayName'     = 'RAS and IAS Servers'
                'SamAccountName'  = 'RAS and IAS Servers'
                'Name'            = 'RAS and IAS Servers'
                'NTAccount'       = 'BUILTIN\RAS and IAS Servers'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-571' {
            return [PSCustomObject]@{
                'Description'     = 'Members in this group can have their passwords replicated to all read-only domain controllers in the domain.'
                'DisplayName'     = 'Allowed RODC Password Replication Group'
                'SamAccountName'  = 'Allowed RODC Password Replication Group'
                'Name'            = 'Allowed RODC Password Replication Group'
                'NTAccount'       = 'BUILTIN\Allowed RODC Password Replication Group'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-572' {
            return [PSCustomObject]@{
                'Description'     = "Members in this group can't have their passwords replicated to all read-only domain controllers in the domain."
                'DisplayName'     = 'Denied RODC Password Replication Group'
                'SamAccountName'  = 'Denied RODC Password Replication Group'
                'Name'            = 'Denied RODC Password Replication Group'
                'NTAccount'       = 'BUILTIN\Denied RODC Password Replication Group'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        default { break }

    }

    if ($SID -match 'S-1-5-5-(?<Session>[^-]-[^-])') {

        return [PSCustomObject]@{
            'Description'     = "Sign-in session $($Matches.Session) (SECURITY_LOGON_IDS_RID)"
            'DisplayName'     = 'Logon Session'
            'Name'            = 'Logon Session'
            'NTAccount'       = 'BUILTIN\Logon Session'
            'SamAccountName'  = 'Logon Session'
            'SchemaClassName' = 'user'
            'SID'             = $SID
        }

    }

}


<#
COMPUTER-SPECIFIC SIDs

            AccountAdministratorSid                             28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-500
            AccountGuestSid                                     28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-501
            AccountKrbtgtSid                                    28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-502
            AccountDomainAdminsSid                              28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-512
            AccountDomainUsersSid                               28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-513
            AccountDomainGuestsSid                              28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-514
            AccountComputersSid                                 28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-515
            AccountControllersSid                               28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-516
            AccountCertAdminsSid                                28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-517
            AccountSchemaAdminsSid                              28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-518
            AccountEnterpriseAdminsSid                          28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-519
            AccountPolicyAdminsSid                              28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-520
            AccountRasAndIasServersSid                          28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-553
            WinCacheablePrincipalsGroupSid                       28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-571
            WinNonCacheablePrincipalsGroupSid                    28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-572
            WinAccountReadonlyControllersSid                     28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-521
            WinNewEnterpriseReadonlyControllersSid               28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-498

        'S-1-5-21-1340649458-2707494813-4121304102-1000'                 = @{
            'Name'        = 'WinRMRemoteWMIUsers__'
            'Description' = 'Members can access WMI resources over management protocols (such as WS-Management via the Windows Remote Management service). This applies only to WMI namespaces
            that grant access to the user.'
            'SID'         = 'S-1-5-21-1340649458-2707494813-4121304102-1000'
        }

        'S-1-5-21-1340649458-2707494813-4121304102-1001'                 = @{
            'Name'        = 'FirstAccountCreatedEndsIn1001'
            'Description' = ''
            'SID'         = 'S-1-5-21-1340649458-2707494813-4121304102-1001'
        }

        'S-1-5-21-1340649458-2707494813-4121304102-1003'                 = @{
            'Name'        = 'GuestAccount'
            'Description' = ''
            'SID'         = 'S-1-5-21-1340649458-2707494813-4121304102-1003'
        }

        'S-1-5-21-1340649458-2707494813-4121304102-500'                  = @{
            'Name'        = 'Administrator'
            'Description' = 'Built-in account for administering the computer/domain'
            'SID'         = 'S-1-5-21-1340649458-2707494813-4121304102-500'
        }

        'S-1-5-21-1340649458-2707494813-4121304102-501'                  = @{
            'Name'        = 'Guest'
            'Description' = 'Built-in account for guest access to the computer/domain'
            'SID'         = 'S-1-5-21-1340649458-2707494813-4121304102-501'
        }

        'S-1-5-21-1340649458-2707494813-4121304102-503'                  = @{
            'Name'        = 'DefaultAccount'
            'Description' = 'A user account managed by the system.'
            'SID'         = 'S-1-5-21-1340649458-2707494813-4121304102-503'
        }

        'S-1-5-21-1340649458-2707494813-4121304102-504'                  = @{
            'Name'        = 'WDAGUtilityAccount'
            'Description' = 'A user account managed and used by the system for Windows Defender Application Guard scenarios.'
            'SID'         = 'S-1-5-21-1340649458-2707494813-4121304102-504'
        }
#>


<#
            # Additional ways to find accounts
            PS C:\Users\Owner> wmic SYSACCOUNT get name,sid
                Name                           SID
                Everyone                       S-1-1-0
                LOCAL                          S-1-2-0
                CREATOR OWNER                  S-1-3-0
                CREATOR GROUP                  S-1-3-1
                CREATOR OWNER SERVER           S-1-3-2
                CREATOR GROUP SERVER           S-1-3-3
                OWNER RIGHTS                   S-1-3-4
                DIALUP                         S-1-5-1
                NETWORK                        S-1-5-2
                BATCH                          S-1-5-3
                INTERACTIVE                    S-1-5-4
                SERVICE                        S-1-5-6
                ANONYMOUS LOGON                S-1-5-7
                PROXY                          S-1-5-8
                SYSTEM                         S-1-5-18
                ENTERPRISE DOMAIN CONTROLLERS  S-1-5-9
                SELF                           S-1-5-10
                Authenticated Users            S-1-5-11
                RESTRICTED                     S-1-5-12
                TERMINAL SERVER USER           S-1-5-13
                REMOTE INTERACTIVE LOGON       S-1-5-14
                IUSR                           S-1-5-17
                LOCAL SERVICE                  S-1-5-19
                NETWORK SERVICE                S-1-5-20
                BUILTIN                        S-1-5-32

            PS C:\Users\Owner> $logonDomainSid = 'S-1-5-21-1340649458-2707494813-4121304102'
            PS C:\Users\Owner> ForEach ($SidType in [System.Security.Principal.WellKnownSidType].GetEnumNames()) {$var = [System.Security.Principal.WellKnownSidType]::$SidType; [System.Security.Principal.SecurityIdentifier]::new($var,$LogonDomainSid) |Add-Member -PassThru -NotePropertyMembers @{'WellKnownSidType' = $SidType}}

            #>
function Get-KnownSidByName {

    <#
    .SYNOPSIS
        Creates a hashtable of well-known SIDs indexed by their friendly names.
    .DESCRIPTION
        This function takes a hashtable of well-known SIDs (indexed by SID) and
        transforms it into a new hashtable where the keys are the friendly names
        of the SIDs. This makes it easier to look up SID information when you
        know the name but not the SID itself.
    .INPUTS
        System.Collections.Hashtable

        A hashtable containing SID strings as keys and information objects as values.
    .OUTPUTS
        System.Collections.Hashtable

        Returns a hashtable with friendly names as keys and SID information objects as values.
    .EXAMPLE
        $sidBySid = Get-KnownSidHashTable
        $sidByName = Get-KnownSidByName -WellKnownSIDBySID $sidBySid
        $administratorsInfo = $sidByName['Administrators']

        Creates a hashtable of well-known SIDs indexed by their friendly names and retrieves
        information about the Administrators group. This is useful when you need to look up
        SID information by name rather than by SID string.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Get-KnownSidByName')]
    [OutputType([System.Collections.Hashtable])]

    param (

        # Hashtable containing well-known SIDs as keys with their properties as values
        [hashtable]$WellKnownSIDBySID

    )

    $WellKnownSIDByName = @{}

    ForEach ($KnownSID in $WellKnownSIDBySID.Keys) {

        $Known = $WellKnownSIDBySID[$KnownSID]
        $WellKnownSIDByName[$Known.Name] = $Known

    }

    return $WellKnownSIDByName

}
function Get-KnownSidHashTable {

    <#
    .SYNOPSIS
    Returns a hashtable of known security identifiers (SIDs) with detailed information.

    .DESCRIPTION
    Returns a hashtable of known SIDs which can be used to avoid errors and delays due to unnecessary directory queries.
    Some SIDs cannot be translated using the [SecurityIdentifier]::Translate or [NTAccount]::Translate methods.
    Some SIDs cannot be retrieved using CIM or ADSI.
    Hardcoding them here allows avoiding queries that we know will fail.
    Hardcoding them also improves performance by avoiding unnecessary directory queries with predictable results.

    .EXAMPLE
    $knownSids = Get-KnownSidHashTable

    This hashtable can be used to look up information about well-known SIDs:
    $knownSids['S-1-5-18'].DisplayName  # Returns 'LocalSystem'
    $knownSids['S-1-5-32-544'].Description  # Returns description of the Administrators group

    .INPUTS
    None. This function does not accept pipeline input.

    .OUTPUTS
    System.Collections.Hashtable. Contains SIDs as keys and PSCustomObjects with SID information as values.

    .LINK
    https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/11e1608c-6169-4fbc-9c33-373fc9b224f4#Appendix_A_34

    .LINK
    https://learn.microsoft.com/en-us/windows/win32/secauthz/well-known-sids
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Get-KnownSidHashTable')]
    [OutputType([System.Collections.Hashtable])]

    param()

    return @{

        #https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-identifiers
        'S-1-0-0'                                                                                              = [PSCustomObject]@{
            'Description'     = "A group with no members. This is often used when a SID value isn't known (WellKnownSidType NullSid)"
            'DisplayName'     = 'Null SID'
            'Name'            = 'Null SID'
            'NTAccount'       = 'NULL SID AUTHORITY\NULL'
            'SamAccountName'  = 'NULL'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-0-0'
        }

        'S-1-1-0'                                                                                              = [PSCustomObject]@{
            'Description'     = "A group that includes all users; aka 'World' (WellKnownSidType WorldSid)"
            'DisplayName'     = 'Everyone'
            'Name'            = 'Everyone'
            'NTAccount'       = 'WORLD SID AUTHORITY\Everyone'
            'SamAccountName'  = 'Everyone'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-1-0'
        }

        'S-1-2-1'                                                                                              = [PSCustomObject]@{
            'Description'     = 'A group that includes users who are signed in to the physical console (WellKnownSidType WinConsoleLogonSid)'
            'DisplayName'     = 'Console Logon'
            'Name'            = 'Console Logon'
            'NTAccount'       = 'LOCAL SID AUTHORITY\CONSOLE_LOGON'
            'SamAccountName'  = 'CONSOLE_LOGON'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-2-1'
        }

        'S-1-3-0'                                                                                              = [PSCustomObject]@{
            'Description'     = 'A security identifier to be replaced by the SID of the user who creates a new object. This SID is used in inheritable access control entries (WellKnownSidType CreatorOwnerSid)'
            'DisplayName'     = 'Creator Owner ID'
            'Name'            = 'Creator Owner'
            'NTAccount'       = 'CREATOR SID AUTHORITY\CREATOR OWNER'
            'SamAccountName'  = 'CREATOR OWNER'
            'SchemaClassName' = 'user'
            'SID'             = 'S-1-3-0'
        }

        'S-1-4'                                                                                                = [PSCustomObject]@{
            'Description'     = 'A SID that represents an identifier authority which is not unique'
            'DisplayName'     = 'Non-unique Authority'
            'Name'            = 'Non-unique Authority'
            'NTAccount'       = 'Non-unique Authority'
            'SamAccountName'  = 'Non-unique Authority'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-4'
        }

        'S-1-5'                                                                                                = [PSCustomObject]@{
            'Description'     = "Identifier authority which produces SIDs that aren't universal and are meaningful only in installations of the Windows operating systems in the 'Applies to' list at the beginning of this article (WellKnownSidType NTAuthoritySid) (SID constant SECURITY_NT_AUTHORITY)"
            'DisplayName'     = 'NT Authority'
            'Name'            = 'NT AUTHORITY'
            'NTAccount'       = 'NT AUTHORITY'
            'SamAccountName'  = 'NT Authority'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-5'
        }

        'S-1-5-1'                                                                                              = [PSCustomObject]@{
            'Description'     = 'A group that includes all users who are signed in to the system via dial-up connection (WellKnownSidType DialupSid) (SID constant SECURITY_DIALUP_RID)'
            'DisplayName'     = 'Dialup'
            'Name'            = 'DIALUP'
            'NTAccount'       = 'NT AUTHORITY\DIALUP'
            'SamAccountName'  = 'DIALUP'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-5-1'
        }

        'S-1-5-2'                                                                                              = [PSCustomObject]@{
            'Description'     = "A group that includes all users who are signed in via a network connection. Access tokens for interactive users don't contain the Network SID (WellKnownSidType NetworkSid) (SID constant SECURITY_NETWORK_RID)"
            'DisplayName'     = 'Network'
            'Name'            = 'NETWORK'
            'NTAccount'       = 'NT AUTHORITY\NETWORK'
            'SamAccountName'  = 'NETWORK'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-2'
        }

        'S-1-5-3'                                                                                              = [PSCustomObject]@{
            'Description'     = 'A group that includes all users who have signed in via batch queue facility, such as task scheduler jobs (WellKnownSidType BatchSid) (SID constant SECURITY_BATCH_RID)'
            'DisplayName'     = 'Batch'
            'Name'            = 'BATCH'
            'NTAccount'       = 'NT AUTHORITY\BATCH'
            'SamAccountName'  = 'BATCH'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-3'
        }

        'S-1-5-4'                                                                                              = [PSCustomObject]@{
            'Description'     = "Users who log on for interactive operation. This is a group identifier added to the token of a process when it was logged on interactively. A group that includes all users who sign in interactively. A user can start an interactive sign-in session by opening a Remote Desktop Services connection from a remote computer, or by using a remote shell such as Telnet. In each case, the user's access token contains the Interactive SID. If the user signs in by using a Remote Desktop Services connection, the user's access token also contains the Remote Interactive Logon SID (WellKnownSidType InteractiveSid) (SID constant SECURITY_INTERACTIVE_RID)"
            'DisplayName'     = 'Interactive'
            'Name'            = 'INTERACTIVE'
            'NTAccount'       = 'NT AUTHORITY\INTERACTIVE'
            'SamAccountName'  = 'INTERACTIVE'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-4'
        }

        'S-1-5-6'                                                                                              = [PSCustomObject]@{
            'Description'     = 'A group that includes all security principals that have signed in as a service (WellKnownSidType ServiceSid) (SID constant SECURITY_SERVICE_RID)'
            'DisplayName'     = 'Service'
            'Name'            = 'SERVICE'
            'NTAccount'       = 'NT AUTHORITY\SERVICE'
            'SamAccountName'  = 'SERVICE'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-6'
        }

        'S-1-5-7'                                                                                              = [PSCustomObject]@{
            'Description'     = 'A user who has connected to the computer without supplying a user name and password. Not a member of Authenticated Users (WellKnownSidType AnonymousSid) (SID constant SECURITY_ANONYMOUS_LOGON_RID)'
            'DisplayName'     = 'Anonymous Logon'
            'Name'            = 'ANONYMOUS LOGON'
            'NTAccount'       = 'NT AUTHORITY\ANONYMOUS LOGON'
            'SamAccountName'  = 'ANONYMOUS LOGON'
            'SchemaClassName' = 'user'
            'SID'             = 'S-1-5-7'
        }

        'S-1-5-8'                                                                                              = [PSCustomObject]@{
            'Description'     = "Doesn't currently apply: this SID isn't used (WellKnownSidType ProxySid) (SID Constant SECURITY_PROXY_RID)"
            'DisplayName'     = 'Proxy'
            'Name'            = 'PROXY'
            'NTAccount'       = 'NT AUTHORITY\PROXY'
            'SamAccountName'  = 'PROXY'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-8'
        }

        'S-1-5-9'                                                                                              = [PSCustomObject]@{
            'Description'     = 'A group that includes all domain controllers in a forest of domains (WellKnownSidType EnterpriseControllersSid) (SID constant SECURITY_ENTERPRISE_CONTROLLERS_RID)'
            'DisplayName'     = 'Enterprise Domain Controllers'
            'Name'            = 'ENTERPRISE DOMAIN CONTROLLERS'
            'NTAccount'       = 'NT AUTHORITY\ENTERPRISE DOMAIN CONTROLLERS'
            'SamAccountName'  = 'ENTERPRISE DOMAIN CONTROLLERS'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-9'
        }

        'S-1-5-10'                                                                                             = [PSCustomObject]@{
            'Description'     = "A placeholder in an ACE for a user, group, or computer object in Active Directory. When you grant permissions to Self, you grant them to the security principal that's represented by the object. During an access check, the operating system replaces the SID for Self with the SID for the security principal that's represented by the object (WellKnownSidType SelfSid) (SID constant SECURITY_PRINCIPAL_SELF_RID)"
            'DisplayName'     = 'Self'
            'Name'            = 'SELF'
            'NTAccount'       = 'NT AUTHORITY\SELF'
            'SamAccountName'  = 'SELF'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-10'
        }

        'S-1-5-11'                                                                                             = [PSCustomObject]@{
            'Description'     = 'A group that includes all users and computers with identities that have been authenticated. Does not include Guest even if the Guest account has a password. This group includes authenticated security principals from any trusted domain, not only the current domain (WellKnownSidType AuthenticatedUserSid) (SID constant SECURITY_AUTHENTICATED_USER_RID)'
            'DisplayName'     = 'Authenticated Users'
            'Name'            = 'Authenticated Users'
            'NTAccount'       = 'NT AUTHORITY\Authenticated Users'
            'SamAccountName'  = 'Authenticated Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-11'
        }

        'S-1-5-12'                                                                                             = [PSCustomObject]@{
            'Description'     = "An identity that's used by a process that's running in a restricted security context. In Windows and Windows Server operating systems, a software restriction policy can assign one of three security levels to code: Unrestricted/Restricted/Disallowed. When code runs at the restricted security level, the Restricted SID is added to the user's access token (WellKnownSidType RestrictedCodeSid) (SID constant SECURITY_RESTRICTED_CODE_RID)"
            'DisplayName'     = 'Restricted Code'
            'Name'            = 'RESTRICTED'
            'NTAccount'       = 'NT AUTHORITY\RESTRICTED'
            'SamAccountName'  = 'RESTRICTED'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-12'
        }

        'S-1-5-13'                                                                                             = [PSCustomObject]@{
            'Description'     = 'A group that includes all users who sign in to a server with Remote Desktop Services enabled (WellKnownSidType TerminalServerSid) (SID constant SECURITY_TERMINAL_SERVER_RID)'
            'DisplayName'     = 'Terminal Server User'
            'Name'            = 'TERMINAL SERVER USER'
            'NTAccount'       = 'NT AUTHORITY\TERMINAL SERVER USER'
            'SamAccountName'  = 'TERMINAL SERVER USER'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-13'
        }

        'S-1-5-14'                                                                                             = [PSCustomObject]@{
            'Description'     = 'A group that includes all users who sign in to the computer by using a remote desktop connection. This group is a subset of the Interactive group. Access tokens that contain the Remote Interactive Logon SID also contain the Interactive SID (WellKnownSidType RemoteLogonIdSid)'
            'DisplayName'     = 'Remote Interactive Logon'
            'Name'            = 'REMOTE INTERACTIVE LOGON'
            'NTAccount'       = 'NT AUTHORITY\REMOTE INTERACTIVE LOGON'
            'SamAccountName'  = 'REMOTE INTERACTIVE LOGON'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-14'
        }

        'S-1-5-15'                                                                                             = [PSCustomObject]@{
            'Description'     = 'A group that includes all users from the same organization. Included only with Active Directory accounts and added only by a domain controller (WellKnownSidType ThisOrganizationSid)'
            'DisplayName'     = 'This Organization'
            'Name'            = 'THIS ORGANIZATION'
            'NTAccount'       = 'NT AUTHORITY\THIS ORGANIZATION'
            'SamAccountName'  = 'THIS ORGANIZATION'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-15'
        }

        'S-1-5-17'                                                                                             = [PSCustomObject]@{
            'Description'     = 'An account used by the default Internet Information Services user (WellKnownSidType WinIUserSid) (SID constant IIS_USRS)'
            'DisplayName'     = 'IIS_USRS'
            'Name'            = 'IUSR'
            'NTAccount'       = 'NT AUTHORITY\IUSR'
            'SamAccountName'  = 'IUSR'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-17'
        }

        'S-1-5-18'                                                                                             = [PSCustomObject]@{
            'Description'     = "An identity used locally by the operating system and by services that are configured to sign in as LocalSystem. System is a hidden member of Administrators. That is, any process running as System has the SID for the built-in Administrators group in its access token. When a process that's running locally as System accesses network resources, it does so by using the computer's domain identity. Its access token on the remote computer includes the SID for the local computer's domain account plus SIDs for security groups that the computer is a member of, such as Domain Computers and Authenticated Users. By default, the SYSTEM account is granted Full Control permissions to all files on an NTFS volume (WellKnownSidType LocalSystemSid) (SID constant SECURITY_LOCAL_SYSTEM_RID)"
            'DisplayName'     = 'LocalSystem'
            'Name'            = 'SYSTEM'
            'NTAccount'       = 'NT AUTHORITY\SYSTEM'
            'SamAccountName'  = 'SYSTEM'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-5-18'
        }

        'S-1-5-19'                                                                                             = [PSCustomObject]@{
            'Description'     = "An identity used by services that are local to the computer, have no need for extensive local access, and don't need authenticated network access. Services that run as LocalService access local resources as ordinary users, and they access network resources as anonymous users. As a result, a service that runs as LocalService has significantly less authority than a service that runs as LocalSystem locally and on the network (WellKnownSidType LocalServiceSid)"
            'DisplayName'     = 'LocalService'
            'Name'            = 'LOCAL SERVICE'
            'NTAccount'       = 'NT AUTHORITY\LOCAL SERVICE'
            'SamAccountName'  = 'LOCAL SERVICE'
            'SchemaClassName' = 'user'
            'SID'             = 'S-1-5-19'
        }

        'S-1-5-20'                                                                                             = [PSCustomObject]@{
            'Description'     = "An identity used by services that have no need for extensive local access but do need authenticated network access. Services running as NetworkService access local resources as ordinary users and access network resources by using the computer's identity. As a result, a service that runs as NetworkService has the same network access as a service that runs as LocalSystem, but it has significantly reduced local access (WellKnownSidType NetworkServiceSid)"
            'DisplayName'     = 'Network Service'
            'Name'            = 'NETWORK SERVICE'
            'NTAccount'       = 'NT AUTHORITY\NETWORK SERVICE'
            'SamAccountName'  = 'NETWORK SERVICE'
            'SchemaClassName' = 'user'
            'SID'             = 'S-1-5-20'
        }

        'S-1-5-32-544'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group used for administration of the computer/domain. Administrators have complete and unrestricted access to the computer/domain. After the initial installation of the operating system, the only member of the group is the Administrator account. When a computer joins a domain, the Domain Admins group is added to the Administrators group. When a server becomes a domain controller, the Enterprise Admins group also is added to the Administrators group (WellKnownSidType BuiltinAdministratorsSid) (SID constant DOMAIN_ALIAS_RID_ADMINS)'
            'DisplayName'     = 'Administrators'
            'Name'            = 'Administrators'
            'NTAccount'       = 'BUILTIN\Administrators'
            'SamAccountName'  = 'Administrators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-544'
        }

        'S-1-5-32-545'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group that represents all users in the domain. Users are prevented from making accidental or intentional system-wide changes and can run most applications. After the initial installation of the operating system, the only member is the Authenticated Users group (WellKnownSidType BuiltinUsersSid) (SID constant DOMAIN_ALIAS_RID_USERS)'
            'DisplayName'     = 'Users'
            'Name'            = 'Users'
            'NTAccount'       = 'BUILTIN\Users'
            'SamAccountName'  = 'Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-545'
        }

        'S-1-5-32-546'                                                                                         = [PSCustomObject]@{
            'Description'     = "A built-in local group that represents guests of the domain. Guests have the same access as members of the Users group by default, except for the Guest account which is further restricted. By default, the only member is the Guest account. The Guests group allows occasional or one-time users to sign in with limited privileges to a computer's built-in Guest account (WellKnownSidType BuiltinGuestsSid) (SID constant DOMAIN_ALIAS_RID_GUESTS)"
            'DisplayName'     = 'Guests'
            'Name'            = 'Guests'
            'NTAccount'       = 'BUILTIN\Guests'
            'SamAccountName'  = 'Guests'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-546'
        }

        'S-1-5-32-547'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group used to represent a user or set of users who expect to treat a system as if it were their personal computer rather than as a workstation for multiple users. By default, the group has no members. Power users can create local users and groups; modify and delete accounts that they have created; and remove users from the Power Users, Users, and Guests groups. Power users also can install programs; create, manage, and delete local printers; and create and delete file shares. Power Users are included for backwards compatibility and possess limited administrative powers (WellKnownSidType BuiltinPowerUsersSid) (SID constant DOMAIN_ALIAS_RID_POWER_USERS)'
            'DisplayName'     = 'Power Users'
            'Name'            = 'Power Users'
            'NTAccount'       = 'BUILTIN\Power Users'
            'SamAccountName'  = 'Power Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-547'
        }

        'S-1-5-32-548'                                                                                         = [PSCustomObject]@{
            'Description'     = "A built-in local group that exists only on domain controllers. This group permits control over nonadministrator accounts. By default, the group has no members. By default, Account Operators have permission to create, modify, and delete accounts for users, groups, and computers in all containers and organizational units of Active Directory except the Builtin container and the Domain Controllers OU. Account Operators don't have permission to modify the Administrators and Domain Admins groups, nor do they have permission to modify the accounts for members of those groups (WellKnownSidType BuiltinAccountOperatorsSid) (SID constant DOMAIN_ALIAS_RID_ACCOUNT_OPS)"
            'DisplayName'     = 'Account Operators'
            'Name'            = 'Account Operators'
            'NTAccount'       = 'BUILTIN\DOMAIN_ALIAS_RID_ACCOUNT_OPS'
            'SamAccountName'  = 'DOMAIN_ALIAS_RID_ACCOUNT_OPS'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-548'
        }

        'S-1-5-32-549'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group that exists only on domain controllers. This group performs system administrative functions, not including security functions. It establishes network shares, controls printers, unlocks workstations, and performs other operations. By default, the group has no members. Server Operators can sign in to a server interactively; create and delete network shares; start and stop services; back up and restore files; format the hard disk of the computer; and shut down the computer (WellKnownSidType BuiltinSystemOperatorsSid) (SID constant DOMAIN_ALIAS_RID_SYSTEM_OPS)'
            'DisplayName'     = 'Server Operators'
            'Name'            = 'Server Operators'
            'NTAccount'       = 'BUILTIN\Server Operators'
            'SamAccountName'  = 'Server Operators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-549'
        }

        'S-1-5-32-550'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group that exists only on domain controllers. This group controls printers and print queues. By default, the only member is the Domain Users group. Print Operators can manage printers and document queues (WellKnownSidType BuiltinPrintOperatorsSid) (SID constant DOMAIN_ALIAS_RID_PRINT_OPS)'
            'DisplayName'     = 'DOMAIN_ALIAS_RID_PRINT_OPS'
            'Name'            = 'Print Operators'
            'NTAccount'       = 'BUILTIN\Print Operators'
            'SamAccountName'  = 'Print Operators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-550'
        }

        'S-1-5-32-551'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group used for controlling assignment of file backup-and-restore privileges. Backup Operators can override security restrictions for the sole purpose of backing up or restoring files. By default, the group has no members. Backup Operators can back up and restore all files on a computer, regardless of the permissions that protect those files. Backup Operators also can sign in to the computer and shut it down (WellKnownSidType BuiltinBackupOperatorsSid) (SID constant DOMAIN_ALIAS_RID_BACKUP_OPS)'
            'DisplayName'     = 'Backup Operators'
            'Name'            = 'Backup Operators'
            'NTAccount'       = 'BUILTIN\Backup Operators'
            'SamAccountName'  = 'Backup Operators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-551'
        }

        'S-1-5-32-552'                                                                                         = [PSCustomObject]@{
            'Description'     = "A built-in local group responsible for copying security databases from the primary domain controller to the backup domain controllers by the File Replication service. By default, the group has no members. Don't add users to this group. These accounts are used only by the system (WellKnownSidType BuiltinReplicatorSid) (SID constant DOMAIN_ALIAS_RID_REPLICATOR)"
            'DisplayName'     = 'Replicators'
            'Name'            = 'Replicators'
            'NTAccount'       = 'BUILTIN\Replicator'
            'SamAccountName'  = 'Replicator'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-552'
        }

        'S-1-5-32-554'                                                                                         = [PSCustomObject]@{
            'Description'     = 'An alias. A local group added by Windows 2000 server and used for backward compatibility. Allows read access on all users and groups in the domain (WellKnownSidType BuiltinPreWindows2000CompatibleAccessSid) (SID constant DOMAIN_ALIAS_RID_PREW2KCOMPACCESS)'
            'DisplayName'     = 'Pre-Windows 2000 Compatible Access'
            'Name'            = 'Pre-Windows 2000 Compatible Access'
            'NTAccount'       = 'BUILTIN\Pre-Windows 2000 Compatible Access'
            'SamAccountName'  = 'Pre-Windows 2000 Compatible Access'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-554'
        }

        'S-1-5-32-555'                                                                                         = [PSCustomObject]@{
            'Description'     = 'An alias. A local group that represents all remote desktop users. Members are granted the right to logon remotely (WellKnownSid BuiltinRemoteDesktopUsersSid) (SID constant DOMAIN_ALIAS_RID_REMOTE_DESKTOP_USERS)'
            'DisplayName'     = 'Remote Desktop Users'
            'Name'            = 'Remote Desktop Users'
            'NTAccount'       = 'BUILTIN\Remote Desktop Users'
            'SamAccountName'  = 'Remote Desktop Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-555'
        }

        'S-1-5-32-556'                                                                                         = [PSCustomObject]@{
            'Description'     = 'An alias. A local group that represents the network configuration. Members can have some administrative privileges to manage configuration of networking features (WellKnownSidType BuiltinNetworkConfigurationOperatorsSid) (SID constant DOMAIN_ALIAS_RID_NETWORK_CONFIGURATION_OPS)'
            'DisplayName'     = 'Network Configuration Operators'
            'Name'            = 'Network Configuration Operators'
            'NTAccount'       = 'BUILTIN\Network Configuration Operators'
            'SamAccountName'  = 'Network Configuration Operators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-556'
        }

        'S-1-5-32-557'                                                                                         = [PSCustomObject]@{
            'Description'     = 'An alias. A local group that represents any forest trust users. Members can create incoming, one-way trusts to this forest (WellKnownSidType BuiltinIncomingForestTrustBuildersSid) (SID constant DOMAIN_ALIAS_RID_INCOMING_FOREST_TRUST_BUILDERS)'
            'DisplayName'     = 'Incoming Forest Trust Builders'
            'Name'            = 'Incoming Forest Trust Builders'
            'NTAccount'       = 'BUILTIN\Incoming Forest Trust Builders'
            'SchemaClassName' = 'group'
            'SamAccountName'  = 'Incoming Forest Trust Builders'
            'SID'             = 'S-1-5-32-557'
        }

        'S-1-5-32-558'                                                                                         = [PSCustomObject]@{
            'Description'     = 'An alias. A local group. Members can access performance counter data locally and remotely (WellKnownSidType BuiltinPerformanceMonitoringUsersSid) (SID constant DOMAIN_ALIAS_RID_MONITORING_USERS)'
            'DisplayName'     = 'Performance Monitor Users'
            'Name'            = 'Performance Monitor Users'
            'NTAccount'       = 'BUILTIN\Performance Monitor Users'
            'SamAccountName'  = 'Performance Monitor Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-558'
        }

        'S-1-5-32-559'                                                                                         = [PSCustomObject]@{
            'Description'     = 'An alias. A local group responsible for logging users. Members may schedule logging of performance counters, enable trace providers, and collect event traces both locally and via remote access to this computer (WellKnownSidType BuiltinPerformanceLoggingUsersSid) (SID constant DOMAIN_ALIAS_RID_LOGGING_USERS)'
            'DisplayName'     = 'Performance Log Users'
            'Name'            = 'Performance Log Users'
            'NTAccount'       = 'BUILTIN\Performance Log Users'
            'SamAccountName'  = 'Performance Log Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-559'
        }

        'S-1-5-32-560'                                                                                         = [PSCustomObject]@{
            'Description'     = 'An alias. A local group that represents all authorized access. Members have access to the computed tokenGroupsGlobalAndUniversal attribute on User objects (WellKnownSidType BuiltinAuthorizationAccessSid) (SID constant DOMAIN_ALIAS_RID_AUTHORIZATIONACCESS)'
            'DisplayName'     = 'Windows Authorization Access Group'
            'Name'            = 'Windows Authorization Access Group'
            'NTAccount'       = 'BUILTIN\Windows Authorization Access Group'
            'SamAccountName'  = 'Windows Authorization Access Group'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-560'
        }

        'S-1-5-32-561'                                                                                         = [PSCustomObject]@{
            'Description'     = 'An alias. A local group that exists only on systems running server operating systems that allow for terminal services and remote access. When Windows Server 2003 Service Pack 1 is installed, a new local group is created (WellKnownSidType WinBuiltinTerminalServerLicenseServersSid) (SID constant DOMAIN_ALIAS_RID_TS_LICENSE_SERVERS)'
            'DisplayName'     = 'Terminal Server License Servers'
            'Name'            = 'Terminal Server License Servers'
            'NTAccount'       = 'BUILTIN\Terminal Server License Servers'
            'SamAccountName'  = 'Terminal Server License Servers'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-561'
        }

        'S-1-5-32-562'                                                                                         = [PSCustomObject]@{
            'Description'     = 'An alias. A local group that represents users who can use Distributed Component Object Model (DCOM). Used by COM to provide computer-wide access controls that govern access to all call, activation, or launch requests on the computer.Members are allowed to launch, activate and use Distributed COM objects on this machine (WellKnownSidType WinBuiltinDCOMUsersSid) (SID constant DOMAIN_ALIAS_RID_DCOM_USERS)'
            'DisplayName'     = 'Distributed COM Users'
            'Name'            = 'Distributed COM Users'
            'NTAccount'       = 'BUILTIN\Distributed COM Users'
            'SamAccountName'  = 'Distributed COM Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-562'
        }

        'S-1-5-32-568'                                                                                         = [PSCustomObject]@{
            'Description'     = 'An alias. A built-in local group used by Internet Information Services that represents Internet users (WellKnownSidType WinBuiltinIUsersSid) (SID constant DOMAIN_ALIAS_RID_IUSERS)'
            'DisplayName'     = 'IIS_IUSRS'
            'Name'            = 'IIS_IUSRS'
            'NTAccount'       = 'BUILTIN\IIS_IUSRS'
            'SamAccountName'  = 'IIS_IUSRS'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-568'
        }

        'S-1-5-32-569'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group that represents access to cryptography operators. Members are authorized to perform cryptographic operations (WellKnownSidType WinBuiltinCryptoOperatorsSid) (SID constant DOMAIN_ALIAS_RID_CRYPTO_OPERATORS)'
            'DisplayName'     = 'Cryptographic Operators'
            'Name'            = 'Cryptographic Operators'
            'NTAccount'       = 'BUILTIN\Cryptographic Operators'
            'SamAccountName'  = 'Cryptographic Operators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-569'
        }

        'S-1-5-32-573'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group that represents event log readers. Members can read event logs from a local computer (WellKnownSidType WinBuiltinEventLogReadersGroup) (SID constant DOMAIN_ALIAS_RID_EVENT_LOG_READERS_GROUP)'
            'DisplayName'     = 'Event Log Readers'
            'Name'            = 'Event Log Readers'
            'SID'             = 'S-1-5-32-573'
            'NTAccount'       = 'BUILTIN\Event Log Readers'
            'SamAccountName'  = 'Event Log Readers'
            'SchemaClassName' = 'group'
        }

        'S-1-5-32-574'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group. Members are allowed to connect to Certification Authorities in the enterprise using Distributed Component Object Model (DCOM) (WellKnownSidType WinBuiltinCertSvcDComAccessGroup) (SID constant DOMAIN_ALIAS_RID_CERTSVC_DCOM_ACCESS_GROUP)'
            'DisplayName'     = 'Certificate Service DCOM Access'
            'Name'            = 'Certificate Service DCOM Access'
            'NTAccount'       = 'BUILTIN\Certificate Service DCOM Access'
            'SamAccountName'  = 'Certificate Service DCOM Access'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-574'
        }

        'S-1-5-32-575'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group. Servers in this group enable users of RemoteApp programs and personal virtual desktops access to these resources. In internet-facing deployments, these servers are typically deployed in an edge network. This group needs to be populated on servers that are running RD Connection Broker. RD Gateway servers and RD Web Access servers used in the deployment need to be in this group (SID constant DOMAIN_ALIAS_RID_RDS_REMOTE_ACCESS_SERVERS)'
            'DisplayName'     = 'RDS Remote Access Servers'
            'Name'            = 'RDS Remote Access Servers'
            'NTAccount'       = 'BUILTIN\RDS Remote Access Servers'
            'SamAccountName'  = 'RDS Remote Access Servers'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-575'
        }

        'S-1-5-32-576'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group. Servers in this group run virtual machines and host sessions where users RemoteApp programs and personal virtual desktops run. This group needs to be populated on servers running RD Connection Broker. RD Session Host servers and RD Virtualization Host servers used in the deployment need to be in this group (SID constant DOMAIN_ALIAS_RID_RDS_ENDPOINT_SERVERS)'
            'DisplayName'     = 'RDS Endpoint Servers'
            'Name'            = 'RDS Endpoint Servers'
            'NTAccount'       = 'BUILTIN\RDS Endpoint Servers'
            'SamAccountName'  = 'RDS Endpoint Servers'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-576'
        }

        'S-1-5-32-577'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group. Servers in this group can perform routine administrative actions on servers running Remote Desktop Services. This group needs to be populated on all servers in a Remote Desktop Services deployment. The servers running the RDS Central Management service must be included in this group (SID constant DOMAIN_ALIAS_RID_RDS_MANAGEMENT_SERVERS)'
            'DisplayName'     = 'RDS Management Servers'
            'Name'            = 'RDS Management Servers'
            'NTAccount'       = 'BUILTIN\RDS Management Servers'
            'SamAccountName'  = 'RDS Management Servers'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-577'
        }

        'S-1-5-32-578'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group. Members have complete and unrestricted access to all features of Hyper-V (SID constant DOMAIN_ALIAS_RID_HYPER_V_ADMINS)'
            'DisplayName'     = 'Hyper-V Administrators'
            'Name'            = 'Hyper-V Administrators'
            'NTAccount'       = 'BUILTIN\Hyper-V Administrators'
            'SamAccountName'  = 'Hyper-V Administrators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-578'
        }

        'S-1-5-32-579'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group. Members can remotely query authorization attributes and permissions for resources on this computer (SID constant DOMAIN_ALIAS_RID_ACCESS_CONTROL_ASSISTANCE_OPS)'
            'DisplayName'     = 'Access Control Assistance Operators'
            'Name'            = 'Access Control Assistance Operators'
            'NTAccount'       = 'BUILTIN\Access Control Assistance Operators'
            'SamAccountName'  = 'Access Control Assistance Operators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-579'
        }

        'S-1-5-32-580'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group. Members can access Windows Management Instrumentation (WMI) resources over management protocols (such as WS-Management via the Windows Remote Management service). This applies only to WMI namespaces that grant access to the user (SID constant DOMAIN_ALIAS_RID_REMOTE_MANAGEMENT_USERS)'
            'DisplayName'     = 'Remote Management Users'
            'Name'            = 'Remote Management Users'
            'NTAccount'       = 'BUILTIN\Remote Management Users'
            'SamAccountName'  = 'Remote Management Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-580'
        }

        'S-1-5-64-10'                                                                                          = [PSCustomObject]@{
            'Description'     = "A SID that's used when the NTLM authentication package authenticates the client (WellKnownSidType NtlmAuthenticationSid)"
            'DisplayName'     = 'NTLM Authentication'
            'Name'            = 'NTLM Authentication'
            'NTAccount'       = 'NT AUTHORITY\NTLM Authentication'
            'SamAccountName'  = 'NTLM Authentication'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-64-10'
        }

        'S-1-5-64-14'                                                                                          = [PSCustomObject]@{
            'Description'     = "A SID that's used when the SChannel authentication package authenticates the client (WellKnownSidType SChannelAuthenticationSid)"
            'DisplayName'     = 'SChannel Authentication'
            'Name'            = 'SChannel Authentication'
            'NTAccount'       = 'NT AUTHORITY\SChannel Authentication'
            'SamAccountName'  = 'SChannel Authentication'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-64-14'
        }

        'S-1-5-64-21'                                                                                          = [PSCustomObject]@{
            'Description'     = "A SID that's used when the Digest authentication package authenticates the client (WellKnownSidType DigestAuthenticationSid)"
            'DisplayName'     = 'Digest Authentication'
            'Name'            = 'Digest Authentication'
            'NTAccount'       = 'NT AUTHORITY\Digest Authentication'
            'SamAccountName'  = 'Digest Authentication'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-64-21'
        }

        'S-1-5-80'                                                                                             = [PSCustomObject]@{
            'Description'     = "A SID that's used as an NT Service account prefix"
            'DisplayName'     = 'NT Service'
            'Name'            = 'NT Service'
            'NTAccount'       = 'NT AUTHORITY\NT Service'
            'SamAccountName'  = 'NT Service'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-5-80'
        }

        'S-1-5-80-0'                                                                                           = [PSCustomObject]@{
            'Description'     = 'A group that includes all service processes that are configured on the system. Membership is controlled by the operating system. This SID was introduced in Windows Server 2008 R2'
            'DisplayName'     = 'All Services'
            'Name'            = 'All Services'
            'NTAccount'       = 'NT SERVICE\ALL SERVICES'
            'SamAccountName'  = 'ALL SERVICES'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-80-0'
        }

        'S-1-5-83-0'                                                                                           = [PSCustomObject]@{
            'Description'     = 'A built-in group. The group is created when the Hyper-V role is installed. Membership in the group is maintained by the Hyper-V Management Service [VMMS]. This group requires the Create Symbolic Links right [SeCreateSymbolicLinkPrivilege] and the Log on as a Service right [SeServiceLogonRight]'
            'DisplayName'     = 'Virtual Machines'
            'Name'            = 'Virtual Machines'
            'NTAccount'       = 'NT VIRTUAL MACHINE\Virtual Machines'
            'SamAccountName'  = 'Virtual Machines'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-83-0'
        }

        'S-1-5-113'                                                                                            = [PSCustomObject]@{
            'Description'     = "You can use this SID when you're restricting network sign-in to local accounts instead of 'administrator' or equivalent. This SID can be effective in blocking network sign-in for local users and groups by account type regardless of what they're named (SID constant LOCAL_ACCOUNT)"
            'DisplayName'     = 'Local account'
            'Name'            = 'Local account'
            'NTAccount'       = 'NT AUTHORITY\Local account'
            'SamAccountName'  = 'Local account'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-113'
        }

        'S-1-5-114'                                                                                            = [PSCustomObject]@{
            'Description'     = "You can use this SID when you're restricting network sign-in to local accounts instead of 'administrator' or equivalent. This SID can be effective in blocking network sign-in for local users and groups by account type regardless of what they're named (SID constant LOCAL_ACCOUNT_AND_MEMBER_OF_ADMINISTRATORS_GROUP)"
            'DisplayName'     = 'Local account and member of Administrators group'
            'Name'            = 'Local account and member of Administrators group'
            'NTAccount'       = 'NT AUTHORITY\Local account and member of Administrators group'
            'SamAccountName'  = 'Local account and member of Administrators group'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-114'
        }

        <#
        https://devblogs.microsoft.com/oldnewthing/20220502-00/?p=106550
        SIDs of the form S-1-15-2-xxx are app container SIDs.
        These SIDs are present in the token of apps running in an app container, and they encode the app container identity.
        According to the rules for Mandatory Integrity Control, objects default to allowing write access only to medium integrity level (IL) or higher.
        App containers run at low IL, so they by default don’t have write access to such objects.
            An object can add access control entries (ACEs) to its access control list (Get-Acl) to grant access to low IL.
            There are a few security identifiers (SIDs) you may see when an object extends access to low IL.
            #>

        'S-1-15-2-1'                                                                                           = [PSCustomObject]@{
            'Description'     = 'All applications running in an app package context have this app container SID (WellKnownSidType WinBuiltinAnyPackageSid) (SID constant SECURITY_BUILTIN_PACKAGE_ANY_PACKAGE)'
            'DisplayName'     = 'All Application Packages'
            'Name'            = 'ALL APPLICATION PACKAGES'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\ALL APPLICATION PACKAGES'
            'SamAccountName'  = 'ALL APPLICATION PACKAGES'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-2-1'
        }

        'S-1-15-2-2'                                                                                           = [PSCustomObject]@{
            'Description'     = 'Some applications running in an app package context may have this app container SID (SID constant SECURITY_BUILTIN_PACKAGE_ANY_RESTRICTED_PACKAGE)'
            'DisplayName'     = 'All Restricted Application Packages'
            'Name'            = 'ALL RESTRICTED APPLICATION PACKAGES'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\ALL RESTRICTED APPLICATION PACKAGES'
            'SamAccountName'  = 'ALL RESTRICTED APPLICATION PACKAGES'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-2-2'
        }

        <#
        # https://devblogs.microsoft.com/oldnewthing/20220503-00/?p=106557
        SIDs of the form S-1-15-3-xxx are app capability SIDs.
        These SIDs are present in the token of apps running in an app container, and they encode the app capabilities possessed by the app.
        The rules for Mandatory Integrity Control say that objects default to allowing write access only to medium integrity level (IL) or higher.
        Granting access to these app capability SIDs permit access from apps running at low IL, provided they possess the matching capability.

        Autogenerated
        S-1-15-3-x1-x2-x3-x4    device capability
        S-1-15-3-1024-x1-x2-x3-x4-x5-x6-x7-x8    app capability

        You can sort of see how these assignments evolved.
        At first, the capability RIDs were assigned by an assigned numbers authority, so anybody who wanted a capability had to apply for a number.
        After about a dozen of these, the assigned numbers team (probably just one person) realized that this had the potential to become a real bottleneck, so they switched to an autogeneration mechanism, so that people who needed a capability SID could just generate their own.
        For device capabilities, the four 32-bit decimal digits represent the 16 bytes of the device interface GUID.
        Let’s decode this one: S-1-15-3-787448254-1207972858-3558633622-1059886964.

        787448254    1207972858    3558633622    1059886964
        0x2eef81be    0x480033fa    0xd41c7096    0x3f2c9774
        be    81    ef    2e    fa    33    00    48    96    70    1c    d4    74    97    2c    3f
        2eef81be    33fa    4800    96    70    1c    d4    74    97    2c    3f
        {2eef81be-    33fa-    4800-    96    70-    1c    d4    74    97    2c    3f}

        And we recognize {2eef81be-33fa-4800-9670-1cd474972c3f} as DEVINTERFACE_AUDIO_CAPTURE, so this is the microphone device capability.
        For app capabilities, the eight 32-bit decimal numbers represent the 32 bytes of the SHA256 hash of the capability name.
        You can programmatically generate these app capability SIDs by calling Derive­Capability­Sids­From­Name.
        #>

        'S-1-15-3-1'                                                                                           = [PSCustomObject]@{
            'Description'     = 'internetClient containerized app capability SID (WellKnownSidType WinCapabilityInternetClientSid)'
            'DisplayName'     = 'Your Internet connection'
            'Name'            = 'Your Internet connection'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your Internet connection'
            'SamAccountName'  = 'Your Internet connection'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-1'
        }

        'S-1-15-3-2'                                                                                           = [PSCustomObject]@{
            'Description'     = 'internetClientServer containerized app capability SID (WellKnownSidType WinCapabilityInternetClientServerSid)'
            'DisplayName'     = 'Your Internet connection, including incoming connections from the Internet'
            'Name'            = 'Your Internet connection, including incoming connections from the Internet'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your Internet connection, including incoming connections from the Internet'
            'SamAccountName'  = 'Your Internet connection, including incoming connections from the Internet'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-2'
        }

        'S-1-15-3-3'                                                                                           = [PSCustomObject]@{
            'Description'     = 'privateNetworkClientServer containerized app capability SID (WellKnownSidType WinCapabilityPrivateNetworkClientServerSid)'
            'DisplayName'     = 'Your home or work networks'
            'Name'            = 'Your home or work networks'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your home or work networks'
            'SamAccountName'  = 'Your home or work networks'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-3'
        }

        'S-1-15-3-4'                                                                                           = [PSCustomObject]@{
            'Description'     = 'picturesLibrary containerized app capability SID (WellKnownSidType WinCapabilityPicturesLibrarySid)'
            'DisplayName'     = 'Your pictures library'
            'Name'            = 'Your pictures library'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your pictures library'
            'SamAccountName'  = 'Your pictures library'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-4'
        }

        'S-1-15-3-5'                                                                                           = [PSCustomObject]@{
            'Description'     = 'videosLibrary containerized app capability SID (WellKnownSidType WinCapabilityVideosLibrarySid)'
            'DisplayName'     = 'Your videos library'
            'Name'            = 'Your videos library'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your videos library'
            'SamAccountName'  = 'Your videos library'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-5'
        }

        'S-1-15-3-6'                                                                                           = [PSCustomObject]@{
            'Description'     = 'musicLibrary containerized app capability SID (WellKnownSidType WinCapabilityMusicLibrarySid)'
            'DisplayName'     = 'Your music library'
            'Name'            = 'Your music library'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your music library'
            'SamAccountName'  = 'Your music library'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-6'
        }

        'S-1-15-3-7'                                                                                           = [PSCustomObject]@{
            'Description'     = 'documentsLibrary containerized app capability SID (WellKnownSidType WinCapabilityDocumentsLibrarySid)'
            'DisplayName'     = 'Your documents library'
            'Name'            = 'Your documents library'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your documents library'
            'SamAccountName'  = 'Your documents library'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-7'
        }

        'S-1-15-3-8'                                                                                           = [PSCustomObject]@{
            'Description'     = 'enterpriseAuthentication containerized app capability SID (WellKnownSidType WinCapabilityEnterpriseAuthenticationSid)'
            'DisplayName'     = 'Your Windows credentials'
            'Name'            = 'Your Windows credentials'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your Windows credentials'
            'SamAccountName'  = 'Your Windows credentials'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-8'
        }

        'S-1-15-3-9'                                                                                           = [PSCustomObject]@{
            'Description'     = 'sharedUserCertificates containerized app capability SID (WellKnownSidType WinCapabilitySharedUserCertificatesSid)'
            'DisplayName'     = 'Software and hardware certificates or a smart card'
            'Name'            = 'Software and hardware certificates or a smart card'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Software and hardware certificates or a smart card'
            'SamAccountName'  = 'Software and hardware certificates or a smart card'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-9'
        }

        'S-1-15-3-10'                                                                                          = [PSCustomObject]@{
            'Description'     = 'removableStorage containerized app capability SID'
            'DisplayName'     = 'Removable storage'
            'Name'            = 'Removable storage'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Removable storage'
            'SamAccountName'  = 'Removable storage'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-10'
        }

        'S-1-15-3-11'                                                                                          = [PSCustomObject]@{
            'Description'     = 'appointments containerized app capability SID'
            'DisplayName'     = 'Your Appointments'
            'Name'            = 'Your Appointments'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your Appointments'
            'SamAccountName'  = 'Your Appointments'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-11'
        }

        'S-1-15-3-12'                                                                                          = [PSCustomObject]@{
            'Description'     = 'contacts containerized app capability SID'
            'DisplayName'     = 'Your Contacts'
            'Name'            = 'Your Contacts'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your Contacts'
            'SamAccountName'  = 'Your Contacts'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-12'
        }

        'S-1-15-3-4096'                                                                                        = [PSCustomObject]@{
            'Description'     = 'internetExplorer containerized app capability SID'
            'DisplayName'     = 'Internet Explorer'
            'Name'            = 'internetExplorer'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\internetExplorer'
            'SamAccountName'  = 'internetExplorer'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-4096'
        }

        <#Other known SIDs#>

        'S-1-5-80-242729624-280608522-2219052887-3187409060-2225943459'                                        = [PSCustomObject]@{
            'Description'     = 'Windows Cryptographic service account'
            'DisplayName'     = 'CryptSvc'
            'Name'            = 'CryptSvc'
            'NTAccount'       = 'NT SERVICE\CryptSvc'
            'SamAccountName'  = 'CryptSvc'
            'SchemaClassName' = 'service'
            'SID'             = 'S-1-5-80-242729624-280608522-2219052887-3187409060-2225943459'
        }

        'S-1-5-80-3139157870-2983391045-3678747466-658725712-1809340420'                                       = [PSCustomObject]@{
            'Description'     = 'Windows Diagnostics service account'
            'DisplayName'     = 'WdiServiceHost'
            'Name'            = 'WdiServiceHost'
            'NTAccount'       = 'NT SERVICE\WdiServiceHost'
            'SamAccountName'  = 'WdiServiceHost'
            'SchemaClassName' = 'service'
            'SID'             = 'S-1-5-80-3139157870-2983391045-3678747466-658725712-1809340420'
        }

        'S-1-5-80-880578595-1860270145-482643319-2788375705-1540778122'                                        = [PSCustomObject]@{
            'Description'     = 'Windows Event Log service account'
            'DisplayName'     = 'EventLog'
            'Name'            = 'EventLog'
            'NTAccount'       = 'NT SERVICE\EventLog'
            'SamAccountName'  = 'EventLog'
            'SchemaClassName' = 'service'
            'SID'             = 'S-1-5-80-880578595-1860270145-482643319-2788375705-1540778122'
        }

        'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'                                       = [PSCustomObject]@{
            'Description'     = 'Windows Modules Installer service account used to install, modify, and remove Windows updates and optional components. Most operating system files are owned by TrustedInstaller'
            'DisplayName'     = 'TrustedInstaller'
            'Name'            = 'TrustedInstaller'
            'NTAccount'       = 'NT SERVICE\TrustedInstaller'
            'SamAccountName'  = 'TrustedInstaller'
            'SchemaClassName' = 'service'
            'SID'             = 'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'
        }

        'S-1-5-32-553'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A local group that represents RAS and IAS servers. This group permits access to various attributes of user objects (SID constant DOMAIN_ALIAS_RID_RAS_SERVERS)'
            'DisplayName'     = 'RAS and IAS Servers'
            'Name'            = 'RAS and IAS Servers'
            'NTAccount'       = 'BUILTIN\RAS and IAS Servers'
            'SamAccountName'  = 'RAS and IAS Servers'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-553'
        }

        'S-1-5-32-571'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A local group that represents principals that can be cached (SID constant DOMAIN_ALIAS_RID_CACHEABLE_PRINCIPALS_GROUP)'
            'DisplayName'     = 'Allowed RODC Password Replication Group'
            'Name'            = 'Allowed RODC Password Replication Group'
            'NTAccount'       = 'BUILTIN\Allowed RODC Password Replication Group'
            'SamAccountName'  = 'Allowed RODC Password Replication Group'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-571'
        }

        'S-1-5-32-572'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A local group that represents principals that cannot be cached (SID constant DOMAIN_ALIAS_RID_NON_CACHEABLE_PRINCIPALS_GROUP)'
            'DisplayName'     = 'Denied RODC Password Replication Group'
            'Name'            = 'Denied RODC Password Replication Group'
            'NTAccount'       = 'BUILTIN\Denied RODC Password Replication Group'
            'SamAccountName'  = 'Denied RODC Password Replication Group'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-572'
        }

        'S-1-5-32-581'                                                                                         = [PSCustomObject]@{
            'Description'     = 'Members are managed by the system. A local group that represents the default account (SID constant DOMAIN_ALIAS_RID_DEFAULT_ACCOUNT)'
            'DisplayName'     = 'System Managed Accounts'
            'Name'            = 'System Managed Accounts'
            'NTAccount'       = 'BUILTIN\System Managed Accounts'
            'SamAccountName'  = 'System Managed Accounts'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-581'
        }

        'S-1-5-32-582'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A local group that represents storage replica admins (SID constant DOMAIN_ALIAS_RID_STORAGE_REPLICA_ADMINS)'
            'DisplayName'     = 'Domain Alias RID Storage Replica Admins'
            'Name'            = 'Domain Alias RID Storage Replica Admins'
            'NTAccount'       = 'BUILTIN\Domain Alias RID Storage Replica Admins'
            'SamAccountName'  = 'Domain Alias RID Storage Replica Admins'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-582'
        }

        'S-1-5-32-583'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A local group that represents can make settings expected for Device Owners (SID constant DOMAIN_ALIAS_RID_DEVICE_OWNERS)'
            'DisplayName'     = 'Device Owners'
            'Name'            = 'Device Owners'
            'NTAccount'       = 'BUILTIN\Device Owners'
            'SamAccountName'  = 'Device Owners'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-583'
        }

        # Additional SIDs found on local machine via discovery
        'S-1-5-32'                                                                                             = [PSCustomObject]@{
            'Description'     = 'The built-in system domain (WellKnownSidType BuiltinDomainSid) (SID constant SECURITY_BUILTIN_DOMAIN_RID)'
            'DisplayName'     = 'Built-in'
            'Name'            = 'BUILTIN'
            'NTAccount'       = 'NT AUTHORITY\BUILTIN'
            'SamAccountName'  = 'BUILTIN'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-5-32'
        }

        'S-1-5-80-1594061079-2000966165-462148798-751814865-2644087104'                                        = [PSCustomObject]@{
            'Description'     = 'Used by the Language Experience Service to provide support for deploying and configuring localized Windows resources'
            'DisplayName'     = 'LxpSvc'
            'Name'            = 'LxpSvc'
            'NTAccount'       = 'NT SERVICE\LxpSvc'
            'SamAccountName'  = 'LxpSvc'
            'SchemaClassName' = 'service'
            'SID'             = 'S-1-5-80-1594061079-2000966165-462148798-751814865-2644087104'
        }

        'S-1-5-80-4230913304-2206818457-801678004-120036174-1892434133'                                        = [PSCustomObject]@{
            'Description'     = 'Used by the TAPI server to provide the central repository of telephony on data on a computer'
            'DisplayName'     = 'TapiSrv'
            'Name'            = 'TapiSrv'
            'NTAccount'       = 'NT SERVICE\TapiSrv'
            'SamAccountName'  = 'TapiSrv'
            'SchemaClassName' = 'service'
            'SID'             = 'S-1-5-80-4230913304-2206818457-801678004-120036174-1892434133'
        }

        'S-1-5-84-0-0-0-0-0'                                                                                   = [PSCustomObject]@{
            #https://learn.microsoft.com/en-us/windows-hardware/drivers/wdf/controlling-device-access
            'Description'     = 'A security identifier that identifies UMDF drivers'
            'DisplayName'     = 'User-Mode Driver Framework (UMDF) drivers'
            'Name'            = 'SDDL_USER_MODE_DRIVERS'
            'NTAccount'       = 'NT SERVICE\SDDL_USER_MODE_DRIVERS'
            'SamAccountName'  = 'SDDL_USER_MODE_DRIVERS'
            'SchemaClassName' = 'service'
            'SID'             = $SID
        }

        <# Get WellKnownSidTypes
        # https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/81d92bba-d22b-4a8c-908a-554ab29148ab
        # PS 5.1 returns fewer results than PS 7
        $logonDomainSid = 'S-1-5-21-1340649458-2707494813-4121304102'
        ForEach ($SidType in [System.Security.Principal.WellKnownSidType].GetEnumNames()) {$var = [System.Security.Principal.WellKnownSidType]::$SidType; [System.Security.Principal.SecurityIdentifier]::new($var,$LogonDomainSid) |Add-Member -PassThru -NotePropertyMembers @{'WellKnownSidType' = $SidType}}
        #>

        'S-1-2-0'                                                                                              = [PSCustomObject]@{
            'Description'     = 'Users who sign in to terminals that are locally (physically) connected to the system (WellKnownSidType LocalSid)'
            'DisplayName'     = 'Local'
            'Name'            = 'Local'
            'NTAccount'       = 'LOCAL SID AUTHORITY\LOCAL'
            'SamAccountName'  = 'LOCAL'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-2-0'
        }

        'S-1-3-1'                                                                                              = [PSCustomObject]@{
            'Description'     = 'A security identifier to be replaced by the primary-group SID of the user who created a new object. Use this SID in inheritable ACEs (WellKnownSidType CreatorGroupSid)'
            'DisplayName'     = 'Creator Group ID'
            'Name'            = 'CREATOR GROUP'
            'NTAccount'       = 'CREATOR SID AUTHORITY\CREATOR GROUP'
            'SamAccountName'  = 'CREATOR GROUP'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-3-1'
        }

        'S-1-3-2'                                                                                              = [PSCustomObject]@{
            'Description'     = "A placeholder in an inheritable ACE. When the ACE is inherited, the system replaces this SID with the SID for the object's owner server and stores information about who created a given object or file (WellKnownSidType CreatorOwnerServerSid)"
            'DisplayName'     = 'Creator Owner Server'
            'Name'            = 'CREATOR OWNER SERVER'
            'NTAccount'       = 'CREATOR SID AUTHORITY\CREATOR OWNER SERVER'
            'SamAccountName'  = 'CREATOR OWNER SERVER'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-3-2'
        }

        'S-1-3-3'                                                                                              = [PSCustomObject]@{
            'Description'     = "A placeholder in an inheritable ACE. When the ACE is inherited, the system replaces this SID with the SID for the object's group server and stores information about the groups that are allowed to work with the object (WellKnownSidType CreatorGroupServerSid)"
            'DisplayName'     = 'Creator Group Server'
            'Name'            = 'CREATOR GROUP SERVER'
            'NTAccount'       = 'CREATOR SID AUTHORITY\CREATOR GROUP SERVER'
            'SamAccountName'  = 'CREATOR GROUP SERVER'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-3-3'
        }

        'S-1-3-4'                                                                                              = [PSCustomObject]@{
            'Description'     = 'A group that represents the current owner of the object. When an ACE that carries this SID is applied to an object, the system ignores the implicit READ_CONTROL and WRITE_DAC permissions for the object owner (WellKnownSidType WinCreatorOwnerRightsSid)'
            'DisplayName'     = 'Owner Rights'
            'Name'            = 'OWNER RIGHTS'
            'NTAccount'       = 'CREATOR SID AUTHORITY\OWNER RIGHTS'
            'SamAccountName'  = 'OWNER RIGHTS'
            'SchemaClassName' = 'user'
            'SID'             = 'S-1-3-4'
        }

        'S-1-5-22'                                                                                             = [PSCustomObject]@{
            'Description'     = 'Domain controllers that are configured as read-only, meaning they cannot make changes to the directory (WellKnownSidType WinEnterpriseReadonlyControllersSid) (SID constant DOMAIN_GROUP_RID_ENTERPRISE_READONLY_DOMAIN_CONTROLLERS)'
            'DisplayName'     = 'Enterprise Read-Only Domain Controllers'
            'Name'            = 'Enterprise Read-Only Domain Controllers'
            'NTAccount'       = 'NT AUTHORITY\Enterprise Read-Only Domain Controllers'
            'SamAccountName'  = 'Enterprise Read-Only Domain Controllers'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-22'
        }

        'S-1-5-1000'                                                                                           = [PSCustomObject]@{
            'Description'     = 'A group that includes all users and computers from another organization. If this SID is present, the THIS_ORGANIZATION SID must NOT be present (WellKnownSidType OtherOrganizationSid) (SID constant OTHER_ORGANIZATION)'
            'DisplayName'     = 'Other Organization'
            'Name'            = 'Other Organization'
            'NTAccount'       = 'NT AUTHORITY\Other Organization'
            'SamAccountName'  = 'Other Organization'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-1000'
        }

        'S-1-16-0'                                                                                             = [PSCustomObject]@{
            'Description'     = 'An untrusted integrity level (WellKnownSidType WinUntrustedLabelSid) (SID constant ML_UNTRUSTED)'
            'DisplayName'     = 'Untrusted Mandatory Level'
            'Name'            = 'Untrusted Mandatory Level'
            'NTAccount'       = 'MANDATORY LABEL AUTHORITY\Untrusted Mandatory Level'
            'SamAccountName'  = 'Untrusted Mandatory Level'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-16-0'
        }

        'S-1-16-4096'                                                                                          = [PSCustomObject]@{
            'Description'     = 'A low integrity level (WellKnownSidType WinLowLabelSid) (SID constant ML_LOW)'
            'DisplayName'     = 'Low Mandatory Level'
            'Name'            = 'Low Mandatory Level'
            'NTAccount'       = 'MANDATORY LABEL AUTHORITY\Low Mandatory Level'
            'SamAccountName'  = 'Low Mandatory Level'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-16-4096'
        }

        'S-1-16-8192'                                                                                          = [PSCustomObject]@{
            'Description'     = 'A medium integrity level (WellKnownSidType WinMediumLabelSid) (SID constant ML_MEDIUM)'
            'DisplayName'     = 'Medium Mandatory Level'
            'Name'            = 'Medium Mandatory Level'
            'NTAccount'       = 'MANDATORY LABEL AUTHORITY\Medium Mandatory Level'
            'SamAccountName'  = 'Medium Mandatory Level'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-16-8192'
        }

        'S-1-16-8448'                                                                                          = [PSCustomObject]@{
            'Description'     = 'A medium-plus integrity level (WellKnownSidType WinMediumPlusLabelSid) (SID constant ML_MEDIUM_PLUS)'
            'DisplayName'     = 'Medium Plus Mandatory Level'
            'Name'            = 'Medium Plus Mandatory Level'
            'NTAccount'       = 'MANDATORY LABEL AUTHORITY\Medium Plus Mandatory Level'
            'SamAccountName'  = 'Medium Plus Mandatory Level'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-16-8448'
        }

        'S-1-16-12288'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A high integrity level (WellKnownSidType WinHighLabelSid) (SID constant ML_HIGH)'
            'DisplayName'     = 'High Mandatory Level'
            'Name'            = 'High Mandatory Level'
            'NTAccount'       = 'MANDATORY LABEL AUTHORITY\High Mandatory Level'
            'SamAccountName'  = 'High Mandatory Level'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-16-12288'
        }

        'S-1-16-16384'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A system integrity level (WellKnownSidType WinSystemLabelSid) (SID constant ML_SYSTEM)'
            'DisplayName'     = 'System Mandatory Level'
            'Name'            = 'System Mandatory Level'
            'NTAccount'       = 'MANDATORY LABEL AUTHORITY\System Mandatory Level'
            'SamAccountName'  = 'System Mandatory Level'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-16-16384'
        }

        'S-1-5-65-1'                                                                                           = [PSCustomObject]@{
            # https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/11e1608c-6169-4fbc-9c33-373fc9b224f4#Appendix_A_32
            'Description'     = "A SID that indicates that the client's Kerberos service ticket's PAC contained a NTLM_SUPPLEMENTAL_CREDENTIAL structure as specified in [MS-PAC] section 2.6.4. If the OTHER_ORGANIZATION SID is present, then this SID MUST NOT be present (WellKnownSidType WinThisOrganizationCertificateSid) (SID constant THIS_ORGANIZATION_CERTIFICATE)"
            'DisplayName'     = 'This Organization Certificate'
            'Name'            = 'This Organization Certificate'
            'NTAccount'       = 'NT AUTHORITY\This Organization Certificate'
            'SamAccountName'  = 'This Organization Certificate'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-65-1'
        }

        # https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/81d92bba-d22b-4a8c-908a-554ab29148ab
        'S-1-5-33'                                                                                             = [PSCustomObject]@{
            'Description'     = 'Any process with a write-restricted token (WellKnownSidType WinWriteRestrictedCodeSid) (SID constant SECURITY_WRITE_RESTRICTED_CODE_RID)'
            'DisplayName'     = 'Write Restricted Code'
            'Name'            = 'Write Restricted Code'
            'NTAccount'       = 'NT AUTHORITY\Write Restricted Code'
            'SamAccountName'  = 'Write Restricted Code'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-33'
        }

        'S-1-5-80-2970612574-78537857-698502321-558674196-1451644582'                                          = [PSCustomObject]@{
            'Description'     = 'The SID gives the Diagnostic Policy Service (which runs as NT AUTHORITY\LocalService in a shared process of svchost.exe) access to coordinate execution of diagnostics/troubleshooting/resolution'
            'DisplayName'     = 'Diagnostic Policy Service'
            'Name'            = 'DPS'
            'NTAccount'       = 'NT SERVICE\DPS'
            'SamAccountName'  = 'DPS'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-33'
        }

        'S-1-16-20480'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A protected-process integrity level (WellKnownSidType WinProtectedProcessLabelSid) (SID constant ML_PROTECTED_PROCESS)'
            'DisplayName'     = 'Protected Process Mandatory Level'
            'Name'            = 'Protected Process Mandatory Level'
            'NTAccount'       = 'MANDATORY LABEL AUTHORITY\Protected Process Mandatory Level'
            'SamAccountName'  = 'Protected Process Mandatory Level'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-16-20480'
        }

        'S-1-16-28672'                                                                                         = [PSCustomObject]@{
            # https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/11e1608c-6169-4fbc-9c33-373fc9b224f4#Appendix_A_36
            'Description'     = 'A secure process integrity level (WellKnownSidType WinSecureProcessLabelSid) (SID constant ML_SECURE_PROCESS)'
            'DisplayName'     = 'Secure Process Mandatory Level'
            'Name'            = 'Secure Process Mandatory Level'
            'NTAccount'       = 'MANDATORY LABEL AUTHORITY\Secure Process Mandatory Level'
            'SamAccountName'  = 'Secure Process Mandatory Level'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-16-28672'
        }

        # https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/dn743661(v=ws.11)
        'S-1-0'                                                                                                = [PSCustomObject]@{
            'Description'     = 'This authority is used to define the Null SID (SID constant SECURITY_NULL_SID_AUTHORITY)'
            'DisplayName'     = 'NULL SID AUTHORITY'
            'Name'            = 'NULL SID AUTHORITY'
            'NTAccount'       = 'NULL SID AUTHORITY'
            'SamAccountName'  = 'NULL SID AUTHORITY'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-0'
        }

        'S-1-1'                                                                                                = [PSCustomObject]@{
            'Description'     = 'This authority is used to define the World SID (SID constant SECURITY_WORLD_SID_AUTHORITY)'
            'DisplayName'     = 'WORLD SID AUTHORITY'
            'Name'            = 'WORLD SID AUTHORITY'
            'NTAccount'       = 'WORLD SID AUTHORITY'
            'SamAccountName'  = 'WORLD SID AUTHORITY'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-1'
        }

        'S-1-2'                                                                                                = [PSCustomObject]@{
            'Description'     = 'This authority manages local users and groups on a computer (SID constant SECURITY_LOCAL_SID_AUTHORITY)'
            'DisplayName'     = 'LOCAL SID AUTHORITY'
            'Name'            = 'LOCAL SID AUTHORITY'
            'NTAccount'       = 'LOCAL SID AUTHORITY'
            'SamAccountName'  = 'LOCAL SID AUTHORITY'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-2'
        }

        'S-1-15-3-1024-1365790099-2797813016-1714917928-519942599-2377126242-1094757716-3949770552-3596009590' = [PSCustomObject]@{
            'Description'     = 'runFullTrust containerized app capability SID (WellKnownSidType WinCapabilityRemovableStorageSid)'
            'DisplayName'     = 'runFullTrust'
            'Name'            = 'runFullTrust'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\runFullTrust'
            'SamAccountName'  = 'runFullTrust'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-1024-1365790099-2797813016-1714917928-519942599-2377126242-1094757716-3949770552-3596009590'
        }

        'S-1-15-3-1024-1195710214-366596411-2746218756-3015581611-3786706469-3006247016-1014575659-1338484819' = [PSCustomObject]@{
            'Description'     = 'userNotificationListener containerized app capability SID'
            'DisplayName'     = 'userNotificationListener'
            'Name'            = 'userNotificationListener'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\userNotificationListener'
            'SamAccountName'  = 'userNotificationListener'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-1024-1195710214-366596411-2746218756-3015581611-3786706469-3006247016-1014575659-1338484819'
        }

    }

}
function Get-ParentDomainDnsName {

    <#
    .SYNOPSIS

        Gets the DNS name of the parent domain for a given computer or domain.
    .DESCRIPTION
        This function retrieves the DNS name of the parent domain for a specified domain
        or computer using CIM queries. For workgroup computers or when no parent domain
        is found, it falls back to using the primary DNS suffix from the client's global
        DNS settings. The function uses caching to improve performance during repeated calls.
    .EXAMPLE
        $Cache = @{}
        Get-ParentDomainDnsName -DomainNetbios "CORPDC01" -Cache ([ref]$Cache)

        Remark: This example retrieves the parent domain DNS name for a domain controller named "CORPDC01".
        The function will first attempt to get the domain information via CIM queries to the specified computer.
        Results are stored in the $Cache variable to improve performance if the function is called again
        with the same parameters. For domain controllers, this will typically return the forest root domain name.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Get-ParentDomainDnsName')]

    param (

        # NetBIOS name of the domain whose parent domain DNS to return
        [string]$DomainNetbios,

        # Existing CIM session to the computer (to avoid creating redundant CIM sessions)
        [CimSession]$CimSession,

        # Switch to remove the CIM session when done
        [switch]$RemoveCimSession,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    if (-not $CimSession) {
        Write-LogMsg -Text "Get-CachedCimSession -ComputerName '$DomainNetbios' -Cache `$Cache" -Cache $Cache
        $CimSession = Get-CachedCimSession -ComputerName $DomainNetbios -Cache $Cache
    }

    Write-LogMsg -Text "((Get-CachedCimInstance -ComputerName '$DomainNetbios' -ClassName CIM_ComputerSystem -Cache `$Cache).domain # for '$DomainNetbios'" -Cache $Cache
    $ParentDomainDnsName = (Get-CachedCimInstance -ComputerName $DomainNetbios -ClassName CIM_ComputerSystem -KeyProperty Name -Cache $Cache).domain

    if ($ParentDomainDnsName -eq 'WORKGROUP' -or $null -eq $ParentDomainDnsName) {
        # For workgroup computers there is no parent domain DNS (workgroups operate on NetBIOS)
        # There could also be unexpeted scenarios where the parent domain DNS is null
        # In these cases, we will use the primary DNS search suffix (that is where the OS would attempt to register DNS records for the computer)
        Write-LogMsg -Text "(Get-DnsClientGlobalSetting -CimSession `$CimSession).SuffixSearchList[0] # for '$DomainNetbios'" -Cache $Cache
        $ParentDomainDnsName = (Get-DnsClientGlobalSetting -CimSession $CimSession).SuffixSearchList[0]
    }

    if ($RemoveCimSession) {
        Remove-CimSession -CimSession $CimSession
    }

    return $ParentDomainDnsName
}
function Get-TrustedDomain {

    <#
    .SYNOPSIS

    Returns a dictionary of trusted domains by the current computer
    .DESCRIPTION
    Works only on domain-joined systems
    Use nltest to get the domain trust relationships for the domain of the current computer
    Use ADSI's LDAP provider to get each trusted domain's DNS name, NETBIOS name, and SID
    For each trusted domain the key is the domain's SID, or its NETBIOS name if the -KeyByNetbios switch parameter was used
    For each trusted domain the value contains the details retrieved with ADSI
    .INPUTS
    None. Pipeline input is not accepted.
    .OUTPUTS
    [PSCustomObject] One object per trusted domain, each with a DomainFqdn property and a DomainNetbios property

    .EXAMPLE
    Get-TrustedDomain -Cache $Cache

    Retrieves information about all domains trusted by the current domain-joined computer, including each domain's
    NetBIOS name, DNS name, and distinguished name. This information is essential for cross-domain identity resolution
    and permission analysis. The function stores the results in the provided cache to improve performance in
    subsequent operations involving these trusted domains.
    .NOTES
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Get-TrustedDomain')]
    [OutputType([PSCustomObject])]

    param (

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    # Errors are expected on non-domain-joined systems
    # Redirecting the error stream to null only suppresses the error in the console; it will still be in the transcript
    # Instead, redirect the error stream to the output stream and filter out the errors by type
    Write-LogMsg -Text "$('& nltest /domain_trusts')" -Cache $Cache
    $nltestresults = & nltest /domain_trusts 2>&1
    $RegExForEachTrust = '(?<index>[\d]*): (?<netbios>\S*) (?<dns>\S*).*'
    $DomainByFqdn = $Cache.Value['DomainByFqdn']
    $DomainByNetbios = $Cache.Value['DomainByNetbios']

    ForEach ($Result in $nltestresults) {

        if ($Result.GetType() -eq [string]) {

            if ($Result -match $RegExForEachTrust) {

                $DN = ConvertTo-DistinguishedName -DomainFQDN $Matches.dns -AdsiProvider 'LDAP' -Cache $Cache

                $OutputObject = [PSCustomObject]@{
                    Netbios           = $Matches.netbios
                    Dns               = $Matches.dns
                    DistinguishedName = $DN
                }

                $DomainByFqdn.Value[$Matches.dns] = $OutputObject
                $DomainByNetbios.Value[$Matches.netbios] = $OutputObject

            }

        }

    }

}
function Get-WinNTGroupMember {

    <#
    .SYNOPSIS

    Get members of a group from the WinNT provider
    .DESCRIPTION
    Get members of a group from the WinNT provider
    Convert them from COM objects into usable DirectoryEntry objects
    .INPUTS
    [System.DirectoryServices.DirectoryEntry]$DirectoryEntry
    .OUTPUTS
    [System.DirectoryServices.DirectoryEntry] for each group member
    .EXAMPLE
    [System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrators') | Get-WinNTGroupMember -Cache $Cache

    Retrieves all members of the local Administrators group and returns them as DirectoryEntry objects.
    This allows for further processing of group membership information, including nested groups, and provides
    a consistent object format that works well with other ADSI functions. The Cache parameter ensures efficient
    operation by avoiding redundant directory queries.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Get-WinNTGroupMember')]
    [OutputType([System.DirectoryServices.DirectoryEntry])]

    param (

        # DirectoryEntry [System.DirectoryServices.DirectoryEntry] of the WinNT group whose members to get
        [Parameter(ValueFromPipeline)]
        $DirectoryEntry,

        # Properties of the group members to find in the directory
        [string[]]$PropertiesToLoad = @('distinguishedName', 'groupType', 'member', 'name', 'objectClass', 'objectSid', 'primaryGroupToken', 'samAccountName'),

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    begin {

        # Add the bare minimum required properties
        $PropertiesToLoad = $PropertiesToLoad + @(
            'distinguishedName',
            'grouptype',
            'member',
            'name',
            'objectClass',
            'objectSid',
            'primaryGroupToken',
            'samAccountName'
        )

        $PropertiesToLoad = $PropertiesToLoad | Sort-Object -Unique

        $Log = @{ 'Cache' = $Cache }
        $DirectoryParams = @{ 'Cache' = $Cache ; 'PropertiesToLoad' = $PropertiesToLoad }

    }

    process {

        ForEach ($ThisDirEntry in $DirectoryEntry) {

            $LogSuffix = "# For '$($ThisDirEntry.Path)'"
            $Log['Suffix'] = " $LogSuffix"

            if (
                $null -ne $ThisDirEntry.Properties['groupType'] -or
                $ThisDirEntry.schemaclassname -in @('group', 'SidTypeWellKnownGroup', 'SidTypeAlias')
            ) {

                Write-LogMsg @Log -Text "`$DirectoryMembers = Invoke-IADsGroupMembersMethod -DirectoryEntry `$ThisDirEntry"
                $DirectoryMembers = Invoke-IADsGroupMembersMethod -DirectoryEntry $ThisDirEntry

                $MembersToGet = @{
                    'WinNTMembers' = @()
                }

                Write-LogMsg @Log -Text "Find-WinNTGroupMember -ComObject `$DirectoryMembers -Out $MembersToGet -LogSuffix `"$LogSuffix`" -DirectoryEntry `$ThisDirEntry -Cache `$Cache # for $(@($DirectoryMembers).Count) members"
                Find-WinNTGroupMember -ComObject $DirectoryMembers -Out $MembersToGet -LogSuffix $LogSuffix -DirectoryEntry $ThisDirEntry -Cache $Cache

                # Get and Expand the directory entries for the WinNT group members
                ForEach ($ThisMember in $MembersToGet['WinNTMembers']) {

                    Write-LogMsg @Log -Text "`$MemberDirectoryEntry = Get-DirectoryEntry -DirectoryPath '$ThisMember'" -Expand $DirectoryParams -ExpansionMap $Cache.Value['LogCacheMap'].Value
                    $MemberDirectoryEntry = Get-DirectoryEntry -DirectoryPath $ThisMember @DirectoryParams
                    Write-LogMsg @Log -Text "Expand-WinNTGroupMember = Get-DirectoryEntry -DirectoryEntry `$MemberDirectoryEntry -Cache `$Cache"
                    Expand-WinNTGroupMember -DirectoryEntry $MemberDirectoryEntry -AccountProperty $PropertiesToLoad -Cache $Cache

                }

                # Remove the WinNTMembers key from the hashtable so the only remaining keys are distinguishedName(s) of LDAP directories
                $MembersToGet.Remove('WinNTMembers')

                # Get and Expand the directory entries for the LDAP group members
                ForEach ($MemberPath in $MembersToGet.Keys) {

                    $ThisMemberToGet = $MembersToGet[$MemberPath]
                    Write-LogMsg @Log -Text "`$MemberDirectoryEntries = Search-Directory -DirectoryPath '$MemberPath' -Filter '(|$ThisMemberToGet)'" -Expand $DirectoryParams -ExpansionMap $Cache.Value['LogCacheMap'].Value
                    $MemberDirectoryEntries = Search-Directory -DirectoryPath $MemberPath -Filter "(|$ThisMemberToGet)" @DirectoryParams
                    Write-LogMsg @Log -Text "Expand-WinNTGroupMember -DirectoryEntry `$MemberDirectoryEntries -Cache `$Cache"
                    Expand-WinNTGroupMember -DirectoryEntry $MemberDirectoryEntries -AccountProperty $PropertiesToLoad -Cache $Cache

                }

            } else {
                Write-LogMsg @Log -Text ' # Is not a group'
            }

        }

    }

}
function Invoke-ComObject {

    <#
    .SYNOPSIS

    Invoke a member method of a ComObject [__ComObject]
    .DESCRIPTION
    Use the InvokeMember method to invoke the InvokeMethod or GetProperty or SetProperty methods
    By default, invokes the GetProperty method for the specified Property
    If the Value parameter is specified, invokes the SetProperty method for the specified Property
    If the Method switch is specified, invokes the InvokeMethod method
    .INPUTS
    None. Pipeline input is not accepted.
    .OUTPUTS
    The output of the invoked method is returned directly
    .EXAMPLE
    $ComObject = [System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrators').Invoke('Members') | Select -First 1
    Invoke-ComObject -ComObject $ComObject -Property AdsPath

    Get the first member of the local Administrators group on the current computer
    Then use Invoke-ComObject to invoke the GetProperty method and return the value of the AdsPath property
    This technique is essential when working with ADSI objects that expose properties or methods only through COM interfaces,
    providing a consistent way to access these properties in PowerShell.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Invoke-ComObject')]

    param (

        # The ComObject whose member method to invoke
        [Parameter(Mandatory)]
        $ComObject,

        # The property to use with the invoked method
        [Parameter(Mandatory)]
        [String]$Property,

        # The value to set with the SetProperty method, or the name of the method to run with the InvokeMethod method
        $Value,

        # Use the InvokeMethod method of the ComObject
        [Switch]$Method

    )

    <#
    # Don't remember what this is for
    If ($ComObject -IsNot "__ComObject") {
        If (!$ComInvoke) {
            $Global:ComInvoke = @{}
        }
        If (!$ComInvoke.$ComObject) {
            $ComInvoke.$ComObject = New-Object -ComObject $ComObject
        }
        $ComObject = $ComInvoke.$ComObject

    }
    #>

    If ($Method) {
        $Invoke = 'InvokeMethod'
    } ElseIf ($MyInvocation.BoundParameters.ContainsKey('Value')) {
        $Invoke = 'SetProperty'
    } Else {
        $Invoke = 'GetProperty'
    }
    [__ComObject].InvokeMember($Property, $Invoke, $Null, $ComObject, $Value)
}
function Resolve-IdentityReference {

    <#
    .SYNOPSIS

    Use CIM and ADSI to lookup info about IdentityReferences from Access Control Entries that came from Discretionary Access Control Lists
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

    Resolves the local Administrator account on the BUILTIN domain to its proper SID, NetBIOS name,
    and DNS name format. This is useful when analyzing permissions to ensure consistency in how identities
    are represented, especially when comparing permissions across different systems or domains.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Resolve-IdentityReference')]
    [OutputType([PSCustomObject])]

    param (

        # IdentityReference from an Access Control Entry
        # Expecting either a SID (S-1-5-18) or an NT account name (CONTOSO\User)
        [Parameter(Mandatory)]
        [string]$IdentityReference,

        # Object from Get-AdsiServer representing the directory server and its attributes
        [PSObject]$AdsiServer,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache,

        # Properties of each Account to display on the report
        [string[]]$AccountProperty = @('DisplayName', 'Company', 'Department', 'Title', 'Description')

    )

    $ServerNetBIOS = $AdsiServer.Netbios
    $splat1 = @{ AdsiServer = $AdsiServer; ServerNetBIOS = $ServerNetBIOS }
    $splat2 = @{ IdentityReference = $IdentityReference }

    # Search for the IdentityReference in the cache of Win32_Account CIM instances and well-known SIDs on the ADSI server. Many cannot be translated with the Translate method.
    $CacheResult = Resolve-IdRefCached -IdentityReference $IdentityReference @splat1

    if ($null -ne $CacheResult) {

        #Write-LogMsg -Text " # IdentityReference '$IdentityReference' # Cache hit" -Cache $Cache
        return $CacheResult

    }


    #Write-LogMsg -Text " # IdentityReference '$IdentityReference' # Cache miss" -Cache $Cache

    <#
    If no match was found in any cache, the resolution method depends on the IdentityReference.
    First, determine whether the IdentityReference is an NTAccount (DOMAIN\Name vs Name).
    #>


    $LastSlashIndex = $IdentityReference.LastIndexOf('\')

    if ($LastSlashIndex -eq -1) {

        $Name = $IdentityReference
        $Domain = ''

    } else {

        $StartIndex = $LastSlashIndex + 1
        $Name = $IdentityReference.Substring( $StartIndex , $IdentityReference.Length - $StartIndex )
        $Domain = $IdentityReference.Substring( 0 , $StartIndex - 1 )

    }

    # Determine whether the IdentityReference's domain is a well-known SID authority.
    $ScriptBlocks = @{
        'NT SERVICE'                    = { Resolve-IdRefSvc -Name $Name -Cache $Cache @splat1 @splat2 }
        'APPLICATION PACKAGE AUTHORITY' = { Resolve-IdRefAppPkgAuth -Name $Name -Cache $Cache @splat1 @splat2 }
        'BUILTIN'                       = { Resolve-IdRefBuiltIn -Name $Name -Cache $Cache @splat1 @splat2 }
    }

    $ScriptToRun = $ScriptBlocks[$Domain]

    # If the IdentityReference's domain is a well-known SID authority, resolve the IdentityReference accordingly.
    if ($null -ne $ScriptToRun) {

        $KnownAuthorityResult = & $ScriptToRun

        if ($null -ne $KnownAuthorityResult) {

            #Write-LogMsg -Text " # IdentityReference '$IdentityReference' # Known SID authority used for successful IdentityReference resolution" -Cache $Cache
            return $KnownAuthorityResult

        }

    }

    # If the IdentityReference's domain is not a well-known SID authority, determine whether the IdentityReference is a Revision 1 SID.
    if ($Name.Substring(0, 4) -eq 'S-1-') {

        # If the IdentityReference is a Revision 1 SID, translate the SID to an NTAccount.
        $Resolved = Resolve-IdRefSID -AccountProperty $AccountProperty -Cache $Cache @splat1 @splat2
        return $Resolved

    }

    # If no match was found with any of the known patterns for SIDs or well-known SID authorities, the IdentityReference is an NTAccount.
    # Translate the NTAccount to a SID.
    if ($null -ne $ServerNetBIOS) {

        # Start by determining the domain DN and DNS name.
        $CacheResult = $null
        $TryGetValueResult = $Cache.Value['DomainByNetbios'].Value.TryGetValue( $ServerNetBIOS, [ref]$CacheResult )

        if ($TryGetValueResult) {
            #Write-LogMsg -Text " # IdentityReference '$IdentityReference' # Domain NetBIOS cache hit for '$ServerNetBIOS'" -Cache $Cache
        } else {

            #Write-LogMsg -Text " # IdentityReference '$IdentityReference' # Domain NetBIOS cache miss for '$ServerNetBIOS'" -Cache $Cache
            $CacheResult = Get-AdsiServer -Netbios $ServerNetBIOS -Cache $Cache

        }

        $DomainDn = $CacheResult.DistinguishedName
        $DomainDns = $CacheResult.Dns

        # Try to resolve the account against the server the Access Control Entry came from (which may or may not be the directory server for the account).
        $SIDString = ConvertTo-SidString -Name $Name -ServerNetBIOS $ServerNetBIOS -Cache $Cache

        if (-not $SIDString) {

            # Try to resolve the account against the domain indicated in its NT Account Name.
            # Add this domain to our list of known domains.
            $SIDString = Resolve-IdRefSearchDir -DomainDn $DomainDn -Name $Name -AccountProperty $AccountProperty -Cache $Cache @splat2

        }

        if (-not $SIDString) {

            # Try to find the DirectoryEntry object directly on the server.
            $SIDString = Resolve-IdRefGetDirEntry -Name $Name -Cache $Cache @splat1

        }

        # The IdentityReference is an unresolved SID (deleted account, account in a domain with a broken domain trust, etc.)
        if ( '' -eq "$Name" ) {

            $Name = $IdentityReference
            Write-LogMsg -Text " # IdentityReference '$IdentityReference' # No name could be parsed." -Cache $Cache

        } else {
            Write-LogMsg -Text " # IdentityReference '$IdentityReference' # Name parsed is '$Name'." -Cache $Cache
        }

        return [PSCustomObject]@{
            IdentityReference        = $IdentityReference
            SIDString                = $SIDString
            IdentityReferenceNetBios = "$ServerNetBIOS\$Name"
            IdentityReferenceDns     = "$DomainDns\$Name"
        }

    }

}
function Resolve-ServiceNameToSID {

    <#
    .SYNOPSIS

        Resolves Windows service names to their corresponding security identifiers (SIDs).
    .DESCRIPTION
        This function takes service objects (from Get-Service or Win32_Service) and
        calculates their corresponding SIDs using the same algorithm as sc.exe showsid.
        It enriches the input service objects with SID and Status and returns the
        enhanced objects with all original properties preserved.
    .EXAMPLE
        Get-Service -Name "BITS" | Resolve-ServiceNameToSID

        Remark: This example retrieves the Background Intelligent Transfer Service and resolves its service name to a SID.
        The output includes all original properties of the service plus the SID property.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Resolve-ServiceNameToSID')]

    param (

        # Output of Get-Service or an instance of the Win32_Service CIM class
        [Parameter(ValueFromPipeline)]
        $InputObject

    )

    process {

        ForEach ($Svc in $InputObject) {

            $SID = ConvertTo-ServiceSID -ServiceName $Svc.Name

            $OutputObject = @{
                Name = $Svc.Name
                SID  = $SID
            }

            ForEach ($Prop in $Svc.PSObject.Properties.GetEnumerator().Name) {
                $OutputObject[$Prop] = $Svc.$Prop
            }

            [PSCustomObject]$OutputObject

        }

    }

}
function Search-Directory {

    <#
    .SYNOPSIS
    Use Active Directory Service Interfaces to search an LDAP directory
    .DESCRIPTION
    Find directory entries using the LDAP provider for ADSI (the WinNT provider does not support searching)
    Provides a wrapper around the [System.DirectoryServices.DirectorySearcher] class
    Supports filtering, paging, and customizing which properties to return.
    .EXAMPLE
    Search-Directory -DirectoryPath "LDAP://DC=contoso,DC=com" -Filter "(objectClass=user)" -PageSize 1000 -Cache $Cache

    Searches the contoso.com domain for all user objects, retrieving results in pages of 1000 objects at a time.
    This is useful for efficiently retrieving large sets of directory objects without overwhelming memory resources.
    .INPUTS
    None. Pipeline input is not accepted.
    .OUTPUTS
    System.DirectoryServices.SearchResult collection representing the matching directory objects.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Search-Directory')]
    [OutputType([System.DirectoryServices.SearchResult[]])]

    param (

        <#
        Path to the directory object to retrieve
        Defaults to the root of the current domain
        #>
        [string]$DirectoryPath = (([adsisearcher]'').SearchRoot.Path),

        # Filter for the LDAP search
        [string]$Filter,

        # Number of results to return in each page
        [int]$PageSize = 1000,

        # Search scope (Base, OneLevel, or Subtree)
        [System.DirectoryServices.SearchScope]$SearchScope = [System.DirectoryServices.SearchScope]::Subtree,



        # Additional properties to return
        [string[]]$PropertiesToLoad,



        # Credentials to use
        [pscredential]$Credential,



        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]

        [ref]$Cache

    )




    $DirectoryEntryParameters = @{ 'Cache' = $Cache }

    if ($Credential) {
        $DirectoryEntryParameters['Credential'] = $Credential

    }

    if (($null -eq $DirectoryPath -or '' -eq $DirectoryPath)) {

        $CimParams = @{
            'Cache'        = $Cache
            'ComputerName' = $Cache.Value['ThisFqdn'].Value
        }

        $Workgroup = (Get-CachedCimInstance -ClassName 'Win32_ComputerSystem' -KeyProperty 'Name' @CimParams).Workgroup
        $DirectoryPath = "WinNT://$Workgroup/$($Cache.Value['ThisHostName'].Value))"

    }

    Write-LogMsg -Text "Get-DirectoryEntry -DirectoryPath '$DirectoryPath'" -Expand $DirectoryEntryParameters -ExpansionMap $Cache.Value['LogCacheMap'].Value -Cache $Cache
    $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath @DirectoryEntryParameters
    Write-LogMsg -Text "`$DirectorySearcher = [System.DirectoryServices.DirectorySearcher]::new(([System.DirectoryServices.DirectoryEntry]::new('$DirectoryPath')))" -Cache $Cache
    $DirectorySearcher = [System.DirectoryServices.DirectorySearcher]::new($DirectoryEntry)

    if ($Filter) {
        Write-LogMsg -Text "`$DirectorySearcher.Filter = '$Filter'" -Cache $Cache
        $DirectorySearcher.Filter = $Filter
    }

    Write-LogMsg -Text "`$DirectorySearcher.PageSize = '$PageSize'" -Cache $Cache
    $DirectorySearcher.PageSize = $PageSize
    Write-LogMsg -Text "`$DirectorySearcher.SearchScope = '$SearchScope'" -Cache $Cache
    $DirectorySearcher.SearchScope = $SearchScope
    Write-LogMsg -Text "`$DirectorySearcher.PropertiesToLoad.AddRange(@('$($PropertiesToLoad -join "','")'))" -Cache $Cache
    $null = $DirectorySearcher.PropertiesToLoad.AddRange($PropertiesToLoad)
    Write-LogMsg -Text "`$DirectorySearcher.FindAll()" -Cache $Cache
    $SearchResultCollection = $DirectorySearcher.FindAll()
    # TODO: Fix this.  Problems in integration testing trying to use the objects later if I dispose them here now.
    # Error: Cannot access a disposed object.
    #$null = $DirectorySearcher.Dispose()
    #$null = $DirectoryEntry.Dispose()
    $Output = [System.DirectoryServices.SearchResult[]]::new($SearchResultCollection.Count)
    $SearchResultCollection.CopyTo($Output, 0)
    #$null = $SearchResultCollection.Dispose()
    return $Output

}
<#
# Add any custom C# classes as usable (exported) types
$CSharpFiles = Get-ChildItem -Path "$PSScriptRoot\*.cs"
ForEach ($ThisFile in $CSharpFiles) {
    Add-Type -Path $ThisFile.FullName -ErrorAction Stop
}
#>

Export-ModuleMember -Function @('Add-DomainFqdnToLdapPath', 'Add-SidInfo', 'ConvertFrom-DirectoryEntry', 'ConvertFrom-PropertyValueCollectionToString', 'ConvertFrom-ResolvedID', 'ConvertFrom-ResultPropertyValueCollectionToString', 'ConvertFrom-SearchResult', 'ConvertFrom-SidString', 'ConvertTo-DecStringRepresentation', 'ConvertTo-DistinguishedName', 'ConvertTo-DomainNetBIOS', 'ConvertTo-DomainSidString', 'ConvertTo-FakeDirectoryEntry', 'ConvertTo-Fqdn', 'ConvertTo-HexStringRepresentation', 'ConvertTo-HexStringRepresentationForLDAPFilterString', 'ConvertTo-SidByteArray', 'Expand-AdsiGroupMember', 'Expand-WinNTGroupMember', 'Find-LocalAdsiServerSid', 'Get-AdsiGroup', 'Get-AdsiGroupMember', 'Get-AdsiServer', 'Get-CurrentDomain', 'Get-DirectoryEntry', 'Get-KnownCaptionHashTable', 'Get-KnownSid', 'Get-KnownSidByName', 'Get-KnownSidHashTable', 'Get-ParentDomainDnsName', 'Get-TrustedDomain', 'Get-WinNTGroupMember', 'Invoke-ComObject', 'Resolve-IdentityReference', 'Resolve-ServiceNameToSID', 'Search-Directory')

