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

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Test-AdsiProvider')]
    [OutputType([System.String])]

    param (

        # IP address or hostname of the directory server whose ADSI provider type to determine
        [string]$AdsiServer,

        # In-process cache to reduce calls to other processes or to disk

        [Parameter(Mandatory)]
        [ref]$Cache



    )





    $Log = @{ 'Cache' = $Cache }
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
