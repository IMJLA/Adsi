---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Get-TrustedDomainSidNameMap

## SYNOPSIS
Returns a dictionary of trusted domains by the current computer

## SYNTAX

```
Get-TrustedDomainSidNameMap [-KeyByNetbios] [[-DirectoryEntryCache] <Hashtable>]
```

## DESCRIPTION
Works only on domain-joined systems
Use nltest to get the domain trust relationships for the domain of the current computer
Use ADSI's LDAP provider to get each trusted domain's DNS name, NETBIOS name, and SID
For each trusted domain the key is the domain's SID, or its NETBIOS name if the -KeyByNetbios switch parameter was used
For each trusted domain the value contains the details retrieved with ADSI

## EXAMPLES

### EXAMPLE 1
```
Get-TrustedDomainSidNameMap
```

Get the trusted domains of the current computer

## PARAMETERS

### -DirectoryEntryCache
Hashtable containing cached directory entries so they don't have to be retrieved from the directory again
Uses a thread-safe hashtable by default

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeyByNetbios
Key the dictionary by the domain NetBIOS names instead of SIDs

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

## INPUTS

### None. Pipeline input is not accepted.
## OUTPUTS

### [System.Collections.Hashtable] The current domain trust relationships
## NOTES

## RELATED LINKS
