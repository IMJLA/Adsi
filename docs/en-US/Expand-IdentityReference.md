---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Expand-IdentityReference

## SYNOPSIS
Use ADSI to collect more information about the IdentityReference in NTFS Access Control Entries

## SYNTAX

```
Expand-IdentityReference [[-AccessControlEntry] <Object[]>] [[-GroupMember] <Boolean>]
 [[-GroupMemberRecursion] <Boolean>] [[-DirectoryEntryCache] <Hashtable>]
 [[-IdentityReferenceCache] <Hashtable>] [<CommonParameters>]
```

## DESCRIPTION
Recursively retrieves group members and detailed information about them
Use caching to reduce duplicate directory queries

## EXAMPLES

### EXAMPLE 1
```
Looks like it expects FileSystemAccessRule objects that have been grouped into GroupInfo objects using Group-Object
```

Retrieve the local Administrators group from the WinNT provider, get the members of the group, and expand them

## PARAMETERS

### -AccessControlEntry
The NTFS AccessControlEntry object(s), grouped by their IdentityReference property
TODO: Use System.Security.Principal.NTAccount instead

```yaml
Type: System.Object[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -DirectoryEntryCache
Thread-safe hashtable to use for caching directory entries and avoiding duplicate directory queries

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

### -GroupMember
Get group members

```yaml
Type: System.Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -GroupMemberRecursion
Get group members recursively
If true, implies $GroupMember = $true

```yaml
Type: System.Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -IdentityReferenceCache
Thread-safe hashtable to use for caching directory entries and avoiding duplicate directory queries

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [System.Object]$AccessControlEntry
## OUTPUTS

### [System.Object] The input object is returned with additional properties added:
###     DirectoryEntry
###     DomainDn
###     DomainNetBIOS
###     ObjectType
###     Members (if the DirectoryEntry is a group).
## NOTES

## RELATED LINKS
