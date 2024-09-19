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

    $SidTypes = @{
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

    $KnownSIDs = @{
        <#
        https://devblogs.microsoft.com/oldnewthing/20220502-00/?p=106550
        SIDs of the form S-1-15-2-xxx are app container SIDs.
        These SIDs are present in the token of apps running in an app container, and they encode the app container identity.
        According to the rules for Mandatory Integrity Control, objects default to allowing write access only to medium integrity level (IL) or higher.
        App containers run at low IL, so they by default don’t have write access to such objects.
        An object can add access control entries (ACEs) to its access control list (ACL) to grant access to low IL.
        There are a few security identifiers (SIDs) you may see when an object extends access to low IL.
        #>
        'S-1-15-2-1'                                                     = @{
            'Description'     = 'All applications running in an app package context have this app container SID. SECURITY_BUILTIN_PACKAGE_ANY_PACKAGE'
            'Name'            = 'ALL APPLICATION PACKAGES'
            'SchemaClassName' = 'group'
        }
        'S-1-15-2-2'                                                     = @{
            'Description'     = 'Some applications running in an app package context may have this app container SID. SECURITY_BUILTIN_PACKAGE_ANY_RESTRICTED_PACKAGE'
            'Name'            = 'ALL RESTRICTED APPLICATION PACKAGES'
            'SchemaClassName' = 'group'
        }
        'S-1-15-7'                                                       = @{
            'Description'     = 'A user who has connected to the computer without supplying a user name and password. Not a member of Authenticated Users.'
            'Name'            = 'ANONYMOUS LOGON'
            'SchemaClassName' = 'user'
        }
        'S-1-5-11'                                                       = @{
            'Description'     = 'A group that includes all users and computers with identities that have been authenticated.'
            'Name'            = 'Authenticated Users'
            'SchemaClassName' = 'group'
        }
        'S-1-3-0'                                                        = @{
            'Description'     = 'A SID to be replaced by the SID of the user who creates a new object. This SID is used in inheritable ACEs.'
            'Name'            = 'CREATOR OWNER'
            'SchemaClassName' = 'user'
        }
        'S-1-1-0'                                                        = @{
            'Description'     = "A group that includes all users; aka 'World'."
            'Name'            = 'Everyone'
            'SchemaClassName' = 'group'
        }
        'S-1-5-4'                                                        = @{
            'Description'     = 'Users who log on for interactive operation. This is a group identifier added to the token of a process when it was logged on interactively.'
            'Name'            = 'INTERACTIVE'
            'SchemaClassName' = 'group'
        }
        'S-1-5-19'                                                       = @{
            'Description'     = 'A local service account'
            'Name'            = 'LOCAL SERVICE'
            'SchemaClassName' = 'user'
        }
        'S-1-5-20'                                                       = @{
            'Description'     = 'A network service account'
            'Name'            = 'NETWORK SERVICE'
            'SchemaClassName' = 'user'
        }
        'S-1-5-18'                                                       = @{
            'Description'     = 'By default, the SYSTEM account is granted Full Control permissions to all files on an NTFS volume'
            'Name'            = 'SYSTEM'
            'SchemaClassName' = 'computer'
        }
        'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464' = @{
            'Description'     = 'Most of the operating system files are owned by the TrustedInstaller security identifier (SID)'
            'Name'            = 'TrustedInstaller'
            'SchemaClassName' = 'user'
        }
        'S-1-5-80-880578595-1860270145-482643319-2788375705-1540778122'  = @{
            'Description'     = 'Windows Event Log service account'
            'Name'            = 'EventLog'
            'SchemaClassName' = 'user'
        }
        'S-1-5-80-242729624-280608522-2219052887-3187409060-2225943459'  = @{
            'Description'     = 'Windows Cryptographic service account'
            'Name'            = 'CryptSvc'
            'SchemaClassName' = 'user'
        }
        'S-1-5-80-3139157870-2983391045-3678747466-658725712-1809340420' = @{
            'Description'     = 'Windows Diagnostics service account'
            'Name'            = 'WdiServiceHost'
            'SchemaClassName' = 'user'
        }
        <#
        # https://devblogs.microsoft.com/oldnewthing/20220503-00/?p=106557
        SIDs of the form S-1-15-3-xxx are app capability SIDs.
        These SIDs are present in the token of apps running in an app container, and they encode the app capabilities possessed by the app.
        The rules for Mandatory Integrity Control say that objects default to allowing write access only to medium integrity level (IL) or higher.
        Granting access to these app capability SIDs permit access from apps running at low IL, provided they possess the matching capability.

        Autogenerated
        S-1-15-3-x1-x2-x3-x4	device capability
        S-1-15-3-1024-x1-x2-x3-x4-x5-x6-x7-x8	app capability

        You can sort of see how these assignments evolved.
        At first, the capability RIDs were assigned by an assigned numbers authority, so anybody who wanted a capability had to apply for a number.
        After about a dozen of these, the assigned numbers team (probably just one person) realized that this had the potential to become a real bottleneck, so they switched to an autogeneration mechanism, so that people who needed a capability SID could just generate their own.
        For device capabilities, the four 32-bit decimal digits represent the 16 bytes of the device interface GUID.
        Let’s decode this one: S-1-15-3-787448254-1207972858-3558633622-1059886964.

        787448254	1207972858	3558633622	1059886964
        0x2eef81be	0x480033fa	0xd41c7096	0x3f2c9774
        be	81	ef	2e	fa	33	00	48	96	70	1c	d4	74	97	2c	3f
        2eef81be	33fa	4800	96	70	1c	d4	74	97	2c	3f
        {2eef81be-	33fa-	4800-	96	70-	1c	d4	74	97	2c	3f}

        And we recognize {2eef81be-33fa-4800-9670-1cd474972c3f} as DEVINTERFACE_AUDIO_CAPTURE, so this is the microphone device capability.
        For app capabilities, the eight 32-bit decimal numbers represent the 32 bytes of the SHA256 hash of the capability name.
        You can programmatically generate these app capability SIDs by calling Derive­Capability­Sids­From­Name.
        #>
        'S-1-15-3-1'                                                     = @{
            'Description'     = 'internetClient containerized app capability SID'
            'Name'            = 'internetClient'
            'SchemaClassName' = 'user'
        }
        'S-1-15-3-2'                                                     = @{
            'Description'     = 'internetClientServer containerized app capability SID'
            'Name'            = 'internetClientServer'
            'SchemaClassName' = 'user'
        }
        'S-1-15-3-3'                                                     = @{
            'Description'     = 'privateNetworkClientServer containerized app capability SID'
            'Name'            = 'privateNetworkClientServer'
            'SchemaClassName' = 'user'
        }
        'S-1-15-3-4'                                                     = @{
            'Description'     = 'picturesLibrary containerized app capability SID'
            'Name'            = 'picturesLibrary'
            'SchemaClassName' = 'user'
        }
        'S-1-15-3-5'                                                     = @{
            'Description'     = 'videosLibrary containerized app capability SID'
            'Name'            = 'videosLibrary'
            'SchemaClassName' = 'user'
        }
        'S-1-15-3-6'                                                     = @{
            'Description'     = 'musicLibrary containerized app capability SID'
            'Name'            = 'musicLibrary'
            'SchemaClassName' = 'user'
        }
        'S-1-15-3-7'                                                     = @{
            'Description'     = 'documentsLibrary containerized app capability SID'
            'Name'            = 'documentsLibrary'
            'SchemaClassName' = 'user'
        }
        'S-1-15-3-8'                                                     = @{
            'Description'     = 'enterpriseAuthentication containerized app capability SID'
            'Name'            = 'enterpriseAuthentication'
            'SchemaClassName' = 'user'
        }
        'S-1-15-3-9'                                                     = @{
            'Description'     = 'sharedUserCertificates containerized app capability SID'
            'Name'            = 'sharedUserCertificates'
            'SchemaClassName' = 'user'
        }
        'S-1-15-3-10'                                                    = @{
            'Description'     = 'removableStorage containerized app capability SID'
            'Name'            = 'removableStorage'
            'SchemaClassName' = 'user'
        }
        'S-1-15-3-11'                                                    = @{
            'Description'     = 'appointments containerized app capability SID'
            'Name'            = 'appointments'
            'SchemaClassName' = 'user'
        }
        'S-1-15-3-12'                                                    = @{
            'Description'     = 'contacts containerized app capability SID'
            'Name'            = 'contacts'
            'SchemaClassName' = 'user'
        }
        'S-1-15-3-4096'                                                  = @{
            'Description'     = 'internetExplorer containerized app capability SID'
            'Name'            = 'internetExplorer'
            'SchemaClassName' = 'user'
        }
    }

    $KnownNames = @{}
    ForEach ($KnownSID in $KnownSIDs.Keys) {
        $KnownNames[$KnownSIDs[$KnownSID]] = $Known
    }

    $LastSlashIndex = $DirectoryPath.LastIndexOf('/')
    $StartIndex = $LastSlashIndex + 1
    $AccountName = $DirectoryPath.Substring($StartIndex, $DirectoryPath.Length - $StartIndex)
    $ParentDirectoryPath = $DirectoryPath.Substring(0, $LastSlashIndex)
    $FirstSlashIndex = $ParentDirectoryPath.IndexOf('/')
    $ParentPath = $ParentDirectoryPath.Substring($FirstSlashIndex + 2, $ParentDirectoryPath.Length - $FirstSlashIndex - 2)
    if ($ParentPath.Contains('/')) {
        $FirstSlashIndex = $ParentPath.IndexOf('/')
        $Server = $ParentPath.Substring(0, $FirstSlashIndex)
    } else {
        $Server = $ParentPath
    }

    $CimServer = $CimCache[$Server]

    <#
    The WinNT provider only throws an error if you try to retrieve certain accounts/identities
    We will create own dummy objects instead of performing the query
    #>
    if ($CimServer) {

        Write-LogMsg @LogParams -Text " # CIM server cache hit for '$Server'"
        $ID = "$Server\$AccountName"
        $CimCacheResult = $CimServer['Win32_AccountByCaption'][$ID]

        if ($CimCacheResult) {

            Write-LogMsg @LogParams -Text " # Win32_AccountByCaption CIM instance cache hit for '$ID' on '$Server'"

            $FakeDirectoryEntry = @{
                'Description'   = $CimCacheResult.Description
                'SID'           = $CimCacheResult.SID
                'DirectoryPath' = $DirectoryPath
            }

            $SIDCacheResult = $KnownSIDs[$CimCacheResult.SID]

            if ($SIDCacheResult) {

                $FakeDirectoryEntry['SchemaClassName'] = $SIDCacheResult['SchemaClassName']

            } else {

                Write-LogMsg @LogParams -Text " # Known SIDs cache miss for '$($CimCacheResult.SID)'"
                $NameCacheResult = $KnownNames[$AccountName]

                if ($NameCacheResult) {
                    $FakeDirectoryEntry['Description'] = $NameCacheResult['Description']
                    $FakeDirectoryEntry['SchemaClassName'] = $NameCacheResult['SchemaClassName']
                } else {
                    Write-LogMsg @LogParams -Text " # Known Account Names cache miss for '$AccountName'"
                }

            }


            if ($FakeDirectoryEntry['Description'] -eq $ID) {
                if ($SIDCacheResult) {
                    $FakeDirectoryEntry['Description'] = $SIDCacheResult['Description']
                }
            }

            if ($CimCacheResult.SidType) {
                $FakeDirectoryEntry['SchemaClassName'] = $SidTypes[$CimCacheResult.SidType]
            }

            $DirectoryEntry = New-FakeDirectoryEntry @FakeDirectoryEntry

        } else {
            Write-LogMsg @LogParams -Text " # Win32_AccountByCaption CIM instance cache miss for '$ID' on '$Server'"
        }

    } else {
        Write-LogMsg @LogParams -Text " # CIM server cache miss for '$Server'"
    }

    if ($null -eq $DirectoryEntry) {

        switch -regex ($DirectoryPath) {
            # Workgroup computers do not return a DirectoryEntry with a SearchRoot Path so this ends up being an empty string
            # This is also invoked when DirectoryPath is null for any reason
            # We will return a WinNT object representing the local computer's WinNT directory
            '^$' {
                Write-LogMsg @LogParams -Text "'$ThisHostname' does not seem to be domain-joined since the SearchRoot Path is empty. Defaulting to WinNT provider for localhost instead."

                $CimParams = @{
                    CimCache          = $CimCache
                    ComputerName      = $ThisFqdn
                    DebugOutputStream = $DebugOutputStream
                    ThisFqdn          = $ThisFqdn
                }
                $Workgroup = (Get-CachedCimInstance -ClassName 'Win32_ComputerSystem' -KeyProperty Name @CimParams @LoggingParams).Workgroup

                $DirectoryPath = "WinNT://$Workgroup/$ThisHostname"
                Write-LogMsg @LogParams -Text "[System.DirectoryServices.DirectoryEntry]::new('$DirectoryPath')"

                if ($Credential) {
                    $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath, $($Credential.UserName), $($Credential.GetNetworkCredential().password))
                } else {
                    $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath)
                }

                $SampleUser = @($DirectoryEntry.PSBase.Children |
                    Where-Object -FilterScript { $_.schemaclassname -eq 'user' })[0] |
                Add-SidInfo -DomainsBySid $DomainsBySid @LoggingParams

                $DirectoryEntry |
                Add-Member -MemberType NoteProperty -Name 'Domain' -Value $SampleUser.Domain -Force
                break

            }
            # Otherwise the DirectoryPath is an LDAP path or a WinNT path (treated the same at this stage)
            default {

                Write-LogMsg @LogParams -Text "[System.DirectoryServices.DirectoryEntry]::new('$DirectoryPath')"
                if ($Credential) {
                    $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath, $($Credential.UserName), $($Credential.GetNetworkCredential().password))
                } else {
                    $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath)
                }
                break

            }

        }
    }

    if ($null -eq $DirectoryEntryCache[$DirectoryPath]) {

        $DirectoryEntryCache[$DirectoryPath] = $DirectoryEntry
    } else {
        #Write-LogMsg @LogParams -Text "DirectoryEntryCache hit for '$DirectoryPath'"
        $DirectoryEntry = $DirectoryEntryCache[$DirectoryPath]
    }

    if ($PropertiesToLoad) {
        try {
            # If the $DirectoryPath was invalid, this line will return an error
            $null = $DirectoryEntry.RefreshCache($PropertiesToLoad)

        } catch {
            $LogParams['Type'] = 'Warning' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat

            # Ensure that the error message appears on 1 line
            # Use .Trim() to remove leading and trailing whitespace
            # Use -replace to remove an errant line break in the following specific error I encountered: The following exception occurred while retrieving member "RefreshCache": "The group name could not be found.`r`n"
            Write-LogMsg @LogParams -Text "'$DirectoryPath' could not be retrieved. Error: $($_.Exception.Message.Trim() -replace '\s"',' "')"

            return
        }
    }
    return $DirectoryEntry

}
