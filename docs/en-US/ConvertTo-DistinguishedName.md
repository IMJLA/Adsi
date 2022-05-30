---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# ConvertTo-DistinguishedName

## SYNOPSIS
Convert a domain NetBIOS name to its distinguishedName

## SYNTAX

```
ConvertTo-DistinguishedName [-Domain] <String[]> [<CommonParameters>]
```

## DESCRIPTION
https://docs.microsoft.com/en-us/windows/win32/api/iads/nn-iads-iadsnametranslate

## EXAMPLES

### EXAMPLE 1
```
ConvertTo-DistinguishedName -Domain 'CONTOSO'
DC=ad,DC=contoso,DC=com
```

Resolve the NetBIOS domain 'CONTOSO' to its distinguishedName 'DC=ad,DC=contoso,DC=com'

## PARAMETERS

### -Domain
NetBIOS name of the domain

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [System.String] Domain parameter
## OUTPUTS

### [System.String] distinguishedName of the domain
## NOTES

## RELATED LINKS
