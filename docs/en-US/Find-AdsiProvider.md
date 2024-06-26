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
Find-AdsiProvider [[-AdsiServer] <String>] [[-ThisFqdn] <String>] [[-ThisHostName] <String>]
 [[-WhoAmI] <String>] [[-LogBuffer] <Hashtable>] [[-CimCache] <Hashtable>] [[-DebugOutputStream] <String>]
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
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
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

### -LogBuffer
Log messages which have not yet been written to disk

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

## INPUTS

### [System.String] AdsiServer parameter.
## OUTPUTS

### [System.String] Possible return values are:
###     None
###     LDAP
###     WinNT
## NOTES

## RELATED LINKS
