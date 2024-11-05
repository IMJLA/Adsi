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
 [[-CimCache] <Hashtable>] [[-DirectoryEntryCache] <PSReference>] [[-DomainsByNetbios] <PSReference>]
 [[-ThisFqdn] <String>] [[-ThisHostName] <String>] [[-WhoAmI] <String>] [-LogBuffer] <PSReference>
 [[-DebugOutputStream] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Find directory entries using the LDAP provider for ADSI (the WinNT provider does not support searching)
Provides a wrapper around the \[System.DirectoryServices.DirectorySearcher\] class

## EXAMPLES

### EXAMPLE 1
```
Search-Directory -Filter ''
```

As the current user on a domain-joined computer, bind to the current domain and search for all directory entries matching the LDAP filter

## PARAMETERS

### -CimCache
Cache of CIM sessions and instances to reduce connections and queries

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

### -Credential
Credentials to use

```yaml
Type: System.Management.Automation.PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
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
Position: 14
Default value: Debug
Accept pipeline input: False
Accept wildcard characters: False
```

### -DirectoryEntryCache
Hashtable containing cached directory entries so they don't have to be retrieved from the directory again

Defaults to a thread-safe dictionary with string keys and object values

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new())
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

### -DomainsByNetbios
{{ Fill DomainsByNetbios Description }}

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new())
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

### -LogBuffer
Log messages which have not yet been written to disk

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: True
Position: 13
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize
Number of records per page of results

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

### -PropertiesToLoad
Additional properties to return

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SearchScope
Scope of the search

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: Subtree
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
Position: 10
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
Position: 11
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
Position: 12
Default value: (whoami.EXE)
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. Pipeline input is not accepted.
## OUTPUTS

### [System.DirectoryServices.DirectoryEntry]
## NOTES

## RELATED LINKS
