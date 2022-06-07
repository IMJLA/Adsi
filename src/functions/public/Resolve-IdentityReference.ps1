function Resolve-IdentityReference {
    <#
        .SYNOPSIS
        Add more detail to IdentityReferences from Access Control Entries in NTFS Discretionary Access Lists
        .DESCRIPTION
        Replace generic defaults like 'NT AUTHORITY' and 'BUILTIN' with the applicable computer name

        .INPUTS
        [System.Security.AccessControl.DirectorySecurity]$AccessControlEntry
        .OUTPUTS
        [System.Security.AccessControl.DirectorySecurity] Original object plus ResolvedIdentityReference and AdsiProvider properties
        .EXAMPLE
        (Get-Acl C:\Test).Access | Resolve-IdentityReference C:\Test

        Get-Acl does not support long paths (>256 characters)
        That was why I originally used the .Net Framework method
        .EXAMPLE
        (Get-Item -LiteralPath 'C:\Test').GetAccessControl('Access') |
        Add-Member -NotePropertyMembers @{Path = 'C:\Item'} -Force -PassThru |
        Resolve-IdentityReference

        This uses the .Net Framework (or legacy .Net Core up to 2.2)
        Those versions of .Net had a GetAccessControl method on the [System.IO.DirectoryInfo] class
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
        $AccountType = [System.Security.Principal.SecurityIdentifier]
        $FileSecurity.GetAccessRules($IncludeExplicitRules,$IncludeInheritedRules,$AccountType) |
        Resolve-IdentityReference -LiteralPath $FolderPath

        This uses .Net Core
        .EXAMPLE
        [System.Security.AccessControl.FileSecurity]::new(
            (Get-Item 'C:\Test'),
            'Access'
        ).GetAccessRules($true,$true,[System.Security.Principal.SecurityIdentifier]) |
        Resolve-IdentityReference 'C:\Test'

        This uses .Net Core
        .EXAMPLE
        [System.Security.AccessControl.FileSecurity]::new(
            (Get-Item 'C:\Test'),
            'Access'
        ).GetAccessRules($true,$true,[System.Security.Principal.NTAccount]) |
        Resolve-IdentityReference 'C:\Test'

        This uses .Net Core
    #>
    param (

        # Path to the file or folder associated with the Access Control Entries passed to the AccessControlEntry parameter
        # This will be used to determine local vs. remote computer, and then WinNT vs. LDAP
        [Parameter(Position = 0)]
        [string]$LiteralPath,

        # AccessControlEntries from an NTFS Access List whose IdentityReferences to resolve
        [Parameter(ValueFromPipeline)]
        [System.Security.AccessControl.FileSystemAccessRule[]]$AccessControlEntry,

        # Dictionary to cache known servers to avoid redundant lookups
        # Defaults to an empty thread-safe hashtable
        [hashtable]$KnownServers = [hashtable]::Synchronized(@{})

    )
    begin {
        if ($LiteralPath -match '[A-Za-z]\:\\') {
            # For local file paths, the "server" is the local computer
            $ThisServer = hostname
            $CimSession = New-CimSession
        } else {
            # Otherwise it must be a UNC path, so the server is the first non-empty string between backwhacks (\)
            $ThisServer = $LiteralPath -split '\\' | Where-Object { $_ -ne '' } | Select-Object -First 1
            $CimSession = New-CimSession -ComputerName $ThisServer
        }
        $AdsiProvider = Find-AdsiProvider -AdsiServer $ThisServer -KnownServers $KnownServers
    }
    process {
        ForEach ($ThisACE in $AccessControlEntry) {
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
                        $DirectoryPath = "$AdsiServer`://$ThisServer/$(($UnresolvedIdentityReference -split '\\') | Select-Object -Last 1)"
                        $SIDString = (Get-DirectoryEntry -DirectoryPath $DirectoryPath |
                            Add-SidInfo).SidString
                    }
                }
            }
            $ThisACE | Add-Member -PassThru -Force -NotePropertyMembers @{
                AdsiProvider              = $AdsiProvider
                AdsiServer                = $ThisServer
                Path                      = $LiteralPath
                IdentityReferenceSID      = $SIDString
                IdentityReferenceName     = $UnresolvedIdentityReference
                IdentityReferenceResolved = $UnresolvedIdentityReference -replace 'NT AUTHORITY', $ThisServer -replace 'BUILTIN', $ThisServer
            }
        }
    }
    end {}
}
