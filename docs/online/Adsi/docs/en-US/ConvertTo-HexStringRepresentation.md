---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# ConvertTo-HexStringRepresentation

## SYNOPSIS
Convert a SID from byte array format to a string representation of its hexadecimal format

## SYNTAX

```powershell
ConvertTo-HexStringRepresentation [[-SIDByteArray] <Byte[]>]
```

## DESCRIPTION
Uses the custom format operator -f to format each byte as a string hex representation

## EXAMPLES

### EXAMPLE 1
```powershell
ConvertTo-HexStringRepresentation -SIDByteArray $Bytes
```

Convert the binary SID $Bytes to a hexadecimal string representation

## PARAMETERS

### -SIDByteArray
SID

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

### [System.Byte[]]$SIDByteArray
## OUTPUTS

### [System.String] SID as an array of strings representing the byte array's hexadecimal values
## NOTES

## RELATED LINKS

