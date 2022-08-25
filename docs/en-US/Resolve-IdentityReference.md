---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Resolve-IdentityReference

## SYNOPSIS
Use ADSI to lookup info about IdentityReferences from Access Control Entries that came from Discretionary Access Control Lists

## SYNTAX

```
Resolve-IdentityReference [-IdentityReference] <String> [[-AdsiServer] <PSObject>]
<<<<<<< HEAD
 [[-AdsiServersByDns] <Hashtable>] [[-Win32AccountsBySID] <Hashtable>] [[-Win32AccountsByCaption] <Hashtable>]
 [[-DirectoryEntryCache] <Hashtable>] [[-DomainsByNetbios] <Hashtable>] [[-DomainsBySid] <Hashtable>]
 [[-DomainsByFqdn] <Hashtable>] [<CommonParameters>]
=======
 [[-Win32AccountsBySID] <Hashtable>] [[-Win32AccountsByCaption] <Hashtable>] [[-AdsiServersByDns] <Hashtable>]
 [[-DomainsByNetbios] <Hashtable>] [[-DomainsBySid] <Hashtable>] [[-DomainsByFqdn] <Hashtable>]
 [<CommonParameters>]
>>>>>>> 9663a8b96d44b8aea92dad5f252f70db06c934d5
```

## DESCRIPTION
Based on the IdentityReference proprety of each Access Control Entry:
Resolve SID to NT account name and vise-versa
Resolve well-known SIDs
Resolve generic defaults like 'NT AUTHORITY' and 'BUILTIN' to the applicable computer or domain name

## EXAMPLES

### EXAMPLE 1
```
Resolve-IdentityReference -IdentityReference 'BUILTIN\Administrator' -AdsiServer (Get-AdsiServer 'localhost')
```

Get information about the local Administrator account

## PARAMETERS

### -AdsiServer
Object from Get-AdsiServer representing the directory server and its attributes

```yaml
Type: System.Management.Automation.PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AdsiServersByDns
Dictionary to cache known servers to avoid redundant lookups

Defaults to an empty thread-safe hashtable

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
<<<<<<< HEAD
Position: 3
=======
Position: 5
>>>>>>> 9663a8b96d44b8aea92dad5f252f70db06c934d5
Default value: [hashtable]::Synchronized(@{})
Accept pipeline input: False
Accept wildcard characters: False
```

<<<<<<< HEAD
### -DirectoryEntryCache
Dictionary to cache directory entries to avoid redundant lookups

Defaults to an empty thread-safe hashtable

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

=======
>>>>>>> 9663a8b96d44b8aea92dad5f252f70db06c934d5
### -DomainsByFqdn
Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
<<<<<<< HEAD
Position: 9
=======
Position: 8
>>>>>>> 9663a8b96d44b8aea92dad5f252f70db06c934d5
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
<<<<<<< HEAD
Position: 7
=======
Position: 6
>>>>>>> 9663a8b96d44b8aea92dad5f252f70db06c934d5
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
<<<<<<< HEAD
Position: 8
=======
Position: 7
>>>>>>> 9663a8b96d44b8aea92dad5f252f70db06c934d5
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### -IdentityReference
IdentityReference from an Access Control Entry
Expecting either a SID (S-1-5-18) or an NT account name (CONTOSO\User)

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Win32AccountsByCaption
{{ Fill Win32AccountsByCaption Description }}

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
<<<<<<< HEAD
Position: 5
=======
Position: 4
>>>>>>> 9663a8b96d44b8aea92dad5f252f70db06c934d5
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### -Win32AccountsBySID
{{ Fill Win32AccountsBySID Description }}

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
<<<<<<< HEAD
Position: 4
=======
Position: 3
>>>>>>> 9663a8b96d44b8aea92dad5f252f70db06c934d5
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. Pipeline input is not accepted.
## OUTPUTS

### [PSCustomObject] with UnresolvedIdentityReference and SIDString properties (each strings)
## NOTES

## RELATED LINKS
