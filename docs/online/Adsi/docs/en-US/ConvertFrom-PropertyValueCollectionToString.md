---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# ConvertFrom-PropertyValueCollectionToString

## SYNOPSIS
Convert a PropertyValueCollection to a string

## SYNTAX

```powershell
ConvertFrom-PropertyValueCollectionToString [[-PropertyValueCollection] <PropertyValueCollection>]
```

## DESCRIPTION
Useful when working with System.DirectoryServices and some other namespaces

## EXAMPLES

### EXAMPLE 1
```powershell
$DirectoryEntry = [adsi]("WinNT://$(hostname)")
$DirectoryEntry.Properties.Keys |
ForEach-Objec- `
 ConvertFrom-PropertyValueCollectionToString -PropertyValueCollection $DirectoryEntry.Properties[$_]
)`
```

For each property in a DirectoryEntry, convert its corresponding PropertyValueCollection to a string

## PARAMETERS

### -PropertyValueCollection
This PropertyValueCollection will be converted to a string

```yaml
Type: System.DirectoryServices.PropertyValueCollection
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### None. Pipeline input is not accepted.
## OUTPUTS

### [System.String]
### Returns a string representation of the PropertyValueCollection's value.
## NOTES

## RELATED LINKS


