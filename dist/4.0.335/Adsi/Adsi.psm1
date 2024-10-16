
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
#>

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
            'NTAccount'       = "APPLICATION PACKAGE AUTHORITY\$SID"
        }
    }
}
function ConvertFrom-ScShowSidResult {
    # Convert the results from sc.exe into an object
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

    param (
        $Account,
        [hashtable]$SidCache = @{},
        [hashtable]$NameCache = @{}
    )

    ForEach ($ThisAccount in $Account) {
        $SidCache[$ThisAccount.SID] = $ThisAccount
        $NameCache[$ThisAccount.Name] = $ThisAccount
    }

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
    [string[]]$hashString = $hashBytes | ForEach-Object { $_.ToString("X2") }

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
    return "S-1-5-80-$([String]::Join("-", $blocks))"

}
function ConvertTo-SidString {

    param ($ServerNetBIOS, $Name, $Log, $DebugOutputStream)

    # Try to resolve the account against the server the Access Control Entry came from (which may or may not be the directory server for the account)
    Write-LogMsg @Log -Text "[System.Security.Principal.NTAccount]::new('$ServerNetBIOS', '$Name').Translate([System.Security.Principal.SecurityIdentifier])"
    $NTAccount = [System.Security.Principal.NTAccount]::new($ServerNetBIOS, $Name)

    try {
        & { $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]) } 2>$null
    } catch {

        $Log['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
        Write-LogMsg @Log -Text " # '$ServerNetBIOS\$Name' could not be translated from NTAccount to SID: $($_.Exception.Message)"
        $Log['Type'] = $DebugOutputStream

    }

}
function Find-CachedWellKnownSID {

    param (
        [hashtable]$DomainsByNetbios,
        [string]$IdentityReference,
        [string]$DomainNetBIOS
    )

    $DomainNetbiosCacheResult = $DomainsByNetbios[$DomainNetBIOS]

    if ($DomainNetbiosCacheResult) {

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

    # Find LDAP and WinNT group members to retrieve from their directories.
    # Convert COM objects from the IADsGroup::Members method into strings.
    # Use contextual information to determine whether each string represents an LDAP or a WinNT group member.

    param (

        # DirectoryEntry [System.DirectoryServices.DirectoryEntry] of the WinNT group whose members to get
        $DirectoryEntry,

        $ComObject,

        [hashtable]$Out,

        [string]$LogSuffix,

        [hashtable]$Log,

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        [string]$SourceDomain

    )

    ForEach ($DirectoryMember in $ComObject) {

        # Convert the ComObjects into DirectoryEntry objects.
        $DirectoryPath = Invoke-ComObject -ComObject $DirectoryMember -Property 'ADsPath'

        $MemberLogSuffix = "# For '$DirectoryPath'"
        $MemberDomainDn = $null

        # Split the DirectoryPath into its constituent components.
        $DirectorySplit = Split-DirectoryPath -DirectoryPath $DirectoryPath
        $MemberName = $DirectorySplit['Account']

        # Resolve well-known SID authorities to the name of the computer the DirectoryEntry came from.
        Resolve-SidAuthority -DirectorySplit $DirectorySplit -DirectoryEntry $DirectoryEntry
        $ResolvedDirectoryPath = $DirectorySplit['ResolvedDirectoryPath']
        $MemberDomainNetbios = $DirectorySplit['ResolvedDomain']

        if ($DirectorySplit['ParentDomain'] -eq 'WORKGROUP') {

            Write-LogMsg @Log -Text " # '$MemberDomainNetbios' is a workgroup computer $MemberLogSuffix $LogSuffix"
            $DomainCacheResult = $DomainsByNetbios[$MemberDomainNetbios]

            if ($DomainCacheResult) {

                #Write-LogMsg @Log -Text " # Domain NetBIOS cache hit for '$MemberDomainNetBios' $MemberLogSuffix $LogSuffix"

                if ( $MemberDomainNetbios -ne $SourceDomain ) {

                    Write-LogMsg @Log -Text " # $MemberDomainNetbios -ne $SourceDomain but why does my logic think this means LDAP group member rather than WinNT? $MemberLogSuffix $LogSuffix"
                    $MemberDomainDn = $DomainCacheResult.DistinguishedName

                } else {
                    Write-LogMsg @Log -Text " # $MemberDomainNetbios -eq $SourceDomain but why does my logic think this means WinNT group member rather than LDAP? $MemberLogSuffix $LogSuffix"
                }

            } else {
                #Write-LogMsg @Log -Text " # Domain NetBIOS cache miss for '$MemberDomainNetBios'. Available keys: $($DomainsByNetBios.Keys -join ',') $MemberLogSuffix $LogSuffix"
            }

            if ($DirectorySplit['Domain'] -eq $SourceDomain) {

                Write-LogMsg @Log -Text " # Member's parsed domain $($DirectorySplit['Domain']) equals the group's parsed domain '$SourceDomain' but why does my logic think this means WinNT group member rather than LDAP? $MemberLogSuffix $LogSuffix"
                $MemberDomainDn = $null

            } else {
                Write-LogMsg @Log -Text " # Member's parsed domain $($DirectorySplit['Domain']) does not equal the group's parsed domain '$SourceDomain' but why does my logic think this means LDAP or unconfirmed WinNT group member? $MemberLogSuffix $LogSuffix"
            }

        } else {
            Write-LogMsg @Log -Text " # '$MemberDomainNetbios' may or may not be a workgroup computer (inconclusive) $MemberLogSuffix $LogSuffix"
        }

        # LDAP directories have a distinguishedName
        if ($MemberDomainDn) {

            # LDAP directories support searching
            # Combine all members' samAccountNames into a single search per directory distinguishedName
            # Use a hashtable with the directory path as the key and a string as the definition
            # The string is a partial LDAP filter, just the segments of the LDAP filter for each samAccountName
            Write-LogMsg @Log -Text " # '$MemberName' is a domain security principal $MemberLogSuffix $LogSuffix"
            $Out["LDAP://$MemberDomainDn"] += "(samaccountname=$MemberName)"

        } else {

            # WinNT directories do not support searching so we will retrieve each member individually
            # Use a hashtable with 'WinNTMembers' as the key and an array of WinNT directory paths as the value
            Write-LogMsg @Log -Text " # Is a local security principal $MemberLogSuffix $LogSuffix"
            $Out['WinNTMembers'] += $ResolvedDirectoryPath

        }

    }

}
function Get-CachedDirectoryEntry {

    # Search the cache of CIM instances and well-known SIDs for the DirectoryEntry

    param (

        <#
        Path to the directory object to retrieve
        Defaults to the root of the current domain
        #>
        [string]$DirectoryPath = (([System.DirectoryServices.DirectorySearcher]::new()).SearchRoot.Path),

        # Cache of CIM sessions and instances for this specific server to reduce connections and queries
        [hashtable]$CimServer = ([hashtable]::Synchronized(@{})),

        [hashtable]$Log,

        [string]$Server,

        [string]$AccountName,

        # Hashtable with known domain FQDNs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        # This is not actually used but is here so the parameter can be included in a splat shared with other functions
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        [hashtable]$SidTypeMap = (Get-SidTypeMap)

    )

    <#
    The WinNT provider only throws an error if you try to retrieve certain accounts/identities
    We will create own dummy objects instead of performing the query
    #>
    $ID = "$Server\$AccountName"
    $DomainCacheResult = $DomainsByFqdn[$Server]

    if ($DomainCacheResult) {

        $SIDCacheResult = $DomainCacheResult.WellKnownSIDBySID[$ID]

        if ($SIDCacheResult) {

            #Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Known SID cache hit on this server."

            if ($SIDCacheResult.SIDType) {
                New-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $SIDCacheResult -SchemaClassName $SidTypeMap[[int]$SIDCacheResult.SIDType]
            } else {
                New-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $SIDCacheResult
            }


        } else {

            #Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Known SID cache miss on this server."
            $NameCacheResult = $DomainCacheResult.WellKnownSIDByName[$AccountName]

            if ($NameCacheResult) {

                #Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Name '$AccountName' # Known Name cache hit on this server."

                if ($NameCacheResult.SIDType) {
                    New-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $NameCacheResult -SchemaClassName $SidTypeMap[[int]$NameCacheResult.SIDType]
                } else {
                    New-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $NameCacheResult
                }

            } else {
                #Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Name '$AccountName' # Known Name cache miss on this server."
            }
        }

    } else {

        $DomainCacheResult = $DomainsByNetbios[$Server]

        if ($DomainCacheResult) {

            $SIDCacheResult = $DomainCacheResult.WellKnownSIDBySID[$ID]

            if ($SIDCacheResult) {

                #Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Known SID cache hit on this server."

                if ($SIDCacheResult.SIDType) {
                    New-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $SIDCacheResult -SchemaClassName $SidTypeMap[[int]$SIDCacheResult.SIDType]
                } else {
                    New-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $SIDCacheResult
                }

            } else {

                #Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Known SID cache miss on this server."
                $NameCacheResult = $DomainCacheResult.WellKnownSIDByName[$AccountName]

                if ($NameCacheResult) {

                    #Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Name '$AccountName' # Known Name cache hit on this server."Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Well-known SID by name cache hit for '$AccountName' on host with NetBIOS '$Server'"

                    if ($NameCacheResult.SIDType) {
                        New-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $NameCacheResult -SchemaClassName $SidTypeMap[[int]$NameCacheResult.SIDType]
                    } else {
                        New-FakeDirectoryEntry -DirectoryPath $DirectoryPath -InputObject $NameCacheResult
                    }

                } else {
                    #Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Name '$AccountName' # Known Name cache miss on this server."
                }

            }

        } else {

            $DomainCacheResult = $DomainsBySid[$Server]

            if ($DomainCacheResult) {

                $SIDCacheResult = $DomainCacheResult.WellKnownSIDBySID[$ID]

                if ($SIDCacheResult) {

                    #Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Known SID cache hit on this server."
                    New-FakeDirectoryEntry -DirectoryPath $DirectoryPath @SIDCacheResult

                } else {

                    #Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Known SID cache miss on this server."
                    $NameCacheResult = $DomainCacheResult.WellKnownSIDByName[$AccountName]

                    if ($NameCacheResult) {

                        #Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Name '$AccountName' # Known Name cache hit on this server."Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Well-known SID by name cache hit for '$AccountName' on host with NetBIOS '$Server'"
                        New-FakeDirectoryEntry -DirectoryPath $DirectoryPath @NameCacheResult

                    } else {
                        #Write-LogMsg @Log -Text " # DirectoryPath '$DirectoryPath' # Server FQDN '$Server' # NTAccount '$ID' # Name '$AccountName' # Known Name cache miss on this server."
                    }

                }

            }

        }

    }

}
function Get-DirectoryEntryParentName {

    # Possibly a debugging issue, not sure whether I need to prepare for both here.
    # in vscode Watch shows it as a DirectoryEntry with properties but the console (and results) have it as a String

    param (
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

    [OutputType([System.DirectoryServices.DirectoryEntry])]

    param (

        # DirectoryEntry [System.DirectoryServices.DirectoryEntry] of the WinNT group whose members to get
        [Parameter(ValueFromPipeline)]
        $DirectoryEntry

    )

    & { $DirectoryEntry.Invoke('Members') } 2>$null

}
function Invoke-ScShowSid {

    # Invoke sc.exe showsid

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

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Log messages which have not yet been written to disk
        [hashtable]$LogBuffer = ([hashtable]::Synchronized(@{})),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output from Get-KnownSidHashTable
        [hashtable]$WellKnownSidBySid = (Get-KnownSidHashTable),

        # Output from Get-KnownCaptionHashTable
        [hashtable]$WellKnownSidByCaption = (Get-KnownCaptionHashTable -WellKnownSidBySid $WellKnownSidBySid),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug'

    )

    $Log = @{ ThisHostname = $ThisHostname ; Type = $DebugOutputStream ; Buffer = $LogBuffer ; WhoAmI = $WhoAmI }
    $LogThis = @{ ThisHostname = $ThisHostname ; DebugOutputStream = $DebugOutputStream ; LogBuffer = $LogBuffer ; WhoAmI = $WhoAmI }

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
    $Known = $WellKnownSidByCaption[$IdentityReference]

    if ($Known) {
        $SIDString = $Known.SID
    } else {
        $SIDString = $Name
    }

    $Caption = "$ServerNetBIOS\$Name"

    $DomainCacheResult = $DomainsByNetbios[$ServerNetBIOS]

    if ($DomainCacheResult) {
        $DomainDns = $DomainCacheResult.Dns
    } else {

        Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # Domain NetBIOS '$ServerNetBIOS' # cache miss"
        $DomainDns = ConvertTo-Fqdn -NetBIOS $ServerNetBIOS -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LogThis
        $DomainCacheResult = Get-AdsiServer -Fqdn $DomainDns -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LogThis

    }

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
    $DomainsByFqdn[$DomainCacheResult.Dns] = $DomainCacheResult
    $DomainsByNetbios[$DomainCacheResult.Netbios] = $DomainCacheResult
    $DomainsBySid[$DomainCacheResult.Sid] = $DomainCacheResult

    return [PSCustomObject]@{
        IdentityReference        = $IdentityReference
        SIDString                = $SIDString
        IdentityReferenceNetBios = $Caption
        IdentityReferenceDns     = "$DomainDns\$Name"
    }

}
function Resolve-IdRefBuiltIn {

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

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Log messages which have not yet been written to disk
        [hashtable]$LogBuffer = ([hashtable]::Synchronized(@{})),

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName)

    )

    $LogThis = @{
        ThisHostname      = $ThisHostname
        DebugOutputStream = $DebugOutputStream
        LogBuffer         = $LogBuffer
        WhoAmI            = $WhoAmI
    }

    # Some built-in groups such as BUILTIN\Users and BUILTIN\Administrators are not in the CIM class or translatable with the NTAccount.Translate() method
    # But they may have real DirectoryEntry objects
    # Try to find the DirectoryEntry object locally on the server
    $DirectoryPath = "$($AdsiServer.AdsiProvider)`://$ServerNetBIOS/$Name"
    if ($Name.Substring(0, 4) -eq 'S-1-') {
        $SIDString = $Name
        $Caption = $IdentityReference
    } else {
        $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath @GetDirectoryEntryParams @LogThis
        $SIDString = (Add-SidInfo -InputObject $DirectoryEntry -DomainsBySid $DomainsBySid @LogThis).SidString
        $Caption = "$ServerNetBIOS\$Name"
    }
    $DomainDns = $AdsiServer.Dns
    $DomainCacheResult = Get-AdsiServer -Fqdn $DomainDns -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LogThis

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
    $DomainsByFqdn[$DomainCacheResult.Dns] = $DomainCacheResult
    $DomainsByNetbios[$DomainCacheResult.Netbios] = $DomainCacheResult
    $DomainsBySid[$DomainCacheResult.Sid] = $DomainCacheResult

    return [PSCustomObject]@{
        IdentityReference        = $IdentityReference
        SIDString                = $SIDString
        IdentityReferenceNetBios = $Caption
        IdentityReferenceDns     = "$DomainDns\$Name"
    }

}
function Resolve-IdRefCached {

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

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Log messages which have not yet been written to disk
        [hashtable]$LogBuffer = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug'

    )

    #$Log = @{
    #    ThisHostname = $ThisHostname
    #    Type         = $DebugOutputStream
    #    Buffer       = $LogBuffer
    #    WhoAmI       = $WhoAmI
    #}

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

    [OutputType([string])]

    param (

        # Object from Get-AdsiServer representing the directory server and its attributes
        [PSObject]$AdsiServer,

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        [string]$ServerNetBIOS,

        [string]$Name,

        [hashtable]$GetDirectoryEntryParams,

        [hashtable]$LogThis

    )

    $DirectoryPath = "$($AdsiServer.AdsiProvider)`://$ServerNetBIOS/$Name"
    $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath @GetDirectoryEntryParams @LogThis
    $DirectoryEntryWithSidInfo = Add-SidInfo -InputObject $DirectoryEntry -DomainsBySid $DomainsBySid @LogThis
    return $DirectoryEntryWithSidInfo.SidString

}
function Resolve-IdRefSearchDir {

    [OutputType([string])]

    param (

        # IdentityReference from an Access Control Entry
        # Expecting either a SID (S-1-5-18) or an NT account name (CONTOSO\User)
        [Parameter(Mandatory)]
        [string]$IdentityReference,

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        [string]$Name,

        [string]$DomainDn,

        [hashtable]$LogThis,

        [hashtable]$Log

    )

    $SearchPath = Add-DomainFqdnToLdapPath -DirectoryPath "LDAP://$DomainDn" -ThisFqdn $ThisFqdn -CimCache $CimCache @LogThis

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

    try {
        $DirectoryEntry = Search-Directory @SearchParams @LogThis
    } catch {

        $Log['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
        Write-LogMsg @Log -Text "'$IdentityReference' could not be resolved against its directory. Error: $($_.Exception.Message)"
        $Log['Type'] = $DebugOutputStream

    }

    $DirectoryEntryWithSidInfo = Add-SidInfo -InputObject $DirectoryEntry -DomainsBySid $DomainsBySid @Log
    return $DirectoryEntryWithSidInfo.SidString

}
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
        $DomainSid = $IdentityReference.Substring(0, $IdentityReference.LastIndexOf("-"))
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
        $DomainCacheResult = $DomainsBySID[$DomainSid]
    }

    if (-not $DomainCacheResult) {

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

        $DomainCacheResult = $DomainsByNetbios[$DomainNetBIOS]

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
function Resolve-IdRefSvc {

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

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

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

    $Log = @{ ThisHostname = $ThisHostname ; Type = $DebugOutputStream ; Buffer = $LogBuffer ; WhoAmI = $WhoAmI }
    $LogThis = @{ ThisHostname = $ThisHostname ; LogBuffer = $LogBuffer ; WhoAmI = $WhoAmI ; DebugOutputStream = $DebugOutputStream }
    $SIDString = ConvertTo-ServiceSID -ServiceName $Name
    $Caption = "$ServerNetBIOS\$Name"
    $DomainCacheResult = $DomainsByNetbios[$ServerNetBIOS]

    if ($DomainCacheResult) {
        $DomainDns = $DomainCacheResult.Dns
    } else {

        Write-LogMsg @Log -Text " # Domain NetBIOS cache miss for '$ServerNetBIOS' # For '$IdentityReference'"
        $DomainDns = ConvertTo-Fqdn -NetBIOS $ServerNetBIOS -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LogThis
        $DomainCacheResult = Get-AdsiServer -Fqdn $DomainDns -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LogThis

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
    $DomainsByFqdn[$DomainCacheResult.Dns] = $DomainCacheResult
    $DomainsByNetbios[$DomainCacheResult.Netbios] = $DomainCacheResult
    $DomainsBySid[$DomainCacheResult.Sid] = $DomainCacheResult

    return [PSCustomObject]@{
        IdentityReference        = $IdentityReference
        SIDString                = $SIDString
        IdentityReferenceNetBios = $Caption
        IdentityReferenceDns     = "$DomainDns\$Name"
    }

}
function Resolve-SidAuthority {

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
        Add-DomainFqdnToLdapPath -DirectoryPath 'LDAP://CN=user1,OU=UsersOU,DC=ad,DC=contoso,DC=com'
        LDAP://ad.contoso.com/CN=user1,OU=UsersOU,DC=ad,DC=contoso,DC=com

        Add the domain FQDN to a single LDAP directory path
    #>
    [OutputType([System.String])]
    param (

        # Incomplete LDAP directory path containing a distinguishedName but lacking a server address
        [Parameter(ValueFromPipeline)]
        [string[]]$DirectoryPath,

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
    begin {

        <#
        $LogParams = @{
            ThisHostname = $ThisHostname
            Type         = $DebugOutputStream
            LogBuffer  = $LogBuffer
            WhoAmI       = $WhoAmI
        }
        #>

        $LoggingParams = @{
            ThisHostname = $ThisHostname
            LogBuffer  = $LogBuffer
            WhoAmI       = $WhoAmI
        }

        $PathRegEx = '(?<Path>LDAP:\/\/[^\/]*)'
        $DomainRegEx = '(?i)DC=\w{1,}?\b'

    }
    process {

        ForEach ($ThisPath in $DirectoryPath) {

            if ($ThisPath -match $PathRegEx) {

                $RegExMatches = $null
                $RegExMatches = [regex]::Matches($ThisPath, $DomainRegEx)

                if ($RegExMatches) {
                    $DomainDN = $null
                    $DomainFqdn = $null

                    $RegExMatches = $RegExMatches |
                    ForEach-Object { $_.Value }

                    $DomainDN = $RegExMatches -join ','
                    $DomainFqdn = ConvertTo-Fqdn -DistinguishedName $DomainDN -ThisFqdn $ThisFqdn -CimCache $CimCache @LoggingParams
                    if ($ThisPath -match "LDAP:\/\/$DomainFqdn\/") {
                        #Write-LogMsg @LogParams -Text " # Domain FQDN already found in the directory path: '$ThisPath'"
                        $ThisPath
                    } else {
                        $ThisPath -replace 'LDAP:\/\/', "LDAP://$DomainFqdn/"
                    }
                } else {
                    #Write-LogMsg @LogParams -Text " # Domain DN not found in the directory path: '$ThisPath'"
                    $ThisPath
                }
            } else {
                #Write-LogMsg @LogParams -Text " # Not an expected directory path: '$ThisPath'"
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
    [OutputType([System.DirectoryServices.DirectoryEntry[]], [PSCustomObject[]])]
    param (

        # Expecting a [System.DirectoryServices.DirectoryEntry] from the LDAP or WinNT providers, or a [PSCustomObject] imitation from Get-DirectoryEntry.
        # Must contain the objectSid property
        [Parameter(ValueFromPipeline)]
        $InputObject,

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Log messages which have not yet been written to disk
        [hashtable]$LogBuffer = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug'

    )
    
    <#
    begin {

        $LogParams = @{
            ThisHostname = $ThisHostname
            Type         = $DebugOutputStream
            Buffer       = $LogBuffer
            WhoAmI       = $WhoAmI
        }

    }
    #>

    process {

        ForEach ($Object in $InputObject) {

            $SID = $null
            $SamAccountName = $null
            $DomainObject = $null

            if ($null -eq $Object) {
                continue
            } elseif ($Object.objectSid.Value) {
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
            } elseif ($Object.objectSid) {
                [string]$SID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]$Object.objectSid, 0)
            }

            if ($Object.Domain.Sid) {
                #if ($Object.Domain.GetType().FullName -ne 'System.Management.Automation.PSMethod') {
                # This would only have come from Add-SidInfo in the first place
                # This means it was added with Add-Member in Get-DirectoryEntry for the root of the computer's directory
                if ($null -eq $SID) {
                    [string]$SID = $Object.Domain.Sid
                }
                $DomainObject = $Object.Domain
                #}
            }
            if (-not $DomainObject) {

                # The SID of the domain is the SID of the user minus the last block of numbers
                $DomainSid = $SID.Substring(0, $Sid.LastIndexOf("-"))

                # Lookup other information about the domain using its SID as the key
                $DomainObject = $DomainsBySid[$DomainSid]
            }

            #Write-LogMsg @LogParams -Text "$SamAccountName`t$SID"

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
    #>

    param (

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
function ConvertFrom-IdentityReferenceResolved {

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
        ConvertFrom-IdentityReferenceResolved

        Incomplete example but it shows the chain of functions to generate the expected input for this
    #>

    [OutputType([void])]

    param (

        # The NTFS AccessControlEntry object(s), grouped by their IdentityReference property
        # TODO: Use System.Security.Principal.NTAccount instead
        [Parameter(ValueFromPipeline)]
        [string]$IdentityReference,

        # Do not get group members
        [switch]$NoGroupMembers,

        # Cache of access control entries keyed by their resolved identities
        [hashtable]$ACEsByResolvedID = ([hashtable]::Synchronized(@{})),

        # Thread-safe hashtable to use for caching directory entries and avoiding duplicate directory queries
        [hashtable]$PrincipalById = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

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

        # The current domain
        # Can be passed as a parameter to reduce calls to Get-CurrentDomain
        [string]$CurrentDomain = (Get-CurrentDomain)

    )

    if ($null -eq $PrincipalById[$IdentityReference]) {

        $LogParams = @{
            ThisHostname = $ThisHostname
            Type         = $DebugOutputStream
            Buffer       = $LogBuffer
            WhoAmI       = $WhoAmI
        }

        $LoggingParams = @{
            ThisHostname = $ThisHostname
            LogBuffer    = $LogBuffer
            WhoAmI       = $WhoAmI
        }

        $AccessControlEntries = $ACEsByResolvedID[$IdentityReference]

        #Write-LogMsg @LogParams -Text " # ADSI Principal cache miss for '$IdentityReference'"
        $split = $IdentityReference.Split('\')
        $DomainNetBIOS = $split[0]
        $SamAccountNameOrSid = $split[1]

        $WellKnownSidParams = @{
            IdentityReference = $SamAccountNameOrSid
            DomainsByNetbios  = $DomainsByNetbios
            DomainNetBios     = $DomainNetBIOS
        }

        $CachedWellKnownSID = Find-CachedWellKnownSID @WellKnownSidParams

        if ($CachedWellKnownSID) {

            $FakeDirectoryEntryParams = @{
                DirectoryPath = "WinNT://$DomainNetBIOS/$($CachedWellKnownSID.Name)"
                InputObject   = $CachedWellKnownSID
            }

            $DirectoryEntry = New-FakeDirectoryEntry @FakeDirectoryEntryParams

        } else {
            Write-LogMsg @LogParams -Text " # Known SID cache miss for '$IdentityReference' on '$DomainNetBIOS'"
        }

        if ($null -eq $DirectoryEntry) {


            $GetDirectoryEntryParams = @{
                DirectoryEntryCache = $DirectoryEntryCache
                DomainsByNetbios    = $DomainsByNetbios
                DomainsBySid        = $DomainsBySid
                DomainsByFqdn       = $DomainsByFqdn
                ThisFqdn            = $ThisFqdn
                CimCache            = $CimCache
                DebugOutputStream   = $DebugOutputStream
            }

            $SearchDirectoryParams = @{
                CimCache            = $CimCache
                DebugOutputStream   = $DebugOutputStream
                DirectoryEntryCache = $DirectoryEntryCache
                DomainsByNetbios    = $DomainsByNetbios
                ThisFqdn            = $ThisFqdn
            }

            if (

                $null -ne $SamAccountNameOrSid -and
                @($AccessControlEntries.AdsiProvider)[0] -eq 'LDAP'

            ) {

                Write-LogMsg @LogParams -Text " # '$IdentityReference' is a domain security principal"

                if ($DomainNetbiosCacheResult) {

                    #Write-LogMsg @LogParams -Text " # Domain NetBIOS cache hit for '$DomainNetBIOS' for '$IdentityReference'"
                    $DomainDn = $DomainNetbiosCacheResult.DistinguishedName
                    $SearchDirectoryParams['DirectoryPath'] = "LDAP://$($DomainNetbiosCacheResult.Dns)/$DomainDn"

                } else {

                    #Write-LogMsg @LogParams -Text " # Domain NetBIOS cache miss for '$DomainNetBIOS' for '$IdentityReference'"

                    if ( -not [string]::IsNullOrEmpty($DomainNetBIOS) ) {
                        #$DomainDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -DomainsByNetbios $DomainsByNetbios @LoggingParams
                    }

                    $FqdnParams = @{
                        DirectoryPath = "LDAP://$DomainNetBIOS"
                        ThisFqdn      = $ThisFqdn
                        CimCache      = $CimCache
                    }
                    $SearchDirectoryParams['DirectoryPath'] = Add-DomainFqdnToLdapPath @FqdnParams @LogParams

                }

                # Search the domain for the principal
                $SearchDirectoryParams['Filter'] = "(samaccountname=$SamAccountNameOrSid)"

                $SearchDirectoryParams['PropertiesToLoad'] = @(
                    'objectClass',
                    'objectSid',
                    'samAccountName',
                    'distinguishedName',
                    'name',
                    'grouptype',
                    'description',
                    'managedby',
                    'member',
                    'Department',
                    'Title',
                    'primaryGroupToken'
                )

                Write-LogMsg @LogParams -Text 'Search-Directory' -Expand $SearchDirectoryParams, $LoggingParams

                try {
                    $DirectoryEntry = Search-Directory @SearchDirectoryParams @LoggingParams
                } catch {

                    $LogParams['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
                    Write-LogMsg @LogParams -Text " # Did not find '$IdentityReference' in a directory search: $($_.Exception.Message.Trim())"
                    $LogParams['Type'] = $DebugOutputStream

                }

            } elseif (
                $IdentityReference.Substring(0, $IdentityReference.LastIndexOf('-') + 1) -eq $CurrentDomain.SIDString
            ) {

                Write-LogMsg @LogParams -Text " # '$IdentityReference' is an unresolved SID from the current domain"

                # Get the distinguishedName and netBIOSName of the current domain.  This also determines whether the domain is online.
                $DomainDN = $CurrentDomain.distinguishedName.Value
                $DomainFQDN = ConvertTo-Fqdn -DistinguishedName $DomainDN -ThisFqdn $ThisFqdn -CimCache $CimCache @LoggingParams
                $SearchDirectoryParams['DirectoryPath'] = "LDAP://$DomainFQDN/cn=partitions,cn=configuration,$DomainDn"
                $SearchDirectoryParams['Filter'] = "(&(objectcategory=crossref)(dnsroot=$DomainFQDN)(netbiosname=*))"
                $SearchDirectoryParams['PropertiesToLoad'] = 'netbiosname'
                Write-LogMsg @LogParams -Text 'Search-Directory' -Expand $SearchDirectoryParams, $LoggingParams
                $DomainCrossReference = Search-Directory @SearchDirectoryParams @LoggingParams

                if ($DomainCrossReference.Properties ) {

                    Write-LogMsg @LogParams -Text " # The domain '$DomainFQDN' is online for '$IdentityReference'"
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
                $SearchDirectoryParams['DirectoryPath'] = "LDAP://$DomainFQDN/$DomainDn"
                $SearchDirectoryParams['Filter'] = "(objectsid=$ObjectSid)"
                $SearchDirectoryParams['PropertiesToLoad'] = @(
                    'objectClass',
                    'objectSid',
                    'samAccountName',
                    'distinguishedName',
                    'name',
                    'grouptype',
                    'description',
                    'managedby',
                    'member',
                    'Department',
                    'Title',
                    'primaryGroupToken'
                )

                Write-LogMsg @LogParams -Text 'Search-Directory' -Expand $SearchDirectoryParams, $LoggingParams

                try {
                    $DirectoryEntry = Search-Directory @SearchDirectoryParams @LoggingParams
                } catch {

                    $LogParams['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
                    Write-LogMsg @LogParams -Text " # Couldn't find '$IdentityReference' in a directory search: $($_.Exception.Message.Trim())"
                    $LogParams['Type'] = $DebugOutputStream

                }

            } else {

                Write-LogMsg @LogParams -Text " # '$IdentityReference' is a local security principal or unresolved SID."

                if ($null -eq $SamAccountNameOrSid) { $SamAccountNameOrSid = $IdentityReference }

                if ($SamAccountNameOrSid -like "S-1-*") {

                    if ($DomainNetBIOS -in 'APPLICATION PACKAGE AUTHORITY', 'BUILTIN', 'NT SERVICE') {

                        Write-LogMsg @LogParams -Text " # '$($IdentityReference)' is a Capability SID or Service SID which could not be resolved to a friendly name."

                        $Known = Get-KnownSid -SID $SamAccountNameOrSid

                        $FakeDirectoryEntryParams = @{
                            DirectoryPath = "WinNT://$DomainNetBIOS/$SamAccountNameOrSid"
                            InputObject   = $Known
                        }

                        $DirectoryEntry = New-FakeDirectoryEntry @FakeDirectoryEntryParams

                    } else {

                        Write-LogMsg @LogParams -Text " # '$($IdentityReference)' is an unresolved SID"

                        # The SID of the domain is the SID of the user minus the last block of numbers
                        $DomainSid = $SamAccountNameOrSid.Substring(0, $SamAccountNameOrSid.LastIndexOf("-"))

                        # Determine if SID belongs to current domain
                        if ($DomainSid -eq $CurrentDomain.SIDString) {
                            Write-LogMsg @LogParams -Text " # '$($IdentityReference)' belongs to the current domain.  Could be a deleted user.  ?possibly a foreign security principal corresponding to an offline trusted domain or deleted user in the trusted domain?"
                        } else {
                            Write-LogMsg @LogParams -Text " # '$($IdentityReference)' does not belong to the current domain. Could be a local security principal or belong to an unresolvable domain."
                        }

                        # Lookup other information about the domain using its SID as the key
                        $DomainObject = $DomainsBySID[$DomainSid]

                        if ($DomainObject) {
                            $GetDirectoryEntryParams['DirectoryPath'] = "WinNT://$($DomainObject.Dns)/Users"
                            $DomainNetBIOS = $DomainObject.Netbios
                            $DomainDN = $DomainObject.DistinguishedName
                        } else {
                            $GetDirectoryEntryParams['DirectoryPath'] = "WinNT://$DomainNetBIOS/Users"
                            $DomainDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -DomainsByNetbios $DomainsByNetbios @LoggingParams
                        }

                        Write-LogMsg @LogParams -Text "Get-DirectoryEntry" -Expand $GetDirectoryEntryParams, $LoggingParams

                        try {
                            $UsersGroup = Get-DirectoryEntry @GetDirectoryEntryParams @LoggingParams
                        } catch {
                            $LogParams['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
                            Write-LogMsg @LogParams -Text "Couldn't get '$($GetDirectoryEntryParams['DirectoryPath'])' using PSRemoting. Error: $_"
                            $LogParams['Type'] = $DebugOutputStream
                        }

                        $MembersOfUsersGroup = Get-WinNTGroupMember -DirectoryEntry $UsersGroup -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn -CimCache $CimCache @LoggingParams

                        $DirectoryEntry = $MembersOfUsersGroup |
                        Where-Object -FilterScript { ($SamAccountNameOrSid -eq $([System.Security.Principal.SecurityIdentifier]::new([byte[]]$_.Properties['objectSid'], 0))) }

                    }

                } else {

                    Write-LogMsg @LogParams -Text " # '$IdentityReference' is a local security principal"
                    $DomainNetbiosCacheResult = $DomainsByNetbios[$DomainNetBIOS]

                    if ($DomainNetbiosCacheResult) {
                        $GetDirectoryEntryParams['DirectoryPath'] = "WinNT://$($DomainNetbiosCacheResult.Dns)/$SamAccountNameOrSid"
                    } else {
                        $GetDirectoryEntryParams['DirectoryPath'] = "WinNT://$DomainNetBIOS/$SamAccountNameOrSid"
                    }

                    $GetDirectoryEntryParams['PropertiesToLoad'] = @(
                        'members',
                        'objectClass',
                        'objectSid',
                        'samAccountName',
                        'distinguishedName',
                        'name',
                        'grouptype',
                        'description',
                        'managedby',
                        'member',
                        'Department',
                        'Title',
                        'primaryGroupToken'
                    )

                    Write-LogMsg @LogParams -Text "Get-DirectoryEntry" -Expand $GetDirectoryEntryParams, $LoggingParams

                    try {
                        $DirectoryEntry = Get-DirectoryEntry @GetDirectoryEntryParams @LoggingParams
                    } catch {

                        $LogParams['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
                        Write-LogMsg @LogParams -Text " # '$($GetDirectoryEntryParams['DirectoryPath'])' Couldn't be resolved for '$IdentityReference'. Error: $($_.Exception.Message.Trim())"
                        $LogParams['Type'] = $DebugOutputStream

                    }

                }

            }

        }

        $PropertiesToAdd = @{
            DomainDn            = $DomainDn
            DomainNetbios       = $DomainNetBIOS
            ResolvedAccountName = $IdentityReference
        }

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
                    Write-LogMsg @LogParams -Text " # '$($DirectoryEntry.Path)' is an LDAP security principal for '$IdentityReference'"
                    $Members = (Get-AdsiGroupMember -Group $DirectoryEntry -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LoggingParams).FullMembers

                } else {

                    Write-LogMsg @LogParams -Text " # '$($DirectoryEntry.Path)' is a WinNT security principal for '$IdentityReference'"

                    if ( $DirectoryEntry.SchemaClassName -in @('group', 'SidTypeWellKnownGroup', 'SidTypeAlias')) {

                        Write-LogMsg @LogParams -Text " # '$($DirectoryEntry.Path)' is a WinNT group for '$IdentityReference'"
                        $Members = Get-WinNTGroupMember -DirectoryEntry $DirectoryEntry -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LoggingParams

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
                                    Dns     = $DomainNetBIOS
                                    Netbios = $DomainNetBIOS
                                    Sid     = @($SamAccountNameOrSid -split '-')[-1]
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
                        $PrincipalById[$ResolvedAccountName] = [PSCustomObject]$OutputProperties
                        $ACEsByResolvedID[$ResolvedAccountName] = $AccessControlEntries
                        $ResolvedAccountName

                    }

                }

                Write-LogMsg @LogParams -Text " # '$($DirectoryEntry.Path)' has $(($Members | Measure-Object).Count) members for '$IdentityReference'"

            }

            $PropertiesToAdd['Members'] = $GroupMembers

        } else {

            $LogParams['Type'] = 'Verbose' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
            Write-LogMsg @LogParams -Text " # '$IdentityReference' Couldn't be matched to a DirectoryEntry"
            $LogParams['Type'] = $DebugOutputStream

        }

        $PrincipalById[$IdentityReference] = [PSCustomObject]$PropertiesToAdd

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
        .EXAMPLE
        $DirectoryEntry = [adsi]("WinNT://$(hostname)")
        $DirectoryEntry.Properties.Keys |
        ForEach-Object {
            ConvertFrom-PropertyValueCollectionToString -PropertyValueCollection $DirectoryEntry.Properties[$_]
        }

        For each property in a DirectoryEntry, convert its corresponding PropertyValueCollection to a string
    #>
    param (
        [System.DirectoryServices.PropertyValueCollection]$PropertyValueCollection
    )
    $SubType = & { $PropertyValueCollection.Value.GetType().FullName } 2>$null
    switch ($SubType) {
        'System.Byte[]' { ConvertTo-DecStringRepresentation -ByteArray $PropertyValueCollection.Value ; break }
        default { "$($PropertyValueCollection.Value)" }
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
    param (
        [System.DirectoryServices.ResultPropertyValueCollection]$ResultPropertyValueCollection
    )
    $SubType = & { $ResultPropertyValueCollection.Value.GetType().FullName } 2>$null
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
    .NOTES
    # TODO: There is a faster way than Select-Object, just need to dig into the default formatting of SearchResult to see how to get those properties
    #>

    param (
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
# This function is not currently in use by Export-Permission

function ConvertFrom-SidString {
    #[OutputType([System.Security.Principal.NTAccount])]
    param (
        [string]$SID,

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

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
        [hashtable]$LogBuffer = ([hashtable]::Synchronized(@{}))
    )

    $GetDirectoryEntryParams = @{
        DirectoryEntryCache = $DirectoryEntryCache
        DomainsByNetbios    = $DomainsByNetbios
        ThisFqdn            = $ThisFqdn
        ThisHostname        = $ThisHostname
        CimCache            = $CimCache
        LogBuffer         = $LogBuffer
        WhoAmI              = $WhoAmI
        DebugOutputStream   = $DebugOutputStream
    }

    #[System.Security.Principal.SecurityIdentifier]::new($SID)
    # Only works if SID is in the current domain...otherwise SID not found
    Get-DirectoryEntry -DirectoryPath "LDAP://<SID=$SID>" @GetDirectoryEntryParams

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
        ConvertTo-DistinguishedName -Domain 'CONTOSO'
        DC=ad,DC=contoso,DC=com

        Resolve the NetBIOS domain 'CONTOSO' to its distinguishedName 'DC=ad,DC=contoso,DC=com'
    #>
    [OutputType([System.String])]
    param (

        # NetBIOS name of the domain
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'NetBIOS')]
        [string[]]$Domain,

        [Parameter(ParameterSetName = 'NetBIOS')]
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

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

        Useful when that has been done already but the DomainsByFqdn and DomainsByNetbios caches have not been updated yet
        #>
        [string]$AdsiProvider,

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Log messages which have not yet been written to disk
        [hashtable]$LogBuffer = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug'

    )
    begin {

        $LogParams = @{
            ThisHostname = $ThisHostname
            Type         = $DebugOutputStream
            Buffer       = $LogBuffer
            WhoAmI       = $WhoAmI
        }

        $LoggingParams = @{
            ThisHostname = $ThisHostname
            LogBuffer    = $LogBuffer
            WhoAmI       = $WhoAmI
        }

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
            $DomainCacheResult = $DomainsByNetbios[$ThisDomain]
            if ($DomainCacheResult) {
                #Write-LogMsg @LogParams -Text " # Domain NetBIOS cache hit for '$ThisDomain'"
                $DomainCacheResult.DistinguishedName
            } else {
                #Write-LogMsg @LogParams -Text " # Domain NetBIOS cache miss for '$ThisDomain'. Available keys: $($DomainsByNetBios.Keys -join ',')"
                Write-LogMsg @LogParams -Text "`$IADsNameTranslateComObject = New-Object -comObject 'NameTranslate' # For '$ThisDomain'"
                $IADsNameTranslateComObject = New-Object -comObject "NameTranslate"
                Write-LogMsg @LogParams -Text "`$IADsNameTranslateInterface = `$IADsNameTranslateComObject.GetType() # For '$ThisDomain'"
                $IADsNameTranslateInterface = $IADsNameTranslateComObject.GetType()
                Write-LogMsg @LogParams -Text "`$null = `$IADsNameTranslateInterface.InvokeMember('Init', 'InvokeMethod', `$Null, `$IADsNameTranslateComObject, ($ChosenInitType, `$Null)) # For '$ThisDomain'"
                # Handle errors for this method
                #    Exception calling "InvokeMember" with "5" argument(s): "The specified domain either does not exist or could not be contacted. (0x8007054B)"
                try {
                    $null = $IADsNameTranslateInterface.InvokeMember("Init", "InvokeMethod", $Null, $IADsNameTranslateComObject, ($ChosenInitType, $Null))
                } catch {
                    Write-LogMsg @LogParams -Text " #Error: $($_.Exception.Message) # For $ThisDomain"
                    continue
                }

                # For a non-domain-joined system there is no DistinguishedName for the domain
                # Suppress errors when calling these next 2 methods
                #     Exception calling "InvokeMember" with "5" argument(s): "Name translation: Could not find the name or insufficient right to see name. (Exception from HRESULT: 0x80072116)"
                Write-LogMsg @LogParams -Text "`$null = `$IADsNameTranslateInterface.InvokeMember('Set', 'InvokeMethod', `$Null, `$IADsNameTranslateComObject, ($ChosenInputType, '$ThisDomain\')) # For '$ThisDomain'"
                $null = { $IADsNameTranslateInterface.InvokeMember("Set", "InvokeMethod", $Null, $IADsNameTranslateComObject, ($ChosenInputType, "$ThisDomain\")) } 2>$null
                #     Exception calling "InvokeMember" with "5" argument(s): "Unspecified error (Exception from HRESULT: 0x80004005 (E_FAIL))"
                Write-LogMsg @LogParams -Text "`$IADsNameTranslateInterface.InvokeMember('Get', 'InvokeMethod', `$Null, `$IADsNameTranslateComObject, $ChosenOutputType) # For '$ThisDomain'"
                $null = { $null = { $IADsNameTranslateInterface.InvokeMember("Get", "InvokeMethod", $Null, $IADsNameTranslateComObject, $ChosenOutputType) } 2>$null } 2>$null
            }
        }
        ForEach ($ThisDomain in $DomainFQDN) {
            $DomainCacheResult = $DomainsByFqdn[$ThisDomain]
            if ($DomainCacheResult) {
                #Write-LogMsg @LogParams -Text " # Domain FQDN cache hit for '$ThisDomain'"
                $DomainCacheResult.DistinguishedName
            } else {

                #Write-LogMsg @LogParams -Text " # Domain FQDN cache miss for '$ThisDomain'"

                if (-not $PSBoundParameters.ContainsKey('AdsiProvider')) {
                    $AdsiProvider = Find-AdsiProvider -AdsiServer $ThisDomain @LoggingParams
                }

                if ($AdsiProvider -ne 'WinNT') {
                    "dc=$($ThisDomain -replace '\.',',dc=')"
                }
            }
        }
    }
}
function ConvertTo-DomainNetBIOS {
    param (
        [string]$DomainFQDN,

        [string]$AdsiProvider,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Log messages which have not yet been written to disk
        [hashtable]$LogBuffer = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug'

    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        Buffer       = $LogBuffer
        WhoAmI       = $WhoAmI
    }

    $DomainCacheResult = $DomainsByFqdn[$DomainFQDN]

    if ($DomainCacheResult) {

        #Write-LogMsg @LogParams -Text " # Domain FQDN cache hit for '$DomainFQDN'"
        return $DomainCacheResult.Netbios

    }

    #Write-LogMsg @LogParams -Text " # Domain FQDN cache miss for '$DomainFQDN'"

    if ($AdsiProvider -eq 'LDAP') {

        $GetDirectoryEntryParams = @{
            DirectoryEntryCache = $DirectoryEntryCache
            DomainsByNetbios    = $DomainsByNetbios
            DomainsBySid        = $DomainsBySid
            ThisFqdn            = $ThisFqdn
            ThisHostname        = $ThisHostname
            CimCache            = $CimCache
            LogBuffer           = $LogBuffer
            WhoAmI              = $WhoAmI
            DebugOutputStream   = $DebugOutputStream
        }

        $RootDSE = Get-DirectoryEntry -DirectoryPath "LDAP://$DomainFQDN/rootDSE" @GetDirectoryEntryParams
        Write-LogMsg @LogParams -Text "`$RootDSE.InvokeGet('defaultNamingContext')"
        $DomainDistinguishedName = $RootDSE.InvokeGet("defaultNamingContext")
        Write-LogMsg @LogParams -Text "`$RootDSE.InvokeGet('configurationNamingContext')"
        $ConfigurationDN = $rootDSE.InvokeGet("configurationNamingContext")
        $partitions = Get-DirectoryEntry -DirectoryPath "LDAP://$DomainFQDN/cn=partitions,$ConfigurationDN" @GetDirectoryEntryParams

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

    param (

        # Domain DNS name to convert to the domain's SID
        [Parameter(Mandatory)]
        [string]$DomainDnsName,

        <#
        Hashtable containing cached directory entries so they don't have to be retrieved from the directory again

        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

        <#
        AdsiProvider (WinNT or LDAP) of the servers associated with the provided FQDNs or NetBIOS names

        This parameter can be used to reduce calls to Find-AdsiProvider

        Useful when that has been done already but the DomainsByFqdn and DomainsByNetbios caches have not been updated yet
        #>
        [string]$AdsiProvider,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

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

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug'

    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        Buffer       = $LogBuffer
        WhoAmI       = $WhoAmI
    }

    $LoggingParams = @{
        ThisHostname = $ThisHostname
        LogBuffer    = $LogBuffer
        WhoAmI       = $WhoAmI
    }


    $CacheResult = $DomainsByFqdn[$DomainDnsName]
    if ($CacheResult) {

        #Write-LogMsg @LogParams -Text " # Domain FQDN cache hit for '$DomainDnsName'"
        return $CacheResult.Sid

    }
    #Write-LogMsg @LogParams -Text " # Domain FQDN cache miss for '$DomainDnsName'"

    if (
        -not $AdsiProvider -or
        $AdsiProvider -eq 'LDAP'
    ) {

        $GetDirectoryEntryParams = @{
            DirectoryEntryCache = $DirectoryEntryCache
            DomainsByNetbios    = $DomainsByNetbios
            DomainsBySid        = $DomainsBySid
            ThisFqdn            = $ThisFqdn
            CimCache            = $CimCache
            DebugOutputStream   = $DebugOutputStream
        }

        $DomainDirectoryEntry = Get-DirectoryEntry -DirectoryPath "LDAP://$DomainDnsName" @GetDirectoryEntryParams @LoggingParams
        try {
            $null = $DomainDirectoryEntry.RefreshCache('objectSid')
        } catch {
            Write-LogMsg @LogParams -Text " # LDAP connection failed to '$DomainDnsName' - $($_.Exception.Message)"
            Write-LogMsg @LogParams -Text "Find-LocalAdsiServerSid -ComputerName '$DomainDnsName'"
            $DomainSid = Find-LocalAdsiServerSid -ComputerName $DomainDnsName -ThisFqdn $ThisFqdn -CimCache $CimCache @LoggingParams
            return $DomainSid
        }
    } else {
        Write-LogMsg @LogParams -Text "Find-LocalAdsiServerSid -ComputerName '$DomainDnsName'"
        $DomainSid = Find-LocalAdsiServerSid -ComputerName $DomainDnsName -ThisFqdn $ThisFqdn -CimCache $CimCache @LoggingParams
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

    Write-LogMsg @LogParams -Text "[System.Security.Principal.SecurityIdentifier]::new([byte[]]@($($SidByteArray -join ',')), 0).ToString()"
    $DomainSid = [System.Security.Principal.SecurityIdentifier]::new($SidByteArray, 0).ToString()

    if ($DomainSid) {
        return $DomainSid
    } else {
        $LogParams['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
        Write-LogMsg @LogParams -Text " # LDAP Domain: '$DomainDnsName' has an invalid SID - $($_.Exception.Message)"
        $LogParams['Type'] = $DebugOutputStream
    }

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
        ConvertTo-Fqdn -DistinguishedName 'DC=ad,DC=contoso,DC=com'
        ad.contoso.com

        Convert the domain distinguishedName 'DC=ad,DC=contoso,DC=com' to its FQDN format 'ad.contoso.com'
    #>
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

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

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
    begin {

        $LogParams = @{
            ThisHostname = $ThisHostname
            Type         = $DebugOutputStream
            Buffer       = $LogBuffer
            WhoAmI       = $WhoAmI
        }

        $LoggingParams = @{
            ThisHostname = $ThisHostname
            LogBuffer    = $LogBuffer
            WhoAmI       = $WhoAmI
        }

    }
    process {
        ForEach ($DN in $DistinguishedName) {
            $DN -replace ',DC=', '.' -replace 'DC=', ''
        }

        ForEach ($ThisNetBios in $NetBIOS) {
            $DomainObject = $DomainsByNetbios[$DomainNetBIOS]

            if (
                -not $DomainObject -and
                -not [string]::IsNullOrEmpty($DomainNetBIOS)
            ) {
                #Write-LogMsg @LogParams -Text " # Domain NetBIOS cache miss for '$DomainNetBIOS'"
                $DomainObject = Get-AdsiServer -Netbios $DomainNetBIOS -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LoggingParams
                $DomainsByNetbios[$DomainNetBIOS] = $DomainObject
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
        ConvertTo-SidByteArray -SidString $SID

        Convert the SID string to a byte array
    #>
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
        [System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrators') | Get-AdsiGroupMember | Expand-AdsiGroupMember

        Need to fix example and add notes
    #>
    [OutputType([System.DirectoryServices.DirectoryEntry])]
    param (

        # Expecting a DirectoryEntry from the LDAP or WinNT providers, or a PSObject imitation from Get-DirectoryEntry
        [parameter(ValueFromPipeline)]
        $DirectoryEntry,

        # Properties of the group members to retrieve
        [string[]]$PropertiesToLoad = (@('Department', 'description', 'distinguishedName', 'grouptype', 'managedby', 'member', 'name', 'objectClass', 'objectSid', 'operatingSystem', 'primaryGroupToken', 'samAccountName', 'Title')),

        <#
        Hashtable containing cached directory entries so they don't need to be retrieved from the directory again

        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid,

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
    begin {

        $LogParams = @{
            ThisHostname = $ThisHostname
            Type         = $DebugOutputStream
            Buffer       = $LogBuffer
            WhoAmI       = $WhoAmI
        }

        $LoggingParams = @{
            ThisHostname = $ThisHostname
            LogBuffer    = $LogBuffer
            WhoAmI       = $WhoAmI
        }

        # The DomainsBySID cache must be populated with trusted domains in order to translate foreign security principals
        if ( $DomainsBySid.Keys.Count -lt 1 ) {
            Write-LogMsg @LogParams -Text "# No valid DomainsBySid cache found"
            $DomainsBySid = ([hashtable]::Synchronized(@{}))

            $GetAdsiServerParams = @{
                DirectoryEntryCache = $DirectoryEntryCache
                DomainsByNetbios    = $DomainsByNetbios
                DomainsBySid        = $DomainsBySid
                DomainsByFqdn       = $DomainsByFqdn
                ThisFqdn            = $ThisFqdn
                CimCache            = $CimCache
            }

            Get-TrustedDomain |
            ForEach-Object {
                Write-LogMsg @LogParams -Text "Get-AdsiServer -Fqdn $($_.DomainFqdn)"
                $null = Get-AdsiServer -Fqdn $_.DomainFqdn @GetAdsiServerParams @LoggingParams
            }
        } else {
            Write-LogMsg @LogParams -Text "# Valid DomainsBySid cache found"
        }

        $CacheParams = @{
            DirectoryEntryCache = $DirectoryEntryCache
            DomainsByNetbios    = $DomainsByNetbios
            DomainsBySid        = $DomainsBySid
        }

        $i = 0
    }

    process {

        ForEach ($Entry in $DirectoryEntry) {

            $i++

            #$status = ("$(Get-Date -Format s)`t$ThisHostname`tExpand-AdsiGroupMember`tStatus: Using ADSI to get info on group member $i`: " + $Entry.Name)
            #Write-LogMsg @LogParams -Text "$status"

            $Principal = $null

            if ($Entry.objectClass -contains 'foreignSecurityPrincipal') {

                if ($Entry.distinguishedName.Value -match '(?>^CN=)(?<SID>[^,]*)') {

                    [string]$SID = $Matches.SID

                    #The SID of the domain is the SID of the user minus the last block of numbers
                    $DomainSid = $SID.Substring(0, $Sid.LastIndexOf("-"))
                    $Domain = $DomainsBySid[$DomainSid]

                    $GetDirectoryEntryParams = @{
                        ThisFqdn          = $ThisFqdn
                        CimCache          = $CimCache
                        DebugOutputStream = $DebugOutputStream
                    }

                    $Principal = Get-DirectoryEntry -DirectoryPath "LDAP://$($Domain.Dns)/<SID=$SID>" @GetDirectoryEntryParams @CacheParams @LoggingParams

                    try {
                        $null = $Principal.RefreshCache($PropertiesToLoad)
                    } catch {
                        #$Success = $false
                        $Principal = $Entry
                        Write-LogMsg @LogParams -Text " # SID '$SID' could not be retrieved from domain '$Domain'"
                    }

                    # Recursively enumerate group members
                    if ($Principal.properties['objectClass'].Value -contains 'group') {
                        Write-LogMsg @LogParams -Text "'$($Principal.properties['name'])' is a group in '$Domain'"
                        $AdsiGroupWithMembers = Get-AdsiGroupMember -Group $Principal -CimCache $CimCache -DomainsByFqdn $DomainsByFqdn -ThisFqdn $ThisFqdn @CacheParams @LoggingParams
                        $Principal = Expand-AdsiGroupMember -DirectoryEntry $AdsiGroupWithMembers.FullMembers -CimCache $CimCache -DomainsByFqdn $DomainsByFqdn -ThisFqdn $ThisFqdn -ThisHostName $ThisHostName @CacheParams

                    }

                }

            } else {
                $Principal = $Entry
            }

            Add-SidInfo -InputObject $Principal -DomainsBySid $DomainsBySid @LoggingParams

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

        Need to fix example and add notes
    #>
    [OutputType([System.DirectoryServices.DirectoryEntry])]
    param (

        # Expecting a DirectoryEntry from the WinNT provider, or a PSObject imitation from Get-DirectoryEntry
        [Parameter(ValueFromPipeline)]
        $DirectoryEntry,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

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

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug'

    )

    begin {

        $LogParams = @{
            ThisHostname = $ThisHostname
            Type         = $DebugOutputStream
            Buffer       = $LogBuffer
            WhoAmI       = $WhoAmI
        }

        $LoggingParams = @{
            ThisHostname = $ThisHostname
            LogBuffer    = $LogBuffer
            WhoAmI       = $WhoAmI
        }

    }

    process {

        ForEach ($ThisEntry in $DirectoryEntry) {

            if (!($ThisEntry.Properties)) {

                $LogParams['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
                Write-LogMsg @LogParams -Text " # '$ThisEntry' has no properties # For '$($ThisEntry.Path)'"
                $LogParams['Type'] = $DebugOutputStream

            } elseif ($ThisEntry.Properties['objectClass'] -contains 'group') {

                Write-LogMsg @LogParams -Text " # Is an ADSI group # For '$($ThisEntry.Path)'"
                $AdsiGroup = Get-AdsiGroup -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DirectoryPath $ThisEntry.Path -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LoggingParams
                Add-SidInfo -InputObject $AdsiGroup.FullMembers -DomainsBySid $DomainsBySid @LoggingParams

            } else {

                if ($ThisEntry.SchemaClassName -eq 'group') {

                    Write-LogMsg @LogParams -Text " # Is a WinNT group # For '$($ThisEntry.Path)'"

                    if ($ThisEntry.GetType().FullName -eq 'System.Collections.Hashtable') {

                        Write-LogMsg @LogParams -Text " # Is a special group with no direct memberships # '$($ThisEntry.Path)'"
                        Add-SidInfo -InputObject $ThisEntry -DomainsBySid $DomainsBySid @LoggingParams

                    } else {
                        # Commented while troubleshooting to avoid infinite loop. This line only seems necessary to handle nested WinNT groups; is that even possible?
                        # After commenting, it seems local group members are still being retrieved as expected.
                        #Get-WinNTGroupMember -DirectoryEntry $ThisEntry -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LoggingParams
                    }

                } else {

                    Write-LogMsg @LogParams -Text " # Is a user account # For '$($ThisEntry.Path)'"
                    Add-SidInfo -InputObject $ThisEntry -DomainsBySid $DomainsBySid @LoggingParams

                }

            }

        }

    }

}
function Find-AdsiProvider {
    <#
        .SYNOPSIS
        Determine whether a directory server is an LDAP or a WinNT server
        .DESCRIPTION
        Uses the ADSI provider to attempt to query the server using LDAP first, then WinNT second
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
    [OutputType([System.String])]

    param (

        # IP address or hostname of the directory server whose ADSI provider type to determine
        [string]$AdsiServer,

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

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

    $AdsiProvider = $null

    $CommandParameters = @{
        ComputerName      = $AdsiServer
        Namespace         = 'ROOT/StandardCimv2'
        Query             = 'Select * From MSFT_NetTCPConnection Where LocalPort = 389'
        KeyProperty       = 'LocalPort'
        CimCache          = $CimCache
        DebugOutputStream = $DebugOutputStream
        ErrorAction       = 'Ignore'
        LogBuffer         = $LogBuffer
        ThisFqdn          = $ThisFqdn
        ThisHostname      = $ThisHostname
        WhoAmI            = $WhoAmI
    }

    ###Write-LogMsg @Log -Text 'Get-CachedCimInstance' -Expand $CommandParameters

    if (Get-CachedCimInstance @CommandParameters) {
        #$AdsiPath = "LDAP://$AdsiServer"
        #Write-LogMsg @LogParams -Text "[System.DirectoryServices.DirectoryEntry]::Exists('$AdsiPath')"
        #try {
        #    $null = [System.DirectoryServices.DirectoryEntry]::Exists($AdsiPath)
        $AdsiProvider = 'LDAP'
        #} catch { Write-LogMsg @LogParams -Text " # $AdsiServer did not respond to LDAP" }
    }

    if (!$AdsiProvider) {
        #$AdsiPath = "WinNT://$AdsiServer"
        #Write-LogMsg @LogParams -Text "[System.DirectoryServices.DirectoryEntry]::Exists('$AdsiPath')"
        #try {
        #    $null = [System.DirectoryServices.DirectoryEntry]::Exists($AdsiPath)
        $AdsiProvider = 'WinNT'
        #} catch {
        #    Write-LogMsg @LogParams -Text " # $AdsiServer did not respond to WinNT"
        #}
    }
    #if (!$AdsiProvider) {
    #    $AdsiPath = "LDAP://$AdsiServer"
    #    Write-LogMsg @LogParams -Text "[System.DirectoryServices.DirectoryEntry]::Exists('$AdsiPath')"
    #    try {
    #        $null = [System.DirectoryServices.DirectoryEntry]::Exists($AdsiPath)
    #        $AdsiProvider = 'LDAP'
    #    } catch { Write-LogMsg @LogParams -Text " # $AdsiServer did not respond to LDAP" }
    #}
    #if (!$AdsiProvider) {
    #    $AdsiProvider = 'none'
    #}

    return $AdsiProvider

}
function Find-LocalAdsiServerSid {

    param (

        # Name of the computer to query via CIM
        [string]$ComputerName,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

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

    $CimParams = @{
        CimCache          = $CimCache
        ComputerName      = $ThisHostName
        DebugOutputStream = $DebugOutputStream
        LogBuffer         = $LogBuffer
        ThisFqdn          = $ThisFqdn
        ThisHostname      = $ThisHostname
        WhoAmI            = $WhoAmI
        Query             = "SELECT SID FROM Win32_UserAccount WHERE LocalAccount = 'True' AND SID LIKE 'S-1-5-21-%-500'"
        KeyProperty       = 'SID'
    }

    Write-LogMsg @Log -Text 'Get-CachedCimInstance' -Expand $CimParams
    $LocalAdminAccount = Get-CachedCimInstance @CimParams

    if (-not $LocalAdminAccount) {
        return
    }

    return $LocalAdminAccount.SID.Substring(0, $LocalAdminAccount.SID.LastIndexOf("-"))

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
        Get-AdsiGroup -DirectoryPath 'WinNT://WORKGROUP/localhost' -GroupName Administrators

        Get members of the local Administrators group
        .EXAMPLE
        Get-AdsiGroup -GroupName Administrators

        On a domain-joined computer, this will get members of the domain's Administrators group
        On a workgroup computer, this will get members of the local Administrators group
    #>
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
        [string[]]$PropertiesToLoad = (@('Department', 'description', 'distinguishedName', 'grouptype', 'managedby', 'member', 'name', 'objectClass', 'objectSid', 'operatingSystem', 'primaryGroupToken', 'samAccountName', 'Title')),

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

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
        [hashtable]$LogBuffer = ([hashtable]::Synchronized(@{}))

    )

    $GroupParams = @{
        DirectoryPath       = $DirectoryPath
        PropertiesToLoad    = $PropertiesToLoad
        DirectoryEntryCache = $DirectoryEntryCache
        DomainsByFqdn       = $DomainsByFqdn
        DomainsByNetbios    = $DomainsByNetbios
        DomainsBySid        = $DomainsBySid
        ThisHostname        = $ThisHostname
        LogBuffer           = $LogBuffer
        WhoAmI              = $WhoAmI
        ThisFqdn            = $ThisFqdn
        CimCache            = $CimCache
        DebugOutputStream   = $DebugOutputStream
    }

    $GroupMemberParams = @{
        PropertiesToLoad    = $PropertiesToLoad
        DirectoryEntryCache = $DirectoryEntryCache
        DomainsByFqdn       = $DomainsByFqdn
        DomainsByNetbios    = $DomainsByNetbios
        DomainsBySid        = $DomainsBySid
        ThisHostName        = $ThisHostName
        ThisFqdn            = $ThisFqdn
        LogBuffer           = $LogBuffer
        CimCache            = $CimCache
        WhoAmI              = $WhoAmI
    }

    switch -Regex ($DirectoryPath) {
        '^WinNT' {
            $GroupParams['DirectoryPath'] = "$DirectoryPath/$GroupName"
            $GroupMemberParams['DirectoryEntry'] = Get-DirectoryEntry @GroupParams
            $FullMembers = Get-WinNTGroupMember @GroupMemberParams
            break
        }
        '^$' {
            # This is expected for a workgroup computer
            $GroupParams['DirectoryPath'] = "WinNT://localhost/$GroupName"
            $GroupMemberParams['DirectoryEntry'] = Get-DirectoryEntry @GroupParams
            $FullMembers = Get-WinNTGroupMember @GroupMemberParams
            break
        }
        default {
            if ($GroupName) {
                $GroupParams['Filter'] = "(&(objectClass=group)(cn=$GroupName))"
            } else {
                $GroupParams['Filter'] = '(objectClass=group)'
            }
            $GroupMemberParams['Group'] = Search-Directory @GroupParams
            $FullMembers = Get-AdsiGroupMember @GroupMemberParams
        }
    }

    $FullMembers

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
        [System.DirectoryServices.DirectoryEntry]::new('LDAP://ad.contoso.com/CN=Administrators,CN=BuiltIn,DC=ad,DC=contoso,DC=com') | Get-AdsiGroupMember

        Get members of the domain Administrators group
    #>
    [OutputType([System.DirectoryServices.DirectoryEntry])]
    param (

        # Directory entry of the LDAP group whose members to get
        [Parameter(ValueFromPipeline)]
        $Group,

        # Properties of the group members to find in the directory
        [string[]]$PropertiesToLoad,

        <#
        Hashtable containing cached directory entries so they don't have to be retrieved from the directory again
        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

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

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug'

    )
    begin {

        $LogParams = @{
            ThisHostname = $ThisHostname
            Type         = $DebugOutputStream
            Buffer       = $LogBuffer
            WhoAmI       = $WhoAmI
        }

        $LoggingParams = @{
            ThisHostname = $ThisHostname
            LogBuffer    = $LogBuffer
            WhoAmI       = $WhoAmI
        }

        $PathRegEx = '(?<Path>LDAP:\/\/[^\/]*)'
        $DomainRegEx = '(?i)DC=\w{1,}?\b'

        $PropertiesToLoad += 'primaryGroupToken', 'objectSid', 'objectClass'

        $PropertiesToLoad = $PropertiesToLoad |
        Sort-Object -Unique

        $SearchParameters = @{
            PropertiesToLoad    = $PropertiesToLoad
            DirectoryEntryCache = $DirectoryEntryCache
            DomainsByNetbios    = $DomainsByNetbios
            CimCache            = $CimCache
            ThisFqdn            = $ThisFqdn
        }

        $CacheParams = @{
            DirectoryEntryCache = $DirectoryEntryCache
            DomainsByNetbios    = $DomainsByNetbios
            DomainsBySid        = $DomainsBySid
        }

    }
    process {

        foreach ($ThisGroup in $Group) {

            if (-not $ThisGroup.Properties['primaryGroupToken']) {
                $ThisGroup.RefreshCache('primaryGroupToken')
            }

            # The memberOf attribute does not reflect a user's Primary Group membership so the primaryGroupId attribute must be searched
            $primaryGroupIdFilter = "(primaryGroupId=$($ThisGroup.Properties['primaryGroupToken']))"

            if ($PrimaryGroupOnly) {
                $SearchParameters['Filter'] = $primaryGroupIdFilter
            } else {

                if ($NoRecurse) {
                    # Non-recursive search of the memberOf attribute
                    $MemberOfFilter = "(memberOf=$($ThisGroup.Properties['distinguishedname']))"
                } else {
                    # Recursive search of the memberOf attribute
                    $MemberOfFilter = "(memberOf:1.2.840.113556.1.4.1941:=$($ThisGroup.Properties['distinguishedname']))"
                }

                $SearchParameters['Filter'] = "(|$MemberOfFilter$primaryGroupIdFilter)"
            }

            if ($ThisGroup.Path -match $PathRegEx) {

                $SearchParameters['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath $Matches.Path -ThisFqdn $ThisFqdn -CimCache $CimCache @LoggingParams

                if ($ThisGroup.Path -match $DomainRegEx) {
                    $Domain = ([regex]::Matches($ThisGroup.Path, $DomainRegEx) | ForEach-Object { $_.Value }) -join ','
                    $SearchParameters['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath "LDAP://$Domain" -ThisFqdn $ThisFqdn -CimCache $CimCache @LoggingParams
                } else {
                    $SearchParameters['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath $ThisGroup.Path -ThisFqdn $ThisFqdn -CimCache $CimCache @LoggingParams
                }

            } else {
                $SearchParameters['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath $ThisGroup.Path -ThisFqdn $ThisFqdn -CimCache $CimCache @LoggingParams
            }

            Write-LogMsg @LogParams -Text "Search-Directory -DirectoryPath '$($SearchParameters['DirectoryPath'])' -Filter '$($SearchParameters['Filter'])'"

            $GroupMemberSearch = Search-Directory @SearchParameters
            Write-LogMsg @LogParams -Text " # '$($GroupMemberSearch.Count)' results for Search-Directory -DirectoryPath '$($SearchParameters['DirectoryPath'])' -Filter '$($SearchParameters['Filter'])'"

            if ($GroupMemberSearch.Count -gt 0) {

                $DirectoryEntryParams = @{
                    PropertiesToLoad  = $PropertiesToLoad
                    DomainsByFqdn     = $DomainsByFqdn
                    ThisFqdn          = $ThisFqdn
                    CimCache          = $CimCache
                    DebugOutputStream = $DebugOutputStream
                }

                $CurrentADGroupMembers = [System.Collections.Generic.List[System.DirectoryServices.DirectoryEntry]]::new()

                $MembersThatAreGroups = $GroupMemberSearch |
                Where-Object -FilterScript { $_.Properties['objectClass'] -contains 'group' }

                $DirectoryEntryParams = @{
                    PropertiesToLoad  = $PropertiesToLoad
                    DomainsByFqdn     = $DomainsByFqdn
                    ThisFqdn          = $ThisFqdn
                    CimCache          = $CimCache
                    DebugOutputStream = $DebugOutputStream
                }
                if ($MembersThatAreGroups.Count -gt 0) {
                    $FilterBuilder = [System.Text.StringBuilder]::new("(|")

                    ForEach ($ThisMember in $MembersThatAreGroups) {
                        $null = $FilterBuilder.Append("(primaryGroupId=$($ThisMember.Properties['primaryGroupToken'])))")
                    }

                    $null = $FilterBuilder.Append(")")
                    $PrimaryGroupFilter = $FilterBuilder.ToString()
                    $SearchParameters['Filter'] = $PrimaryGroupFilter
                    Write-LogMsg @LogParams -Text "Search-Directory -DirectoryPath '$($SearchParameters['DirectoryPath'])' -Filter '$($SearchParameters['Filter'])'"
                    $PrimaryGroupMembers = Search-Directory @SearchParameters

                    ForEach ($ThisMember in $PrimaryGroupMembers) {
                        $FQDNPath = Add-DomainFqdnToLdapPath -DirectoryPath $ThisMember.Path -ThisFqdn $ThisFqdn -CimCache $CimCache @LoggingParams
                        $DirectoryEntry = $null
                        Write-LogMsg @LogParams -Text "Get-DirectoryEntry -DirectoryPath '$FQDNPath'"

                        $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $FQDNPath @DirectoryEntryParams @CacheParams @LoggingParams
                        if ($DirectoryEntry) {
                            $null = $CurrentADGroupMembers.Add($DirectoryEntry)
                        }
                    }
                }

                ForEach ($ThisMember in $GroupMemberSearch) {
                    $FQDNPath = Add-DomainFqdnToLdapPath -DirectoryPath $ThisMember.Path -ThisFqdn $ThisFqdn -CimCache $CimCache @LoggingParams
                    $DirectoryEntry = $null
                    Write-LogMsg @LogParams -Text "Get-DirectoryEntry -DirectoryPath '$FQDNPath'"
                    $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $FQDNPath @DirectoryEntryParams @CacheParams @LoggingParams
                    if ($DirectoryEntry) {
                        $null = $CurrentADGroupMembers.Add($DirectoryEntry)
                    }
                }

            } else {
                $CurrentADGroupMembers = $null
            }

            Write-LogMsg @LogParams -Text "$($ThisGroup.Properties.name) has $(($CurrentADGroupMembers | Measure-Object).Count) members"

            $ProcessedGroupMembers = Expand-AdsiGroupMember -DirectoryEntry $CurrentADGroupMembers -CimCache $CimCache -DomainsByFqdn $DomainsByFqdn -ThisFqdn $ThisFqdn @CacheParams @LoggingParams

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
        Get-AdsiServer -Fqdn localhost

        Find the ADSI provider of the local computer
        .EXAMPLE
        Get-AdsiServer -Fqdn 'ad.contoso.com'

        Find the ADSI provider of the AD domain 'ad.contoso.com'
    #>

    [OutputType([System.String])]

    param (

        # IP address or hostname of the directory server whose ADSI provider type to determine
        [Parameter(ValueFromPipeline)]
        [string[]]$Fqdn,

        # NetBIOS name of the ADSI server whose information to determine
        [string[]]$Netbios,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName,AdsiProvider,Win32Accounts properties as values
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

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        [switch]$RemoveCimSession,

        # Output from Get-KnownSidHashTable
        [hashtable]$WellKnownSidBySid = (Get-KnownSidHashTable),

        # Output from Get-KnownSidHashTable but keyed by account Name
        [hashtable]$WellKnownSidByName = @{}

    )

    begin {

        $LogParams = @{
            ThisHostname = $ThisHostname
            Type         = $DebugOutputStream
            Buffer       = $LogBuffer
            WhoAmI       = $WhoAmI
        }

        $LogThis = @{
            ThisHostname = $ThisHostname
            LogBuffer    = $LogBuffer
            WhoAmI       = $WhoAmI
        }

        $CacheParams = @{
            DirectoryEntryCache = $DirectoryEntryCache
            DomainsByFqdn       = $DomainsByFqdn
            DomainsByNetbios    = $DomainsByNetbios
            DomainsBySid        = $DomainsBySid
        }

        $CimParams = @{
            CimCache          = $CimCache
            DebugOutputStream = $DebugOutputStream
            ThisFqdn          = $ThisFqdn
        }

    }

    process {

        ForEach ($DomainFqdn in $Fqdn) {

            $OutputObject = $DomainsByFqdn[$DomainFqdn]

            if ($OutputObject) {

                #Write-LogMsg @LogParams -Text " # Domain FQDN cache hit for '$DomainFqdn'"
                $OutputObject
                continue

            }

            #Write-LogMsg @LogParams -Text "Find-AdsiProvider -AdsiServer '$DomainFqdn' # Domain FQDN cache miss for '$DomainFqdn'"
            $AdsiProvider = Find-AdsiProvider -AdsiServer $DomainFqdn -CimCache $CimCache -ThisFqdn $ThisFqdn @LogThis
            $CacheParams['AdsiProvider'] = $AdsiProvider

            Write-LogMsg @LogParams -Text "ConvertTo-DistinguishedName -DomainFQDN '$DomainFqdn' -AdsiProvider '$AdsiProvider' # for '$DomainFqdn'"
            $DomainDn = ConvertTo-DistinguishedName -DomainFQDN $DomainFqdn -AdsiProvider $AdsiProvider -DomainsByFqdn $DomainsByFqdn @LogThis

            Write-LogMsg @LogParams -Text "ConvertTo-DomainSidString -DomainDnsName '$DomainFqdn' -ThisFqdn '$ThisFqdn' # for '$DomainFqdn'"
            $DomainSid = ConvertTo-DomainSidString -DomainDnsName $DomainFqdn -ThisFqdn $ThisFqdn -CimCache $CimCache @CacheParams @LogThis

            Write-LogMsg @LogParams -Text "ConvertTo-DomainNetBIOS -DomainFQDN '$DomainFqdn' # for '$DomainFqdn'"
            $DomainNetBIOS = ConvertTo-DomainNetBIOS -DomainFQDN $DomainFqdn -ThisFqdn $ThisFqdn -CimCache $CimCache @CacheParams @LogThis

            <#
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

                # PS 5.1 returns fewer results than PS 7.4
                    WellKnownSidType                          BinaryLength AccountDomainSid                          Value
                    ----------------                          ------------ ----------------                          -----
                    NullSid                                             12                                           S-1-0-0
                    WorldSid                                            12                                           S-1-1-0
                    LocalSid                                            12                                           S-1-2-0
                    CreatorOwnerSid                                     12                                           S-1-3-0
                    CreatorGroupSid                                     12                                           S-1-3-1
                    CreatorOwnerServerSid                               12                                           S-1-3-2
                    CreatorGroupServerSid                               12                                           S-1-3-3
                    NTAuthoritySid                                       8                                           S-1-5
                    DialupSid                                           12                                           S-1-5-1
                    NetworkSid                                          12                                           S-1-5-2
                    BatchSid                                            12                                           S-1-5-3
                    InteractiveSid                                      12                                           S-1-5-4
                    ServiceSid                                          12                                           S-1-5-6
                    AnonymousSid                                        12                                           S-1-5-7
                    ProxySid                                            12                                           S-1-5-8
                    EnterpriseControllersSid                            12                                           S-1-5-9
                    SelfSid                                             12                                           S-1-5-10
                    AuthenticatedUserSid                                12                                           S-1-5-11
                    RestrictedCodeSid                                   12                                           S-1-5-12
                    TerminalServerSid                                   12                                           S-1-5-13
                    RemoteLogonIdSid                                    12                                           S-1-5-14
                    Exception calling ".ctor" with "2" argument(s): "Well-known SIDs of type LogonIdsSid cannot be created.
                    Parameter name: sidType"
                    At line:1 char:147
                    + ... ::$SidType; [System.Security.Principal.SecurityIdentifier]::new($var, ...
                    +                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                        + CategoryInfo          : NotSpecified: (:) [], MethodInvocationException
                        + FullyQualifiedErrorId : ArgumentException

                    LocalSystemSid                                      12                                           S-1-5-18
                    LocalServiceSid                                     12                                           S-1-5-19
                    NetworkServiceSid                                   12                                           S-1-5-20
                    BuiltinDomainSid                                    12                                           S-1-5-32
                    BuiltinAdministratorsSid                            16                                           S-1-5-32-544
                    BuiltinUsersSid                                     16                                           S-1-5-32-545
                    BuiltinGuestsSid                                    16                                           S-1-5-32-546
                    BuiltinPowerUsersSid                                16                                           S-1-5-32-547
                    BuiltinAccountOperatorsSid                          16                                           S-1-5-32-548
                    BuiltinSystemOperatorsSid                           16                                           S-1-5-32-549
                    BuiltinPrintOperatorsSid                            16                                           S-1-5-32-550
                    BuiltinBackupOperatorsSid                           16                                           S-1-5-32-551
                    BuiltinReplicatorSid                                16                                           S-1-5-32-552
                    BuiltinPreWindows2000CompatibleAccessSid            16                                           S-1-5-32-554
                    BuiltinRemoteDesktopUsersSid                        16                                           S-1-5-32-555
                    BuiltinNetworkConfigurationOperatorsSid             16                                           S-1-5-32-556
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
                    NtlmAuthenticationSid                               16                                           S-1-5-64-10
                    DigestAuthenticationSid                             16                                           S-1-5-64-21
                    SChannelAuthenticationSid                           16                                           S-1-5-64-14
                    ThisOrganizationSid                                 12                                           S-1-5-15
                    OtherOrganizationSid                                12                                           S-1-5-1000
                    BuiltinIncomingForestTrustBuildersSid               16                                           S-1-5-32-557
                    BuiltinPerformanceMonitoringUsersSid                16                                           S-1-5-32-558
                    BuiltinPerformanceLoggingUsersSid                   16                                           S-1-5-32-559
                    BuiltinAuthorizationAccessSid                       16                                           S-1-5-32-560
                    WinBuiltinTerminalServerLicenseServersSid           16                                           S-1-5-32-561
                    MaxDefined                                          16                                           S-1-5-32-561

                # PS 7 returns more results
                    WellKnownSidType                           BinaryLength AccountDomainSid                          Value
                    ----------------                           ------------ ----------------                          -----
                    NullSid                                              12                                           S-1-0-0
                    WorldSid                                             12                                           S-1-1-0
                    LocalSid                                             12                                           S-1-2-0
                    CreatorOwnerSid                                      12                                           S-1-3-0
                    CreatorGroupSid                                      12                                           S-1-3-1
                    CreatorOwnerServerSid                                12                                           S-1-3-2
                    CreatorGroupServerSid                                12                                           S-1-3-3
                    NTAuthoritySid                                        8                                           S-1-5
                    DialupSid                                            12                                           S-1-5-1
                    NetworkSid                                           12                                           S-1-5-2
                    BatchSid                                             12                                           S-1-5-3
                    InteractiveSid                                       12                                           S-1-5-4
                    ServiceSid                                           12                                           S-1-5-6
                    AnonymousSid                                         12                                           S-1-5-7
                    ProxySid                                             12                                           S-1-5-8
                    EnterpriseControllersSid                             12                                           S-1-5-9
                    SelfSid                                              12                                           S-1-5-10
                    AuthenticatedUserSid                                 12                                           S-1-5-11
                    RestrictedCodeSid                                    12                                           S-1-5-12
                    TerminalServerSid                                    12                                           S-1-5-13
                    RemoteLogonIdSid                                     12                                           S-1-5-14
                    MethodInvocationException: Exception calling ".ctor" with "2" argument(s): "Well-known SIDs of type LogonIdsSid cannot be created. (Parameter 'sidType')"
                    LocalSystemSid                                       12                                           S-1-5-18
                    LocalServiceSid                                      12                                           S-1-5-19
                    NetworkServiceSid                                    12                                           S-1-5-20
                    BuiltinDomainSid                                     12                                           S-1-5-32
                    BuiltinAdministratorsSid                             16                                           S-1-5-32-544
                    BuiltinUsersSid                                      16                                           S-1-5-32-545
                    BuiltinGuestsSid                                     16                                           S-1-5-32-546
                    BuiltinPowerUsersSid                                 16                                           S-1-5-32-547
                    BuiltinAccountOperatorsSid                           16                                           S-1-5-32-548
                    BuiltinSystemOperatorsSid                            16                                           S-1-5-32-549
                    BuiltinPrintOperatorsSid                             16                                           S-1-5-32-550
                    BuiltinBackupOperatorsSid                            16                                           S-1-5-32-551
                    BuiltinReplicatorSid                                 16                                           S-1-5-32-552
                    BuiltinPreWindows2000CompatibleAccessSid             16                                           S-1-5-32-554
                    BuiltinRemoteDesktopUsersSid                         16                                           S-1-5-32-555
                    BuiltinNetworkConfigurationOperatorsSid              16                                           S-1-5-32-556
                    AccountAdministratorSid                              28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-500
                    AccountGuestSid                                      28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-501
                    AccountKrbtgtSid                                     28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-502
                    AccountDomainAdminsSid                               28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-512
                    AccountDomainUsersSid                                28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-513
                    AccountDomainGuestsSid                               28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-514
                    AccountComputersSid                                  28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-515
                    AccountControllersSid                                28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-516
                    AccountCertAdminsSid                                 28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-517
                    AccountSchemaAdminsSid                               28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-518
                    AccountEnterpriseAdminsSid                           28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-519
                    AccountPolicyAdminsSid                               28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-520
                    AccountRasAndIasServersSid                           28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-553
                    NtlmAuthenticationSid                                16                                           S-1-5-64-10
                    DigestAuthenticationSid                              16                                           S-1-5-64-21
                    SChannelAuthenticationSid                            16                                           S-1-5-64-14
                    ThisOrganizationSid                                  12                                           S-1-5-15
                    OtherOrganizationSid                                 12                                           S-1-5-1000
                    BuiltinIncomingForestTrustBuildersSid                16                                           S-1-5-32-557
                    BuiltinPerformanceMonitoringUsersSid                 16                                           S-1-5-32-558
                    BuiltinPerformanceLoggingUsersSid                    16                                           S-1-5-32-559
                    BuiltinAuthorizationAccessSid                        16                                           S-1-5-32-560
                    WinBuiltinTerminalServerLicenseServersSid            16                                           S-1-5-32-561
                    MaxDefined                                           16                                           S-1-5-32-561
                    WinBuiltinDCOMUsersSid                               16                                           S-1-5-32-562
                    WinBuiltinIUsersSid                                  16                                           S-1-5-32-568
                    WinIUserSid                                          12                                           S-1-5-17
                    WinBuiltinCryptoOperatorsSid                         16                                           S-1-5-32-569
                    WinUntrustedLabelSid                                 12                                           S-1-16-0
                    WinLowLabelSid                                       12                                           S-1-16-4096
                    WinMediumLabelSid                                    12                                           S-1-16-8192
                    WinHighLabelSid                                      12                                           S-1-16-12288
                    WinSystemLabelSid                                    12                                           S-1-16-16384
                    WinWriteRestrictedCodeSid                            12                                           S-1-5-33
                    WinCreatorOwnerRightsSid                             12                                           S-1-3-4
                    WinCacheablePrincipalsGroupSid                       28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-571
                    WinNonCacheablePrincipalsGroupSid                    28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-572
                    WinEnterpriseReadonlyControllersSid                  12                                           S-1-5-22
                    WinAccountReadonlyControllersSid                     28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-521
                    WinBuiltinEventLogReadersGroup                       16                                           S-1-5-32-573
                    WinNewEnterpriseReadonlyControllersSid               28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-498
                    WinBuiltinCertSvcDComAccessGroup                     16                                           S-1-5-32-574
                    WinMediumPlusLabelSid                                12                                           S-1-16-8448
                    MethodInvocationException: Exception calling ".ctor" with "2" argument(s): "The parameter is incorrect. (Parameter 'sidType/domainSid')"
                    WinConsoleLogonSid                                   12                                           S-1-2-1
                    WinThisOrganizationCertificateSid                    16                                           S-1-5-65-1
                    MethodInvocationException: Exception calling ".ctor" with "2" argument(s): "The parameter is incorrect. (Parameter 'sidType/domainSid')"
                    WinBuiltinAnyPackageSid                              16                                           S-1-15-2-1
                    WinCapabilityInternetClientSid                       16                                           S-1-15-3-1
                    WinCapabilityInternetClientServerSid                 16                                           S-1-15-3-2
                    WinCapabilityPrivateNetworkClientServerSid           16                                           S-1-15-3-3
                    WinCapabilityPicturesLibrarySid                      16                                           S-1-15-3-4
                    WinCapabilityVideosLibrarySid                        16                                           S-1-15-3-5
                    WinCapabilityMusicLibrarySid                         16                                           S-1-15-3-6
                    WinCapabilityDocumentsLibrarySid                     16                                           S-1-15-3-7
                    WinCapabilitySharedUserCertificatesSid               16                                           S-1-15-3-9
                    WinCapabilityEnterpriseAuthenticationSid             16                                           S-1-15-3-8
                    WinCapabilityRemovableStorageSid                     16                                           S-1-15-3-10
            #>

            Write-LogMsg @LogParams -Text "Get-CachedCimInstance -ComputerName '$DomainFqdn' -ClassName 'Win32_Account' # for '$DomainFqdn'"
            $Win32Accounts = Get-CachedCimInstance -ComputerName $DomainFqdn -ClassName 'Win32_Account' -KeyProperty Caption -CacheByProperty @() @CimParams @LogThis

            Write-LogMsg @LogParams -Text "Get-CachedCimInstance -ComputerName '$DomainFqdn' -ClassName 'Win32_Service' # for '$DomainFqdn'"
            $Win32Services = Get-CachedCimInstance -ComputerName $DomainFqdn -ClassName 'Win32_Service' -KeyProperty Name -CacheByProperty @() @CimParams @LogThis

            Write-LogMsg @LogParams -Text "Resolve-ServiceNameToSID -ComputerName '$DomainFqdn' -ThisFqdn $ThisFqdn -ThisHostName $ThisHostName -InputObject `$Win32Services # for '$DomainFqdn'"
            $ResolvedWin32Services = Resolve-ServiceNameToSID -InputObject $Win32Services

            #Add-CachedCimInstance -ComputerName $DomainFqdn -ClassName 'Win32_Service' -InputObject $ResolvedWin32Services -CacheByProperty @('Name', 'SID') -CimCache $CimCache -DebugOutputStream $DebugOutputStream @LogThis
            ConvertTo-AccountCache -Account $Win32Accounts -SidCache $WellKnownSidBySid -NameCache $WellKnownSidByName
            ConvertTo-AccountCache -Account $ResolvedWin32Services -SidCache $WellKnownSidBySid -NameCache $WellKnownSidByName

            $OutputObject = [PSCustomObject]@{
                DistinguishedName  = $DomainDn
                Dns                = $DomainFqdn
                Sid                = $DomainSid
                Netbios            = $DomainNetBIOS
                AdsiProvider       = $AdsiProvider
                #Win32Accounts      = $Win32Accounts
                #Win32Services      = $ResolvedWin32Services
                WellKnownSidBySid  = $WellKnownSidBySid
                WellKnownSidByName = $WellKnownSidByName
            }

            $DomainsBySid[$OutputObject.Sid] = $OutputObject
            $DomainsByNetbios[$OutputObject.Netbios] = $OutputObject
            $DomainsByFqdn[$DomainFqdn] = $OutputObject
            $OutputObject

        }

        ForEach ($DomainNetbios in $Netbios) {

            $OutputObject = $DomainsByNetbios[$DomainNetbios]

            if ($OutputObject) {

                #Write-LogMsg @LogParams -Text " # Domain NetBIOS cache hit for '$DomainNetbios'"
                $OutputObject
                continue

            }

            #Write-LogMsg @LogParams -Text "Get-CachedCimSession -ComputerName '$DomainNetbios' # Domain NetBIOS cache miss for '$DomainNetbios'"
            $CimSession = Get-CachedCimSession -ComputerName $DomainNetbios -ThisFqdn $ThisFqdn -CimCache $CimCache @LogThis

            Write-LogMsg @LogParams -Text "Find-AdsiProvider -AdsiServer '$DomainDnsName' # for '$DomainNetbios'"
            $AdsiProvider = Find-AdsiProvider -AdsiServer $DomainDnsName -CimCache $CimCache -ThisFqdn $ThisFqdn @LogThis
            $CacheParams['AdsiProvider'] = $AdsiProvider

            Write-LogMsg @LogParams -Text "ConvertTo-DistinguishedName -Domain '$DomainNetBIOS' # for '$DomainNetbios'"
            $DomainDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -DomainsByNetbios $DomainsByNetbios -DomainsByFqdn $DomainsByFqdn @LogThis

            if ($DomainDn) {

                Write-LogMsg @LogParams -Text "ConvertTo-Fqdn -DistinguishedName '$DomainDn' # for '$DomainNetbios'"
                $DomainDnsName = ConvertTo-Fqdn -DistinguishedName $DomainDn -ThisFqdn $ThisFqdn -CimCache $CimCache @LogThis

            } else {

                $ParentDomainDnsName = Get-ParentDomainDnsName -DomainsByNetbios $DomainNetBIOS -CimSession $CimSession -ThisFqdn $ThisFqdn -CimCache $CimCache @LogThis
                $DomainDnsName = "$DomainNetBIOS.$ParentDomainDnsName"

            }

            Write-LogMsg @LogParams -Text "ConvertTo-DomainSidString -DomainDnsName '$DomainFqdn' -AdsiProvider '$AdsiProvider' -ThisFqdn '$ThisFqdn' # for '$DomainNetbios'"
            $DomainSid = ConvertTo-DomainSidString -DomainDnsName $DomainDnsName -ThisFqdn $ThisFqdn -CimCache $CimCache @CacheParams @LogThis

            Write-LogMsg @LogParams -Text "Get-CachedCimInstance -ComputerName '$DomainDnsName' -ClassName 'Win32_Account' # for '$DomainNetbios'"
            $Win32Accounts = Get-CachedCimInstance -ComputerName $DomainDnsName -ClassName 'Win32_Account' -KeyProperty Caption -CacheByProperty @('Caption', 'SID') @CimParams @LogThis

            Write-LogMsg @LogParams -Text "Get-CachedCimInstance -ComputerName '$DomainDnsName' -ClassName 'Win32_Service' # for '$DomainNetbios'"
            $Win32Services = Get-CachedCimInstance -ComputerName $DomainDnsName -ClassName 'Win32_Service' -KeyProperty Name -CacheByProperty @() @CimParams @LogThis

            Write-LogMsg @LogParams -Text "Resolve-ServiceNameToSID -ComputerName '$DomainDnsName' -ThisFqdn $ThisFqdn -ThisHostName $ThisHostName -InputObject `$Win32Services # for '$DomainFqdn'"
            $ResolvedWin32Services = Resolve-ServiceNameToSID -InputObject $Win32Services
            Add-CachedCimInstance -ComputerName $DomainDnsName -ClassName 'Win32_Service' -InputObject $ResolvedWin32Services -CacheByProperty @('Name', 'SID') @CimParams @LogThis

            if ($RemoveCimSession) {
                Remove-CimSession -CimSession $CimSession
            }

            $OutputObject = [PSCustomObject]@{
                DistinguishedName  = $DomainDn
                Dns                = $DomainDnsName
                Sid                = $DomainSid
                Netbios            = $DomainNetBIOS
                AdsiProvider       = $AdsiProvider
                Win32Accounts      = $Win32Accounts
                Win32Services      = $ResolvedWin32Services
                WellKnownSidBySid  = $WellKnownSidBySid
                WellKnownSidByName = $WellKnownSidByName
            }

            $DomainsBySid[$OutputObject.Sid] = $OutputObject
            $DomainsByNetbios[$OutputObject.Netbios] = $OutputObject
            $DomainsByFqdn[$OutputObject.Dns] = $OutputObject
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
        Get-CurrentDomain

        Get the domain of the current computer
    #>

    [OutputType([System.DirectoryServices.DirectoryEntry])]

    param (

        # Name of the computer to query via CIM
        [string]$ComputerName,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

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

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug'

    )

    $CimParams = @{
        CimCache          = $CimCache
        ComputerName      = $ComputerName
        DebugOutputStream = $DebugOutputStream
        LogBuffer         = $LogBuffer
        ThisFqdn          = $ThisFqdn
        ThisHostname      = $ThisHostname
        WhoAmI            = $WhoAmI
    }

    $Comp = Get-CachedCimInstance -ClassName Win32_ComputerSystem -KeyProperty Name @CimParams

    if ($Comp.Domain -eq 'WORKGROUP') {

        # Use CIM to find the domain
        $SIDString = Find-LocalAdsiServerSid @CimParams
        $SID = $SIDString | ConvertTo-SidByteArray

        $OutputProperties = @{
            SIDString         = $SIDString
            ObjectSid         = [PSCustomObject]@{
                Value = $Sid
            }
            DistinguishedName = [PSCustomObject]@{
                Value = "DC=$ComputerName"
            }
        }

    } else {

        # Use ADSI to find the domain

        $CurrentDomain = [adsi]::new()
        $null = $CurrentDomain.RefreshCache('objectSid')

        # Convert the objectSID attribute (byte array) to a security descriptor string formatted according to SDDL syntax (Security Descriptor Definition Language)
        Write-LogMsg @LogParams -Text '[System.Security.Principal.SecurityIdentifier]::new([byte[]]$CurrentDomain.objectSid.Value, 0)'
        $OutputProperties = @{
            SIDString = & { [System.Security.Principal.SecurityIdentifier]::new([byte[]]$CurrentDomain.objectSid.Value, 0) } 2>$null
        }

        # Get any existing properties for inclusion later
        if ($CurrentDomain -is [System.Collections.IEnumerable]) {
            $FirstDomain = $CurrentDomain[0]
        } else {
            $FirstDomain = $CurrentDomain
        }

        $InputProperties = $FirstDomain.PSObject.Properties.GetEnumerator().Name

        # Include any existing properties found earlier
        ForEach ($ThisProperty in $InputProperties) {
            $OutputProperties[$ThisProperty] = $ThisPrincipal.$ThisProperty
        }

    }

    # Output the object
    return [PSCustomObject]$OutputProperties

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

    [OutputType([System.DirectoryServices.DirectoryEntry], [PSCustomObject])]
    [CmdletBinding()]

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

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        <#
        Hashtable containing cached directory entries so they don't have to be retrieved from the directory again
        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain FQDNs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        # This is not actually used but is here so the parameter can be included in a splat shared with other functions
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

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

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        [hashtable]$SidTypeMap = (Get-SidTypeMap)

    )

    $Log = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        Buffer       = $LogBuffer
        WhoAmI       = $WhoAmI
    }

    $CacheResult = $DirectoryEntryCache[$DirectoryPath]

    if ($CacheResult) {

        #Write-LogMsg @Log -Text " # DirectoryEntryCache hit # for '$DirectoryPath'"
        return $CacheResult

    }

    #Write-LogMsg @Log -Text " # DirectoryEntryCache miss # for '$DirectoryPath'"

    $LoggingParams = @{
        ThisHostname = $ThisHostname
        LogBuffer    = $LogBuffer
        WhoAmI       = $WhoAmI
    }

    $SplitDirectoryPath = Split-DirectoryPath -DirectoryPath $DirectoryPath
    $Server = $SplitDirectoryPath['Domain']

    $CacheSearch = @{
        AccountName      = $SplitDirectoryPath['Account']
        CimServer        = $CimCache[$Server]
        DirectoryPath    = $DirectoryPath
        Log              = $Log
        Server           = $Server
        DomainsByFqdn    = $DomainsByFqdn
        DomainsByNetbios = $DomainsByNetbios
        DomainsBySid     = $DomainsBySid
        SidTypeMap       = $SidTypeMap
    }

    $DirectoryEntry = Get-CachedDirectoryEntry @CacheSearch

    if ($null -eq $DirectoryEntry) {

        if ([string]::IsNullOrEmpty($DirectoryPath)) {

            # Workgroup computers do not return a DirectoryEntry with a SearchRoot Path so this ends up being an empty string
            # This is also invoked when DirectoryPath is null for any reason
            # We will return a WinNT object representing the local computer's WinNT directory
            Write-LogMsg @Log -Text " # The SearchRoot Path is empty, indicating '$ThisHostname' is not domain-joined. Defaulting to WinNT provider for localhost instead. # for '$DirectoryPath'"

            $CimParams = @{
                CimCache          = $CimCache
                ComputerName      = $ThisFqdn
                DebugOutputStream = $DebugOutputStream
                ThisFqdn          = $ThisFqdn
            }

            $Workgroup = (Get-CachedCimInstance -ClassName 'Win32_ComputerSystem' -KeyProperty Name @CimParams @LoggingParams).Workgroup
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
            Add-SidInfo -DomainsBySid $DomainsBySid @LoggingParams

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

    $DirectoryEntryCache[$DirectoryPath] = $DirectoryEntry
    return $DirectoryEntry

}
function Get-KnownCaptionHashTable {

    param (
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

    #https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/81d92bba-d22b-4a8c-908a-554ab29148ab
    #https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-identifiers

    param (

        [string]$SID

    )

    $StartingPatterns = @{
        'S-1-5-80-' = {
            [PSCustomObject]@{
                'Name'            = $SID
                'Description'     = "Service $SID"
                'NTAccount'       = "NT SERVICE\$SID"
                'SchemaClassName' = 'service'
                'SID'             = $SID
            }
        }
        'S-1-15-2-' = {
            [PSCustomObject]@{
                'Name'            = $SID
                'Description'     = "App Container $SID"
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
                'Name'            = $SID
                'Description'     = "BuiltIn $SID"
                'NTAccount'       = "BUILTIN\$SID"
                'SchemaClassName' = 'user'
                'SID'             = $SID
            }
        }
    }

    $TheNine = $SID.Substring(0, 9)
    $Match = $StartingPatterns[$TheNine]

    if ($Match) {
        $result = Invoke-Command -ScriptBlock $Match
        return $result
    }

    switch -Wildcard ($SID) {
        'S-1-5-*-500' {
            return [PSCustomObject]@{
                'Name'            = 'Administrator'
                'Description'     = "A built-in user account for the system administrator to administer the computer/domain. Every computer has a local Administrator account and every domain has a domain Administrator account. The Administrator account is the first account created during operating system installation. The account can't be deleted, disabled, or locked out, but it can be renamed. By default, the Administrator account is a member of the Administrators group, and it can't be removed from that group."
                'NTAccount'       = 'BUILTIN\Administrator'
                'SchemaClassName' = 'user'
                'SID'             = $SID
            }
        }
        'S-1-5-*-501' {
            return [PSCustomObject]@{
                'Name'            = 'Guest'
                'Description'     = "A user account for people who don't have individual accounts. Every computer has a local Guest account, and every domain has a domain Guest account. By default, Guest is a member of the Everyone and the Guests groups. The domain Guest account is also a member of the Domain Guests and Domain Users groups. Unlike Anonymous Logon, Guest is a real account, and it can be used to sign in interactively. The Guest account doesn't require a password, but it can have one."
                'NTAccount'       = 'BUILTIN\Guest'
                'SchemaClassName' = 'user'
                'SID'             = $SID
            }
        }
        'S-1-5-*-502' {
            return [PSCustomObject]@{
                'Name'            = 'KRBTGT'
                'Description'     = "Kerberos Ticket-Generating Ticket account: a user account that's used by the Key Distribution Center (KDC) service. The account exists only on domain controllers."
                'NTAccount'       = 'BUILTIN\KRBTGT'
                'SchemaClassName' = 'user'
                'SID'             = $SID
            }
        }
        'S-1-5-*-512' {
            return [PSCustomObject]@{
                'Name'            = 'Domain Admins'
                'Description'     = "A global group with members that are authorized to administer the domain. By default, the Domain Admins group is a member of the Administrators group on all computers that have joined the domain, including domain controllers. Domain Admins is the default owner of any object that's created in the domain's Active Directory by any member of the group. If members of the group create other objects, such as files, the default owner is the Administrators group."
                'NTAccount'       = 'BUILTIN\Domain Admins'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-*-513' {
            return [PSCustomObject]@{
                'Name'            = 'Domain Users'
                'Description'     = "A global group that includes all users in a domain. When you create a new User object in Active Directory, the user is automatically added to this group."
                'NTAccount'       = 'BUILTIN\Domain Users'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-*-514' {
            return [PSCustomObject]@{
                'Name'            = 'Domain Guests'
                'Description'     = "A global group that, by default, has only one member: the domain's built-in Guest account."
                'NTAccount'       = 'BUILTIN\Domain Guests'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-*-515' {
            return [PSCustomObject]@{
                'Name'            = 'Domain Computers'
                'Description'     = "A global group that includes all computers that have joined the domain, excluding domain controllers."
                'NTAccount'       = 'BUILTIN\Domain Computers'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-*-516' {
            return [PSCustomObject]@{
                'Name'            = 'Domain Controllers'
                'Description'     = "A global group that includes all domain controllers in the domain. New domain controllers are added to this group automatically."
                'NTAccount'       = 'BUILTIN\Domain Controllers'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-*-517' {
            return [PSCustomObject]@{
                'Name'            = 'Cert Publishers'
                'Description'     = "A global group that includes all computers that host an enterprise certification authority. Cert Publishers are authorized to publish certificates for User objects in Active Directory."
                'NTAccount'       = 'BUILTIN\Cert Publishers'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-*-518' {
            return [PSCustomObject]@{
                'Name'            = 'Schema Admins'
                'Description'     = "A group that exists only in the forest root domain. It's a universal group if the domain is in native mode, and it's a global group if the domain is in mixed mode. The Schema Admins group is authorized to make schema changes in Active Directory. By default, the only member of the group is the Administrator account for the forest root domain."
                'NTAccount'       = 'BUILTIN\Schema Admins'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-*-519' {
            return [PSCustomObject]@{
                'Name'            = 'Enterprise Admins'
                'Description'     = "A group that exists only in the forest root domain. It's a universal group if the domain is in native mode, and it's a global group if the domain is in mixed mode. The Enterprise Admins group is authorized to make changes to the forest infrastructure, such as adding child domains, configuring sites, authorizing DHCP servers, and installing enterprise certification authorities. By default, the only member of Enterprise Admins is the Administrator account for the forest root domain. The group is a default member of every Domain Admins group in the forest."
                'NTAccount'       = 'BUILTIN\Enterprise Admins'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-*-520' {
            return [PSCustomObject]@{
                'Name'            = 'Group Policy Creator Owners'
                'Description'     = "A global group that's authorized to create new Group Policy Objects in Active Directory. By default, the only member of the group is Administrator. Objects that are created by members of Group Policy Creator Owners are owned by the individual user who creates them. In this way, the Group Policy Creator Owners group is unlike other administrative groups (such as Administrators and Domain Admins). Objects that are created by members of these groups are owned by the group rather than by the individual."
                'NTAccount'       = 'BUILTIN\Group Policy Creator Owners'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-*-521' {
            return [PSCustomObject]@{
                'Name'            = 'Read-only Domain Controllers'
                'Description'     = "A global group that includes all read-only domain controllers."
                'NTAccount'       = 'BUILTIN\Read-only Domain Controllers'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-*-522' {
            return [PSCustomObject]@{
                'Name'            = 'Clonable Controllers'
                'Description'     = "A global group that includes all domain controllers in the domain that can be cloned."
                'NTAccount'       = 'BUILTIN\Clonable Controllers'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-*-525' {
            return [PSCustomObject]@{
                'Name'            = 'Protected Users'
                'Description'     = "A global group that is afforded additional protections against authentication security threats."
                'NTAccount'       = 'BUILTIN\Protected Users'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-*-526' {
            return [PSCustomObject]@{
                'Name'            = 'Key Admins'
                'Description'     = "This group is intended for use in scenarios where trusted external authorities are responsible for modifying this attribute. Only trusted administrators should be made a member of this group."
                'NTAccount'       = 'BUILTIN\Key Admins'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-*-527' {
            return [PSCustomObject]@{
                'Name'            = 'Enterprise Key Admins'
                'Description'     = "This group is intended for use in scenarios where trusted external authorities are responsible for modifying this attribute. Only trusted enterprise administrators should be made a member of this group."
                'NTAccount'       = 'BUILTIN\Enterprise Key Admins'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-*-553' {
            return [PSCustomObject]@{
                'Name'            = 'RAS and IAS Servers'
                'Description'     = "A local domain group. By default, this group has no members. Computers that are running the Routing and Remote Access service are added to the group automatically. Members have access to certain properties of User objects, such as Read Account Restrictions, Read Logon Information, and Read Remote Access Information."
                'NTAccount'       = 'BUILTIN\RAS and IAS Servers'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-*-571' {
            return [PSCustomObject]@{
                'Name'            = 'Allowed RODC Password Replication Group'
                'Description'     = "Members in this group can have their passwords replicated to all read-only domain controllers in the domain."
                'NTAccount'       = 'BUILTIN\Allowed RODC Password Replication Group'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-*-572' {
            return [PSCustomObject]@{
                'Name'            = 'Denied RODC Password Replication Group'
                'Description'     = "Members in this group can't have their passwords replicated to all read-only domain controllers in the domain."
                'NTAccount'       = 'BUILTIN\Denied RODC Password Replication Group'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        default { break }
    }

    if ($SID -match 'S-1-5-5-(?<Session>[^-]-[^-])') {

        return [PSCustomObject]@{
            'Name'            = 'Logon Session'
            'Description'     = "Sign-in session $($Matches.Session)"
            'NTAccount'       = 'BUILTIN\Logon Session'
            'SchemaClassName' = 'user'
            'SID'             = $SID
        }

    }

}
function Get-KnownSidHashTable {
    # Some of these cannot be translated using the [SecurityIdentifier]::Translate or [NTAccount]::Translate methods.
    # Some of these cannot be retrieved using CIM or ADSI.
    # Hardcoding them here allows avoiding queries that we know will fail.
    return @{
        #https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-identifiers
        'S-1-0-0'                                                        = [PSCustomObject]@{
            'Description'     = "A group with no members. This is often used when a SID value isn't known."
            'Name'            = 'NULL SID'
            'NTAccount'       = 'NULL SID AUTHORITY\NULL SID'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-0-0'
        }
        'S-1-1-0'                                                        = [PSCustomObject]@{
            'Description'     = "A group that includes all users; aka 'World'."
            'Name'            = 'Everyone'
            'NTAccount'       = 'WORLD SID AUTHORITY\Everyone'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-1-0'
        }
        'S-1-2-1'                                                        = [PSCustomObject]@{
            'Description'     = 'A group that includes users who are signed in to the physical console.'
            'Name'            = 'CONSOLE LOGON'
            'NTAccount'       = 'LOCAL SID AUTHORITY\CONSOLE LOGON'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-2-0'
        }
        'S-1-3-0'                                                        = [PSCustomObject]@{
            'Description'     = 'A security identifier to be replaced by the SID of the user who creates a new object. This SID is used in inheritable access control entries.'
            'Name'            = 'CREATOR OWNER'
            'NTAccount'       = 'CREATOR SID AUTHORITY\CREATOR OWNER'
            'SchemaClassName' = 'user'
            'SID'             = 'S-1-3-0'
        }
        'S-1-4'                                                          = [PSCustomObject]@{
            'Description'     = 'A SID that represents an identifier authority which is not unique.'
            'Name'            = 'Non-unique Authority'
            'NTAccount'       = 'Non-unique Authority'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-4'
        }
        'S-1-5'                                                          = [PSCustomObject]@{
            'Description'     = "The SECURITY_NT_AUTHORITY (S-1-5) predefined identifier authority produces SIDs that aren't universal and are meaningful only in installations of the Windows operating systems in the 'Applies to' list at the beginning of this article."
            'Name'            = 'NT Authority'
            'NTAccount'       = 'NT Authority'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-5'
        }
        'S-1-5-1'                                                        = [PSCustomObject]@{
            'Description'     = "A group that includes all users who are signed in to the system via dial-up connection."
            'Name'            = 'Dialup'
            'NTAccount'       = 'NT AUTHORITY\DIALUP'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-5-1'
        }
        'S-1-5-2'                                                        = [PSCustomObject]@{
            'Description'     = "A group that includes all users who are signed in via a network connection. Access tokens for interactive users don't contain the Network SID."
            'Name'            = 'Network'
            'NTAccount'       = 'NT AUTHORITY\NETWORK'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-2'
        }
        'S-1-5-3'                                                        = [PSCustomObject]@{
            'Description'     = "A group that includes all users who have signed in via batch queue facility, such as task scheduler jobs."
            'Name'            = 'Batch'
            'NTAccount'       = 'NT AUTHORITY\BATCH'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-3'
        }
        'S-1-5-4'                                                        = [PSCustomObject]@{
            'Description'     = "Users who log on for interactive operation. This is a group identifier added to the token of a process when it was logged on interactively. A group that includes all users who sign in interactively. A user can start an interactive sign-in session by opening a Remote Desktop Services connection from a remote computer, or by using a remote shell such as Telnet. In each case, the user's access token contains the Interactive SID. If the user signs in by using a Remote Desktop Services connection, the user's access token also contains the Remote Interactive Logon SID."
            'Name'            = 'INTERACTIVE'
            'NTAccount'       = 'NT AUTHORITY\INTERACTIVE'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-4'
        }
        'S-1-5-6'                                                        = [PSCustomObject]@{
            'Description'     = "A group that includes all security principals that have signed in as a service."
            'Name'            = 'Service'
            'NTAccount'       = 'NT AUTHORITY\SERVICE'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-6'
        }
        'S-1-5-7'                                                        = [PSCustomObject]@{
            'Description'     = 'A user who has connected to the computer without supplying a user name and password. Not a member of Authenticated Users.'
            'Name'            = 'ANONYMOUS LOGON'
            'NTAccount'       = 'NT AUTHORITY\ANONYMOUS LOGON'
            'SchemaClassName' = 'user'
            'SID'             = 'S-1-5-7'
        }
        'S-1-5-8'                                                        = [PSCustomObject]@{
            'Description'     = "Doesn't currently apply: this SID isn't used."
            'Name'            = 'Proxy'
            'NTAccount'       = 'NT AUTHORITY\PROXY'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-8'
        }
        'S-1-5-9'                                                        = [PSCustomObject]@{
            'Description'     = "A group that includes all domain controllers in a forest of domains."
            'Name'            = 'Enterprise Domain Controllers'
            'NTAccount'       = 'NT AUTHORITY\ENTERPRISE DOMAIN CONTROLLERS'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-9'
        }
        'S-1-5-10'                                                       = [PSCustomObject]@{
            'Description'     = "A placeholder in an ACE for a user, group, or computer object in Active Directory. When you grant permissions to Self, you grant them to the security principal that's represented by the object. During an access check, the operating system replaces the SID for Self with the SID for the security principal that's represented by the object."
            'Name'            = 'Self'
            'NTAccount'       = 'NT AUTHORITY\SELF'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-10'
        }
        'S-1-5-11'                                                       = [PSCustomObject]@{
            'Description'     = 'A group that includes all users and computers with identities that have been authenticated. Does not include Guest even if the Guest account has a password. This group includes authenticated security principals from any trusted domain, not only the current domain.'
            'Name'            = 'Authenticated Users'
            'NTAccount'       = 'NT AUTHORITY\Authenticated Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-11'
        }
        'S-1-5-12'                                                       = [PSCustomObject]@{
            'Description'     = "An identity that's used by a process that's running in a restricted security context. In Windows and Windows Server operating systems, a software restriction policy can assign one of three security levels to code: Unrestricted/Restricted/Disallowed. When code runs at the restricted security level, the Restricted SID is added to the user's access token."
            'Name'            = 'Restricted Code'
            'NTAccount'       = 'NT AUTHORITY\RESTRICTED'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-12'
        }
        'S-1-5-13'                                                       = [PSCustomObject]@{
            'Description'     = "A group that includes all users who sign in to a server with Remote Desktop Services enabled."
            'Name'            = 'Terminal Server User'
            'NTAccount'       = 'NT AUTHORITY\TERMINAL SERVER USER'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-13'
        }
        'S-1-5-14'                                                       = [PSCustomObject]@{
            'Description'     = "A group that includes all users who sign in to the computer by using a remote desktop connection. This group is a subset of the Interactive group. Access tokens that contain the Remote Interactive Logon SID also contain the Interactive SID."
            'Name'            = 'Remote Interactive Logon'
            'NTAccount'       = 'NT AUTHORITY\REMOTE INTERACTIVE LOGON'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-14'
        }
        'S-1-5-15'                                                       = [PSCustomObject]@{
            'Description'     = "A group that includes all users from the same organization. Included only with Active Directory accounts and added only by a domain controller."
            'Name'            = 'This Organization'
            'NTAccount'       = 'NT AUTHORITY\This Organization'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-15'
        }
        'S-1-5-17'                                                       = [PSCustomObject]@{
            'Description'     = "An account that's used by the default Internet Information Services (IIS) user."
            'Name'            = 'IUSR'
            'NTAccount'       = 'NT AUTHORITY\IUSR'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-17'
        }
        'S-1-5-18'                                                       = [PSCustomObject]@{
            'Description'     = "An identity used locally by the operating system and by services that are configured to sign in as LocalSystem. System is a hidden member of Administrators. That is, any process running as System has the SID for the built-in Administrators group in its access token. When a process that's running locally as System accesses network resources, it does so by using the computer's domain identity. Its access token on the remote computer includes the SID for the local computer's domain account plus SIDs for security groups that the computer is a member of, such as Domain Computers and Authenticated Users. By default, the SYSTEM account is granted Full Control permissions to all files on an NTFS volume (LocalSystem)"
            'Name'            = 'SYSTEM'
            'NTAccount'       = 'NT AUTHORITY\SYSTEM'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-5-18'
        }
        'S-1-5-19'                                                       = [PSCustomObject]@{
            'Description'     = "An identity used by services that are local to the computer, have no need for extensive local access, and don't need authenticated network access. Services that run as LocalService access local resources as ordinary users, and they access network resources as anonymous users. As a result, a service that runs as LocalService has significantly less authority than a service that runs as LocalSystem locally and on the network."
            'Name'            = 'LOCAL SERVICE'
            'NTAccount'       = 'NT AUTHORITY\LOCAL SERVICE'
            'SchemaClassName' = 'user'
            'SID'             = 'S-1-5-19'
        }
        'S-1-5-20'                                                       = [PSCustomObject]@{
            'Description'     = "An identity used by services that have no need for extensive local access but do need authenticated network access. Services running as NetworkService access local resources as ordinary users and access network resources by using the computer's identity. As a result, a service that runs as NetworkService has the same network access as a service that runs as LocalSystem, but it has significantly reduced local access."
            'Name'            = 'NETWORK SERVICE'
            'NTAccount'       = 'NT AUTHORITY\NETWORK SERVICE'
            'SchemaClassName' = 'user'
            'SID'             = 'S-1-5-20'
        }
        'S-1-5-32-544'                                                   = [PSCustomObject]@{
            'Description'     = "A built-in local group used for administration of the computer/domain. Administrators have complete and unrestricted access to the computer/domain. After the initial installation of the operating system, the only member of the group is the Administrator account. When a computer joins a domain, the Domain Admins group is added to the Administrators group. When a server becomes a domain controller, the Enterprise Admins group also is added to the Administrators group. (DOMAIN_ALIAS_RID_ADMINS)"
            'Name'            = 'Administrators'
            'NTAccount'       = 'BUILTIN\Administrators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-544'
        }
        'S-1-5-32-545'                                                   = [PSCustomObject]@{
            'Description'     = "A built-in local group that represents all users in the domain. Users are prevented from making accidental or intentional system-wide changes and can run most applications. After the initial installation of the operating system, the only member is the Authenticated Users group. (DOMAIN_ALIAS_RID_USERS)"
            'Name'            = 'Users'
            'NTAccount'       = 'BUILTIN\Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-545'
        }
        'S-1-5-32-546'                                                   = [PSCustomObject]@{
            'Description'     = "A built-in local group that represents guests of the domain. Guests have the same access as members of the Users group by default, except for the Guest account which is further restricted. By default, the only member is the Guest account. The Guests group allows occasional or one-time users to sign in with limited privileges to a computer's built-in Guest account. (DOMAIN_ALIAS_RID_GUESTS)"
            'Name'            = 'Guests'
            'NTAccount'       = 'BUILTIN\Guests'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-546'
        }
        'S-1-5-32-547'                                                   = [PSCustomObject]@{
            'Description'     = "A built-in local group used to represent a user or set of users who expect to treat a system as if it were their personal computer rather than as a workstation for multiple users. By default, the group has no members. Power users can create local users and groups; modify and delete accounts that they have created; and remove users from the Power Users, Users, and Guests groups. Power users also can install programs; create, manage, and delete local printers; and create and delete file shares. Power Users are included for backwards compatibility and possess limited administrative powers. (DOMAIN_ALIAS_RID_POWER_USERS)"
            'Name'            = 'Power Users'
            'NTAccount'       = 'BUILTIN\Power Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-547'
        }
        'S-1-5-32-548'                                                   = [PSCustomObject]@{
            'Description'     = "A built-in local group that exists only on domain controllers. This group permits control over nonadministrator accounts. By default, the group has no members. By default, Account Operators have permission to create, modify, and delete accounts for users, groups, and computers in all containers and organizational units of Active Directory except the Builtin container and the Domain Controllers OU. Account Operators don't have permission to modify the Administrators and Domain Admins groups, nor do they have permission to modify the accounts for members of those groups. (DOMAIN_ALIAS_RID_ACCOUNT_OPS)"
            'Name'            = 'Account Operators'
            'NTAccount'       = 'BUILTIN\DOMAIN_ALIAS_RID_ACCOUNT_OPS'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-548'
        }
        'S-1-5-32-549'                                                   = [PSCustomObject]@{
            'Description'     = "A built-in local group that exists only on domain controllers. This group performs system administrative functions, not including security functions. It establishes network shares, controls printers, unlocks workstations, and performs other operations. By default, the group has no members. Server Operators can sign in to a server interactively; create and delete network shares; start and stop services; back up and restore files; format the hard disk of the computer; and shut down the computer. (DOMAIN_ALIAS_RID_SYSTEM_OPS)"
            'Name'            = 'Server Operators'
            'NTAccount'       = 'BUILTIN\DOMAIN_ALIAS_RID_SYSTEM_OPS'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-549'
        }
        'S-1-5-32-550'                                                   = [PSCustomObject]@{
            'Description'     = "A built-in local group that exists only on domain controllers. This group controls printers and print queues. By default, the only member is the Domain Users group. Print Operators can manage printers and document queues. (DOMAIN_ALIAS_RID_PRINT_OPS)"
            'Name'            = 'Print Operators'
            'NTAccount'       = 'BUILTIN\DOMAIN_ALIAS_RID_PRINT_OPS'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-550'
        }
        'S-1-5-32-551'                                                   = [PSCustomObject]@{
            'Description'     = "A built-in local group used for controlling assignment of file backup-and-restore privileges. Backup Operators can override security restrictions for the sole purpose of backing up or restoring files. By default, the group has no members. Backup Operators can back up and restore all files on a computer, regardless of the permissions that protect those files. Backup Operators also can sign in to the computer and shut it down. (DOMAIN_ALIAS_RID_BACKUP_OPS)"
            'Name'            = 'Backup Operators'
            'NTAccount'       = 'BUILTIN\Backup Operators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-551'
        }
        'S-1-5-32-552'                                                   = [PSCustomObject]@{
            'Description'     = "A built-in local group responsible for copying security databases from the primary domain controller to the backup domain controllers by the File Replication service. By default, the group has no members. Don't add users to this group. These accounts are used only by the system. (DOMAIN_ALIAS_RID_REPLICATOR)"
            'Name'            = 'Replicators'
            'NTAccount'       = 'BUILTIN\Replicator'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-552'
        }
        'S-1-5-32-554'                                                   = [PSCustomObject]@{
            'Description'     = "An alias. A local group added by Windows 2000 server and used for backward compatibility. Allows read access on all users and groups in the domain. (DOMAIN_ALIAS_RID_PREW2KCOMPACCESS)"
            'Name'            = 'Pre-Windows 2000 Compatible Access'
            'NTAccount'       = 'BUILTIN\Pre-Windows 2000 Compatible Access'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-554'
        }
        'S-1-5-32-555'                                                   = [PSCustomObject]@{
            'Description'     = "An alias. A local group that represents all remote desktop users. Members are granted the right to logon remotely. (DOMAIN_ALIAS_RID_REMOTE_DESKTOP_USERS)"
            'Name'            = 'Remote Desktop Users'
            'NTAccount'       = 'BUILTIN\Remote Desktop Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-555'
        }
        'S-1-5-32-556'                                                   = [PSCustomObject]@{
            'Description'     = "An alias. A local group that represents the network configuration. Members can have some administrative privileges to manage configuration of networking features. (DOMAIN_ALIAS_RID_NETWORK_CONFIGURATION_OPS)"
            'Name'            = 'Network Configuration Operators'
            'NTAccount'       = 'BUILTIN\Network Configuration Operators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-556'
        }
        'S-1-5-32-557'                                                   = [PSCustomObject]@{
            'Description'     = "An alias. A local group that represents any forest trust users. Members can create incoming, one-way trusts to this forest. (DOMAIN_ALIAS_RID_INCOMING_FOREST_TRUST_BUILDERS)"
            'Name'            = 'Incoming Forest Trust Builders'
            'NTAccount'       = 'BUILTIN\Incoming Forest Trust Builders'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-557'
        }
        'S-1-5-32-558'                                                   = [PSCustomObject]@{
            'Description'     = "An alias. A local group. Members can access performance counter data locally and remotely. (DOMAIN_ALIAS_RID_MONITORING_USERS)"
            'Name'            = 'Performance Monitor Users'
            'NTAccount'       = 'BUILTIN\Performance Monitor Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-558'
        }
        'S-1-5-32-559'                                                   = [PSCustomObject]@{
            'Description'     = "An alias. A local group responsible for logging users. Members may schedule logging of performance counters, enable trace providers, and collect event traces both locally and via remote access to this computer. (DOMAIN_ALIAS_RID_LOGGING_USERS)"
            'Name'            = 'Performance Log Users'
            'NTAccount'       = 'BUILTIN\Performance Log Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-559'
        }
        'S-1-5-32-560'                                                   = [PSCustomObject]@{
            'Description'     = "An alias. A local group that represents all authorized access. Members have access to the computed tokenGroupsGlobalAndUniversal attribute on User objects. (DOMAIN_ALIAS_RID_AUTHORIZATIONACCESS)"
            'Name'            = 'Windows Authorization Access Group'
            'NTAccount'       = 'BUILTIN\Windows Authorization Access Group'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-560'
        }
        'S-1-5-32-561'                                                   = [PSCustomObject]@{
            'Description'     = "An alias. A local group that exists only on systems running server operating systems that allow for terminal services and remote access. When Windows Server 2003 Service Pack 1 is installed, a new local group is created. (DOMAIN_ALIAS_RID_TS_LICENSE_SERVERS)"
            'Name'            = 'Terminal Server License Servers'
            'NTAccount'       = 'BUILTIN\Terminal Server License Servers'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-561'
        }
        'S-1-5-32-562'                                                   = [PSCustomObject]@{
            'Description'     = "An alias. A local group that represents users who can use Distributed Component Object Model (DCOM). Used by COM to provide computer-wide access controls that govern access to all call, activation, or launch requests on the computer.Members are allowed to launch, activate and use Distributed COM objects on this machine. (DOMAIN_ALIAS_RID_DCOM_USERS)"
            'Name'            = 'Distributed COM Users'
            'NTAccount'       = 'BUILTIN\Distributed COM Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-562'
        }
        'S-1-5-32-568'                                                   = [PSCustomObject]@{
            'Description'     = "An alias. A built-in local group used by Internet Information Services that represents Internet users. (DOMAIN_ALIAS_RID_IUSERS)"
            'Name'            = 'IIS_IUSRS'
            'NTAccount'       = 'BUILTIN\IIS_IUSRS'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-568'
        }
        'S-1-5-32-569'                                                   = [PSCustomObject]@{
            'Description'     = "A built-in local group that represents access to cryptography operators. Members are authorized to perform cryptographic operations. (DOMAIN_ALIAS_RID_CRYPTO_OPERATORS)"
            'Name'            = 'Cryptographic Operators'
            'NTAccount'       = 'BUILTIN\Cryptographic Operators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-569'
        }
        'S-1-5-32-573'                                                   = [PSCustomObject]@{
            'Description'     = "A built-in local group that represents event log readers. Members can read event logs from a local computer. (DOMAIN_ALIAS_RID_EVENT_LOG_READERS_GROUP)"
            'Name'            = 'Event Log Readers'
            'SID'             = 'S-1-5-32-573'
            'NTAccount'       = 'BUILTIN\Event Log Readers'
            'SchemaClassName' = 'group'
        }
        'S-1-5-32-574'                                                   = [PSCustomObject]@{
            'Description'     = "A built-in local group. Members are allowed to connect to Certification Authorities in the enterprise using Distributed Component Object Model (DCOM). (DOMAIN_ALIAS_RID_CERTSVC_DCOM_ACCESS_GROUP)"
            'Name'            = 'Certificate Service DCOM Access'
            'NTAccount'       = 'BUILTIN\Certificate Service DCOM Access'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-574'
        }
        'S-1-5-32-575'                                                   = [PSCustomObject]@{
            'Description'     = "A built-in local group. Servers in this group enable users of RemoteApp programs and personal virtual desktops access to these resources. In internet-facing deployments, these servers are typically deployed in an edge network. This group needs to be populated on servers that are running RD Connection Broker. RD Gateway servers and RD Web Access servers used in the deployment need to be in this group. (DOMAIN_ALIAS_RID_RDS_REMOTE_ACCESS_SERVERS)"
            'Name'            = 'RDS Remote Access Servers'
            'NTAccount'       = 'BUILTIN\RDS Remote Access Servers'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-575'
        }
        'S-1-5-32-576'                                                   = [PSCustomObject]@{
            'Description'     = "A built-in local group. Servers in this group run virtual machines and host sessions where users RemoteApp programs and personal virtual desktops run. This group needs to be populated on servers running RD Connection Broker. RD Session Host servers and RD Virtualization Host servers used in the deployment need to be in this group. (DOMAIN_ALIAS_RID_RDS_ENDPOINT_SERVERS)"
            'Name'            = 'RDS Endpoint Servers'
            'NTAccount'       = 'BUILTIN\RDS Endpoint Servers'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-576'
        }
        'S-1-5-32-577'                                                   = [PSCustomObject]@{
            'Description'     = "A built-in local group. Servers in this group can perform routine administrative actions on servers running Remote Desktop Services. This group needs to be populated on all servers in a Remote Desktop Services deployment. The servers running the RDS Central Management service must be included in this group. (DOMAIN_ALIAS_RID_RDS_MANAGEMENT_SERVERS)"
            'Name'            = 'RDS Management Servers'
            'NTAccount'       = 'BUILTIN\RDS Management Servers'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-577'
        }
        'S-1-5-32-578'                                                   = [PSCustomObject]@{
            'Description'     = "A built-in local group. Members have complete and unrestricted access to all features of Hyper-V. (DOMAIN_ALIAS_RID_HYPER_V_ADMINS)"
            'Name'            = 'Hyper-V Administrators'
            'NTAccount'       = 'BUILTIN\Hyper-V Administrators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-578'
        }
        'S-1-5-32-579'                                                   = [PSCustomObject]@{
            'Description'     = "A built-in local group. Members can remotely query authorization attributes and permissions for resources on this computer. (DOMAIN_ALIAS_RID_ACCESS_CONTROL_ASSISTANCE_OPS)"
            'Name'            = 'Access Control Assistance Operators'
            'NTAccount'       = 'BUILTIN\Access Control Assistance Operators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-579'
        }
        'S-1-5-32-580'                                                   = [PSCustomObject]@{
            'Description'     = "A built-in local group. Members can access Windows Management Instrumentation (WMI) resources over management protocols (such as WS-Management via the Windows Remote Management service). This applies only to WMI namespaces that grant access to the user. (DOMAIN_ALIAS_RID_REMOTE_MANAGEMENT_USERS)"
            'Name'            = 'Remote Management Users'
            'NTAccount'       = 'BUILTIN\Remote Management Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-580'
        }
        'S-1-5-64-10'                                                    = [PSCustomObject]@{
            'Description'     = "A SID that's used when the NTLM authentication package authenticates the client."
            'Name'            = 'NTLM Authentication'
            'NTAccount'       = 'NT AUTHORITY\NTLM Authentication'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-64-10'
        }
        'S-1-5-64-14'                                                    = [PSCustomObject]@{
            'Description'     = "A SID that's used when the SChannel authentication package authenticates the client."
            'Name'            = 'SChannel Authentication'
            'NTAccount'       = 'NT AUTHORITY\SChannel Authentication'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-64-14'
        }
        'S-1-5-64-21'                                                    = [PSCustomObject]@{
            'Description'     = "A SID that's used when the Digest authentication package authenticates the client."
            'Name'            = 'Digest Authentication'
            'NTAccount'       = 'NT AUTHORITY\Digest Authentication'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-64-21'
        }
        'S-1-5-80'                                                       = [PSCustomObject]@{
            'Description'     = "A SID that's used as an NT Service account prefix."
            'Name'            = 'NT Service'
            'NTAccount'       = 'NT AUTHORITY\NT Service'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-5-80'
        }
        'S-1-5-80-0'                                                     = [PSCustomObject]@{
            'Description'     = "A group that includes all service processes that are configured on the system. Membership is controlled by the operating system. This SID was introduced in Windows Server 2008 R2."
            'Name'            = 'All Services'
            'NTAccount'       = 'NT SERVICE\ALL SERVICES'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-80-0'
        }
        'S-1-5-83-0'                                                     = [PSCustomObject]@{
            'Description'     = "A built-in group. The group is created when the Hyper-V role is installed. Membership in the group is maintained by the Hyper-V Management Service (VMMS). This group requires the Create Symbolic Links right (SeCreateSymbolicLinkPrivilege) and the Log on as a Service right (SeServiceLogonRight)."
            'Name'            = 'Virtual Machines'
            'NTAccount'       = 'NT VIRTUAL MACHINE\Virtual Machines'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-83-0'
        }
        'S-1-5-113'                                                      = [PSCustomObject]@{
            'Description'     = "You can use this SID when you're restricting network sign-in to local accounts instead of 'administrator' or equivalent. This SID can be effective in blocking network sign-in for local users and groups by account type regardless of what they're named."
            'Name'            = 'Local account'
            'NTAccount'       = 'NT AUTHORITY\Local account'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-113'
        }
        'S-1-5-114'                                                      = [PSCustomObject]@{
            'Description'     = "You can use this SID when you're restricting network sign-in to local accounts instead of 'administrator' or equivalent. This SID can be effective in blocking network sign-in for local users and groups by account type regardless of what they're named."
            'Name'            = 'Local account and member of Administrators group'
            'NTAccount'       = 'NT AUTHORITY\Local account and member of Administrators group'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-114'
        }

        <#
        https://devblogs.microsoft.com/oldnewthing/20220502-00/?p=106550
        SIDs of the form S-1-15-2-xxx are app container SIDs.
        These SIDs are present in the token of apps running in an app container, and they encode the app container identity.
        According to the rules for Mandatory Integrity Control, objects default to allowing write access only to medium integrity level (IL) or higher.
        App containers run at low IL, so they by default don’t have write access to such objects.
            An object can add access control entries (ACEs) to its access control list (ACL) to grant access to low IL.
            There are a few security identifiers (SIDs) you may see when an object extends access to low IL.
            #>
        'S-1-15-2-1'                                                     = [PSCustomObject]@{
            'Description'     = 'All applications running in an app package context have this app container SID. SECURITY_BUILTIN_PACKAGE_ANY_PACKAGE'
            'Name'            = 'ALL APPLICATION PACKAGES'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\ALL APPLICATION PACKAGES'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-2-1'
        }
        'S-1-15-2-2'                                                     = [PSCustomObject]@{
            'Description'     = 'Some applications running in an app package context may have this app container SID. SECURITY_BUILTIN_PACKAGE_ANY_RESTRICTED_PACKAGE'
            'Name'            = 'ALL RESTRICTED APPLICATION PACKAGES'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\ALL RESTRICTED APPLICATION PACKAGES'
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
        'S-1-15-3-1'                                                     = [PSCustomObject]@{
            'Description'     = 'internetClient containerized app capability SID'
            'Name'            = 'Your Internet connection'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your Internet connection'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-1'
        }
        'S-1-15-3-2'                                                     = [PSCustomObject]@{
            'Description'     = 'internetClientServer containerized app capability SID'
            'Name'            = 'Your Internet connection, including incoming connections from the Internet'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your Internet connection, including incoming connections from the Internet'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-2'
        }
        'S-1-15-3-3'                                                     = [PSCustomObject]@{
            'Description'     = 'privateNetworkClientServer containerized app capability SID'
            'Name'            = 'Your home or work networks'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your home or work networks'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-3'
        }
        'S-1-15-3-4'                                                     = [PSCustomObject]@{
            'Description'     = 'picturesLibrary containerized app capability SID'
            'Name'            = 'Your pictures library'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your pictures library'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-4'
        }
        'S-1-15-3-5'                                                     = [PSCustomObject]@{
            'Description'     = 'videosLibrary containerized app capability SID'
            'Name'            = 'Your videos library'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your videos library'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-5'
        }
        'S-1-15-3-6'                                                     = [PSCustomObject]@{
            'Description'     = 'musicLibrary containerized app capability SID'
            'Name'            = 'Your music library'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your music library'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-6'
        }
        'S-1-15-3-7'                                                     = [PSCustomObject]@{
            'Description'     = 'documentsLibrary containerized app capability SID'
            'Name'            = 'Your documents library'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your documents library'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-7'
        }
        'S-1-15-3-8'                                                     = [PSCustomObject]@{
            'Description'     = 'enterpriseAuthentication containerized app capability SID'
            'Name'            = 'Your Windows credentials'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your Windows credentials'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-8'
        }
        'S-1-15-3-9'                                                     = [PSCustomObject]@{
            'Description'     = 'sharedUserCertificates containerized app capability SID'
            'Name'            = 'Software and hardware certificates or a smart card'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Software and hardware certificates or a smart card'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-9'
        }
        'S-1-15-3-10'                                                    = [PSCustomObject]@{
            'Description'     = 'removableStorage containerized app capability SID'
            'Name'            = 'Removable storage'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Removable storage'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-10'
        }
        'S-1-15-3-11'                                                    = [PSCustomObject]@{
            'Description'     = 'appointments containerized app capability SID'
            'Name'            = 'Your Appointments'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your Appointments'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-11'
        }
        'S-1-15-3-12'                                                    = [PSCustomObject]@{
            'Description'     = 'contacts containerized app capability SID'
            'Name'            = 'Your Contacts'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your Contacts'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-12'
        }
        'S-1-15-3-4096'                                                  = [PSCustomObject]@{
            'Description'     = 'internetExplorer containerized app capability SID'
            'Name'            = 'internetExplorer'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\internetExplorer'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-4096'
        }
        <#Other known SIDs#>
        'S-1-5-80-242729624-280608522-2219052887-3187409060-2225943459'  = [PSCustomObject]@{
            'Description'     = 'Windows Cryptographic service account'
            'Name'            = 'CryptSvc'
            'NTAccount'       = 'NT SERVICE\CryptSvc'
            'SchemaClassName' = 'service'
            'SID'             = 'S-1-5-80-242729624-280608522-2219052887-3187409060-2225943459'
        }
        'S-1-5-80-3139157870-2983391045-3678747466-658725712-1809340420' = [PSCustomObject]@{
            'Description'     = 'Windows Diagnostics service account'
            'Name'            = 'WdiServiceHost'
            'NTAccount'       = 'NT SERVICE\WdiServiceHost'
            'SchemaClassName' = 'service'
            'SID'             = 'S-1-5-80-3139157870-2983391045-3678747466-658725712-1809340420'
        }
        'S-1-5-80-880578595-1860270145-482643319-2788375705-1540778122'  = [PSCustomObject]@{
            'Description'     = 'Windows Event Log service account'
            'Name'            = 'EventLog'
            'NTAccount'       = 'NT SERVICE\EventLog'
            'SchemaClassName' = 'service'
            'SID'             = 'S-1-5-80-880578595-1860270145-482643319-2788375705-1540778122'
        }
        'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464' = [PSCustomObject]@{
            'Description'     = 'Most of the operating system files are owned by the TrustedInstaller security identifier (SID)'
            'Name'            = 'TrustedInstaller'
            'NTAccount'       = 'NT SERVICE\TrustedInstaller'
            'SchemaClassName' = 'service'
            'SID'             = 'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'
        }
        <#
        The following table has examples of domain-relative RIDs that you can use to form well-known SIDs for local groups (aliases). For more information about local and global groups, see Local Group Functions and Group Functions.
        #>
        'S-1-5-32-553'                                                   = [PSCustomObject]@{
            'Name'            = 'DOMAIN_ALIAS_RID_RAS_SERVERS'
            'NTAccount'       = 'BUILTIN\DOMAIN_ALIAS_RID_RAS_SERVERS'
            'Description'     = 'A local group that represents RAS and IAS servers. This group permits access to various attributes of user objects. (DOMAIN_ALIAS_RID_RAS_SERVERS)'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-553'
        }
        'S-1-5-32-571'                                                   = [PSCustomObject]@{
            'Name'            = 'DOMAIN_ALIAS_RID_CACHEABLE_PRINCIPALS_GROUP'
            'NTAccount'       = 'BUILTIN\DOMAIN_ALIAS_RID_CACHEABLE_PRINCIPALS_GROUP'
            'Description'     = 'A local group that represents principals that can be cached. (DOMAIN_ALIAS_RID_CACHEABLE_PRINCIPALS_GROUP)'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-571'
        }
        'S-1-5-32-572'                                                   = [PSCustomObject]@{
            'Name'            = 'DOMAIN_ALIAS_RID_NON_CACHEABLE_PRINCIPALS_GROUP'
            'NTAccount'       = 'BUILTIN\DOMAIN_ALIAS_RID_NON_CACHEABLE_PRINCIPALS_GROUP'
            'Description'     = 'A local group that represents principals that cannot be cached. (DOMAIN_ALIAS_RID_NON_CACHEABLE_PRINCIPALS_GROUP)'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-572'
        }
        'S-1-5-32-581'                                                   = [PSCustomObject]@{
            'Name'            = 'System Managed Accounts Group'
            'NTAccount'       = 'BUILTIN\System Managed Accounts Group'
            'Description'     = 'Members are managed by the system. A local group that represents the default account. (DOMAIN_ALIAS_RID_DEFAULT_ACCOUNT)'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-581'
        }
        'S-1-5-32-582'                                                   = [PSCustomObject]@{
            'Name'            = 'DOMAIN_ALIAS_RID_STORAGE_REPLICA_ADMINS'
            'NTAccount'       = 'BUILTIN\DOMAIN_ALIAS_RID_STORAGE_REPLICA_ADMINS'
            'Description'     = 'A local group that represents storage replica admins. (DOMAIN_ALIAS_RID_STORAGE_REPLICA_ADMINS)'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-582'
        }
        'S-1-5-32-583'                                                   = [PSCustomObject]@{
            'Name'            = 'DOMAIN_ALIAS_RID_DEVICE_OWNERS'
            'NTAccount'       = 'BUILTIN\Device Owners'
            'Description'     = 'A local group that represents can make settings expected for Device Owners. (DOMAIN_ALIAS_RID_DEVICE_OWNERS)'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-583'
        }
        # Additional SIDs found on local machine via discovery
        'S-1-2-0'                                                        = [PSCustomObject]@{
            'Name'            = 'LOCAL'
            'Description'     = 'Users who sign in to terminals that are locally (physically) connected to the system.'
            'NTAccount'       = 'LOCAL SID AUTHORITY\LOCAL'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-2-0'
        }
        'S-1-3-1'                                                        = [PSCustomObject]@{
            'Name'            = 'CREATOR GROUP'
            'Description'     = 'A security identifier to be replaced by the primary-group SID of the user who created a new object. Use this SID in inheritable ACEs.'
            'NTAccount'       = 'CREATOR SID AUTHORITY\CREATOR GROUP'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-3-1'
        }
        'S-1-3-2'                                                        = [PSCustomObject]@{
            'Name'            = 'CREATOR OWNER SERVER'
            'Description'     = "A placeholder in an inheritable ACE. When the ACE is inherited, the system replaces this SID with the SID for the object's owner server and stores information about who created a given object or file."
            'NTAccount'       = 'CREATOR SID AUTHORITY\CREATOR OWNER SERVER'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-3-2'
        }
        'S-1-3-3'                                                        = [PSCustomObject]@{
            'Name'            = 'CREATOR GROUP SERVER'
            'Description'     = "A placeholder in an inheritable ACE. When the ACE is inherited, the system replaces this SID with the SID for the object's group server and stores information about the groups that are allowed to work with the object."
            'NTAccount'       = 'CREATOR SID AUTHORITY\CREATOR GROUP SERVER'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-3-3'
        }
        'S-1-3-4'                                                        = [PSCustomObject]@{
            'Name'            = 'OWNER RIGHTS'
            'Description'     = 'A group that represents the current owner of the object. When an ACE that carries this SID is applied to an object, the system ignores the implicit READ_CONTROL and WRITE_DAC permissions for the object owner.'
            'NTAccount'       = 'CREATOR SID AUTHORITY\OWNER RIGHTS'
            'SchemaClassName' = 'user'
            'SID'             = 'S-1-3-4'
        }
        'S-1-5-32'                                                       = [PSCustomObject]@{
            'Name'            = 'BUILTIN'
            'Description'     = 'NT AUTHORITY\BUILTIN'
            'NTAccount'       = 'NT AUTHORITY\BUILTIN'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-5-32'
        }
        'S-1-5-80-1594061079-2000966165-462148798-751814865-2644087104'  = [PSCustomObject]@{
            'Name'            = 'LxpSvc'
            'Description'     = 'Used by the Language Experience Service to provide support for deploying and configuring localized Windows resources.'
            'NTAccount'       = 'NT SERVICE\LxpSvc'
            'SchemaClassName' = 'service'
            'SID'             = 'S-1-5-80-1594061079-2000966165-462148798-751814865-2644087104'
        }
        'S-1-5-80-4230913304-2206818457-801678004-120036174-1892434133'  = [PSCustomObject]@{
            'Name'            = 'TapiSrv'
            'NTAccount'       = 'NT SERVICE\TapiSrv'
            'Description'     = 'Used by the TAPI server to provide the central repository of telephony on data on a computer.'
            'SchemaClassName' = 'service'
            'SID'             = 'S-1-5-80-4230913304-2206818457-801678004-120036174-1892434133'
        }
        'S-1-5-84-0-0-0-0-0'                                             = [PSCustomObject]@{
            #https://learn.microsoft.com/en-us/windows-hardware/drivers/wdf/controlling-device-access
            'Description'     = "A security identifier that identifies UMDF drivers."
            'Name'            = 'SDDL_USER_MODE_DRIVERS'
            'NTAccount'       = "NT SERVICE\SDDL_USER_MODE_DRIVERS"
            'SchemaClassName' = 'service'
            'SID'             = $SID
        }
    }
}


<#
COMPUTER-SPECIFIC SIDs


        'S-1-5-21-1340649458-2707494813-4121304102-1000'                 = [PSCustomObject]@{
            'Name'        = 'WinRMRemoteWMIUsers__'
            'Description' = 'Members can access WMI resources over management protocols (such as WS-Management via the Windows Remote Management service). This applies only to WMI namespaces 
            that grant access to the user.'
            'SID'         = 'S-1-5-21-1340649458-2707494813-4121304102-1000'
        }
        'S-1-5-21-1340649458-2707494813-4121304102-1001'                 = [PSCustomObject]@{
            'Name'        = 'FirstAccountCreatedEndsIn1001'
            'Description' = ''
            'SID'         = 'S-1-5-21-1340649458-2707494813-4121304102-1001'
        }
        'S-1-5-21-1340649458-2707494813-4121304102-1003'                 = [PSCustomObject]@{
            'Name'        = 'GuestAccount'
            'Description' = ''
            'SID'         = 'S-1-5-21-1340649458-2707494813-4121304102-1003'
        }
        'S-1-5-21-1340649458-2707494813-4121304102-500'                  = [PSCustomObject]@{
            'Name'        = 'Administrator'
            'Description' = 'Built-in account for administering the computer/domain'
            'SID'         = 'S-1-5-21-1340649458-2707494813-4121304102-500'
        }
        'S-1-5-21-1340649458-2707494813-4121304102-501'                  = [PSCustomObject]@{
            'Name'        = 'Guest'
            'Description' = 'Built-in account for guest access to the computer/domain'
            'SID'         = 'S-1-5-21-1340649458-2707494813-4121304102-501'
        }
        'S-1-5-21-1340649458-2707494813-4121304102-503'                  = [PSCustomObject]@{
            'Name'        = 'DefaultAccount'
            'Description' = 'A user account managed by the system.'
            'SID'         = 'S-1-5-21-1340649458-2707494813-4121304102-503'
        }
        'S-1-5-21-1340649458-2707494813-4121304102-504'                  = [PSCustomObject]@{
            'Name'        = 'WDAGUtilityAccount'
            'Description' = 'A user account managed and used by the system for Windows Defender Application Guard scenarios.'
            'SID'         = 'S-1-5-21-1340649458-2707494813-4121304102-504'
        }
#>
function Get-ParentDomainDnsName {
    param (

        # NetBIOS name of the domain whose parent domain DNS to return
        [string]$DomainNetbios,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

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

        # Existing CIM session to the computer (to avoid creating redundant CIM sessions)
        [CimSession]$CimSession,

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        [switch]$RemoveCimSession

    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        Buffer = $LogBuffer
        WhoAmI       = $WhoAmI
    }

    if (-not $CimSession) {
        Write-LogMsg @LogParams -Text "Get-CachedCimSession -ComputerName '$DomainNetbios'"
        $CimSession = Get-CachedCimSession -ComputerName $DomainNetbios -ThisFqdn $ThisFqdn -CimCache $CimCache @LoggingParams
    }

    Write-LogMsg @LogParams -Text "((Get-CachedCimInstance -ComputerName '$DomainNetbios' -ClassName CIM_ComputerSystem -ThisFqdn '$ThisFqdn').domain # for '$DomainNetbios'"
    $ParentDomainDnsName = (Get-CachedCimInstance -ComputerName $DomainNetbios -ClassName CIM_ComputerSystem -ThisFqdn $ThisFqdn -KeyProperty Name -CimCache $CimCache @LoggingParams).domain

    if ($ParentDomainDnsName -eq 'WORKGROUP' -or $null -eq $ParentDomainDnsName) {
        # For workgroup computers there is no parent domain DNS (workgroups operate on NetBIOS)
        # There could also be unexpeted scenarios where the parent domain DNS is null
        # In all of these cases, we will use the primary DNS search suffix (that is where the OS would attempt to register DNS records for the computer)
        Write-LogMsg @LogParams -Text "(Get-DnsClientGlobalSetting -CimSession `$CimSession).SuffixSearchList[0] # for '$DomainNetbios'"
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
        Get-TrustedDomain

        Get the trusted domains of the current computer
        .NOTES
    #>
    [OutputType([PSCustomObject])]
    param (

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        $ThisHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Log messages which have not yet been written to disk
        [hashtable]$LogBuffer = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug'

    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        Buffer       = $LogBuffer
        WhoAmI       = $WhoAmI
    }

    # Errors are expected on non-domain-joined systems
    # Redirecting the error stream to null only suppresses the error in the console; it will still be in the transcript
    # Instead, redirect the error stream to the output stream and filter out the errors by type
    Write-LogMsg @LogParams -Text "$('& nltest /domain_trusts 2>&1')"
    $nltestresults = & nltest /domain_trusts 2>&1

    $RegExForEachTrust = '(?<index>[\d]*): (?<netbios>\S*) (?<dns>\S*).*'
    ForEach ($Result in $nltestresults) {
        if ($Result.GetType() -eq [string]) {
            if ($Result -match $RegExForEachTrust) {
                [PSCustomObject]@{
                    DomainFqdn    = $Matches.dns
                    DomainNetbios = $Matches.netbios
                }
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
        [System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrators') | Get-WinNTGroupMember

        Get members of the local Administrators group
    #>

    [OutputType([System.DirectoryServices.DirectoryEntry])]

    param (

        # DirectoryEntry [System.DirectoryServices.DirectoryEntry] of the WinNT group whose members to get
        [Parameter(ValueFromPipeline)]
        $DirectoryEntry,

        # Properties of the group members to find in the directory
        [string[]]$PropertiesToLoad,

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

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

    begin {

        $Log = @{
            ThisHostname = $ThisHostname
            Type         = $DebugOutputStream
            Buffer       = $LogBuffer
            WhoAmI       = $WhoAmI
        }

        $LogThis = @{
            ThisHostname = $ThisHostname
            LogBuffer    = $LogBuffer
            WhoAmI       = $WhoAmI
        }

        # Add the bare minimum required properties (TODO: distinguished desirable but not mandatory properties e.g. Department)
        $PropertiesToLoad = $PropertiesToLoad + @(
            'Department',
            'description',
            'distinguishedName',
            'grouptype',
            'managedby',
            'member',
            'name',
            'objectClass',
            'objectSid',
            'operatingSystem',
            'primaryGroupToken',
            'samAccountName',
            'Title'
        )

        $PropertiesToLoad = $PropertiesToLoad |
        Sort-Object -Unique

        $MemberParams = @{
            DirectoryEntryCache = $DirectoryEntryCache
            DomainsByNetbios    = $DomainsByNetbios
            CimCache            = $CimCache
            ThisFqdn            = $ThisFqdn
        }

        $GetSearch = @{ PropertiesToLoad = $PropertiesToLoad }

        $ExpandParams = @{
            DomainsByFqdn = $DomainsByFqdn
            DomainsBySid  = $DomainsBySid
        }

    }

    process {

        ForEach ($ThisDirEntry in $DirectoryEntry) {

            $LogSuffix = "# For '$($ThisDirEntry.Path)'"
            $ThisSplitPath = Split-DirectoryPath -DirectoryPath $ThisDirEntry.Path
            $SourceDomain = $ThisSplitPath['Domain']

            if (
                $null -ne $ThisDirEntry.Properties['groupType'] -or
                $ThisDirEntry.schemaclassname -in @('group', 'SidTypeWellKnownGroup', 'SidTypeAlias')
            ) {

                $DirectoryMembers = Invoke-IADsGroupMembersMethod -DirectoryEntry $ThisDirEntry
                Write-LogMsg @Log -Text " # $(@($DirectoryMembers).Count) members found $LogSuffix"

                $MembersToGet = @{
                    'WinNTMembers' = @()
                }

                Find-WinNTGroupMember -ComObject $DirectoryMembers -Out $MembersToGet -LogSuffix $LogSuffix -DirectoryEntry $DirectoryEntry -SourceDomain $SourceDomain -Log $Log -DomainsByNetbios $DomainsByNetbios

                # Get and Expand the directory entries for the WinNT group members
                ForEach ($ThisMember in $MembersToGet['WinNTMembers']) {

                    Write-LogMsg @Log -Text "Get-DirectoryEntry -DirectoryPath '$ThisMember' $LogSuffix"
                    $MemberDirectoryEntry = Get-DirectoryEntry -DirectoryPath $ThisMember @GetSearch @MemberParams @LogThis
                    Expand-WinNTGroupMember -DirectoryEntry $MemberDirectoryEntry @MemberParams @ExpandParams @LogThis

                }

                # Remove the WinNTMembers key from the hashtable so the only remaining keys are distinguishedName(s) of LDAP directories
                $MembersToGet.Remove('WinNTMembers')

                # Get and Expand the directory entries for the LDAP group members
                ForEach ($MemberPath in $MembersToGet.Keys) {

                    $ThisMemberToGet = $MembersToGet[$MemberPath]
                    Write-LogMsg @Log -Text "Search-Directory -DirectoryPath '$MemberPath' -Filter '(|$ThisMemberToGet)' $LogSuffix"
                    $MemberDirectoryEntries = Search-Directory -DirectoryPath $MemberPath -Filter "(|$ThisMemberToGet)" @GetSearch @MemberParams @LogThis
                    Expand-WinNTGroupMember -DirectoryEntry $MemberDirectoryEntries @MemberParams @ExpandParams @LogThis

                }

            } else {
                Write-LogMsg @Log -Text " # Is not a group $LogSuffix"
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
    #>
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
        $Invoke = "InvokeMethod"
    } ElseIf ($MyInvocation.BoundParameters.ContainsKey("Value")) {
        $Invoke = "SetProperty"
    } Else {
        $Invoke = "GetProperty"
    }
    [__ComObject].InvokeMember($Property, $Invoke, $Null, $ComObject, $Value)
}
function New-FakeDirectoryEntry {

    <#
    Used in place of a DirectoryEntry for certain WinNT security principals that do not have objects in the directory
    The WinNT provider only throws an error if you try to retrieve certain accounts/identities
    #>

    param (
        [string]$DirectoryPath,
        [string]$SID,
        [string]$Description,
        [string]$SchemaClassName,
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
        },

        # Unused but here for convenient splats
        [string]$Name,

        # Unused but here for convenient splats
        [string]$NTAccount

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

    $LastSlashIndex = $IdentityReference.LastIndexOf('\')

    if ($LastSlashIndex -eq -1) {
        $Name = $IdentityReference
    } else {
        $StartIndex = $LastSlashIndex + 1
        $Name = $IdentityReference.Substring( $StartIndex , $IdentityReference.Length - $StartIndex )
    }

    $ServerNetBIOS = $AdsiServer.Netbios
    $Log = @{ ThisHostname = $ThisHostname ; Type = $DebugOutputStream ; Buffer = $LogBuffer ; WhoAmI = $WhoAmI }
    $LogThis = @{ ThisHostname = $ThisHostname ; LogBuffer = $LogBuffer ; WhoAmI = $WhoAmI ; DebugOutputStream = $DebugOutputStream }
    $splat1 = @{ WellKnownSidBySid = $WellKnownSidBySid ; WellKnownSidByCaption = $WellKnownSidByCaption }
    $splat2 = @{ DomainsByFqdn = $DomainsByFqdn ; DomainsByNetbios = $DomainsByNetbios ; DomainsBySid = $DomainsBySid }
    $splat3 = @{ AdsiServer = $AdsiServer; ServerNetBIOS = $ServerNetBIOS }
    $splat4 = @{ DomainsByFqdn = $DomainsByFqdn ; DomainsBySid = $DomainsBySid }
    $splat5 = @{ DirectoryEntryCache = $DirectoryEntryCache; DomainsByNetbios = $DomainsByNetbios; ThisFqdn = $ThisFqdn }
    $splat8 = @{ CimCache = $CimCache ; IdentityReference = $IdentityReference }
    $GetDirectoryEntryParams = @{ DirectoryEntryCache = $DirectoryEntryCache ; DomainsByNetbios = $DomainsByNetbios; DomainsBySid = $DomainsBySid }
    $splat10 = @{ GetDirectoryEntryParams = $GetDirectoryEntryParams }

    # Many Well-Known SIDs cannot be translated with the Translate method.
    # Instead Get-AdsiServer used CIM to find instances of the Win32_Account class on the server
    # and update the Win32_AccountBySID and Win32_AccountByCaption caches.
    # Get-KnownSidHashTable and Get-KnownSID are hard-coded with additional well-known SIDs.
    # Search these caches now.
    $CacheResult = Resolve-IdRefCached -IdentityReference $IdentityReference @splat2 @splat3 @LogThis

    if ($CacheResult) {

        #Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # Cache hit"
        return $CacheResult

    }

    #Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # Cache miss"

    # If no match was found in any cache, the path forward depends on the IdentityReference.
    switch -Wildcard ($IdentityReference) {

        "S-1-*" {

            # IdentityReference is a Revision 1 SID
            $Resolved = Resolve-IdRefSID -AdsiServersByDns $AdsiServersByDns @splat3 @splat4 @splat5 @splat8 @LogThis
            return $Resolved

        }

        "NT SERVICE\*" {
            $Resolved = Resolve-IdRefSvc -Name $Name @splat3 @splat4 @splat5 @splat8 @LogThis
            return $Resolved
        }

        "APPLICATION PACKAGE AUTHORITY\*" {
            $Resolved = Resolve-IdRefAppPkgAuth -Name $Name @splat1 @splat3 @splat4 @splat5 @splat8 @LogThis
            return $Resolved
        }

        "BUILTIN\*" {
            $Resolved = Resolve-IdRefBuiltIn -Name $Name -DomainsBySid $DomainsBySid -DomainsByFqdn $DomainsByFqdn @splat3 @splat5 @splat8 @LogThis
            return $Resolved
        }

    }

    # If no regular expression match was found with any of the known patterns for SIDs or well-known SID authorities, the IdentityReference is an NTAccount.
    # Translate the NTAccount to a SID.

    if ($ServerNetBIOS) {

        # Start by determining the domain DN and DNS name
        $CacheResult = $DomainsByNetbios[$ServerNetBIOS]

        if ($CacheResult) {
            #Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # Domain NetBIOS cache hit for '$ServerNetBIOS'"
        } else {

            #Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # Domain NetBIOS cache miss for '$ServerNetBIOS'"
            $CacheResult = Get-AdsiServer -Netbios $ServerNetBIOS -CimCache $CimCache @splat4 @splat5 @LogThis

        }

        $DomainDn = $CacheResult.DistinguishedName
        $DomainDns = $CacheResult.Dns

        # Try to resolve the account against the server the Access Control Entry came from (which may or may not be the directory server for the account)
        $SIDString = ConvertTo-SidString -Name $Name -ServerNetBIOS $ServerNetBIOS -DebugOutputStream $DebugOutputStream -Log $Log

        if (-not $SIDString) {

            # Try to resolve the account against the domain indicated in its NT Account Name
            # Add this domain to our list of known domains
            $SIDString = Resolve-IdRefSearchDir -DomainDn $DomainDn -Log $Log -LogThis $LogThis -DomainsBySid $DomainsBySid -Name $Name @splat5 @splat6 @splat8

        }

        if (-not $SIDString) {

            # Try to find the DirectoryEntry object directly on the server
            $SIDString = Resolve-IdRefGetDirEntry -LogThis $LogThis -Name $Name -DomainsBySid $DomainsBySid @splat3 @splat10

        }

        # This covers unresolved SIDs for deleted accounts, broken domain trusts, etc.
        if ( '' -eq "$Name" ) {

            $Name = $IdentityReference
            Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # No name could be parsed."

        } else {
            Write-LogMsg @Log -Text " # IdentityReference '$IdentityReference' # Name parsed is '$Name'."
        }

        return [PSCustomObject]@{
            IdentityReference        = $IdentityReference
            SIDString                = $SIDString
            IdentityReferenceNetBios = "$ServerNetBIOS\$Name" #-replace "^$ThisHostname\\", "$ThisHostname\" # to correct capitalization in a PS5-friendly way
            IdentityReferenceDns     = "$DomainDns\$Name"
        }

    }

}
function Resolve-ServiceNameToSID {

    # Use the same math as sc.exe showsid to enrich a Service object with the SID and Status of the service

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
        .INPUTS
        None. Pipeline input is not accepted.
        .OUTPUTS
        [System.DirectoryServices.DirectoryEntry]
        .EXAMPLE
        Search-Directory -Filter ''

        As the current user on a domain-joined computer, bind to the current domain and search for all directory entries matching the LDAP filter
    #>
    param (

        <#
        Path to the directory object to retrieve
        Defaults to the root of the current domain
        #>
        [string]$DirectoryPath = (([adsisearcher]'').SearchRoot.Path),

        # Filter for the LDAP search
        [string]$Filter,

        # Number of records per page of results
        [int]$PageSize = 1000,

        # Additional properties to return
        [string[]]$PropertiesToLoad,

        # Credentials to use
        [pscredential]$Credential,

        # Scope of the search
        [string]$SearchScope = 'subtree',

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        <#
        Hashtable containing cached directory entries so they don't have to be retrieved from the directory again
        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Log messages which have not yet been written to disk
        [hashtable]$LogBuffer = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug'

    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        Buffer       = $LogBuffer
        WhoAmI       = $WhoAmI
    }

    $DirectoryEntryParameters = @{
        DirectoryEntryCache = $DirectoryEntryCache
        DomainsByNetbios    = $DomainsByNetbios
        ThisHostname        = $ThisHostname
        LogBuffer           = $LogBuffer
        WhoAmI              = $WhoAmI
        CimCache            = $CimCache
        ThisFqdn            = $ThisFqdn
    }

    if ($Credential) {
        $DirectoryEntryParameters['Credential'] = $Credential
    }

    if (($null -eq $DirectoryPath -or '' -eq $DirectoryPath)) {
        $CimParams = @{
            CimCache          = $CimCache
            ComputerName      = $ThisFqdn
            DebugOutputStream = $DebugOutputStream
            ThisFqdn          = $ThisFqdn
        }
        $LoggingParams = @{
            ThisHostname = $ThisHostname
            LogBuffer    = $LogBuffer
            WhoAmI       = $WhoAmI
        }
        $Workgroup = (Get-CachedCimInstance -ClassName 'Win32_ComputerSystem' -KeyProperty Name @CimParams @LoggingParams).Workgroup
        $DirectoryPath = "WinNT://$Workgroup/$ThisHostname"
    }
    $DirectoryEntryParameters['DirectoryPath'] = $DirectoryPath

    $DirectoryEntry = Get-DirectoryEntry @DirectoryEntryParameters

    Write-LogMsg @LogParams -Text "`$DirectorySearcher = [System.DirectoryServices.DirectorySearcher]::new(([System.DirectoryServices.DirectoryEntry]::new('$DirectoryPath')))"
    $DirectorySearcher = [System.DirectoryServices.DirectorySearcher]::new($DirectoryEntry)

    if ($Filter) {
        Write-LogMsg @LogParams -Text "`$DirectorySearcher.Filter = '$Filter'"
        $DirectorySearcher.Filter = $Filter
    }

    Write-LogMsg @LogParams -Text "`$DirectorySearcher.PageSize = '$PageSize'"
    $DirectorySearcher.PageSize = $PageSize
    Write-LogMsg @LogParams -Text "`$DirectorySearcher.SearchScope = '$SearchScope'"
    $DirectorySearcher.SearchScope = $SearchScope

    ForEach ($Property in $PropertiesToLoad) {
        Write-LogMsg @LogParams -Text "`$DirectorySearcher.PropertiesToLoad.Add('$Property')"
        $null = $DirectorySearcher.PropertiesToLoad.Add($Property)
    }

    Write-LogMsg @LogParams -Text "`$DirectorySearcher.FindAll()"
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
Export-ModuleMember -Function @('Add-DomainFqdnToLdapPath','Add-SidInfo','ConvertFrom-DirectoryEntry','ConvertFrom-IdentityReferenceResolved','ConvertFrom-PropertyValueCollectionToString','ConvertFrom-ResultPropertyValueCollectionToString','ConvertFrom-SearchResult','ConvertFrom-SidString','ConvertTo-DecStringRepresentation','ConvertTo-DistinguishedName','ConvertTo-DomainNetBIOS','ConvertTo-DomainSidString','ConvertTo-Fqdn','ConvertTo-HexStringRepresentation','ConvertTo-HexStringRepresentationForLDAPFilterString','ConvertTo-SidByteArray','Expand-AdsiGroupMember','Expand-WinNTGroupMember','Find-AdsiProvider','Find-LocalAdsiServerSid','Get-AdsiGroup','Get-AdsiGroupMember','Get-AdsiServer','Get-CurrentDomain','Get-DirectoryEntry','Get-KnownCaptionHashTable','Get-KnownSid','Get-KnownSidHashtable','Get-ParentDomainDnsName','Get-TrustedDomain','Get-WinNTGroupMember','Invoke-ComObject','New-FakeDirectoryEntry','Resolve-IdentityReference','Resolve-ServiceNameToSID','Search-Directory')














































































































































































































































































































































































































