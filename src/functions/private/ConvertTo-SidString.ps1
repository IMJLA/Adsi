function ConvertTo-SidString {

    param ($ServerNetBIOS, $Name, $Log, $DebugOutputStream)

    # Try to resolve the account against the server the Access Control Entry came from (which may or may not be the directory server for the account)
    Write-LogMsg @Log -Text "[System.Security.Principal.NTAccount]::new('$ServerNetBIOS', '$Name').Translate([System.Security.Principal.SecurityIdentifier])"
    $NTAccount = [System.Security.Principal.NTAccount]::new($ServerNetBIOS, $Name)

    try {
        & { $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]) } 2>$null
    } catch {

        $Log['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
        Write-LogMsg @Log -Text " # '$ServerNetBIOS\$Name' could not be translated from NTAccount to SID: $($_.Exception.Message)"
        $Log['Type'] = $DebugOutputStream

    }

}
