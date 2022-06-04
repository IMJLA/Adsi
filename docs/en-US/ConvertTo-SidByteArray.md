---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# ConvertTo-SidByteArray

## SYNOPSIS
Convert a SID from a string to binary format (byte array)

## SYNTAX

```
ConvertTo-SidByteArray [[-SidString] <String[]>] [<CommonParameters>]
```

## DESCRIPTION
Uses the GetBinaryForm method of the \[System.Security.Principal.SecurityIdentifier\] class

## EXAMPLES

### EXAMPLE 1
```
ConvertTo-SidByteArray -SidString $SID
```

Convert the SID string to a byte array

## PARAMETERS

### -SidString
SID to convert to binary

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

### [System.String] SidString parameter
## OUTPUTS

### [System.Byte] SID a a byte array
## NOTES

## RELATED LINKS
