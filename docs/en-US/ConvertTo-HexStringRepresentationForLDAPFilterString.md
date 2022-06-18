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

```
ConvertTo-HexStringRepresentationForLDAPFilterString [[-SIDByteArray] <Byte[]>]
```

## DESCRIPTION
Uses the custom format operator -f to format each byte as a string hex representation

## EXAMPLES

### EXAMPLE 1
```
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

## INPUTS

### [System.Byte[]]$SIDByteArray
## OUTPUTS

### [System.String] SID as an array of strings representing the byte array's hexadecimal values
## NOTES

## RELATED LINKS
