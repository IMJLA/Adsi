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
Add-DomainFqdnToLdapPath [[-DirectoryPath] <String[]>] [-Cache] <PSReference>
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Uses RegEx to:
 - Match the Domain Components from the Distinguished Name in the LDAP directory path
 - Convert the Domain Components to an FQDN
 - Insert them into the directory path as the server address

## EXAMPLES

### EXAMPLE 1
```
Add-DomainFqdnToLdapPath -DirectoryPath 'LDAP://CN=user1,OU=UsersOU,DC=ad,DC=contoso,DC=com' -Cache $Cache
```

Completes the partial LDAP path 'LDAP://CN=user1,OU=UsersOU,DC=ad,DC=contoso,DC=com' to
'LDAP://ad.contoso.com/CN=user1,OU=UsersOU,DC=ad,DC=contoso,DC=com' with the domain FQDN added as the
server address.
This is crucial for making remote LDAP queries to specific domain controllers, especially
when working in multi-domain environments or when connecting to trusted domains.

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

### [System.String]$DirectoryPath
## OUTPUTS

### [System.String] Complete LDAP directory path including server address
## NOTES

## RELATED LINKS

