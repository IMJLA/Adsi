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

```powershell
ConvertTo-DomainNetBIOS [[-DomainFQDN] <String>] [[-AdsiProvider] <String>] [-Cache] <PSReference>
 [<CommonParameters>]
```

## DESCRIPTION
Retrieves the NetBIOS name for a specified domain FQDN by checking the cache or querying
the directory service.
For LDAP providers, it retrieves domain information from the directory.
For non-LDAP providers, it extracts the first part of the FQDN before the first period.

## EXAMPLES

### EXAMPLE 1
```powershell
ConvertTo-DomainNetBIOS -DomainFQDN 'contoso.com' -Cache $Cache
```

Converts the fully qualified domain name 'contoso.com' to its NetBIOS name by automatically
determining the appropriate method based on available information.
The function will check the
cache first to avoid unnecessary directory queries.

### EXAMPLE 2
```powershell
ConvertTo-DomainNetBIOS -DomainFQDN 'contoso.com' -AdsiProvider 'LDAP' -Cache $Cache
```

Converts the fully qualified domain name 'contoso.com' to its NetBIOS name using the LDAP provider
specifically, which provides more accurate results in an Active Directory environment by querying
the domain controller directly.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. Pipeline input is not accepted.
## OUTPUTS

### System.String. The NetBIOS name of the domain.
## NOTES

## RELATED LINKS

