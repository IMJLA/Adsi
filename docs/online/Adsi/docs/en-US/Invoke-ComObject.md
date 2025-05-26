---
external help file: Adsi-help.xml
Module Name: Adsi
online version:
schema: 2.0.0
---

# Invoke-ComObject

## SYNOPSIS
Invoke a member method of a ComObject \[__ComObject\]

## SYNTAX

```powershell
Invoke-ComObject [-ComObject] <Object> [-Property] <String> [[-Value] <Object>] [-Method]
 [<CommonParameters>]
```

## DESCRIPTION
Use the InvokeMember method to invoke the InvokeMethod or GetProperty or SetProperty methods
By default, invokes the GetProperty method for the specified Property
If the Value parameter is specified, invokes the SetProperty method for the specified Property
If the Method switch is specified, invokes the InvokeMethod method

## EXAMPLES

### EXAMPLE 1
```powershell
$ComObject = [System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrators').Invoke('Members') | Select -First 1
Invoke-ComObject -ComObject $ComObject -Property AdsPath
```

Get the first member of the local Administrators group on the current computer
Then use Invoke-ComObject to invoke the GetProperty method and return the value of the AdsPath property

## PARAMETERS

### -ComObject
The ComObject whose member method to invoke

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Method
Use the InvokeMethod method of the ComObject

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

### -Property
The property to use with the invoked method

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Value
The value to set with the SetProperty method, or the name of the method to run with the InvokeMethod method

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. Pipeline input is not accepted.
## OUTPUTS

### The output of the invoked method is returned directly
## NOTES

## RELATED LINKS

