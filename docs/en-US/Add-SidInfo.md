---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Add-SidInfo

## SYNOPSIS
Add some useful properties to a DirectoryEntry object for easier access

## SYNTAX

```
Add-SidInfo [[-InputObject] <Object>] [[-DomainsBySid] <Hashtable>] [<CommonParameters>]
```

## DESCRIPTION
Add SidString, Domain, and SamAccountName NoteProperties to a DirectoryEntry

## EXAMPLES

### EXAMPLE 1
```
[System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrator') | Add-SidInfo
distinguishedName :
Path              : WinNT://localhost/Administrator
```

The output object's default format is not modified so with default formatting it appears identical to the original.
Upon closer inspection it now has SidString, Domain, and SamAccountName properties.

## PARAMETERS

### -DomainsBySid
Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values

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

### -InputObject
Expecting a \[System.DirectoryServices.DirectoryEntry\] from the LDAP or WinNT providers, or a \[PSCustomObject\] imitation from Get-DirectoryEntry.
Must contain the objectSid property

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

### [System.DirectoryServices.DirectoryEntry] or a [PSCustomObject] imitation. InputObject parameter.  Must contain the objectSid property.
## OUTPUTS

### [System.DirectoryServices.DirectoryEntry] or a [PSCustomObject] imitation. Whatever was input, but with three extra properties added now.
## NOTES

## RELATED LINKS
