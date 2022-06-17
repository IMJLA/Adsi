---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Get-ADSIGroupMember

## SYNOPSIS
Get members of a group from the LDAP provider

## SYNTAX

```
Get-ADSIGroupMember [[-Group] <Object>] [[-PropertiesToLoad] <String[]>] [[-DirectoryEntryCache] <Hashtable>]
 [<CommonParameters>]
```

## DESCRIPTION
Use ADSI to get members of a group from the LDAP provider
Return the group's DirectoryEntry plus a FullMembers property containing the member DirectoryEntries

## EXAMPLES

### EXAMPLE 1
```
[System.DirectoryServices.DirectoryEntry]::new('LDAP://ad.contoso.com/CN=Administrators,CN=BuiltIn,DC=ad,DC=contoso,DC=com') | Get-ADSIGroupMember
```

Get members of the domain Administrators group

## PARAMETERS

### -DirectoryEntryCache
Hashtable containing cached directory entries so they don't have to be retrieved from the directory again
Uses a thread-safe hashtable by default

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: ([hashtable]::Synchronized(@{}))
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

### -PropertiesToLoad
Properties of the group members to find in the directory

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [System.DirectoryServices.DirectoryEntry] DirectoryEntry parameter
## OUTPUTS

### [System.DirectoryServices.DirectoryEntry] plus a FullMembers property
## NOTES

## RELATED LINKS
