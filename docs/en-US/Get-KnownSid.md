---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Get-KnownSid

## SYNOPSIS
Retrieves information about well-known security identifiers (SIDs).

## SYNTAX

```
Get-KnownSid [[-SID] <String>]
```

## DESCRIPTION
Gets information about well-known security identifiers (SIDs) based on patterns and common formats.
Uses Microsoft documentation references for SID information:
- https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/81d92bba-d22b-4a8c-908a-554ab29148ab
- https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-identifiers

## EXAMPLES

### EXAMPLE 1
```
Get-KnownSid -SID 'S-1-5-32-544'
```

Returns information about the built-in Administrators group.

### EXAMPLE 2
```
Get-KnownSid -SID 'S-1-5-18'
```

Returns information about the Local System account.

## PARAMETERS

### -SID
Security Identifier (SID) string to retrieve information for

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### System.String
## OUTPUTS

### PSCustomObject with properties such as Description, DisplayName, Name, NTAccount, SamAccountName, SchemaClassName, and SID.
## NOTES

## RELATED LINKS

