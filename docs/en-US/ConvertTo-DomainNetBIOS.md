---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# ConvertTo-DomainNetBIOS

## SYNOPSIS
Converts a domain FQDN to its NetBIOS name.

## SYNTAX

```
ConvertTo-DomainNetBIOS [[-DomainFQDN] <String>] [[-AdsiProvider] <String>] [-Cache] <PSReference>
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves the NetBIOS name for a specified domain FQDN by checking the cache or querying
the directory service.
For LDAP providers, it retrieves domain information from the directory.
For non-LDAP providers, it extracts the first part of the FQDN before the first period.

## EXAMPLES

### EXAMPLE 1
```
ConvertTo-DomainNetBIOS -DomainFQDN 'contoso.com' -Cache $Cache
```

### EXAMPLE 2
```
ConvertTo-DomainNetBIOS -DomainFQDN 'contoso.com' -AdsiProvider 'LDAP' -Cache $Cache
```

## PARAMETERS

### -AdsiProvider
ADSI provider to use (LDAP or WinNT)

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

### -Cache
In-process cache to reduce calls to other processes or to disk

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DomainFQDN
Fully Qualified Domain Name (FQDN) to convert to NetBIOS name

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. Pipeline input is not accepted.
## OUTPUTS

### System.String. The NetBIOS name of the domain.
## NOTES

## RELATED LINKS

