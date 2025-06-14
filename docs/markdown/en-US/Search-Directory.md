---
external help file: Adsi-help.xml
Module Name: Adsi
ModuleGuid: 282a2aed-9567-49a1-901c-122b7831a805
ModuleName: Adsi
ModuleVersion: 5.0.508
online version: https://IMJLA.github.io/Adsi/docs/en-US/Resolve-ServiceNameToSID
schema: 2.0.0
---

# Search-Directory

## SYNOPSIS
Use Active Directory Service Interfaces to search an LDAP directory

## SYNTAX

```powershell
Search-Directory [[-DirectoryPath] <String>] [[-Filter] <String>] [[-PageSize] <Int32>]
 [[-SearchScope] <SearchScope>] [[-PropertiesToLoad] <String[]>] [[-Credential] <PSCredential>]
 [-Cache] <PSReference> [<CommonParameters>]
```

## DESCRIPTION
Find directory entries using the LDAP provider for ADSI (the WinNT provider does not support searching)
Provides a wrapper around the \[System.DirectoryServices.DirectorySearcher\] class
Supports filtering, paging, and customizing which properties to return.

## EXAMPLES

### EXAMPLE 1
```powershell
Search-Directory -DirectoryPath "LDAP://DC=contoso,DC=com" -Filter "(objectClass=user)" -PageSize 1000 -Cache $Cache
```

Searches the contoso.com domain for all user objects, retrieving results in pages of 1000 objects at a time.
This is useful for efficiently retrieving large sets of directory objects without overwhelming memory resources.

## PARAMETERS

### -Cache
In-process cache to reduce calls to other processes or to disk

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: True
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Credentials to use

```yaml
Type: System.Management.Automation.PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DirectoryPath
Path to the directory object to retrieve
Defaults to the root of the current domain

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: (([adsisearcher]'').SearchRoot.Path)
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
Filter for the LDAP search

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
Number of results to return in each page

```yaml
Type: System.Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 1000
Accept pipeline input: False
Accept wildcard characters: False
```

### -PropertiesToLoad
Additional properties to return

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SearchScope
Search scope (Base, OneLevel, or Subtree)

```yaml
Type: System.DirectoryServices.SearchScope
Parameter Sets: (All)
Aliases:
Accepted values: Base, OneLevel, Subtree

Required: False
Position: 4
Default value: Subtree
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. Pipeline input is not accepted.
## OUTPUTS

### System.DirectoryServices.SearchResult collection representing the matching directory objects.
## NOTES

## RELATED LINKS

