function Find-AdsiProvider {
    <#
        .SYNOPSIS
        Determine whether a directory server is an LDAP or a WinNT server
        .DESCRIPTION
        Uses CIM to look for open TCP port 389 indicating LDAP, otherwise assumes WinNT.
        If CIM is unavailable, uses the ADSI provider to attempt to query the server using LDAP first, then WinNT second.
        .INPUTS
        [System.String] AdsiServer parameter.
        .OUTPUTS
        [System.String] Possible return values are:
            None
            LDAP
            WinNT
        .EXAMPLE
        Find-AdsiProvider -AdsiServer localhost

        Find the ADSI provider of the local computer
        .EXAMPLE
        Find-AdsiProvider -AdsiServer 'ad.contoso.com'

        Find the ADSI provider of the AD domain 'ad.contoso.com'
    #>
    [OutputType([System.String])]

    param (

        # IP address or hostname of the directory server whose ADSI provider type to determine
        [string]$AdsiServer,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    ###$Log = @{
    ###    ThisHostname = $ThisHostname
    ###    Type         = $DebugOutputStream
    ###    Buffer       = $Cache.Value['LogBuffer']
    ###    WhoAmI       = $WhoAmI
    ###}

    $CommandParameters = @{
        Cache        = $Cache
        ComputerName = $AdsiServer
        ErrorAction  = 'Ignore'
        KeyProperty  = 'LocalPort'
        Namespace    = 'ROOT/StandardCimv2'
        Query        = 'Select * From MSFT_NetTCPConnection Where LocalPort = 389'
    }

    ###Write-LogMsg @Log -Text 'Get-CachedCimInstance' -Expand $CommandParameters

    $CimInstance = Get-CachedCimInstance @CommandParameters

    if ($Cache.Value['CimCache'].Value[$AdsiServer].Value.TryGetValue( 'CimFailure' , [ref]$null )) {
        ###Write-LogMsg @Log -Text " # CIM connection failure # for '$AdsiServer'"
        $TestResult = Test-AdsiProvider -AdsiServer $AdsiServer -ThisHostName $ThisHostName -WhoAmI $WhoAmI -DebugOutputStream $DebugOutputStream -Cache $Cache
        return $TestResult
    }

    if ($CimInstance) {
        return 'LDAP'
    } else {
        return 'WinNT'
    }

}
