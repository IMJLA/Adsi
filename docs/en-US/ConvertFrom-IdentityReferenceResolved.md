---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# ConvertFrom-IdentityReferenceResolved

## SYNOPSIS
Use ADSI to collect more information about the IdentityReference in NTFS Access Control Entries

## SYNTAX

```
ConvertFrom-IdentityReferenceResolved [[-IdentityReference] <String>] [-NoGroupMembers]
 [[-DebugOutputStream] <String>] [[-ThisHostName] <String>] [[-ThisFqdn] <String>] [[-WhoAmI] <String>]
 [-Cache] <PSReference> [[-CurrentDomain] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
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
ConvertFrom-IdentityReferenceResolved
```

Incomplete example but it shows the chain of functions to generate the expected input for this

## PARAMETERS

### -Cache
In-process cache to reduce calls to other processes or to disk

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: True
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CurrentDomain
The current domain
Can be passed as a parameter to reduce calls to Get-CurrentDomain

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: (Get-CurrentDomain -Cache $Cache)
Accept pipeline input: False
Accept wildcard characters: False
```

### -DebugOutputStream
Output stream to send the log messages to

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Debug
Accept pipeline input: False
Accept wildcard characters: False
```

### -IdentityReference
The NTFS AccessControlEntry object(s), grouped by their IdentityReference property
TODO: Use System.Security.Principal.NTAccount instead

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

### -ThisFqdn
FQDN of the computer running this function.

Can be provided as a string to avoid calls to HOSTNAME.EXE and \[System.Net.Dns\]::GetHostByName()

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName)
Accept pipeline input: False
Accept wildcard characters: False
```

### -ThisHostName
Hostname of the computer running this function.

Can be provided as a string to avoid calls to HOSTNAME.EXE

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: (HOSTNAME.EXE)
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhoAmI
Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: (whoami.EXE)
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [System.Object]$IdentityReference
## OUTPUTS

### [System.Object] The input object is returned with additional properties added:
###     DirectoryEntry
###     DomainDn
###     DomainNetBIOS
###     ObjectType
###     Members (if the DirectoryEntry is a group).
## NOTES

## RELATED LINKS
