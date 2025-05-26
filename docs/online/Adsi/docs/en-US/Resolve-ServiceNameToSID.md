---
external help file: Adsi-help.xml
Module Name: Adsi
online version: https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/11e1608c-6169-4fbc-9c33-373fc9b224f4#Appendix_A_34
schema: 2.0.0
---

# Resolve-ServiceNameToSID

## SYNOPSIS
Resolves Windows service names to their corresponding security identifiers (SIDs).

## SYNTAX

```powershell
Resolve-ServiceNameToSID [[-InputObject] <Object>] [<CommonParameters>]
```

## DESCRIPTION
This function takes service objects (from Get-Service or Win32_Service) and
calculates their corresponding SIDs using the same algorithm as sc.exe showsid.
It enriches the input service objects with SID and Status and returns the
enhanced objects with all original properties preserved.

## EXAMPLES

### EXAMPLE 1
```powershell
Get-Service -Name "BITS" | Resolve-ServiceNameToSID
```

Remark: This example retrieves the Background Intelligent Transfer Service and resolves its service name to a SID.
The output includes all original properties of the service plus the SID property.

## PARAMETERS

### -InputObject
Output of Get-Service or an instance of the Win32_Service CIM class

```yaml
Type: System.Object
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

## OUTPUTS

## NOTES

## RELATED LINKS

