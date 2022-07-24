---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Get-WellKnownSid

## SYNOPSIS
Use CIM to get well-known SIDs

## SYNTAX

```
Get-WellKnownSid [[-CimServerName] <String[]>] [<CommonParameters>]
```

## DESCRIPTION
Use WinRM to query the CIM namespace root/cimv2 for instances of the Win32_SystemAccount class

## EXAMPLES

### EXAMPLE 1
```
Get-WellKnownSid
```

Get the well-known SIDs on the current computer

### EXAMPLE 2
```
Get-WellKnownSid -CimServerName 'server123'
```

Get the well-known SIDs on the remote computer 'server123'

## PARAMETERS

### -CimServerName
{{ Fill CimServerName Description }}

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [System.String]$CimServerName
## OUTPUTS

### [Microsoft.Management.Infrastructure.CimInstance] for each instance of the Win32_SystemAccount class in the root/cimv2 namespace
## NOTES

## RELATED LINKS
