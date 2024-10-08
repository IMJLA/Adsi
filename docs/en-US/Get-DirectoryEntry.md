---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Get-DirectoryEntry

## SYNOPSIS
Use Active Directory Service Interfaces to retrieve an object from a directory

## SYNTAX

```
Get-DirectoryEntry [[-DirectoryPath] <String>] [[-Credential] <PSCredential>] [[-PropertiesToLoad] <String[]>]
 [[-CimCache] <Hashtable>] [[-DirectoryEntryCache] <Hashtable>] [[-DomainsByFqdn] <Hashtable>]
 [[-DomainsByNetbios] <Hashtable>] [[-DomainsBySid] <Hashtable>] [[-ThisHostName] <String>]
 [[-ThisFqdn] <String>] [[-WhoAmI] <String>] [[-LogBuffer] <Hashtable>] [[-DebugOutputStream] <String>]
 [[-SidTypeMap] <Hashtable>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Retrieve a directory entry using either the WinNT or LDAP provider for ADSI

## EXAMPLES

### EXAMPLE 1
```
Get-DirectoryEntry
distinguishedName : {DC=ad,DC=contoso,DC=com}
Path              : LDAP://DC=ad,DC=contoso,DC=com
```

As the current user on a domain-joined computer, bind to the current domain and retrieve the DirectoryEntry for the root of the domain

### EXAMPLE 2
```
Get-DirectoryEntry
distinguishedName :
Path              : WinNT://ComputerName
```

As the current user on a workgroup computer, bind to the local system and retrieve the DirectoryEntry for the root of the directory

## PARAMETERS

### -CimCache
Cache of CIM sessions and instances to reduce connections and queries

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

### -Credential
Credentials to use to bind to the directory
Defaults to the credentials of the current user

```yaml
Type: System.Management.Automation.PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
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
Position: 13
Default value: Debug
Accept pipeline input: False
Accept wildcard characters: False
```

### -DirectoryEntryCache
Hashtable containing cached directory entries so they don't have to be retrieved from the directory again
Uses a thread-safe hashtable by default

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

### -DirectoryPath
Path to the directory object to retrieve
Defaults to the root of the current domain

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: (([System.DirectoryServices.DirectorySearcher]::new()).SearchRoot.Path)
Accept pipeline input: False
Accept wildcard characters: False
```

### -DomainsByFqdn
Hashtable with known domain FQDNs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
This is not actually used but is here so the parameter can be included in a splat shared with other functions

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

### -DomainsByNetbios
Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values

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

### -DomainsBySid
Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values

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

### -LogBuffer
Log messages which have not yet been written to disk

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
Properties of the target object to retrieve

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SidTypeMap
{{ Fill SidTypeMap Description }}

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 14
Default value: (Get-SidTypeMap)
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
Position: 9
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
Position: 11
Default value: (whoami.EXE)
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. Pipeline input is not accepted.
## OUTPUTS

### [System.DirectoryServices.DirectoryEntry] where possible
### [PSCustomObject] for security principals with no directory entry
## NOTES

## RELATED LINKS
