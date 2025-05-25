---
external help file: Adsi-help.xml
Module Name: Adsi
online version: https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/11e1608c-6169-4fbc-9c33-373fc9b224f4#Appendix_A_34
schema: 2.0.0
---

# New-FakeDirectoryEntry

## SYNOPSIS
Creates a fake DirectoryEntry object for security principals that don't have objects in the directory.

## SYNTAX

```powershell
New-FakeDirectoryEntry [[-DirectoryPath] <String>] [[-SID] <String>] [[-Description] <String>]
 [[-SchemaClassName] <String>] [[-InputObject] <Object>] [[-NameAllowList] <Hashtable>]
 [[-NameBlockList] <Hashtable>] [[-Name] <String>] [[-NTAccount] <String>]
```

## DESCRIPTION
Used in place of a DirectoryEntry for certain WinNT security principals that do not have objects in the directory.
The WinNT provider only throws an error if you try to retrieve certain accounts/identities.
This function creates a PSCustomObject that mimics a DirectoryEntry with the necessary properties.

## EXAMPLES

### EXAMPLE 1
```powershell
New-FakeDirectoryEntry -DirectoryPath "WinNT://BUILTIN/Everyone" -SID "S-1-1-0"
```

Creates a fake DirectoryEntry object for the well-known "Everyone" security principal with the SID "S-1-1-0",
which can be used for permission analysis when a real DirectoryEntry object cannot be retrieved.

## PARAMETERS

### -Description
Description of the security principal

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DirectoryPath
Full directory path for the fake entry in the format "Provider://Domain/Name"

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

### -InputObject
Optional input object containing additional properties to include in the fake directory entry

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Unused but here for convenient splats

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NameAllowList
Account names known to be impossible to resolve to a Directory Entry (currently based on testing on a non-domain-joined PC)

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: @{ 'ALL APPLICATION PACKAGES' = $null ; 'ALL RESTRICTED APPLICATION PACKAGES' = $null ; 'ANONYMOUS LOGON' = $null ; 'Authenticated Users' = $null ; 'BATCH' = $null ; 'BUILTIN' = $null ; 'CREATOR GROUP' = $null ; 'CREATOR GROUP SERVER' = $null ; 'CREATOR OWNER' = $null ; 'CREATOR OWNER SERVER' = $null ; 'DIALUP' = $null ; 'ENTERPRISE DOMAIN CONTROLLERS' = $null ; 'Everyone' = $null ; 'INTERACTIVE' = $null ; 'internetExplorer' = $null ; 'IUSR' = $null ; 'LOCAL' = $null ; 'LOCAL SERVICE' = $null ; 'NETWORK' = $null ; 'NETWORK SERVICE' = $null ; 'OWNER RIGHTS' = $null ; 'PROXY' = $null ; 'RDS Endpoint Servers' = $null ; 'RDS Management Servers' = $null ; 'RDS Remote Access Servers' = $null ; 'REMOTE INTERACTIVE LOGON' = $null ; 'RESTRICTED' = $null ; 'SELF' = $null ; 'SERVICE' = $null ; 'SYSTEM' = $null ; 'TERMINAL SERVER USER' = $null }
Accept pipeline input: False
Accept wildcard characters: False
```

### -NameBlockList
These are retrievable via the WinNT ADSI Provider which enables group member retrival so we don't want to return fake directory entries

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: @{ 'Access Control Assistance Operators' = $null ; 'Administrators' = $null ; 'Backup Operators' = $null ; 'Cryptographic Operators' = $null ; 'DefaultAccount' = $null ; 'Distributed COM Users' = $null ; 'Event Log Readers' = $null ; 'Guests' = $null ; 'Hyper-V Administrators' = $null ; 'IIS_IUSRS' = $null ; 'Network Configuration Operators' = $null ; 'Performance Log Users' = $null ; 'Performance Monitor Users' = $null ; 'Power Users' = $null ; 'Remote Desktop Users' = $null ; 'Remote Management Users' = $null ; 'Replicator' = $null ; 'System Managed Accounts Group' = $null ; 'Users' = $null ; 'WinRMRemoteWMIUsers__' = $null }
Accept pipeline input: False
Accept wildcard characters: False
```

### -NTAccount
Unused but here for convenient splats

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SchemaClassName
Schema class name (e.g., 'user', 'group', 'computer')

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SID
Security Identifier (SID) string for the fake entry

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### None. Pipeline input is not accepted.
## OUTPUTS

### PSCustomObject. A custom object that mimics a DirectoryEntry with properties such as Name, Description,
### SchemaClassName, and objectSid.
## NOTES

## RELATED LINKS

