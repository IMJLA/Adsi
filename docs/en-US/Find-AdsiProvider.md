---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Find-AdsiProvider

## SYNOPSIS
Determine whether a directory server is an LDAP or a WinNT server

## SYNTAX

```
Find-AdsiProvider [[-AdsiServer] <String[]>] [[-ThisFqdn] <String>] [[-ThisHostName] <String>]
 [[-WhoAmI] <String>] [[-LogMsgCache] <Hashtable>] [[-CimCache] <Hashtable>] [[-DebugOutputStream] <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Uses the ADSI provider to attempt to query the server using LDAP first, then WinNT second

## EXAMPLES

### EXAMPLE 1
```
Find-AdsiProvider -AdsiServer localhost
```

Find the ADSI provider of the local computer

### EXAMPLE 2
```
Find-AdsiProvider -AdsiServer 'ad.contoso.com'
```

Find the ADSI provider of the AD domain 'ad.contoso.com'

## PARAMETERS

### -AdsiServer
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

### -CimCache
Cache of CIM sessions and instances to reduce connections and queries

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

### -DebugOutputStream
Output stream to send the log messages to

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: Debug
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
Position: 5
Default value: $Global:LogMessages
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

### -ThisFqdn
FQDN of the computer running this function.

Can be provided as a string to avoid calls to HOSTNAME.EXE and \[System.Net.Dns\]::GetHostByName()

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
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
Position: 3
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
Position: 4
Default value: (whoami.EXE)
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [System.String] AdsiServer parameter.
## OUTPUTS

### [System.String] Possible return values are:
###     None
###     LDAP
###     WinNT
## NOTES

## RELATED LINKS
