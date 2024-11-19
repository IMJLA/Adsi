function Test-AdsiProvider {
    <#
        .SYNOPSIS
        Determine whether a directory server is an LDAP or a WinNT server
        .DESCRIPTION
        Uses the ADSI provider to attempt to query the server using LDAP first, then WinNT second
        .INPUTS
        [System.String] AdsiServer parameter.
        .OUTPUTS
        [System.String] Possible return values are:
            LDAP
            WinNT
        .EXAMPLE
        Test-AdsiProvider -AdsiServer localhost

        Find the ADSI provider of the local computer
        .EXAMPLE
        Test-AdsiProvider -AdsiServer 'ad.contoso.com'

        Find the ADSI provider of the AD domain 'ad.contoso.com'
    #>
    [OutputType([System.String])]

    param (

        # IP address or hostname of the directory server whose ADSI provider type to determine
        [string]$AdsiServer,

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $Log = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        Buffer       = $Cache.Value['LogBuffer']
        WhoAmI       = $WhoAmI
    }

    Pause

    $AdsiPath = "LDAP://$AdsiServer"
    Write-LogMsg @Log -Text "[System.DirectoryServices.DirectoryEntry]::Exists('$AdsiPath') # for '$AdsiServer'"

    try {
        $null = [System.DirectoryServices.DirectoryEntry]::Exists($AdsiPath)
        return 'LDAP'
    } catch { Write-LogMsg @Log -Text " # No response to LDAP # for '$AdsiServer'" }

    $AdsiPath = "WinNT://$AdsiServer"
    Write-LogMsg @Log -Text "[System.DirectoryServices.DirectoryEntry]::Exists('$AdsiPath') # for '$AdsiServer'"

    try {
        $null = [System.DirectoryServices.DirectoryEntry]::Exists($AdsiPath)
        return 'WinNT'
    } catch {
        Write-LogMsg @Log -Text " # No response to WinNT. # for '$AdsiServer'"
    }

}
