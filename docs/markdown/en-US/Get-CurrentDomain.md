---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Get-CurrentDomain

## SYNOPSIS
Use ADSI to get the current domain

## SYNTAX

```powershell
Get-CurrentDomain [-Cache] <PSReference> [<CommonParameters>]
```

## DESCRIPTION
Works only on domain-joined systems, otherwise returns nothing

## EXAMPLES

### EXAMPLE 1
```powershell
Get-CurrentDomain -Cache $Cache
```

Retrieves the current domain of the computer running the script as a DirectoryEntry object.
On domain-joined systems, this returns the Active Directory domain.
On workgroup computers,
it returns the local computer as the domain.
The function caches the result to improve
performance in subsequent operations involving the current domain.

## PARAMETERS

### -Cache
In-process cache to reduce calls to other processes or to disk

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction- `{ Fill ProgressAction Description )`}

```yaml
Type: System.Management.Automation.ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. Pipeline input is not accepted.
## OUTPUTS

### [System.DirectoryServices.DirectoryEntry] The current domain
## NOTES

## RELATED LINKS

