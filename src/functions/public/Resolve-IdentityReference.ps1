function Resolve-IdentityReference {
    <#
        .SYNOPSIS
        Add more detail to IdentityReferences from Access Control Entries in NTFS Discretionary Access Lists
        .DESCRIPTION
        Resolve generic defaults like 'NT AUTHORITY' and 'BUILTIN' to the applicable computer or domain name
        Resolve SID to NT account name and vise-versa
        Resolve well-known SIDs
        .INPUTS
        [System.Security.AccessControl.DirectorySecurity]$AccessControlEntry
        .OUTPUTS
        [System.Security.AccessControl.DirectorySecurity] Original object plus IdentityReferenceResolved and AdsiProvider properties
        .EXAMPLE
        $FolderPath = 'C:\Test'
        (Get-Acl $FolderPath).Access | Resolve-IdentityReference $FolderPath

        Use Get-Acl as the source of the access list
        This works in either Windows Powershell or in Powershell
        Get-Acl does not support long paths (>256 characters)
        That was why I originally used the .Net Framework method
        .EXAMPLE
        $FolderPath = 'C:\Test'
        if ($FolderPath.Length -gt 255) {
            $FolderPath = "\\?\$FolderPath"
        }
        [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
        [System.Security.AccessControl.DirectorySecurity]$DirectorySecurity = $DirectoryInfo.GetAccessControl('Access')
        [System.Security.AccessControl.AuthorizationRuleCollection]$AuthRules = $DirectorySecurity.Access
        $AuthRules | Resolve-IdentityReference -LiteralPath $FolderPath

        Use the .Net Framework (or legacy .Net Core up to 2.2) as the source of the access list
        Only works in Windows PowerShell
        Those versions of .Net had a GetAccessControl method on the [System.IO.DirectoryInfo] class
        This method is missing in modern versions of .Net Core
        .EXAMPLE
        $FolderPath = 'C:\Test'
        if ($FolderPath.Length -gt 255) {
            $FolderPath = "\\?\$FolderPath"
        }
        [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
        $Sections = [System.Security.AccessControl.AccessControlSections]::Access
        $FileSecurity = [System.Security.AccessControl.FileSecurity]::new($DirectoryInfo,$Sections)
        $IncludeExplicitRules = $true
        $IncludeInheritedRules = $true
        $AccountType = [System.Security.Principal.SecurityIdentifier]
        $FileSecurity.GetAccessRules($IncludeExplicitRules,$IncludeInheritedRules,$AccountType) |
        Resolve-IdentityReference -LiteralPath $FolderPath

        This uses .Net Core as the source of the access list
        It uses the GetAccessRules method on the [System.Security.AccessControl.FileSecurity] class
        The targetType parameter of the method is used to specify that the accounts in the ACL are returned as SIDs
        .EXAMPLE
        $FolderPath = 'C:\Test'
        if ($FolderPath.Length -gt 255) {
            $FolderPath = "\\?\$FolderPath"
        }
        [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
        $Sections = [System.Security.AccessControl.AccessControlSections]::Access
        $FileSecurity = [System.Security.AccessControl.FileSecurity]::new($DirectoryInfo,$Sections)
        $IncludeExplicitRules = $true
        $IncludeInheritedRules = $true
        $AccountType = [System.Security.Principal.NTAccount]
        $FileSecurity.GetAccessRules($IncludeExplicitRules,$IncludeInheritedRules,$AccountType) |
        Resolve-IdentityReference -LiteralPath $FolderPath

        This uses .Net Core as the source of the access list
        It uses the GetAccessRules method on the [System.Security.AccessControl.FileSecurity] class
        The targetType parameter of the method is used to specify that the accounts in the ACL are returned as NT account names (DOMAIN\User)
        .NOTES
        Dependencies:
            Get-DirectoryEntry
            Add-SidInfo
            Get-TrustedDomainSidNameMap
            Find-AdsiProvider
    #>
    param (

        # Path to the file or folder associated with the Access Control Entries passed to the AccessControlEntry parameter
        # This will be used to determine local vs. remote computer, and then WinNT vs. LDAP
        [Parameter(Position = 0)]
        [string]$LiteralPath,

        # Access Control Entry from an NTFS Access List whose IdentityReferences to resolve
        # Accepts [System.Security.AccessControl.FileSystemAccessRule] objects from Get-Acl or otherwise, but you need to add a Path property with the path to the file/folder
        # Accepts [PSCustomObject] objects with similar properties
        [Parameter(ValueFromPipeline)]
        $FileSystemAccessRule,
        #[System.Security.AccessControl.FileSystemAccessRule[]]$FileSystemAccessRule,

        # Dictionary to cache known servers to avoid redundant lookups
        # Defaults to an empty thread-safe hashtable
        [hashtable]$KnownServers = [hashtable]::Synchronized(@{})

    )
    process {
        ForEach ($ThisACE in $FileSystemAccessRule) {
            if ($ThisACE.Path -match '[A-Za-z]\:\\' -or $null -eq $ThisACE.Path) {
                # For local file paths, the "server" is the local computer.  Assume the same for null paths.
                $ThisServer = hostname
            } else {
                # Otherwise it must be a UNC path, so the server is the first non-empty string between backwhacks (\)
                $ThisServer = $ThisACE.Path -split '\\' |
                Where-Object -FilterScript { $_ -ne '' } |
                Select-Object -First 1
                $ThisServer = $ThisServer -replace '\?', (hostname)
            }
            if ($ThisServer -eq (hostname)) {
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tResolve-IdentityReference`tNew-CimSession"
                $CimSession = New-CimSession
            } else {
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tResolve-IdentityReference`tNew-CimSession -ComputerName '$ThisServer'"
                $CimSession = New-CimSession -ComputerName $ThisServer
            }
            $AdsiProvider = Find-AdsiProvider -AdsiServer $ThisServer -KnownServers $KnownServers
            if ($ThisACE.IdentityReference -match '^S-1-') {
                # The IdentityReference is a SID
                $SecurityIdentifier = [System.Security.Principal.SecurityIdentifier]::new($ThisACE.IdentityReference)

                # This .Net method makes it impossible to redirect the error stream directly
                # Wrapping it in a scriptblock (which is then executed with &) fixes the problem
                # I don't understand exactly why
                $UnresolvedIdentityReference = & { $SecurityIdentifier.Translate([System.Security.Principal.NTAccount]).Value } 2>$null
                $SIDString = $ThisACE.IdentityReference
            } else {
                # The IdentityReference is an NTAccount
                $UnresolvedIdentityReference = $ThisACE.IdentityReference

                # Resolve NTAccount to SID
                $NTAccount = [System.Security.Principal.NTAccount]::new($ThisServer, $ThisACE.IdentityReference)
                $SIDString = $null
                $SIDString = & { $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]) } 2>$null
                if (!($SIDString)) {
                    # Well-Known SIDs cannot be translated with the Translate method so instead we will use CIM
                    $WellKnownSIDs = Get-CimInstance -ClassName Win32_SystemAccount -CimSession $CimSession
                    $SIDString = ($WellKnownSIDs |
                        Where-Object -FilterScript { $UnresolvedIdentityReference -like "*\$($_.Name)" }).SID
                    if (!($SIDString)) {
                        # Some built-in groups such as BUILTIN\Users and BUILTIN\Administrators are not in the CIM class or translatable with the Translate method
                        # But they have real DirectoryEntry objects
                        $DirectoryPath = "$AdsiProvider`://$ThisServer/$(($UnresolvedIdentityReference -split '\\') | Select-Object -Last 1)"
                        $SIDString = (Get-DirectoryEntry -DirectoryPath $DirectoryPath |
                            Add-SidInfo).SidString
                    }
                }
            }
            [pscustomobject]@{
                Path                        = $ThisACE.Path
                PathAreAccessRulesProtected = $ThisACE.PathAreAccessRulesProtected
                FileSystemRights            = $ThisACE.FileSystemRights
                AccessControlType           = $ThisACE.AccessControlType
                IdentityReference           = $ThisACE.IdentityReference
                IsInherited                 = $ThisACE.IsInherited
                InheritanceFlags            = $ThisACE.InheritanceFlags
                PropagationFlags            = $ThisACE.PropagationFlags
                AdsiProvider                = $AdsiProvider
                AdsiServer                  = $ThisServer
                IdentityReferenceSID        = $SIDString
                IdentityReferenceName       = $UnresolvedIdentityReference
                IdentityReferenceResolved   = $UnresolvedIdentityReference -replace 'NT AUTHORITY', $ThisServer -replace 'BUILTIN', $ThisServer
            }
        }
    }
    end {}
}
