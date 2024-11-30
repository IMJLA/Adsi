function Find-LocalAdsiServerSid {

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

    Write-LogMsg -Text 'Get-CachedCimInstance' -Expand $CimParams -ExpandKeyMap @{ Cache = '$Cache' } -Cache $Cache
    $LocalAdminAccount = Get-CachedCimInstance @CimParams

    if (-not $LocalAdminAccount) {
        return
    }

    return $LocalAdminAccount.SID.Substring(0, $LocalAdminAccount.SID.LastIndexOf('-'))

}
