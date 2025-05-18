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

```
Get-KnownCaptionHashTable [[-WellKnownSidBySid] <Hashtable>]
```

## DESCRIPTION
This function takes a hashtable of well-known SIDs (indexed by SID) and
transforms it into a new hashtable where the keys are the NT Account names
(captions) of the SIDs.
This makes it easier to look up SID information when
you have the account name representation rather than the SID itself.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

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

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

