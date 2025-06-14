---
external help file: Adsi-help.xml
Module Name: Adsi
ModuleGuid: 282a2aed-9567-49a1-901c-122b7831a805
ModuleName: Adsi
ModuleVersion: 5.0.507
online version: https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/11e1608c-6169-4fbc-9c33-373fc9b224f4#Appendix_A_34
schema: 2.0.0
---

# Get-KnownSidHashTable

## SYNOPSIS
Returns a hashtable of known security identifiers (SIDs) with detailed information.

## SYNTAX

```powershell
Get-KnownSidHashTable [<CommonParameters>]
```

## DESCRIPTION
Returns a hashtable of known SIDs which can be used to avoid errors and delays due to unnecessary directory queries.
Some SIDs cannot be translated using the \[SecurityIdentifier\]::Translate or \[NTAccount\]::Translate methods.
Some SIDs cannot be retrieved using CIM or ADSI.
Hardcoding them here allows avoiding queries that we know will fail.
Hardcoding them also improves performance by avoiding unnecessary directory queries with predictable results.

## EXAMPLES

### EXAMPLE 1
```powershell
$knownSids = Get-KnownSidHashTable
```

This hashtable can be used to look up information about well-known SIDs:
$knownSids\['S-1-5-18'\].DisplayName # Returns 'LocalSystem'
$knownSids\['S-1-5-32-544'\].Description # Returns description of the Administrators group

## PARAMETERS

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. This function does not accept pipeline input.
## OUTPUTS

### System.Collections.Hashtable. Contains SIDs as keys and PSCustomObjects with SID information as values.
## NOTES

## RELATED LINKS

[https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/11e1608c-6169-4fbc-9c33-373fc9b224f4#Appendix_A_34](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/11e1608c-6169-4fbc-9c33-373fc9b224f4#Appendix_A_34)

[https://learn.microsoft.com/en-us/windows/win32/secauthz/well-known-sids](https://learn.microsoft.com/en-us/windows/win32/secauthz/well-known-sids)


