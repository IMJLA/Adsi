function Get-AdsiServer {
    <#
        .SYNOPSIS
        Get information about a directory server including the ADSI provider it hosts and its well-known SIDs
        .DESCRIPTION
        Uses the ADSI provider to query the server using LDAP first, then WinNT upon failure
        Uses WinRM to query the CIM class Win32_SystemAccount for well-known SIDs
        .INPUTS
        [System.String]$AdsiServer
        .OUTPUTS
        [PSCustomObject] with AdsiProvider and WellKnownSIDs properties
        .EXAMPLE
        Get-AdsiServer -AdsiServer localhost

        Find the ADSI provider of the local computer
        .EXAMPLE
        Get-AdsiServer -AdsiServer 'ad.contoso.com'

        Find the ADSI provider of the AD domain 'ad.contoso.com'
    #>
    [OutputType([System.String])]

    param (

        # IP address or hostname of the directory server whose ADSI provider type to determine
        [Parameter(ValueFromPipeline)]
        [string[]]$AdsiServer,

        # Cache of known Win32_Account instances keyed by domain and SID
        [hashtable]$Win32AccountsBySID = ([hashtable]::Synchronized(@{})),

        # Cache of known Win32_Account instances keyed by domain (e.g. CONTOSO) and Caption (NTAccount name e.g. CONTOSO\User1)
        [hashtable]$Win32AccountsByCaption = ([hashtable]::Synchronized(@{})),

        # Cache of known directory servers to reduce duplicate queries
        [hashtable]$AdsiServersByDns = [hashtable]::Synchronized(@{}),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{}))

    )
    process {
        ForEach ($ThisServer in $AdsiServer) {
            if (-not $AdsiServersByDns[$ThisServer]) {
                $AdsiProvider = $null
                $AdsiProvider = Find-AdsiProvider -AdsiServer $ThisServer
                # Attempt to use CIM to populate the account caches with known instances of the Win32_Account class on $ThisServer
                # Note: CIM is not expected to be reachable on domain controllers or other scenarios
                # Because this does not interfere with returning the ADSI Server's PSCustomObject with the AdsiProvider, -ErrorAction SilentlyContinue was used
                $null = Get-WellKnownSid -CimServerName $ThisServer -Win32AccountsBySID $Win32AccountsBySID -AdsiServersByDns $AdsiServersByDns -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetBios -DomainsBySid $DomainsBySid -ErrorAction SilentlyContinue |
                ForEach-Object {
                    $Win32AccountsBySID["$($_.Domain)\$($_.SID)"] = $_
                    $Win32AccountsByCaption["$($_.Domain)\$($_.Caption)"] = $_
                }
                $AdsiServersByDns[$ThisServer] = [pscustomobject]@{
                    AdsiProvider = $AdsiProvider
                    ServerName   = $ThisServer
                }
            }
            $AdsiServersByDns[$ThisServer]
        }
    }
}
