---
external help file: Adsi-help.xml
Module Name: Adsi
online version: https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/11e1608c-6169-4fbc-9c33-373fc9b224f4#Appendix_A_34
schema: 2.0.0
---

# Resolve-IdentityReference

## SYNOPSIS
Use CIM and ADSI to lookup info about IdentityReferences from Access Control Entries that came from Discretionary Access Control Lists

## SYNTAX

```
Resolve-IdentityReference [-IdentityReference] <String> [[-AdsiServer] <PSObject>] [-Cache] <PSReference>
 [[-AccountProperty] <String[]>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
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

Resolves the local Administrator account on the BUILTIN domain to its proper SID, NetBIOS name,
and DNS name format.
This is useful when analyzing permissions to ensure consistency in how identities
are represented, especially when comparing permissions across different systems or domains.

## PARAMETERS

### -AccountProperty
Properties of each Account to display on the report

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: @('DisplayName', 'Company', 'Department', 'Title', 'Description')
Accept pipeline input: False
Accept wildcard characters: False
```

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. Pipeline input is not accepted.
## OUTPUTS

### [PSCustomObject] with IdentityReferenceNetBios,IdentityReferenceDns, and SIDString properties (each strings)
## NOTES

## RELATED LINKS

