---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# ConvertFrom-ResultPropertyValueCollectionToString

## SYNOPSIS
Convert a ResultPropertyValueCollection to a string

## SYNTAX

```powershell
ConvertFrom-ResultPropertyValueCollectionToString
 [[-ResultPropertyValueCollection] <ResultPropertyValueCollection>]
```

## DESCRIPTION
Useful when working with System.DirectoryServices and some other namespaces

## EXAMPLES

### EXAMPLE 1
```powershell
$DirectoryEntry = [adsi]("WinNT://$(hostname)")
$DirectoryEntry.Properties.Keys |
ForEach-Object {
 ConvertFrom-PropertyValueCollectionToString -PropertyValueCollection $DirectoryEntry.Properties[$_]
}
```

For each property in a DirectoryEntry, convert its corresponding PropertyValueCollection to a string

## PARAMETERS

### -ResultPropertyValueCollection
{{ Fill ResultPropertyValueCollection Description }}

```yaml
Type: System.DirectoryServices.ResultPropertyValueCollection
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
## NOTES

## RELATED LINKS

