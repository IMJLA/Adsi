---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Get-AdsiGroupMember

## SYNOPSIS
Get members of a group from the LDAP provider

## SYNTAX

```
Get-AdsiGroupMember [[-Group] <Object>] [[-PropertiesToLoad] <String[]>] [-NoRecurse] [-PrimaryGroupOnly]
 [-Cache] <PSReference> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Use ADSI to get members of a group from the LDAP provider
Return the group's DirectoryEntry plus a FullMembers property containing the member DirectoryEntries

## EXAMPLES

### EXAMPLE 1
```
[System.DirectoryServices.DirectoryEntry]::new('LDAP://ad.contoso.com/CN=Administrators,CN=BuiltIn,DC=ad,DC=contoso,DC=com') |
Get-AdsiGroupMember -Cache $Cache
```

Retrieves all members of the domain's Administrators group, including both direct members and those
who inherit membership through their primary group.
The function returns the original group DirectoryEntry
object with an added FullMembers property containing all member DirectoryEntry objects.
This
approach ensures proper resolution of all group memberships regardless of how they are assigned.

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

### -Group
Directory entry of the LDAP group whose members to get

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

### -NoRecurse
Perform a non-recursive search of the memberOf attribute

Otherwise the search will be recursive by default

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -PrimaryGroupOnly
Search the primaryGroupId attribute only

Ignore the memberOf attribute

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
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

### [System.DirectoryServices.DirectoryEntry] plus a FullMembers property
## NOTES

## RELATED LINKS

