---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# ConvertFrom-SearchResult

## SYNOPSIS
Convert a SearchResult to a PSCustomObject

## SYNTAX

```powershell
ConvertFrom-SearchResult [[-SearchResult] <SearchResult[]>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Recursively convert every property into a string, or a PSCustomObject (whose properties are all strings, or more PSCustomObjects)
This obfuscates the troublesome ResultPropertyCollection and ResultPropertyValueCollection and Hashtable aspects of working with ADSI searches

## EXAMPLES

### EXAMPLE 1
```powershell
$DirectorySearcher = [System.DirectoryServices.DirectorySearcher]::new("LDAP://DC=contoso,DC=com")
$DirectorySearcher.Filter = "(objectClass=user)"
$SearchResults = $DirectorySearcher.FindAll()
$SearchResults | ConvertFrom-SearchResult
```

Performs a search in Active Directory for all user objects, then converts each SearchResult
into a PSCustomObject with simplified properties.
This makes it easier to work with the
search results in PowerShell by flattening complex nested property collections into
regular object properties.

## PARAMETERS

### -SearchResult
SearchResult objects to convert to PSCustomObjects

```yaml
Type: System.DirectoryServices.SearchResult[]
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

### System.DirectoryServices.SearchResult[]
### Accepts SearchResult objects from a directory search via the pipeline.
## OUTPUTS

### PSCustomObject
### Returns PSCustomObject instances with simplified properties.
## NOTES
# TODO: There is a faster way than Select-Object, just need to dig into the default formatting of SearchResult to see how to get those properties

## RELATED LINKS

