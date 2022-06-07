---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Search-Directory

## SYNOPSIS
Use Active Directory Service Interfaces to search an LDAP directory

## SYNTAX

```
Search-Directory [[-DirectoryPath] <String>] [[-Filter] <String>] [[-PageSize] <Int32>]
 [[-PropertiesToLoad] <String[]>] [[-Credential] <PSCredential>] [[-SearchScope] <String>]
 [[-DirectoryEntryCache] <Hashtable>]
```

## DESCRIPTION
Retrieve directory entries using either the WinNT or LDAP provider for ADSI

## EXAMPLES

### EXAMPLE 1
```
Search-Directory -Filter ''
```

As the current user on a domain-joined computer, bind to the current domain and search for all directory entries matching the LDAP filter

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
Default value: (([adsisearcher]'').SearchRoot.Path)
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
Filter for the LDAP search

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

### -PageSize
Number of records per page of results

```yaml
Type: Int32
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
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Credentials to use

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SearchScope
Scope of the search

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: Subtree
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
Position: 7
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### None. Pipeline input is not accepted.
## OUTPUTS

### [System.DirectoryServices.DirectoryEntry]
## NOTES

## RELATED LINKS
