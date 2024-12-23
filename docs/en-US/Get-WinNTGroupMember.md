---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Get-WinNTGroupMember

## SYNOPSIS
Get members of a group from the WinNT provider

## SYNTAX

```
Get-WinNTGroupMember [[-DirectoryEntry] <Object>] [[-PropertiesToLoad] <String[]>] [-Cache] <PSReference>
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Get members of a group from the WinNT provider
Convert them from COM objects into usable DirectoryEntry objects

## EXAMPLES

### EXAMPLE 1
```
[System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrators') | Get-WinNTGroupMember
```

Get members of the local Administrators group

## PARAMETERS

### -Cache
In-process cache to reduce calls to other processes or to disk

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DirectoryEntry
DirectoryEntry \[System.DirectoryServices.DirectoryEntry\] of the WinNT group whose members to get

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

### -ProgressAction
{{ Fill ProgressAction Description }}

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

### -PropertiesToLoad
Properties of the group members to find in the directory

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: @('distinguishedName', 'groupType', 'member', 'name', 'objectClass', 'objectSid', 'primaryGroupToken', 'samAccountName')
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [System.DirectoryServices.DirectoryEntry]$DirectoryEntry
## OUTPUTS

### [System.DirectoryServices.DirectoryEntry] for each group member
## NOTES

## RELATED LINKS
