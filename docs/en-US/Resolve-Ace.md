---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Resolve-Ace

## SYNOPSIS
Use ADSI to lookup info about IdentityReferences from Authorization Rule Collections that came from Discretionary Access Control Lists

## SYNTAX

```
Resolve-Ace [[-ACE] <Object>] [[-ACLsByPath] <Hashtable>] [[-ItemPath] <Object>] [[-ACEsByGUID] <Hashtable>]
 [[-AceGUIDsByResolvedID] <Hashtable>] [[-AceGUIDsByPath] <Hashtable>] [[-DirectoryEntryCache] <Hashtable>]
 [[-Win32AccountsBySID] <Hashtable>] [[-Win32AccountsByCaption] <Hashtable>] [[-DomainsByNetbios] <Hashtable>]
 [[-DomainsBySid] <Hashtable>] [[-DomainsByFqdn] <Hashtable>] [[-ThisHostName] <String>] [[-ThisFqdn] <String>]
 [[-WhoAmI] <String>] [[-LogMsgCache] <Hashtable>] [[-CimCache] <Hashtable>] [[-DebugOutputStream] <String>]
 [[-ACEPropertyName] <String[]>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Based on the IdentityReference proprety of each Access Control Entry:
Resolve SID to NT account name and vise-versa
Resolve well-known SIDs
Resolve generic defaults like 'NT AUTHORITY' and 'BUILTIN' to the applicable computer or domain name
Add these properties (IdentityReferenceSID,IdentityReferenceResolved) to the object and return it

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

### -ACE
Authorization Rule Collection of Access Control Entries from Discretionary Access Control Lists

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -AceGUIDsByPath
Cache of access control entry GUIDs keyed by their paths

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

### -AceGUIDsByResolvedID
Cache of access control entry GUIDs keyed by their resolved identities

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

### -ACEPropertyName
{{ Fill ACEPropertyName Description }}

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 19
Default value: (Get-Member -InputObject $ACE -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name
Accept pipeline input: False
Accept wildcard characters: False
```

### -ACEsByGUID
Cache of access control entries keyed by GUID generated in this function

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

### -ACLsByPath
Cache of access control lists keyed by path

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: [hashtable]::Synchronized(@{})
Accept pipeline input: False
Accept wildcard characters: False
```

### -CimCache
Cache of CIM sessions and instances to reduce connections and queries

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 17
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### -DebugOutputStream
Output stream to send the log messages to

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 18
Default value: Debug
Accept pipeline input: False
Accept wildcard characters: False
```

### -DirectoryEntryCache
Dictionary to cache directory entries to avoid redundant lookups

Defaults to an empty thread-safe hashtable

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

### -DomainsByFqdn
Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 12
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### -DomainsByNetbios
Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### -DomainsBySid
Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 11
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### -ItemPath
{{ Fill ItemPath Description }}

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -LogMsgCache
Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 16
Default value: $Global:LogMessages
Accept pipeline input: False
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

### -ThisFqdn
FQDN of the computer running this function.

Can be provided as a string to avoid calls to HOSTNAME.EXE and \[System.Net.Dns\]::GetHostByName()

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 14
Default value: ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName)
Accept pipeline input: False
Accept wildcard characters: False
```

### -ThisHostName
Hostname of the computer running this function.

Can be provided as a string to avoid calls to HOSTNAME.EXE

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 13
Default value: (HOSTNAME.EXE)
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhoAmI
Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 15
Default value: (whoami.EXE)
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
Position: 9
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
Position: 8
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [System.Security.AccessControl.AuthorizationRuleCollection]$ACE
## OUTPUTS

### [PSCustomObject] Original object plus IdentityReferenceSID,IdentityReferenceResolved, and AdsiProvider properties
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
