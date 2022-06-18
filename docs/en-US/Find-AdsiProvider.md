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
Find-AdsiProvider [[-AdsiServer] <String[]>] [[-KnownServers] <Hashtable>] [<CommonParameters>]
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

### -KnownServers
Cache of known directory servers to reduce duplicate queries

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: [hashtable]::Synchronized(@{})
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [System.String]$AdsiServer
## OUTPUTS

### [System.String] Possible return values are:
###     None
###     LDAP
###     WinNT
## NOTES

## RELATED LINKS
