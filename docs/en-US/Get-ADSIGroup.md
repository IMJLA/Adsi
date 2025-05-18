---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Get-AdsiGroup

## SYNOPSIS
Get the directory entries for a group and its members using ADSI

## SYNTAX

```
Get-AdsiGroup [[-DirectoryPath] <String>] [[-GroupName] <String>] [[-PropertiesToLoad] <String[]>]
 [-Cache] <PSReference> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Uses the ADSI components to search a directory for a group, then get its members
Both the WinNT and LDAP providers are supported

## EXAMPLES

### EXAMPLE 1
```
Get-AdsiGroup -DirectoryPath 'WinNT://WORKGROUP/localhost' -GroupName Administrators
```

Get members of the local Administrators group

### EXAMPLE 2
```
Get-AdsiGroup -GroupName Administrators
```

On a domain-joined computer, this will get members of the domain's Administrators group
On a workgroup computer, this will get members of the local Administrators group

## PARAMETERS

### -Cache
In-process cache to reduce calls to other processes or to disk

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DirectoryPath
Path to the directory object to retrieve
Defaults to the root of the current domain

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: (([System.DirectoryServices.DirectorySearcher]::new()).SearchRoot.Path)
Accept pipeline input: False
Accept wildcard characters: False
```

### -GroupName
Name (CN or Common Name) of the group to retrieve

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
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
Properties of the group members to retrieve

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: @('distinguishedName', 'groupType', 'member', 'name', 'objectClass', 'objectSid', 'primaryGroupToken', 'samAccountName')
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. Pipeline input is not accepted.
## OUTPUTS

### [System.DirectoryServices.DirectoryEntry] for each group memeber
## NOTES

## RELATED LINKS

