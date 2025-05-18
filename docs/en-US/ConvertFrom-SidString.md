---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# ConvertFrom-SidString

## SYNOPSIS
Converts a SID string to a DirectoryEntry object.

## SYNTAX

```
ConvertFrom-SidString [[-SID] <String>] [-Cache] <PSReference> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Attempts to resolve a security identifier (SID) string to its corresponding DirectoryEntry object
by querying the directory service using the LDAP provider.
This function is not currently in use
by the Export-Permission module.

## EXAMPLES

### EXAMPLE 1
```
ConvertFrom-SidString -SID 'S-1-5-21-3165297888-301567370-576410423-1103' -Cache $Cache
```

## PARAMETERS

### -Cache
In-process cache to reduce calls to other processes or to disk

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
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

### -SID
Security Identifier (SID) string to convert to a DirectoryEntry

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

### System.String
## OUTPUTS

### System.DirectoryServices.DirectoryEntry
## NOTES
This function is not currently in use by Export-Permission

## RELATED LINKS

