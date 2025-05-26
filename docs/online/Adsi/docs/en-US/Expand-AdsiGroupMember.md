---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Expand-AdsiGroupMember

## SYNOPSIS
Use the LDAP provider to add information about group members to a DirectoryEntry of a group for easier access

## SYNTAX

```powershell
Expand-AdsiGroupMember [[-DirectoryEntry] <Object>] [[-PropertiesToLoad] <String[]>] [-Cache] <PSReference>
 [<CommonParameters>]
```

## DESCRIPTION
Recursively retrieves group members and detailed information about them
Specifically gets the SID, and resolves foreign security principals to their DirectoryEntry from the trusted domain

## EXAMPLES

### EXAMPLE 1
```powershell
[System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrators') |
Get-AdsiGroupMember |
Expand-AdsiGroupMember
```

Retrieves the members of the local Administrators group and then expands each member with additional
information such as SID and domain information.
Foreign security principals from trusted domains are
resolved to their actual DirectoryEntry objects from the appropriate domain.

### EXAMPLE 2
```powershell
[System.DirectoryServices.DirectoryEntry]::new('LDAP://ad.contoso.com/CN=Administrators,CN=BuiltIn,DC=ad,DC=contoso,DC=com') |
Get-AdsiGroupMember |
Expand-AdsiGroupMember -Cache $Cache
```

Retrieves the members of the domain Administrators group and then expands each member with additional
information such as SID and domain information.
Foreign security principals from trusted domains are
resolved to their actual DirectoryEntry objects from the appropriate domain.

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
Expecting a DirectoryEntry from the LDAP or WinNT providers, or a PSObject imitation from Get-DirectoryEntry

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
Properties of the group members to retrieve

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

### [System.DirectoryServices.DirectoryEntry] Returned with member info added now (if the DirectoryEntry is a group).
## NOTES

## RELATED LINKS

