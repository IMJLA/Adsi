---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Get-Win32Account

## SYNOPSIS
Use CIM to get well-known SIDs

## SYNTAX

```
Get-Win32Account [[-ComputerName] <String[]>] [[-Win32AccountsBySID] <Hashtable>]
 [[-Win32AccountsByCaption] <Hashtable>] [[-AdsiServersByDns] <Hashtable>] [[-DirectoryEntryCache] <Hashtable>]
 [[-DomainsByNetbios] <Hashtable>] [[-DomainsBySid] <Hashtable>] [[-DomainsByFqdn] <Hashtable>]
 [[-ThisHostName] <String>] [[-ThisFqdn] <String>] [[-AdsiProvider] <String>] [[-WhoAmI] <String>]
 [[-LogMsgCache] <Hashtable>] [[-CimSession] <CimSession>] [<CommonParameters>]
```

## DESCRIPTION
Use WinRM to query the CIM namespace root/cimv2 for instances of the Win32_Account class

## EXAMPLES

### EXAMPLE 1
```
Get-Win32Account
```

Get the well-known SIDs on the current computer

### EXAMPLE 2
```
Get-Win32Account -CimServerName 'server123'
```

Get the well-known SIDs on the remote computer 'server123'

## PARAMETERS

### -AdsiProvider
AdsiProvider (WinNT or LDAP) of the servers associated with the provided FQDNs or NetBIOS names

This parameter can be used to reduce calls to Find-AdsiProvider

Useful when that has been done already but the DomainsByFqdn and DomainsByNetbios caches have not been updated yet

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 11
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AdsiServersByDns
Cache of known directory servers to reduce duplicate queries

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: [hashtable]::Synchronized(@{})
Accept pipeline input: False
Accept wildcard characters: False
```

### -CimSession
Existing CIM session to the computer (to avoid creating redundant CIM sessions)

```yaml
Type: Microsoft.Management.Infrastructure.CimSession
Parameter Sets: (All)
Aliases:

Required: False
Position: 14
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
Name or address of the computer whose Win32_Account instances to return

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
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
Position: 5
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
Position: 8
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
Position: 6
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
Position: 7
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogMsgCache
Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 13
Default value: $Global:LogMessages
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
Position: 12
Default value: (whoami.EXE)
Accept pipeline input: False
Accept wildcard characters: False
```

### -Win32AccountsByCaption
Cache of known Win32_Account instances keyed by domain (e.g.
CONTOSO) and Caption (NTAccount name e.g.
CONTOSO\User1)

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### -Win32AccountsBySID
Cache of known Win32_Account instances keyed by domain and SID

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [System.String]$ComputerName
## OUTPUTS

### [Microsoft.Management.Infrastructure.CimInstance] for each instance of the Win32_Account class in the root/cimv2 namespace
## NOTES

## RELATED LINKS
