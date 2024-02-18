function Resolve-Ace {
    <#
    .SYNOPSIS
    Use ADSI to lookup info about IdentityReferences from Authorization Rule Collections that came from Discretionary Access Control Lists
    .DESCRIPTION
    Based on the IdentityReference proprety of each Access Control Entry:
    Resolve SID to NT account name and vise-versa
    Resolve well-known SIDs
    Resolve generic defaults like 'NT AUTHORITY' and 'BUILTIN' to the applicable computer or domain name
    Add these properties (IdentityReferenceSID,IdentityReferenceResolved) to the object and return it
    .INPUTS
    [System.Security.AccessControl.AuthorizationRuleCollection]$ACE
    .OUTPUTS
    [PSCustomObject] Original object plus IdentityReferenceSID,IdentityReferenceResolved, and AdsiProvider properties
    .EXAMPLE
    Get-Acl |
    Expand-Acl |
    Resolve-Ace

    Use Get-Acl from the Microsoft.PowerShell.Security module as the source of the access list
    This works in either Windows Powershell or in Powershell
    Get-Acl does not support long paths (>256 characters)
    That was why I originally used the .Net Framework method
    .EXAMPLE
    Get-FolderAce -LiteralPath C:\Test -IncludeInherited |
    Resolve-Ace
    .EXAMPLE
    [System.String]$FolderPath = 'C:\Test'
    [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
    $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor [System.Security.AccessControl.AccessControlSections]::Owner
    $FileSecurity = [System.Security.AccessControl.FileSecurity]::new($DirectoryInfo,$Sections)
    $IncludeExplicitRules = $true
    $IncludeInheritedRules = $true
    $AccountType = [System.Security.Principal.SecurityIdentifier]
    $FileSecurity.GetAccessRules($IncludeExplicitRules,$IncludeInheritedRules,$AccountType) |
    Resolve-Ace

    This uses .Net Core as the source of the access list
    It uses the GetAccessRules method on the [System.Security.AccessControl.FileSecurity] class
    The targetType parameter of the method is used to specify that the accounts in the ACL are returned as SIDs
    .EXAMPLE
    [System.String]$FolderPath = 'C:\Test'
    [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
    $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor
    [System.Security.AccessControl.AccessControlSections]::Owner -bor
    [System.Security.AccessControl.AccessControlSections]::Group
    $DirectorySecurity = [System.Security.AccessControl.DirectorySecurity]::new($DirectoryInfo,$Sections)
    $IncludeExplicitRules = $true
    $IncludeInheritedRules = $true
    $AccountType = [System.Security.Principal.NTAccount]
    $FileSecurity.GetAccessRules($IncludeExplicitRules,$IncludeInheritedRules,$AccountType) |
    Resolve-Ace

    This uses .Net Core as the source of the access list
    It uses the GetAccessRules method on the [System.Security.AccessControl.FileSecurity] class
    The targetType parameter of the method is used to specify that the accounts in the ACL are returned as NT account names (DOMAIN\User)
    .EXAMPLE
    [System.String]$FolderPath = 'C:\Test'
    [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
    [System.Security.AccessControl.DirectorySecurity]$DirectorySecurity = $DirectoryInfo.GetAccessControl('Access')
    [System.Security.AccessControl.AuthorizationRuleCollection]$AuthRules = $DirectorySecurity.Access
    $AuthRules | Resolve-Ace

    Use the .Net Framework (or legacy .Net Core up to 2.2) as the source of the access list
    Only works in Windows PowerShell
    Those versions of .Net had a GetAccessControl method on the [System.IO.DirectoryInfo] class
    This method is removed in modern versions of .Net Core

    .EXAMPLE
    [System.String]$FolderPath = 'C:\Test'
    [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
    $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor [System.Security.AccessControl.AccessControlSections]::Owner
    $FileSecurity = [System.IO.FileSystemAclExtensions]::GetAccessControl($DirectoryInfo,$Sections)

    The [System.IO.FileSystemAclExtensions] class is a Windows-specific implementation
    It provides no known benefit over the cross-platform equivalent [System.Security.AccessControl.FileSecurity]

    .NOTES
    Dependencies:
        Get-DirectoryEntry
        Add-SidInfo
        Get-TrustedDomain
        Find-AdsiProvider

    if ($FolderPath.Length -gt 255) {
        $FolderPath = "\\?\$FolderPath"
    }
#>
    [OutputType([void])]
    param (

        # Authorization Rule Collection of Access Control Entries from Discretionary Access Control Lists
        [Parameter(
            ValueFromPipeline
        )]
        [object]$ACE,

        # Cache of access control lists keyed by path
        [hashtable]$ACLsByPath = [hashtable]::Synchronized(@{}),

        [Parameter(
            ValueFromPipeline
        )]
        [object]$ItemPath,

        # Cache of access control entries keyed by GUID generated in this function
        [hashtable]$ACEsByGUID = ([hashtable]::Synchronized(@{})),

        # Cache of access control entry GUIDs keyed by their resolved identities
        [hashtable]$AceGUIDsByResolvedID = ([hashtable]::Synchronized(@{})),

        # Cache of access control entry GUIDs keyed by their paths
        [hashtable]$AceGUIDsByPath = ([hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        [hashtable]$Win32AccountsBySID = ([hashtable]::Synchronized(@{})),

        [hashtable]$Win32AccountsByCaption = ([hashtable]::Synchronized(@{})),

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
        [string]$DebugOutputStream = 'Debug',

        [string[]]$ACEPropertyName = (Get-Member -InputObject $ACE -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name,

        # Will be set as the Source property of the output object.
        # Intended to reflect permissions resulting from Ownership rather than Discretionary Access Lists
        [string]$Source,

        # String translations indexed by value in the [System.Security.AccessControl.InheritanceFlags] enum
        # Parameter default value is on a single line as a workaround to a PlatyPS bug
        [string[]]$InheritanceFlagResolved = @('this folder but not subfolders','this folder and subfolders','this folder and files, but not subfolders','this folder, subfolders, and files')

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

    $IdentityReference = $ACE.IdentityReference #.ToString()
    
    $ResolveDomainDNSParams = @{
        IdentityReference = $IdentityReference
        ItemPath          = $ItemPath
        DomainsByNetBIOS  = $DomainsByNetbios
        DomainsBySid      = $DomainsBySid
        ThisFqdn          = $ThisFqdn
        CimCache          = $CimCache
    }
    
    $DomainDNS = Resolve-IdentityReferenceDomainDNS @ResolveDomainDNSParams @LoggingParams

    $GetAdsiServerParams = @{
        Fqdn                   = $DomainDNS
        CimCache               = $CimCache
        DirectoryEntryCache    = $DirectoryEntryCache
        DomainsByFqdn          = $DomainsByFqdn
        DomainsByNetbios       = $DomainsByNetbios
        DomainsBySid           = $DomainsBySid
        ThisFqdn               = $ThisFqdn
        Win32AccountsBySID     = $Win32AccountsBySID
        Win32AccountsByCaption = $Win32AccountsByCaption
    }

    Write-LogMsg @LogParams -Text "`$AdsiServer = Get-AdsiServer -Fqdn '$DomainDNS' -ThisFqdn '$ThisFqdn'"
    $AdsiServer = Get-AdsiServer @GetAdsiServerParams @LoggingParams

    $ResolveIdentityReferenceParams = @{
        IdentityReference      = $IdentityReference
        AdsiServer             = $AdsiServer
        Win32AccountsBySID     = $Win32AccountsBySID
        Win32AccountsByCaption = $Win32AccountsByCaption
        DirectoryEntryCache    = $DirectoryEntryCache
        DomainsBySID           = $DomainsBySID
        DomainsByNetbios       = $DomainsByNetbios
        DomainsByFqdn          = $DomainsByFqdn
        ThisFqdn               = $ThisFqdn
        CimCache               = $CimCache
    }

    Write-LogMsg @LogParams -Text "Resolve-IdentityReference -IdentityReference '$IdentityReference' -AdsiServer `$AdsiServer # ADSI server '$($AdsiServer.AdsiProvider)://$($AdsiServer.Dns)'"
    $ResolvedIdentityReference = Resolve-IdentityReference @ResolveIdentityReferenceParams @LoggingParams

    # TODO: add a param to offer DNS instead of or in addition to NetBIOS
        
    $ObjectProperties = @{
        Access                    = "$($ACE.AccessControlType) $($ACE.FileSystemRights) $($InheritanceFlagResolved[$ACE.InheritanceFlags])"
        AdsiProvider              = $AdsiServer.AdsiProvider
        AdsiServer                = $AdsiServer.Dns
        IdentityReferenceSID      = $ResolvedIdentityReference.SIDString
        IdentityReferenceResolved = $ResolvedIdentityReference.IdentityReferenceNetBios
        Path                      = $ItemPath
        SourceOfAccess            = $Source
        PSTypeName                = 'Permission.AccessControlEntry'
    }

    ForEach ($ThisProperty in $ACEPropertyName) {
        $ObjectProperties[$ThisProperty] = $ACE.$ThisProperty
    }
    
    $OutputObject = [PSCustomObject]$ObjectProperties
    $Guid = [guid]::NewGuid()    
    Add-CacheItem -Cache $ACEsByGUID -Key $Guid -Value $OutputObject -Type ([object])
    $Type = [guid]
    Add-CacheItem -Cache $AceGUIDsByResolvedID -Key $OutputObject.IdentityReferenceResolved -Value $Guid -Type $Type
    Add-CacheItem -Cache $AceGUIDsByPath -Key $OutputObject.Path -Value $Guid -Type $Type
    
    <#
    $ACEs = $ACEsByGUID[$Guid]
    if (-not $ACEs) {
        $ACEs = [System.Collections.Generic.List[object]]::new()
    }
    $ACEs.Add($OutputObject)
    $ACEsByGUID[$Guid] = $ACEs

    $Key = $OutputObject.IdentityReferenceResolved
    $AceGuids = $AceGUIDsByResolvedID[$Key]
    if (-not $AceGuids) {
        $AceGuids = [System.Collections.Generic.List[guid]]::new()
    }
    $AceGuids.Add($Guid)
    $AceGUIDsByResolvedID[$Key] = $AceGuids

    $Key = $OutputObject.Path
    $AceGuids = $AceGUIDsByPath[$Key]
    if (-not $AceGuids) {
        $AceGuids = [System.Collections.Generic.List[guid]]::new()
    }
    $AceGuids.Add($Guid)
    $AceGUIDsByPath[$Key] = $AceGuids
    #>

}
