---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Get-KnownSidByName

## SYNOPSIS
Creates a hashtable of well-known SIDs indexed by their friendly names.

## SYNTAX

```
Get-KnownSidByName [[-WellKnownSIDBySID] <Hashtable>]
```

## DESCRIPTION
This function takes a hashtable of well-known SIDs (indexed by SID) and
transforms it into a new hashtable where the keys are the friendly names
of the SIDs.
This makes it easier to look up SID information when you
know the name but not the SID itself.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

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

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

