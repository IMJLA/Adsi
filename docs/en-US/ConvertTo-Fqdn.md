---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# ConvertTo-Fqdn

## SYNOPSIS
Convert a domain distinguishedName name or NetBIOS name to its FQDN

## SYNTAX

### DistinguishedName
```
ConvertTo-Fqdn [-DistinguishedName <String[]>] [-DirectoryEntryCache <Hashtable>]
 [-DomainsByNetbios <Hashtable>] [-DomainsBySid <Hashtable>] [-DomainsByFqdn <Hashtable>] [<CommonParameters>]
```

### NetBIOS
```
ConvertTo-Fqdn [-NetBIOS <String[]>] [-DirectoryEntryCache <Hashtable>] [-DomainsByNetbios <Hashtable>]
 [-DomainsBySid <Hashtable>] [-DomainsByFqdn <Hashtable>] [<CommonParameters>]
```

## DESCRIPTION
For the DistinguishedName parameter, uses PowerShell's -replace operator to perform the conversion
For the NetBIOS parameter, uses ConvertTo-DistinguishedName to convert from NetBIOS to distinguishedName, then recursively calls this function to get the FQDN

## EXAMPLES

### EXAMPLE 1
```
ConvertTo-Fqdn -DistinguishedName 'DC=ad,DC=contoso,DC=com'
ad.contoso.com
```

Convert the domain distinguishedName 'DC=ad,DC=contoso,DC=com' to its FQDN format 'ad.contoso.com'

## PARAMETERS

### -DirectoryEntryCache
Dictionary to cache directory entries to avoid redundant lookups

Defaults to an empty thread-safe hashtable

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### -DistinguishedName
distinguishedName of the domain

```yaml
Type: System.String[]
Parameter Sets: DistinguishedName
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -DomainsByFqdn
Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### -DomainsByNetbios
Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### -DomainsBySid
Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### -NetBIOS
NetBIOS name of the domain

```yaml
Type: System.String[]
Parameter Sets: NetBIOS
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [System.String]$DistinguishedName
## OUTPUTS

### [System.String] FQDN version of the distinguishedName
## NOTES

## RELATED LINKS
