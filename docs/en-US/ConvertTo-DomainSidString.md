---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# ConvertTo-DomainSidString

## SYNOPSIS
Converts a domain DNS name to its corresponding SID string.

## SYNTAX

```
ConvertTo-DomainSidString [-DomainDnsName] <String> [[-AdsiProvider] <String>] [-Cache] <PSReference>
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Retrieves the security identifier (SID) string for a specified domain DNS name using either
cached values or by querying the directory service.
It supports both LDAP and WinNT providers
and can fall back to local server resolution methods when needed.

## EXAMPLES

### EXAMPLE 1
```
ConvertTo-DomainSidString -DomainDnsName 'contoso.com' -Cache $Cache
```

Converts the DNS domain name 'contoso.com' to its corresponding domain SID string by
automatically determining the best ADSI provider to use and utilizing the cache to avoid
redundant directory queries.

### EXAMPLE 2
```
ConvertTo-DomainSidString -DomainDnsName 'contoso.com' -AdsiProvider 'LDAP' -Cache $Cache
```

Converts the DNS domain name 'contoso.com' to its corresponding domain SID string by
explicitly using the LDAP provider, which can be more efficient when you already know
the appropriate provider to use.

## PARAMETERS

### -AdsiProvider
AdsiProvider (WinNT or LDAP) of the servers associated with the provided FQDNs or NetBIOS names

This parameter can be used to reduce calls to Find-AdsiProvider

Useful when that has been done already but the DomainsByFqdn and DomainsByNetbios caches have not been updated yet

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

### -DomainDnsName
Domain DNS name to convert to the domain's SID

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
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

### System.String. The SID string of the specified domain.
## NOTES

## RELATED LINKS

