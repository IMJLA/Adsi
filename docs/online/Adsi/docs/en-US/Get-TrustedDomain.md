---
external help file: Adsi-help.xml
Module Name: Adsi
online version: https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/11e1608c-6169-4fbc-9c33-373fc9b224f4#Appendix_A_34
schema: 2.0.0
---

# Get-TrustedDomain

## SYNOPSIS
Returns a dictionary of trusted domains by the current computer

## SYNTAX

```powershell
Get-TrustedDomain [-Cache] <PSReference> [<CommonParameters>]
```

## DESCRIPTION
Works only on domain-joined systems
Use nltest to get the domain trust relationships for the domain of the current computer
Use ADSI's LDAP provider to get each trusted domain's DNS name, NETBIOS name, and SID
For each trusted domain the key is the domain's SID, or its NETBIOS name if the -KeyByNetbios switch parameter was used
For each trusted domain the value contains the details retrieved with ADSI

## EXAMPLES

### EXAMPLE 1
```powershell
Get-TrustedDomain -Cache $Cache
```

Retrieves information about all domains trusted by the current domain-joined computer, including each domain's
NetBIOS name, DNS name, and distinguished name.
This information is essential for cross-domain identity resolution
and permission analysis.
The function stores the results in the provided cache to improve performance in
subsequent operations involving these trusted domains.

## PARAMETERS

### -Cache
In-process cache to reduce calls to other processes or to disk

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction- `{ Fill ProgressAction Description )`}

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

### [PSCustomObject] One object per trusted domain, each with a DomainFqdn property and a DomainNetbios property
## NOTES

## RELATED LINKS


