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
Resolve-IdentityReference [[-LiteralPath] <String>] [-AccessControlEntry <FileSystemAccessRule[]>]
 [-KnownServers <Hashtable>] [<CommonParameters>]
```

## DESCRIPTION
Replace generic defaults like 'NT AUTHORITY' and 'BUILTIN' with the applicable computer name

## EXAMPLES

### EXAMPLE 1
```
----------  EXAMPLE 1  ----------
(Get-Acl C:\Test).Access | Resolve-IdentityReference C:\Test
```

Get-Acl does not support long paths (\>256 characters)
That was why I originally used the .Net Framework method
----------  EXAMPLE 2  ----------
(Get-Item -LiteralPath 'C:\Test').GetAccessControl('Access') |
Add-Member -NotePropertyMembers @{Path = 'C:\Item'} -Force -PassThru |
Resolve-IdentityReference

This uses the .Net Framework (or legacy .Net Core up to 2.2)
Those versions of .Net had a GetAccessControl method on the \[System.IO.DirectoryInfo\] class
----------  EXAMPLE 3  ----------
$FolderPath = 'C:\Test'
if ($FolderPath.Length -gt 255) {
    $FolderPath = "\\\\?\$FolderPath"
}
\[System.IO.DirectoryInfo\]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
$Sections = \[System.Security.AccessControl.AccessControlSections\]::Access
$FileSecurity = \[System.Security.AccessControl.FileSecurity\]::new($DirectoryInfo,$Sections)
$IncludeExplicitRules = $true
$IncludeInheritedRules = $true
$AccountType = \[System.Security.Principal.NTAccount\]
$AccountType = \[System.Security.Principal.SecurityIdentifier\]
$FileSecurity.GetAccessRules($IncludeExplicitRules,$IncludeInheritedRules,$AccountType) |
Resolve-IdentityReference -LiteralPath $FolderPath

This uses .Net Core
----------  EXAMPLE 4  ----------
\[System.Security.AccessControl.FileSecurity\]::new(
    (Get-Item 'C:\Test'),
    'Access'
).GetAccessRules($true,$true,\[System.Security.Principal.SecurityIdentifier\]) |
Resolve-IdentityReference 'C:\Test'

This uses .Net Core
----------  EXAMPLE 5  ----------
\[System.Security.AccessControl.FileSecurity\]::new(
    (Get-Item 'C:\Test'),
    'Access'
).GetAccessRules($true,$true,\[System.Security.Principal.NTAccount\]) |
Resolve-IdentityReference 'C:\Test'

This uses .Net Core

## PARAMETERS

### -LiteralPath
Path to the file or folder associated with the Access Control Entries passed to the AccessControlEntry parameter
This will be used to determine local vs.
remote computer, and then WinNT vs.
LDAP

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AccessControlEntry
AccessControlEntries from an NTFS Access List whose IdentityReferences to resolve

```yaml
Type: FileSystemAccessRule[]
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
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: [hashtable]::Synchronized(@{})
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

## RELATED LINKS
