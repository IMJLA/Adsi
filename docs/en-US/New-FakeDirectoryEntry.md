---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# New-FakeDirectoryEntry

## SYNOPSIS
Returns a PSCustomObject in place of a DirectoryEntry for certain WinNT security principals that do not have objects in the directory

## SYNTAX

```
New-FakeDirectoryEntry [[-DirectoryPath] <String>]
```

## DESCRIPTION
The WinNT provider only throws an error if you try to retrieve certain accounts/identities
We will create dummy objects instead of performing the query

## EXAMPLES

### EXAMPLE 1
```
----------  EXAMPLE 1  ----------
New-FakeDirectoryEntry -DirectoryPath 'WinNT://WORKGROUP/Computer/CREATOR OWNER'
```

Create a fake DirectoryEntry to represent the CREATOR OWNER special security principal

## PARAMETERS

### -DirectoryPath
Path to the directory object to retrieve
Defaults to the root of the current domain (but don't use it for that, just do this instead: \[System.DirectoryServices.DirectorySearcher\]::new())

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

## INPUTS

### None.
## OUTPUTS

### [System.Management.Automation.PSCustomObject]
## NOTES

## RELATED LINKS
