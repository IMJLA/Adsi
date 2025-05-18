function Find-LocalAdsiServerSid {
    <#
    .SYNOPSIS
        Finds the SID prefix of the local server by querying the built-in administrator account.
    .DESCRIPTION
        This function queries the local computer or a remote computer via CIM to find the SID
        of the built-in administrator account (RID 500), then extracts and returns the server's
        SID prefix by removing the RID portion. This is useful for identifying the server's
        unique domain identifier in Active Directory environments.
    #>

    [OutputType([System.String])]

    param (

        # Name of the computer to query via CIM
        [string]$ComputerName = (HOSTNAME.EXE),

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $CimParams = @{
        Cache        = $Cache
        ComputerName = $ComputerName
        Query        = "SELECT SID FROM Win32_UserAccount WHERE LocalAccount = 'True' AND SID LIKE 'S-1-5-21-%-500'"
        KeyProperty  = 'SID'
    }

    Write-LogMsg -Text 'Get-CachedCimInstance' -Expand $CimParams -ExpansionMap $Cache.Value['LogCacheMap'].Value -Cache $Cache
    $LocalAdminAccount = Get-CachedCimInstance @CimParams

    if (-not $LocalAdminAccount) {
        return
    }

    return $LocalAdminAccount.SID.Substring(0, $LocalAdminAccount.SID.LastIndexOf('-'))

}
