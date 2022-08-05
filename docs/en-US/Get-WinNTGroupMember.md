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
Get-WinNTGroupMember [[-DirectoryEntry] <Object>] [[-DirectoryEntryCache] <Hashtable>]
 [[-PropertiesToLoad] <String[]>] [[-DomainsByNetbios] <Hashtable>] [[-KnownDomains] <Object>]
 [<CommonParameters>]
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

### -DirectoryEntryCache
Hashtable containing cached directory entries so they don't have to be retrieved from the directory again
Uses a thread-safe hashtable by default

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### -DomainsByNetbios
{{ Fill DomainsByNetbios Description }}

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### -KnownDomains
Hashtable of domain DNs

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: (Get-TrustedDomainSidNameMap -DirectoryEntryCache $DirectoryEntryCache -KeyByNetbios -DomainsByNetbios $DomainsByNetbios)
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
Position: 3
Default value: None
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
