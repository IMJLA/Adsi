---
external help file: PsAdsi-help.xml
Module Name: PsAdsi
online version:
schema: 2.0.0
---

# Get-DirectoryEntry

## SYNOPSIS
Use Active Directory Service Interfaces to retrieve an object from a directory

## SYNTAX

```
Get-DirectoryEntry [[-DirectoryPath] <String>] [[-Credential] <PSCredential>] [[-PropertiesToLoad] <String[]>]
 [[-DirectoryEntryCache] <Hashtable>] [<CommonParameters>]
```

## DESCRIPTION
Retrieve a directory entry using either the WinNT or LDAP provider for ADSI

## EXAMPLES

### EXAMPLE 1
```
----------  EXAMPLE 1  ----------
As the current user, bind to the current domain and retrieve the DirectoryEntry for the root of the domain
```

Get-DirectoryEntry

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
Default value: (([System.DirectoryServices.DirectorySearcher]'').SearchRoot.Path)
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Credentials to use to bind to the directory
Defaults to the credentials of the current user

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PropertiesToLoad
Properties of the target object to retrieve

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
A hashtable containing cached directory entries so they don't have to be retrieved from the directory again
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject[]
## NOTES

## RELATED LINKS
