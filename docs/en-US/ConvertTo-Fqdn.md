---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# ConvertTo-Fqdn

## SYNOPSIS
Convert a domain distinguishedName name to its FQDN

## SYNTAX

```
ConvertTo-Fqdn [[-DistinguishedName] <String[]>] [<CommonParameters>]
```

## DESCRIPTION
Uses PowerShell's -replace operator to perform the conversion

## EXAMPLES

### EXAMPLE 1
```
ConvertTo-Fqdn -DistinguishedName 'DC=ad,DC=contoso,DC=com'
ad.contoso.com
```

Convert the domain distinguishedName 'DC=ad,DC=contoso,DC=com' to its FQDN format 'ad.contoso.com'

## PARAMETERS

### -DistinguishedName
distinguishedName of the domain

```yaml
Type: String[]
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

### [System.String] DistinguishedName parameter
## OUTPUTS

### [System.String] FQDN version of the distinguishedName
## NOTES

## RELATED LINKS
