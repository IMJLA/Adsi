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
Expand-IdentityReference [[-AccessControlEntry] <Object[]>] [-NoGroupMembers]
 [[-IdentityReferenceCache] <Hashtable>] [[-DirectoryEntryCache] <Hashtable>] [[-DomainsByNetbios] <Hashtable>]
 [[-DomainsBySid] <Hashtable>] [[-DomainsByFqdn] <Hashtable>] [<CommonParameters>]
```

## DESCRIPTION
Recursively retrieves group members and detailed information about them
Use caching to reduce duplicate directory queries

## EXAMPLES

### EXAMPLE 1
```
(Get-Acl).Access |
Resolve-IdentityReference |
Group-Object -Property IdentityReferenceResolved |
Expand-IdentityReference
```

Incomplete example but it shows the chain of functions to generate the expected input for this

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
Dictionary to cache directory entries to avoid redundant lookups

Defaults to an empty thread-safe hashtable

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

### -DomainsByFqdn
Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### -DomainsByNetbios
Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values

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

### -DomainsBySid
Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values

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

### -IdentityReferenceCache
Thread-safe hashtable to use for caching directory entries and avoiding duplicate directory queries

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

### -NoGroupMembers
Do not get group members

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
