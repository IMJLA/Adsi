---
external help file: Adsi-help.xml
Module Name: Adsi
online version: https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/11e1608c-6169-4fbc-9c33-373fc9b224f4#Appendix_A_34
schema: 2.0.0
---

# Get-ParentDomainDnsName

## SYNOPSIS
Gets the DNS name of the parent domain for a given computer or domain.

## SYNTAX

```powershell
Get-ParentDomainDnsName [[-DomainNetbios] <String>] [[-CimSession] <CimSession>] [-RemoveCimSession]
 [-Cache] <PSReference> [<CommonParameters>]
```

## DESCRIPTION
This function retrieves the DNS name of the parent domain for a specified domain
or computer using CIM queries.
For workgroup computers or when no parent domain
is found, it falls back to using the primary DNS suffix from the client's global
DNS settings.
The function uses caching to improve performance during repeated calls.

## EXAMPLES

### EXAMPLE 1
```powershell
$Cache = @{}
Get-ParentDomainDnsName -DomainNetbios "CORPDC01" -Cache ([ref]$Cache)
```

Remark: This example retrieves the parent domain DNS name for a domain controller named "CORPDC01".
The function will first attempt to get the domain information via CIM queries to the specified computer.
Results are stored in the $Cache variable to improve performance if the function is called again
with the same parameters.
For domain controllers, this will typically return the forest root domain name.

## PARAMETERS

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

### -CimSession
Existing CIM session to the computer (to avoid creating redundant CIM sessions)

```yaml
Type: Microsoft.Management.Infrastructure.CimSession
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DomainNetbios
NetBIOS name of the domain whose parent domain DNS to return

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

### -RemoveCimSession
Switch to remove the CIM session when done

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

## OUTPUTS

## NOTES

## RELATED LINKS

