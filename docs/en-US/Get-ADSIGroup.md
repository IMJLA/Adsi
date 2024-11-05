---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Get-AdsiGroup

## SYNOPSIS
Get the directory entries for a group and its members using ADSI

## SYNTAX

```
Get-AdsiGroup [[-DirectoryPath] <String>] [[-GroupName] <String>] [[-PropertiesToLoad] <String[]>]
 [[-CimCache] <Hashtable>] [[-DirectoryEntryCache] <PSReference>] [[-DomainsByNetbios] <PSReference>]
 [[-DomainsBySid] <PSReference>] [[-DomainsByFqdn] <PSReference>] [[-ThisHostName] <String>]
 [[-ThisFqdn] <String>] [[-WhoAmI] <String>] [-LogBuffer] <PSReference> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Uses the ADSI components to search a directory for a group, then get its members
Both the WinNT and LDAP providers are supported

## EXAMPLES

### EXAMPLE 1
```
Get-AdsiGroup -DirectoryPath 'WinNT://WORKGROUP/localhost' -GroupName Administrators
```

Get members of the local Administrators group

### EXAMPLE 2
```
Get-AdsiGroup -GroupName Administrators
```

On a domain-joined computer, this will get members of the domain's Administrators group
On a workgroup computer, this will get members of the local Administrators group

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

### -DirectoryEntryCache
Dictionary to cache directory entries to avoid redundant lookups

Defaults to a thread-safe dictionary with string keys and object values

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
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
Default value: (([System.DirectoryServices.DirectorySearcher]::new()).SearchRoot.Path)
Accept pipeline input: False
Accept wildcard characters: False
```

### -DomainsByFqdn
Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values

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

### -DomainsByNetbios
Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new())
Accept pipeline input: False
Accept wildcard characters: False
```

### -DomainsBySid
Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new())
Accept pipeline input: False
Accept wildcard characters: False
```

### -GroupName
Name (CN or Common Name) of the group to retrieve

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
Position: 12
Default value: None
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
Properties of the group members to retrieve

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: (@('Department', 'description', 'distinguishedName', 'grouptype', 'managedby', 'member', 'name', 'objectClass', 'objectSid', 'operatingSystem', 'primaryGroupToken', 'samAccountName', 'Title'))
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

### [System.DirectoryServices.DirectoryEntry] for each group memeber
## NOTES

## RELATED LINKS
