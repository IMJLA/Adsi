---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Get-ADSIGroup

## SYNOPSIS
Get the directory entries for a group and its members using ADSI

## SYNTAX

```
Get-ADSIGroup [[-DirectoryPath] <String>] [[-GroupName] <String>] [[-PropertiesToLoad] <String[]>]
 [[-DirectoryEntryCache] <Hashtable>]
```

## DESCRIPTION
Uses the ADSI components to search a directory for a group, then get its members
Both the WinNT and LDAP providers are supported

## EXAMPLES

### EXAMPLE 1
```
Get-ADSIGroup -DirectoryPath 'WinNT://WORKGROUP/localhost' -GroupName Administrators
```

Get members of the local Administrators group

### EXAMPLE 2
```
Get-ADSIGroup -GroupName Administrators
```

On a domain-joined computer, this will get members of the domain's Administrators group
On a workgroup computer, this will get members of the local Administrators group

## PARAMETERS

### -DirectoryPath
Path to the directory object to retrieve
Defaults to the root of the current domain

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: (([System.DirectoryServices.DirectorySearcher]::new()).SearchRoot.Path)
Accept pipeline input: False
Accept wildcard characters: False
```

### -GroupName
Name (CN or Common Name) of the group to retrieve

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PropertiesToLoad
Properties of the group and its members to find in the directory

       \[string\[\]\]$PropertiesToLoad = @(
           'department',
           'description',
           'distinguishedName',
           'grouptype',
           'managedby',
           'member',
           'name',
           'objectClass',
           'objectSid',
           'operatingSystem',
           'samAccountName',
           'title'
       ),

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DirectoryEntryCache
Hashtable containing cached directory entries so they don't have to be retrieved from the directory again
Uses a thread-safe hashtable by default

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### None.
## OUTPUTS

### [System.DirectoryServices.DirectoryEntry] for each group memeber
## NOTES

## RELATED LINKS
