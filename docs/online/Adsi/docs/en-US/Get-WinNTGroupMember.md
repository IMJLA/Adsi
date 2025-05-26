---
external help file: Adsi-help.xml
Module Name: Adsi
online version: https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/11e1608c-6169-4fbc-9c33-373fc9b224f4#Appendix_A_34
schema: 2.0.0
---

# Get-WinNTGroupMember

## SYNOPSIS
Get members of a group from the WinNT provider

## SYNTAX

```powershell
Get-WinNTGroupMember [[-DirectoryEntry] <Object>] [[-PropertiesToLoad] <String[]>] [-Cache] <PSReference>
 [<CommonParameters>]
```

## DESCRIPTION
Get members of a group from the WinNT provider
Convert them from COM objects into usable DirectoryEntry objects

## EXAMPLES

### EXAMPLE 1
```powershell
[System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrators') | Get-WinNTGroupMember -Cache $Cache
```

Retrieves all members of the local Administrators group and returns them as DirectoryEntry objects.
This allows for further processing of group membership information, including nested groups, and provides
a consistent object format that works well with other ADSI functions.
The Cache parameter ensures efficient
operation by avoiding redundant directory queries.

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


