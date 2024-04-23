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

### NetBIOS
```
ConvertTo-DistinguishedName -Domain <String[]> [-DomainsByNetbios <Hashtable>] [-InitType <String>]
 [-InputType <String>] [-OutputType <String>] [-AdsiProvider <String>] [-ThisHostName <String>]
 [-WhoAmI <String>] [-LogBuffer <Hashtable>] [-DebugOutputStream <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### FQDN
```
ConvertTo-DistinguishedName -DomainFQDN <String[]> [-InitType <String>] [-InputType <String>]
 [-OutputType <String>] [-AdsiProvider <String>] [-ThisHostName <String>] [-WhoAmI <String>]
 [-LogBuffer <Hashtable>] [-DebugOutputStream <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
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

### -AdsiProvider
AdsiProvider (WinNT or LDAP) of the servers associated with the provided FQDNs or NetBIOS names

This parameter can be used to reduce calls to Find-AdsiProvider

Useful when that has been done already but the DomainsByFqdn and DomainsByNetbios caches have not been updated yet

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

### -DebugOutputStream
Output stream to send the log messages to

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Debug
Accept pipeline input: False
Accept wildcard characters: False
```

### -Domain
NetBIOS name of the domain

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
NetBIOS name of the domain

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

### -DomainsByNetbios
{{ Fill DomainsByNetbios Description }}

```yaml
Type: System.Collections.Hashtable
Parameter Sets: NetBIOS
Aliases:

Required: False
Position: Named
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### -InitType
Type of initialization to be performed
Will be translated to the corresponding integer for use as the lnSetType parameter of the IADsNameTranslate::Init method (iads.h)
https://docs.microsoft.com/en-us/windows/win32/api/iads/ne-iads-ads_name_inittype_enum

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: ADS_NAME_INITTYPE_GC
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputType
Format of the name of the directory object that will be used for the input
Will be translated to the corresponding integer for use as the lnSetType parameter of the IADsNameTranslate::Set method (iads.h)
https://docs.microsoft.com/en-us/windows/win32/api/iads/ne-iads-ads_name_type_enum

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: ADS_NAME_TYPE_NT4
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogBuffer
Log messages which have not yet been written to disk

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

### -OutputType
Format of the name of the directory object that will be used for the output
Will be translated to the corresponding integer for use as the lnSetType parameter of the IADsNameTranslate::Get method (iads.h)
https://docs.microsoft.com/en-us/windows/win32/api/iads/ne-iads-ads_name_type_enum

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: ADS_NAME_TYPE_1779
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

### -ThisHostName
Hostname of the computer running this function.

Can be provided as a string to avoid calls to HOSTNAME.EXE

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (HOSTNAME.EXE)
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhoAmI
Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: (whoami.EXE)
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [System.String]$Domain
## OUTPUTS

### [System.String] distinguishedName of the domain
## NOTES

## RELATED LINKS
