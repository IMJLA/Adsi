---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# ConvertTo-DecStringRepresentation

## SYNOPSIS
Convert a byte array to a string representation of its decimal format

## SYNTAX

```powershell
ConvertTo-DecStringRepresentation [[-ByteArray] <Byte[]>]
```

## DESCRIPTION
Uses the custom format operator -f to format each byte as a string decimal representation

## EXAMPLES

### EXAMPLE 1
```powershell
ConvertTo-DecStringRepresentation -ByteArray $Bytes
```

Convert the binary SID $Bytes to a decimal string representation

## PARAMETERS

### -ByteArray
Byte array. 
Often the binary format of an objectSid or LoginHours

```yaml
Type: System.Byte[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### [System.Byte[]]$ByteArray
## OUTPUTS

### [System.String] Array of strings representing the byte array's decimal values
## NOTES

## RELATED LINKS


