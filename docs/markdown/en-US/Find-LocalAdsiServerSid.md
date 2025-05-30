---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Find-LocalAdsiServerSid

## SYNOPSIS
Finds the SID prefix of the local server by querying the built-in administrator account.

## SYNTAX

```powershell
Find-LocalAdsiServerSid [[-ComputerName] <String>] [-Cache] <PSReference> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
This function queries the local computer or a remote computer via CIM to find the SID
of the built-in administrator account (RID 500), then extracts and returns the server's
SID prefix by removing the RID portion.
This is useful for identifying the server's
unique domain identifier in Active Directory environments.

## EXAMPLES

### EXAMPLE 1
```powershell
Find-LocalAdsiServerSid -ComputerName "DC01" -Cache $Cache
```

Retrieves the SID prefix for the computer "DC01" by querying the built-in Administrator
account and removing the RID portion.
This domain SID prefix can be used to identify
the domain and construct SIDs for domain users and groups.

## PARAMETERS

### -Cache
In-process cache to reduce calls to other processes or to disk

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
Name of the computer to query via CIM

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: (HOSTNAME.EXE)
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. Pipeline input is not accepted.
## OUTPUTS

### System.String
### Returns the SID prefix of the specified computer or local computer.
## NOTES

## RELATED LINKS

