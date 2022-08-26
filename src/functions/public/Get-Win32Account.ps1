function Get-Win32Account {
    <#
        .SYNOPSIS
        Use CIM to get well-known SIDs
        .DESCRIPTION
        Use WinRM to query the CIM namespace root/cimv2 for instances of the Win32_Account class
        .INPUTS
        [System.String]$ComputerName
        .OUTPUTS
        [Microsoft.Management.Infrastructure.CimInstance] for each instance of the Win32_Account class in the root/cimv2 namespace
        .EXAMPLE
        Get-Win32Account

        Get the well-known SIDs on the current computer
        .EXAMPLE
        Get-Win32Account -CimServerName 'server123'

        Get the well-known SIDs on the remote computer 'server123'
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param (

        # Name or address of the computer whose Win32_Account instances to return
        [Parameter(ValueFromPipeline)]
        [string[]]$ComputerName,

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
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
        AdsiProvider (WinNT or LDAP) of the servers associated with the provided FQDNs or NetBIOS names

        This parameter can be used to reduce calls to Find-AdsiProvider

        Useful when that has been done already but the DomainsByFqdn and DomainsByNetbios caches have not been updated yet
        #>
        [string]$AdsiProvider,

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages

    )
    begin {

        $LogParams = @{
            ThisHostname = $ThisHostname
            Type         = 'Debug'
            LogMsgCache  = $LogMsgCache
            WhoAmI       = $WhoAmI
        }

        $LoggingParams = @{
            ThisHostname = $ThisHostname
            LogMsgCache  = $LogMsgCache
            WhoAmI       = $WhoAmI
        }

        $AdsiServersWhoseWin32AccountsExistInCache = $Win32AccountsBySID.Keys |
        ForEach-Object { ($_ -split '\\')[0] } |
        Sort-Object -Unique
    }
    process {
        ForEach ($ThisServer in $ComputerName) {
            if (
                $ThisServer -eq 'localhost' -or
                $ThisServer -eq '127.0.0.1' -or
                [string]::IsNullOrEmpty($ThisServer)
            ) {
                $ThisServer = $ThisHostName
            }
            if (-not $PSBoundParameters.ContainsKey('AdsiProvider')) {
                $AdsiProvider = Find-AdsiProvider -AdsiServer $ThisServer @LoggingParams
            }
            # Return matching objects from the cache if possible rather than performing a CIM query
            # The cache is based on the Caption of the Win32 accounts which conatins only NetBios names
            if ($AdsiServersWhoseWin32AccountsExistInCache -contains $ThisServer) {
                $Win32AccountsBySID.Keys |
                ForEach-Object {
                    if ($_ -like "$ThisServer\*") {
                        $Win32AccountsBySID[$_]
                    }
                }
            } else {

                if ($ThisServer -eq $ThisHostName) {
                    Write-LogMsg @LogParams -Text "`$CimSession = New-CimSession # For '$ThisServer'"
                    $CimSession = New-CimSession
                    Write-LogMsg @LogParams -Text "Get-CimInstance -ClassName Win32_Account -CimSession `$CimSession # For '$ThisServer'"
                } else {
                    Write-LogMsg @LogParams -Text "`$CimSession = New-CimSession -ComputerName '$ThisServer' # For '$ThisServer'"
                    $CimSession = New-CimSession -ComputerName $ThisServer
                    Write-LogMsg @LogParams -Text "Get-CimInstance -ClassName Win32_Account -CimSession `$CimSession # For '$ThisServer'"
                }

                $Win32_Accounts = Get-CimInstance -ClassName Win32_Account -CimSession $CimSession
                $Win32_Accounts

                Remove-CimSession -CimSession $CimSession

            }
        }
    }
}
