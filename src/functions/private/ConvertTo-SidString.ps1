function ConvertTo-SidString {

    <#
.SYNOPSIS
Converts an NT account name to a SID string.

.DESCRIPTION
Attempts to translate an NT account name (domain\username format) to its corresponding Security Identifier (SID) string.
Uses the .NET Framework's NTAccount and SecurityIdentifier classes for the translation.

.EXAMPLE
ConvertTo-SidString -ServerNetBIOS 'CONTOSO' -Name 'Administrator' -Cache $cacheRef

.INPUTS
System.String

.OUTPUTS
System.Security.Principal.SecurityIdentifier
#>

    param (
        [string]$ServerNetBIOS,
        [string]$Name,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache
    )

    # Try to resolve the account against the server the Access Control Entry came from (which may or may not be the directory server for the account)
    Write-LogMsg -Text "[System.Security.Principal.NTAccount]::new('$ServerNetBIOS', '$Name').Translate([System.Security.Principal.SecurityIdentifier])" -Cache $Cache
    $NTAccount = [System.Security.Principal.NTAccount]::new($ServerNetBIOS, $Name)

    try {
        & { $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]) } 2>$null
    } catch {

        $Log['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
        Write-LogMsg -Text " # '$ServerNetBIOS\$Name' could not be translated from NTAccount to SID: $($_.Exception.Message)" -Cache $Cache

    }

}
