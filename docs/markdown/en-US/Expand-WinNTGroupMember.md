---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Expand-WinNTGroupMember

## SYNOPSIS
Use the LDAP provider to add information about group members to a DirectoryEntry of a group for easier access

## SYNTAX

```powershell
Expand-WinNTGroupMember [[-DirectoryEntry] <Object>] [-Cache] <PSReference> [[-AccountProperty] <String[]>]
 [<CommonParameters>]
```

## DESCRIPTION
Recursively retrieves group members and detailed information about them

## EXAMPLES

### EXAMPLE 1
```powershell
[System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrators') | Get-WinNTGroupMember | Expand-WinNTGroupMember
```

Retrieves the members of the local Administrators group and then expands each member by adding
additional information such as SID, domain information, and group membership details if the member
is itself a group.
This provides a complete hierarchical view of permissions.

## PARAMETERS

### -AccountProperty
Properties of each Account to display on the report

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: @('DisplayName', 'Company', 'Department', 'Title', 'Description')
Accept pipeline input: False
Accept wildcard characters: False
```

### -Cache
In-process cache to reduce calls to other processes or to disk

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DirectoryEntry
Expecting a DirectoryEntry from the WinNT provider, or a PSObject imitation from Get-DirectoryEntry

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

### [System.DirectoryServices.DirectoryEntry]$DirectoryEntry
## OUTPUTS

### [System.DirectoryServices.DirectoryEntry] Returned with member info added now (if the DirectoryEntry is a group).
## NOTES

## RELATED LINKS

