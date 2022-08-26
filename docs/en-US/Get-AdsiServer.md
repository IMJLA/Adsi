---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Get-AdsiServer

## SYNOPSIS
Get information about a directory server including the ADSI provider it hosts and its well-known SIDs

## SYNTAX

```
Get-AdsiServer [[-Fqdn] <String[]>] [[-Netbios] <String[]>] [[-Win32AccountsBySID] <Hashtable>]
 [[-Win32AccountsByCaption] <Hashtable>] [[-DirectoryEntryCache] <Hashtable>] [[-DomainsByNetbios] <Hashtable>]
 [[-DomainsBySid] <Hashtable>] [[-DomainsByFqdn] <Hashtable>] [[-ThisHostName] <String>] [[-ThisFqdn] <String>]
 [[-WhoAmI] <String>] [[-LogMsgCache] <Hashtable>] [<CommonParameters>]
```

## DESCRIPTION
Uses the ADSI provider to query the server using LDAP first, then WinNT upon failure
Uses WinRM to query the CIM class Win32_SystemAccount for well-known SIDs

## EXAMPLES

### EXAMPLE 1
```
Get-AdsiServer -Fqdn localhost
```

Find the ADSI provider of the local computer

### EXAMPLE 2
```
Get-AdsiServer -Fqdn 'ad.contoso.com'
```

Find the ADSI provider of the AD domain 'ad.contoso.com'

## PARAMETERS

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
Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName,AdsiProvider,Win32Accounts properties as values

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

### -Fqdn
IP address or hostname of the directory server whose ADSI provider type to determine

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

### -LogMsgCache
Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 12
Default value: $Global:LogMessages
Accept pipeline input: False
Accept wildcard characters: False
```

### -Netbios
NetBIOS name of the ADSI server whose information to determine

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
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

### -Win32AccountsByCaption
Cache of known Win32_Account instances keyed by domain (e.g.
CONTOSO) and Caption (NTAccount name e.g.
CONTOSO\User1)

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

### -Win32AccountsBySID
Cache of known Win32_Account instances keyed by domain and SID

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [System.String]$Fqdn
## OUTPUTS

### [PSCustomObject] with AdsiProvider and WellKnownSIDs properties
## NOTES

## RELATED LINKS
