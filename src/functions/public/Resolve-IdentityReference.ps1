function Resolve-IdentityReference {
    <#
        .SYNOPSIS
        Use ADSI to lookup info about IdentityReferences from Access Control Entries that came from Discretionary Access Control Lists
        .DESCRIPTION
        Based on the IdentityReference proprety of each Access Control Entry:
        Resolve SID to NT account name and vise-versa
        Resolve well-known SIDs
        Resolve generic defaults like 'NT AUTHORITY' and 'BUILTIN' to the applicable computer or domain name
        .INPUTS
        None. Pipeline input is not accepted.
        .OUTPUTS
        [PSCustomObject] with UnresolvedIdentityReference and SIDString properties (each strings)
        .EXAMPLE
        Resolve-IdentityReference -IdentityReference 'BUILTIN\Administrator' -ServerName 'localhost' -AdsiServer (Get-AdsiServer 'localhost')

        Get information about the local Administrator account
    #>
    [OutputType([PSCustomObject])]
    param (
        # IdentityReference from an Access Control Entry
        # Expecting either a SID (S-1-5-18) or an NT account name (CONTOSO\User)
        [string]$IdentityReference,

        # Name of the directory server to use to resolve the IdentityReference
        [string]$ServerName,

        # Object from Get-AdsiServer representing the directory server and its attributes
        [PSObject]$AdsiServer
    )

    if ($IdentityReference -match '^S-1-') {
        # The IdentityReference is a SID
        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tResolve-IdentityReference`t[System.Security.Principal.SecurityIdentifier]::new('$IdentityReference')"
        $SecurityIdentifier = [System.Security.Principal.SecurityIdentifier]::new($IdentityReference)

        # This .Net method makes it impossible to redirect the error stream directly
        # Wrapping it in a scriptblock (which is then executed with &) fixes the problem
        # I don't understand exactly why
        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tResolve-IdentityReference`t[System.Security.Principal.SecurityIdentifier]::new('$IdentityReference').Translate([System.Security.Principal.NTAccount])"
        $UnresolvedIdentityReference = & { $SecurityIdentifier.Translate([System.Security.Principal.NTAccount]).Value } 2>$null
        $SIDString = $IdentityReference
    } else {
        # The IdentityReference is an NTAccount
        $UnresolvedIdentityReference = $IdentityReference

        # Resolve NTAccount to SID
        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tResolve-IdentityReference`t[System.Security.Principal.NTAccount]::new('$ServerName','$IdentityReference')"
        $NTAccount = [System.Security.Principal.NTAccount]::new($ServerName, $IdentityReference)
        $SIDString = $null
        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tResolve-IdentityReference`t[System.Security.Principal.NTAccount]::new('$ServerName','$IdentityReference').Translate([System.Security.Principal.SecurityIdentifier])"
        $SIDString = & { $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]) } 2>$null
        if (!($SIDString)) {
            # Well-Known SIDs cannot be translated with the Translate method so instead we will use CIM
            $SIDString = ($AdsiServer.WellKnownSIDs |
                Where-Object -FilterScript {
                    $UnresolvedIdentityReference -like "*\$($_.Name)"
                }
            ).SID

            if (!($SIDString)) {
                # Some built-in groups such as BUILTIN\Users and BUILTIN\Administrators are not in the CIM class or translatable with the Translate method
                # But they have real DirectoryEntry objects
                $DirectoryPath = "$($AdsiServer.AdsiProvider)`://$ServerName/$(($UnresolvedIdentityReference -split '\\') | Select-Object -Last 1)"
                $SIDString = (Get-DirectoryEntry -DirectoryPath $DirectoryPath |
                    Add-SidInfo).SidString
            }
        }
    }

    [PSCustomObject]@{
        UnresolvedIdentityReference = $UnresolvedIdentityReference
        SIDString                   = $SIDString
    }

}
