---
external help file: Adsi-help.xml
Module Name: Adsi
online version: https://IMJLA.github.io/Adsi/docs/en-US/ConvertTo-DistinguishedName
schema: 2.0.0
---

# ConvertTo-DistinguishedName

## SYNOPSIS
Fill in the Synopsis

## SYNTAX

### NetBIOS
```powershell
ConvertTo-DistinguishedName -Domain <String[]> [-InitType <String>] [-InputType <String>]
 [-OutputType <String>] [-AdsiProvider <String>] -Cache <PSReference> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### FQDN
```powershell
ConvertTo-DistinguishedName -DomainFQDN <String[]> [-InitType <String>] [-InputType <String>]
 [-OutputType <String>] [-AdsiProvider <String>] -Cache <PSReference> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Fill in the Description

## EXAMPLES

### Example 1
```powershell
PS C:\> Add example code here
```

Add example description here

## PARAMETERS

### -AdsiProvider
Fill AdsiProvider Description

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Cache
Fill Cache Description

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

### -Domain
Fill Domain Description

```yaml
Type: System.String[]
Parameter Sets: NetBIOS
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -DomainFQDN
Fill DomainFQDN Description

```yaml
Type: System.String[]
Parameter Sets: FQDN
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -InitType
Fill InitType Description

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputType
Fill InputType Description

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutputType
Fill OutputType Description

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String[]

## OUTPUTS

### System.String

## NOTES

## RELATED LINKS

[https://IMJLA.github.io/Adsi/docs/en-US/ConvertTo-DistinguishedName](https://IMJLA.github.io/Adsi/docs/en-US/ConvertTo-DistinguishedName)


