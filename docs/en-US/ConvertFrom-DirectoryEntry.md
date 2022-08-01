---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# ConvertFrom-DirectoryEntry

## SYNOPSIS
Convert a DirectoryEntry to a PSCustomObject

## SYNTAX

```
ConvertFrom-DirectoryEntry [[-DirectoryEntry] <DirectoryEntry[]>] [<CommonParameters>]
```

## DESCRIPTION
Recursively convert every property into a string, or a PSCustomObject (whose properties are all strings, or more PSCustomObjects)
This obfuscates the troublesome PropertyCollection and PropertyValueCollection and Hashtable aspects of working with ADSI

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -DirectoryEntry
{{ Fill DirectoryEntry Description }}

```yaml
Type: System.DirectoryServices.DirectoryEntry[]
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

## OUTPUTS

## NOTES
# TODO: There is a faster way than Select-Object, just need to dig into the default formatting of DirectoryEntry to see how to get those properties

## RELATED LINKS
