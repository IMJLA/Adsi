function Get-Win32Account {
    <#
        .SYNOPSIS
        Use CIM to get well-known SIDs
        .DESCRIPTION
        Use WinRM to query the CIM namespace root/cimv2 for instances of the Win32_Account class
        .INPUTS
        [System.String]$CimServerName
        .OUTPUTS
        [Microsoft.Management.Infrastructure.CimInstance] for each instance of the Win32_Account class in the root/cimv2 namespace
        .EXAMPLE
        Get-WellKnownSid

        Get the well-known SIDs on the current computer
        .EXAMPLE
        Get-WellKnownSid -CimServerName 'server123'

        Get the well-known SIDs on the remote computer 'server123'
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param (
        [Parameter(ValueFromPipeline)]
        [string[]]$CimServerName,

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
    begin {
        $AdsiServersWhoseWin32AccountsExistInCache = $Win32AccountsBySID.Keys |
        ForEach-Object { ($_ -split '\\')[0] } |
        Sort-Object -Unique
    }
    process {
        ForEach ($ThisServer in $CimServerName) {
            if ($ThisServer -eq (hostname) -or $ThisServer -eq 'localhost' -or $ThisServer -eq '127.0.0.1' -or [string]::IsNullOrEmpty($ThisServer)) {
                $ThisServer = hostname
            }
            # Return matching objects from the cache if possible rather than performing a CIM query
            # The cache is based on the Caption of the Win32 accounts which conatins only NetBios names
            $AdsiProvider = Find-AdsiProvider -AdsiServer $ThisServer
            $ThisServerNetbios = ConvertTo-DomainNetBIOS -DomainFQDN $ThisServer -AdsiProvider $AdsiProvider -AdsiServersByDns $AdsiServersByDns -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
            if ($AdsiServersWhoseWin32AccountsExistInCache -contains $ThisServer) {
                $Win32AccountsBySID.Keys | ForEach-Object {
                    if ($_ -like "$ThisServer\*") {
                        $Win32AccountsBySID[$_]
                    }
                }
            } else {
                if ($ThisServer -eq (hostname)) {
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-WellKnownSid`t`$CimSession = New-CimSession # For '$ThisServer'"
                    $CimSession = New-CimSession
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-WellKnownSid`tGet-CimInstance -ClassName Win32_Account -CimSession `$CimSession # For '$ThisServer'"
                } else {
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-WellKnownSid`t`$CimSession = New-CimSession -ComputerName '$ThisServer' # For '$ThisServer'"
                    $CimSession = New-CimSession -ComputerName $ThisServer
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-WellKnownSid`tGet-CimInstance -ClassName Win32_Account -CimSession `$CimSession # For '$ThisServer'"
                }

                $Win32_Accounts = Get-CimInstance -ClassName Win32_Account -CimSession $CimSession
                $Win32_Accounts

                Remove-CimSession -CimSession $CimSession
            }
        }
    }
}
