
function Resolve-Ace {
    <#
        .SYNOPSIS
        Use ADSI to lookup info about IdentityReferences from Authorization Rule Collections that came from Discretionary Access Control Lists
        .DESCRIPTION
        Based on the IdentityReference proprety of each Access Control Entry:
        Resolve SID to NT account name and vise-versa
        Resolve well-known SIDs
        Resolve generic defaults like 'NT AUTHORITY' and 'BUILTIN' to the applicable computer or domain name
        Add these properties (IdentityReferenceSID,IdentityReferenceName,IdentityReferenceResolved) to the object and return it
        .INPUTS
        [System.Security.AccessControl.AuthorizationRuleCollection]$InputObject
        .OUTPUTS
        [PSCustomObject] Original object plus IdentityReferenceSID,IdentityReferenceName,IdentityReferenceResolved, and AdsiProvider properties
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
            Get-TrustedDomainSidNameMap
            Find-AdsiProvider

        if ($FolderPath.Length -gt 255) {
            $FolderPath = "\\?\$FolderPath"
        }
    #>
    [OutputType([PSCustomObject])]
    param (

        # Authorization Rule Collection of Access Control Entries from Discretionary Access Control Lists
        [Parameter(
            ValueFromPipeline
        )]
        [PSObject[]]$InputObject,

        # Dictionary to cache known servers to avoid redundant lookups
        # Defaults to an empty thread-safe hashtable
        [hashtable]$KnownServers = [hashtable]::Synchronized(@{})

    )

    process {

        $ACEPropertyNames = (Get-Member -InputObject $InputObject[0] -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name
        ForEach ($ThisACE in $InputObject) {

            # Remove the PsProvider prefix from the path string
            if (-not [string]::IsNullOrEmpty($ThisACE.SourceAccessList.Path)) {
                $LiteralPath = $ThisACE.SourceAccessList.Path -replace [regex]::escape("$($ThisACE.SourceAccessList.PsProvider)::"), ''
            } else {
                $LiteralPath = $LiteralPath -replace [regex]::escape("$($ThisACE.SourceAccessList.PsProvider)::"), ''
            }

            $ThisServer = Find-ServerNameInPath -LiteralPath $LiteralPath
            $AdsiServer = Get-AdsiServer -AdsiServer $ThisServer -KnownServers $KnownServers
            $ResolvedIdentityReference = Resolve-IdentityReference -IdentityReference $ThisACE.IdentityReference -ServerName $ThisServer -AdsiServer $AdsiServer
            $FullyResolved = $ResolvedIdentityReference.UnresolvedIdentityReference -replace
            'NT AUTHORITY', $ThisServer -replace
            'NT SERVICE', $ThisServer -replace
            'BUILTIN', $ThisServer

            $ObjectProperties = @{
                AdsiProvider              = $AdsiServer.AdsiProvider
                AdsiServer                = $ThisServer
                IdentityReferenceSID      = $ResolvedIdentityReference.SIDString
                IdentityReferenceName     = $ResolvedIdentityReference.UnresolvedIdentityReference
                IdentityReferenceResolved = $FullyResolved
                #Path                        = $LiteralPath
                #PathProvider                = $PsProvider
                #PathAreAccessRulesProtected = $ThisACE.SourceAccessList.AreAccessRulesProtected
            }
            ForEach ($ThisProperty in $ACEPropertyNames) {
                $ObjectProperties[$ThisProperty] = $ThisACE.$ThisProperty
            }
            [PSCustomObject]$ObjectProperties

        }

    }

}
