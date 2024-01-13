---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Resolve-Ace4

## SYNOPSIS
Use ADSI to lookup info about IdentityReferences from Authorization Rule Collections that came from Discretionary Access Control Lists

## SYNTAX

```
Resolve-Ace4 [[-InputObject] <PSObject[]>] [[-DirectoryEntryCache] <Hashtable>]
 [[-Win32AccountsBySID] <Hashtable>] [[-Win32AccountsByCaption] <Hashtable>] [[-DomainsBySID] <Hashtable>]
 [[-DomainsByNetbios] <Hashtable>] [[-DomainsByFqdn] <Hashtable>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Based on the IdentityReference proprety of each Access Control Entry:
Resolve SID to NT account name and vise-versa
Resolve well-known SIDs
Resolve generic defaults like 'NT AUTHORITY' and 'BUILTIN' to the applicable computer or domain name
Add these properties (IdentityReferenceSID,IdentityReferenceName,IdentityReferenceResolved) to the object and return it

## EXAMPLES

### EXAMPLE 1
```
Get-Acl |
Expand-Acl |
Resolve-Ace
```

Use Get-Acl from the Microsoft.PowerShell.Security module as the source of the access list
This works in either Windows Powershell or in Powershell
Get-Acl does not support long paths (\>256 characters)
That was why I originally used the .Net Framework method

### EXAMPLE 2
```
Get-FolderAce -LiteralPath C:\Test -IncludeInherited |
Resolve-Ace
```

### EXAMPLE 3
```
[System.String]$FolderPath = 'C:\Test'
[System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
$Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor [System.Security.AccessControl.AccessControlSections]::Owner
$FileSecurity = [System.Security.AccessControl.FileSecurity]::new($DirectoryInfo,$Sections)
$IncludeExplicitRules = $true
$IncludeInheritedRules = $true
$AccountType = [System.Security.Principal.SecurityIdentifier]
$FileSecurity.GetAccessRules($IncludeExplicitRules,$IncludeInheritedRules,$AccountType) |
Resolve-Ace
```

This uses .Net Core as the source of the access list
It uses the GetAccessRules method on the \[System.Security.AccessControl.FileSecurity\] class
The targetType parameter of the method is used to specify that the accounts in the ACL are returned as SIDs

### EXAMPLE 4
```
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
```

This uses .Net Core as the source of the access list
It uses the GetAccessRules method on the \[System.Security.AccessControl.FileSecurity\] class
The targetType parameter of the method is used to specify that the accounts in the ACL are returned as NT account names (DOMAIN\User)

### EXAMPLE 5
```
[System.String]$FolderPath = 'C:\Test'
[System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
[System.Security.AccessControl.DirectorySecurity]$DirectorySecurity = $DirectoryInfo.GetAccessControl('Access')
[System.Security.AccessControl.AuthorizationRuleCollection]$AuthRules = $DirectorySecurity.Access
$AuthRules | Resolve-Ace
```

Use the .Net Framework (or legacy .Net Core up to 2.2) as the source of the access list
Only works in Windows PowerShell
Those versions of .Net had a GetAccessControl method on the \[System.IO.DirectoryInfo\] class
This method is removed in modern versions of .Net Core

### EXAMPLE 6
```
[System.String]$FolderPath = 'C:\Test'
[System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
$Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor [System.Security.AccessControl.AccessControlSections]::Owner
$FileSecurity = [System.IO.FileSystemAclExtensions]::GetAccessControl($DirectoryInfo,$Sections)
```

The \[System.IO.FileSystemAclExtensions\] class is a Windows-specific implementation
It provides no known benefit over the cross-platform equivalent \[System.Security.AccessControl.FileSecurity\]

## PARAMETERS

### -DirectoryEntryCache
Dictionary to cache directory entries to avoid redundant lookups

Defaults to an empty thread-safe hashtable

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### -DomainsByFqdn
{{ Fill DomainsByFqdn Description }}

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### -DomainsByNetbios
{{ Fill DomainsByNetbios Description }}

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### -DomainsBySID
{{ Fill DomainsBySID Description }}

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputObject
Authorization Rule Collection of Access Control Entries from Discretionary Access Control Lists

```yaml
Type: System.Management.Automation.PSObject[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: System.Management.Automation.ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Win32AccountsByCaption
{{ Fill Win32AccountsByCaption Description }}

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### -Win32AccountsBySID
{{ Fill Win32AccountsBySID Description }}

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [System.Security.AccessControl.AuthorizationRuleCollection]$InputObject
## OUTPUTS

### [PSCustomObject] Original object plus IdentityReferenceSID,IdentityReferenceName,IdentityReferenceResolved, and AdsiProvider properties
## NOTES
Dependencies:
    Get-DirectoryEntry
    Add-SidInfo
    Get-TrustedDomain
    Find-AdsiProvider

if ($FolderPath.Length -gt 255) {
    $FolderPath = "\\\\?\$FolderPath"
}

## RELATED LINKS
