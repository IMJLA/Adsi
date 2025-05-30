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
```powershell
ConvertTo-Fqdn [-DistinguishedName <String[]>] -Cache <PSReference> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### NetBIOS
```powershell
ConvertTo-Fqdn [-NetBIOS <String[]>] -Cache <PSReference> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
For the DistinguishedName parameter, uses PowerShell's -replace operator to perform the conversion
For the NetBIOS parameter, uses ConvertTo-DistinguishedName to convert from NetBIOS to distinguishedName, then recursively calls this function to get the FQDN

## EXAMPLES

### EXAMPLE 1
```powershell
ConvertTo-Fqdn -DistinguishedName 'DC=ad,DC=contoso,DC=com' -Cache $Cache
```

Converts the domain distinguishedName 'DC=ad,DC=contoso,DC=com' to its FQDN format 'ad.contoso.com'.
This is essential when working with LDAP directory paths that need to be converted to readable domain
names or when constructing proper LDAP paths that require the FQDN of the domain for remote connections.

## PARAMETERS

### -Cache
In-process cache to reduce calls to other processes or to disk

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
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

