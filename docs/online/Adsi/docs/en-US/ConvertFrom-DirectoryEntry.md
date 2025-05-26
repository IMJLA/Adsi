---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# ConvertFrom-DirectoryEntry

## SYNOPSIS
Convert a DirectoryEntry to a PSCustomObject

## SYNTAX

```powershell
ConvertFrom-DirectoryEntry [[-DirectoryEntry] <DirectoryEntry[]>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Recursively convert every property into a string, or a PSCustomObject (whose properties are all strings, or more PSCustomObjects)
This obfuscates the troublesome PropertyCollection and PropertyValueCollection and Hashtable aspects of working with ADSI

## EXAMPLES

### EXAMPLE 1
```powershell
$DirEntry = [System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrator')
ConvertFrom-DirectoryEntry -DirectoryEntry $DirEntry
```

Converts the DirectoryEntry for the local Administrator account into a PowerShell custom object with simplified
property values.
This makes it easier to work with the object in PowerShell and avoids the complexity of
DirectoryEntry property collections, which can be difficult to access and manipulate directly.

## PARAMETERS

### -DirectoryEntry
DirectoryEntry objects to convert to PSCustomObjects

```yaml
Type: System.DirectoryServices.DirectoryEntry[]
Parameter Sets: (All)
Aliases:

Required: False
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

### [System.DirectoryServices.DirectoryEntry]
## OUTPUTS

### [PSCustomObject]
## NOTES

## RELATED LINKS

