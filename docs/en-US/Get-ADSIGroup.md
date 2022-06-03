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

## EXAMPLES

### EXAMPLE 1
```
Get-ADSIGroup -DirectoryPath 'WinNT://WORKGROUP/localhost' -GroupName Administrators
```

Find the ADSI provider of the local computer

### EXAMPLE 2
```
Get-ADSIGroup -GroupName Administrators
```

On a domain-joined computer, this will get the the domain's Administrators group
On a workgroup computer, this will get the local Administrators group

## PARAMETERS

### -DirectoryPath
{{ Fill DirectoryPath Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: (([adsisearcher]'').SearchRoot.Path)
Accept pipeline input: False
Accept wildcard characters: False
```

### -GroupName
{{ Fill GroupName Description }}

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
{{ Fill PropertiesToLoad Description }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: @('objectClass', 'distinguishedName', 'name', 'grouptype', 'description', 'managedby', 'member', 'objectClass', 'department', 'title')
Accept pipeline input: False
Accept wildcard characters: False
```

### -DirectoryEntryCache
{{ Fill DirectoryEntryCache Description }}

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

### [System.DirectoryServices.DirectoryEntry] Possible return values are:
###     None
###     LDAP
###     WinNT
## NOTES

## RELATED LINKS
