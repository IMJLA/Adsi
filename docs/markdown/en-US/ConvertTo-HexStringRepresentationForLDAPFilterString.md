---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# ConvertTo-HexStringRepresentationForLDAPFilterString

## SYNOPSIS
Convert a SID from byte array format to a string representation of its hexadecimal format, properly formatted for an LDAP filter string

## SYNTAX

```powershell
ConvertTo-HexStringRepresentationForLDAPFilterString [[-SIDByteArray] <Byte[]>]
 [<CommonParameters>]
```

## DESCRIPTION
Uses the custom format operator -f to format each byte as a string hex representation

## EXAMPLES

### EXAMPLE 1
```powershell
ConvertTo-HexStringRepresentationForLDAPFilterString -SIDByteArray $Bytes
```

Convert the binary SID $Bytes to a hexadecimal string representation, formatted for use in an LDAP filter string

## PARAMETERS

### -SIDByteArray
SID to convert to a hex string

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [System.Byte[]]$SIDByteArray
## OUTPUTS

### [System.String] SID as an array of strings representing the byte array's hexadecimal values
## NOTES

## RELATED LINKS

