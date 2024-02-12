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

        # Cache of access control entries keyed by their resolved identities
        [hashtable]$ACEsByResolvedID = ([hashtable]::Synchronized(@{})),

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

        [string[]]$ACEPropertyName = (Get-Member -InputObject $ACE -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name

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

    $IdentityReference = $ACE.IdentityReference.ToString()

    if ([string]::IsNullOrEmpty($IdentityReference)) {
        continue
    }

    $ThisServerDns = $null
    $DomainNetBios = $null

    # Remove the PsProvider prefix from the path string
    #if (-not [string]::IsNullOrEmpty($ACE.SourceAccessList.Path)) {
    #    $LiteralPath = $ACE.SourceAccessList.Path -replace [regex]::escape("$($ACE.SourceAccessList.PsProvider)::"), ''
    #} else {
    #    $LiteralPath = $LiteralPath -replace [regex]::escape("$($ACE.SourceAccessList.PsProvider)::"), ''
    #}

    switch -Wildcard ($IdentityReference) {
        "S-1-*" {
            # IdentityReference is a SID (Revision 1)
            $IndexOfLastHyphen = $IdentityReference.LastIndexOf("-")
            $DomainSid = $IdentityReference.Substring(0, $IndexOfLastHyphen)
            if ($DomainSid) {
                $DomainCacheResult = $DomainsBySID[$DomainSid]
                if ($DomainCacheResult) {
                    Write-LogMsg @LogParams -Text " # Domain SID cache hit for '$DomainSid' for '$IdentityReference'"
                    $ThisServerDns = $DomainCacheResult.Dns
                    $DomainNetBios = $DomainCacheResult.Netbios
                } else {
                    Write-LogMsg @LogParams -Text " # Domain SID cache miss for '$DomainSid' for '$IdentityReference'"
                }
            }
        }
        "NT SERVICE\*" {}
        "BUILTIN\*" {}
        "NT AUTHORITY\*" {}
        default {
            $DomainNetBios = ($IdentityReference -split '\\')[0]
            if ($DomainNetBios) {
                $ThisServerDns = $DomainsByNetbios[$DomainNetBios].Dns #Doesn't work for BUILTIN, etc.
            }
            if (-not $ThisServerDns) {
                $ThisServerDn = ConvertTo-DistinguishedName -Domain $DomainNetBios -DomainsByNetbios $DomainsByNetbios @LoggingParams
                $ThisServerDns = ConvertTo-Fqdn -DistinguishedName $ThisServerDn -ThisFqdn $ThisFqdn -CimCache $CimCache @LoggingParams
            }
        }
    }

    if (-not $ThisServerDns) {
        # TODO - Bug: I think this will report incorrectly for a remote domain not in the cache (trust broken or something)
        Write-LogMsg @LogParams -Text "Find-ServerNameInPath -LiteralPath '$ItemPath' -ThisFqdn '$ThisFqdn'"
        $ThisServerDns = Find-ServerNameInPath -LiteralPath $ItemPath -ThisFqdn $ThisFqdn
    }

    $GetAdsiServerParams = @{
        Fqdn                   = $ThisServerDns
        CimCache               = $CimCache
        DirectoryEntryCache    = $DirectoryEntryCache
        DomainsByFqdn          = $DomainsByFqdn
        DomainsByNetbios       = $DomainsByNetbios
        DomainsBySid           = $DomainsBySid
        ThisHostName           = $ThisHostName
        ThisFqdn               = $ThisFqdn
        LogMsgCache            = $LogMsgCache
        WhoAmI                 = $WhoAmI
        Win32AccountsBySID     = $Win32AccountsBySID
        Win32AccountsByCaption = $Win32AccountsByCaption
    }
    Write-LogMsg @LogParams -Text "`$AdsiServer = Get-AdsiServer -Fqdn '$ThisServerDns'"
    $AdsiServer = Get-AdsiServer @GetAdsiServerParams

    <#

            if ([string]$DomainNetBios -eq '') {
                $DomainNetBios = $AdsiServer.Netbios
            }
            Write-LogMsg @LogParams -Text " # Domain NetBIOS is '$DomainNetBios' for '$IdentityReference'"

            $AdsiProvider = $null
            if (-not $DomainNetBios) {
                $DomainCacheResult = $DomainsByFqdn[$ThisServerDns]
                if ($DomainCacheResult) {
                    Write-LogMsg @LogParams -Text " # Domain FQDN cache hit for '$ThisServerDns'"
                    $DomainNetBios = $DomainCacheResult.Netbios
                    $AdsiProvider = $DomainCacheResult.AdsiProvider
                } else {
                    Write-LogMsg @LogParams -Text " # Domain FQDN cache miss for '$ThisServerDns'"
                }
            }

            if (-not $DomainNetBios) {
                if (-not $AdsiProvider) {
                    $AdsiProvider = Find-AdsiProvider -AdsiServer $ThisServerDns
                }
                $DomainNetBios = ConvertTo-DomainNetBIOS -DomainFQDN $ThisServerDns -AdsiProvider $AdsiProvider -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
            }
            #>

    $ResolveIdentityReferenceParams = @{
        IdentityReference      = $IdentityReference
        AdsiServer             = $AdsiServer
        Win32AccountsBySID     = $Win32AccountsBySID
        Win32AccountsByCaption = $Win32AccountsByCaption
        DirectoryEntryCache    = $DirectoryEntryCache
        DomainsBySID           = $DomainsBySID
        DomainsByNetbios       = $DomainsByNetbios
        DomainsByFqdn          = $DomainsByFqdn
        ThisHostName           = $ThisHostName
        ThisFqdn               = $ThisFqdn
        LogMsgCache            = $LogMsgCache
        CimCache               = $CimCache
        WhoAmI                 = $WhoAmI
    }
    Write-LogMsg @LogParams -Text "Resolve-IdentityReference -IdentityReference '$IdentityReference' -AdsiServer `$AdsiServer # ADSI server '$($AdsiServer.AdsiProvider)://$($AdsiServer.Dns)'"
    $ResolvedIdentityReference = Resolve-IdentityReference @ResolveIdentityReferenceParams

    # not sure if I should add a param to offer DNS instead of NetBIOS

    $ObjectProperties = @{
        AdsiProvider              = $AdsiServer.AdsiProvider
        AdsiServer                = $AdsiServer.Dns
        IdentityReferenceSID      = $ResolvedIdentityReference.SIDString
        IdentityReferenceResolved = $ResolvedIdentityReference.IdentityReferenceNetBios
        Path                      = $ItemPath
    }
    ForEach ($ThisProperty in $ACEPropertyName) {
        $ObjectProperties[$ThisProperty] = $ACE.$ThisProperty
    }
    $OutputObject = [PSCustomObject]$ObjectProperties

    $Key = $OutputObject.IdentityReferenceResolved
    $CacheResult = $ACEsByResolvedID[$Key]
    if (-not $CacheResult) {
        $CacheResult = [System.Collections.Generic.List[object]]::new()
    }
    $CacheResult.Add($OutputObject)
    $ACEsByResolvedID[$Key] = $CacheResult

}
