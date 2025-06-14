---
external help file: Adsi-help.xml
Module Name: Adsi
ModuleGuid: 282a2aed-9567-49a1-901c-122b7831a805
ModuleName: Adsi
ModuleVersion: 5.0.509
online version: https://IMJLA.github.io/Adsi/docs/en-US/Get-CurrentDomain
schema: 2.0.0
---

# Get-KnownSidByName

## SYNOPSIS
Creates a hashtable of well-known SIDs indexed by their friendly names.

## SYNTAX

```powershell
Get-KnownSidByName [[-WellKnownSIDBySID] <Hashtable>] [<CommonParameters>]
```

## DESCRIPTION
This function takes a hashtable of well-known SIDs (indexed by SID) and
transforms it into a new hashtable where the keys are the friendly names
of the SIDs.
This makes it easier to look up SID information when you
know the name but not the SID itself.

## EXAMPLES

### EXAMPLE 1
```powershell
$sidBySid = Get-KnownSidHashTable
$sidByName = Get-KnownSidByName -WellKnownSIDBySID $sidBySid
$administratorsInfo = $sidByName['Administrators']
```

Creates a hashtable of well-known SIDs indexed by their friendly names and retrieves
information about the Administrators group.
This is useful when you need to look up
SID information by name rather than by SID string.

## PARAMETERS

### -WellKnownSIDBySID
Hashtable containing well-known SIDs as keys with their properties as values

```yaml
Type: System.Collections.Hashtable
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

### System.Collections.Hashtable
### A hashtable containing SID strings as keys and information objects as values.
## OUTPUTS

### System.Collections.Hashtable
### Returns a hashtable with friendly names as keys and SID information objects as values.
## NOTES

## RELATED LINKS

