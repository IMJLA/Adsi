---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Get-AdsiServer

## SYNOPSIS
Get information about a directory server including the ADSI provider it hosts and its well-known SIDs

## SYNTAX

```powershell
Get-AdsiServer [[-Fqdn] <String[]>] [[-Netbios] <String[]>] [-RemoveCimSession] [-Cache] <PSReference>
 [<CommonParameters>]
```

## DESCRIPTION
Uses the ADSI provider to query the server using LDAP first, then WinNT upon failure
Uses WinRM to query the CIM class Win32_SystemAccount for well-known SIDs

## EXAMPLES

### EXAMPLE 1
```powershell
Get-AdsiServer -Fqdn localhost -Cache $Cache
```

Retrieves information about the local computer's directory service, determining whether it uses
the LDAP or WinNT provider, and collects information about well-known security identifiers (SIDs).
This is essential for consistent identity resolution on the local system when analyzing permissions.

### EXAMPLE 2
```powershell
Get-AdsiServer -Fqdn 'ad.contoso.com' -Cache $Cache
```

Connects to the domain controller for 'ad.contoso.com', determines it uses the LDAP provider,
and retrieves domain-specific information including SIDs, NetBIOS name, and distinguished name.
This enables proper identity resolution for domain accounts when working with permissions across systems.

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

### -Fqdn
IP address or hostname of the directory server whose ADSI provider type to determine

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Netbios
NetBIOS name of the ADSI server whose information to determine

```yaml
Type: System.String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
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

### -RemoveCimSession
Remove the CIM session used to get ADSI server information

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

### [System.String]$Fqdn
## OUTPUTS

### [PSCustomObject] with AdsiProvider and WellKnownSidBySid properties
## NOTES

## RELATED LINKS


