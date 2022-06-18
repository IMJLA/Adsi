---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Resolve-IdentityReference

## SYNOPSIS
Add more detail to IdentityReferences from Access Control Entries in NTFS Discretionary Access Lists

## SYNTAX

```
Resolve-IdentityReference [[-LiteralPath] <String>] [-FileSystemAccessRule <FileSystemAccessRule[]>]
 [-KnownServers <Hashtable>] [<CommonParameters>]
```

## DESCRIPTION
Resolve generic defaults like 'NT AUTHORITY' and 'BUILTIN' to the applicable computer or domain name
Resolve SID to NT account name and vise-versa
Resolve well-known SIDs

## EXAMPLES

### EXAMPLE 1
```
$FolderPath = 'C:\Test'
(Get-Acl $FolderPath).Access | Resolve-IdentityReference $FolderPath
```

Use Get-Acl as the source of the access list
This works in either Windows Powershell or in Powershell
Get-Acl does not support long paths (\>256 characters)
That was why I originally used the .Net Framework method

### EXAMPLE 2
```
$FolderPath = 'C:\Test'
if ($FolderPath.Length -gt 255) {
    $FolderPath = "\\?\$FolderPath"
}
[System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
[System.Security.AccessControl.DirectorySecurity]$DirectorySecurity = $DirectoryInfo.GetAccessControl('Access')
[System.Security.AccessControl.AuthorizationRuleCollection]$AuthRules = $DirectorySecurity.Access
$AuthRules | Resolve-IdentityReference -LiteralPath $FolderPath
```

Use the .Net Framework (or legacy .Net Core up to 2.2) as the source of the access list
Only works in Windows PowerShell
Those versions of .Net had a GetAccessControl method on the \[System.IO.DirectoryInfo\] class
This method is missing in modern versions of .Net Core

### EXAMPLE 3
```
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
```

This uses .Net Core as the source of the access list
It uses the GetAccessRules method on the \[System.Security.AccessControl.FileSecurity\] class
The targetType parameter of the method is used to specify that the accounts in the ACL are returned as SIDs

### EXAMPLE 4
```
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
```

This uses .Net Core as the source of the access list
It uses the GetAccessRules method on the \[System.Security.AccessControl.FileSecurity\] class
The targetType parameter of the method is used to specify that the accounts in the ACL are returned as NT account names (DOMAIN\User)

## PARAMETERS

### -FileSystemAccessRule
Access Control Entry from an NTFS Access List whose IdentityReferences to resolve
Accepts FileSystemAccessRule objects from Get-Acl or otherwise

```yaml
Type: System.Security.AccessControl.FileSystemAccessRule[]
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -KnownServers
Dictionary to cache known servers to avoid redundant lookups
Defaults to an empty thread-safe hashtable

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: [hashtable]::Synchronized(@{})
Accept pipeline input: False
Accept wildcard characters: False
```

### -LiteralPath
Path to the file or folder associated with the Access Control Entries passed to the AccessControlEntry parameter
This will be used to determine local vs.
remote computer, and then WinNT vs.
LDAP

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [System.Security.AccessControl.DirectorySecurity]$AccessControlEntry
## OUTPUTS

### [System.Security.AccessControl.DirectorySecurity] Original object plus ResolvedIdentityReference and AdsiProvider properties
## NOTES
Dependencies:
    Get-DirectoryEntry
    Add-SidInfo
    Get-TrustedDomainSidNameMap
    Find-AdsiProvider

## RELATED LINKS
