---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Get-CurrentDomain

## SYNOPSIS
Use ADSI to get the current domain

## SYNTAX

```
Get-CurrentDomain [[-ComputerName] <String>] [[-CimCache] <Hashtable>] [[-ThisHostName] <String>]
 [[-ThisFqdn] <String>] [[-WhoAmI] <String>] [[-LogMsgCache] <Hashtable>] [[-DebugOutputStream] <String>]
```

## DESCRIPTION
Works only on domain-joined systems, otherwise returns nothing

## EXAMPLES

### EXAMPLE 1
```
Get-CurrentDomain
```

Get the domain of the current computer

## PARAMETERS

### -CimCache
Cache of CIM sessions and instances to reduce connections and queries

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

### -ComputerName
Name of the computer to query via CIM

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
Position: 6
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
Position: 4
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
Position: 5
Default value: (whoami.EXE)
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### None. Pipeline input is not accepted.
## OUTPUTS

### [System.DirectoryServices.DirectoryEntry] The current domain
## NOTES

## RELATED LINKS
