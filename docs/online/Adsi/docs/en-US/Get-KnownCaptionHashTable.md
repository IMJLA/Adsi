---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Get-KnownCaptionHashTable

## SYNOPSIS
Creates a hashtable of well-known SIDs indexed by their NT Account names (captions).

## SYNTAX

```powershell
Get-KnownCaptionHashTable [[-WellKnownSidBySid] <Hashtable>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
This function takes a hashtable of well-known SIDs (indexed by SID) and
transforms it into a new hashtable where the keys are the NT Account names
(captions) of the SIDs.
This makes it easier to look up SID information when
you have the account name representation rather than the SID itself.

## EXAMPLES

### EXAMPLE 1
```powershell
$sidBySid = Get-KnownSidHashTable
$sidByCaption = Get-KnownCaptionHashTable -WellKnownSidBySid $sidBySid
$systemInfo = $sidByCaption['NT AUTHORITY\SYSTEM']
```

Creates a hashtable of well-known SIDs indexed by their NT Account names and retrieves
information about the SYSTEM account.
This is useful when you need to look up SID
information by NT Account name rather than by SID string.

## PARAMETERS

### -WellKnownSidBySid
Hashtable of well-known Security Identifiers (SIDs) with their properties

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: (Get-KnownSidHashTable)
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
### Returns a hashtable with NT Account names as keys and SID information objects as values.
## NOTES

## RELATED LINKS

