---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Get-TrustedDomain

## SYNOPSIS
Returns a dictionary of trusted domains by the current computer

## SYNTAX

```
Get-TrustedDomain [[-ThisHostname] <Object>] [[-WhoAmI] <String>] [[-LogMsgCache] <Hashtable>]
 [[-DebugOutputStream] <String>]
```

## DESCRIPTION
Works only on domain-joined systems
Use nltest to get the domain trust relationships for the domain of the current computer
Use ADSI's LDAP provider to get each trusted domain's DNS name, NETBIOS name, and SID
For each trusted domain the key is the domain's SID, or its NETBIOS name if the -KeyByNetbios switch parameter was used
For each trusted domain the value contains the details retrieved with ADSI

## EXAMPLES

### EXAMPLE 1
```
Get-TrustedDomain
```

Get the trusted domains of the current computer

## PARAMETERS

### -DebugOutputStream
Output stream to send the log messages to

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
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
Position: 3
Default value: $Global:LogMessages
Accept pipeline input: False
Accept wildcard characters: False
```

### -ThisHostname
Hostname of the computer running this function.

Can be provided as a string to avoid calls to HOSTNAME.EXE

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
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
Position: 2
Default value: (whoami.EXE)
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### None. Pipeline input is not accepted.
## OUTPUTS

### [PSCustomObject] One object per trusted domain, each with a DomainFqdn property and a DomainNetbios property
## NOTES

## RELATED LINKS
