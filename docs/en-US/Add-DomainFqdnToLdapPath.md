---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Add-DomainFqdnToLdapPath

## SYNOPSIS
Add a domain FQDN to an LDAP directory path as the server address so the new path can be used for remote queries

## SYNTAX

```
Add-DomainFqdnToLdapPath [[-DirectoryPath] <String[]>] [[-ThisHostName] <String>] [[-ThisFqdn] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Uses RegEx to:
    - Match the Domain Components from the Distinguished Name in the LDAP directory path
    - Convert the Domain Components to an FQDN
    - Insert them into the directory path as the server address

## EXAMPLES

### EXAMPLE 1
```
Add-DomainFqdnToLdapPath -DirectoryPath 'LDAP://CN=user1,OU=UsersOU,DC=ad,DC=contoso,DC=com'
LDAP://ad.contoso.com/CN=user1,OU=UsersOU,DC=ad,DC=contoso,DC=com
```

Add the domain FQDN to a single LDAP directory path

## PARAMETERS

### -DirectoryPath
Incomplete LDAP directory path containing a distinguishedName but lacking a server address

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

### -ThisFqdn
FQDN of the computer running this function.

Can be provided as a string to avoid calls to HOSTNAME.EXE and \[System.Net.Dns\]::GetHostByName()

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
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
Position: 2
Default value: (HOSTNAME.EXE)
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [System.String]$DirectoryPath
## OUTPUTS

### [System.String] Complete LDAP directory path including server address
## NOTES

## RELATED LINKS
