---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Get-DirectoryEntry

## SYNOPSIS
Use Active Directory Service Interfaces to retrieve an object from a directory

## SYNTAX

```powershell
Get-DirectoryEntry [[-DirectoryPath] <String>] [[-Credential] <PSCredential>] [[-PropertiesToLoad] <String[]>]
 [[-SidTypeMap] <Hashtable>] [-Cache] <PSReference> [<CommonParameters>]
```

## DESCRIPTION
Retrieve a directory entry using either the WinNT or LDAP provider for ADSI

## EXAMPLES

### EXAMPLE 1
```powershell
Get-DirectoryEntry
distinguishedName : {DC=ad,DC=contoso,DC=com}
Path : LDAP://DC=ad,DC=contoso,DC=com
```

As the current user on a domain-joined computer, bind to the current domain and retrieve the DirectoryEntry for the root of the domain

### EXAMPLE 2
```powershell
Get-DirectoryEntry
distinguishedName :
Path : WinNT://ComputerName
```

As the current user on a workgroup computer, bind to the local system and retrieve the DirectoryEntry for the root of the directory

## PARAMETERS

### -Cache
In-process cache to reduce calls to other processes or to disk

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: True
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
Credentials to use to bind to the directory
Defaults to the credentials of the current user

```yaml
Type: System.Management.Automation.PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DirectoryPath
Path to the directory object to retrieve
Defaults to the root of the current domain

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: (([System.DirectoryServices.DirectorySearcher]::new()).SearchRoot.Path)
Accept pipeline input: False
Accept wildcard characters: False
```

### -PropertiesToLoad
Properties of the target object to retrieve

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

### -SidTypeMap
Mapping of SID types to descriptions used for converting security identifiers

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: (Get-SidTypeMap)
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. Pipeline input is not accepted.
## OUTPUTS

### [System.DirectoryServices.DirectoryEntry] where possible
### [PSCustomObject] for security principals with no directory entry
## NOTES

## RELATED LINKS

