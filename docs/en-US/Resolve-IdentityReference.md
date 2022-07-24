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
Resolve-IdentityReference [[-IdentityReference] <String>] [[-ServerName] <String>] [[-AdsiServer] <PSObject>]
```

## DESCRIPTION
Based on the IdentityReference proprety of each Access Control Entry:
Resolve SID to NT account name and vise-versa
Resolve well-known SIDs
Resolve generic defaults like 'NT AUTHORITY' and 'BUILTIN' to the applicable computer or domain name

## EXAMPLES

### EXAMPLE 1
```
Resolve-IdentityReference -IdentityReference 'BUILTIN\Administrator' -ServerName 'localhost' -AdsiServer (Get-AdsiServer 'localhost')
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
Position: 3
Default value: None
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

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ServerName
Name of the directory server to use to resolve the IdentityReference

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

## INPUTS

### None. Pipeline input is not accepted.
## OUTPUTS

### [PSCustomObject] with UnresolvedIdentityReference and SIDString properties (each strings)
## NOTES

## RELATED LINKS
