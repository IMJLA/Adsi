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
        [hashtable]$Win32AccountsBySID = ([hashtable]::Synchronized(@{}))

    )
    begin {
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
                $ThisServer = hostname
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

                if ($ThisServer -eq (hostname)) {
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-Win32Account`t`$CimSession = New-CimSession # For '$ThisServer'"
                    $CimSession = New-CimSession
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-Win32Account`tGet-CimInstance -ClassName Win32_Account -CimSession `$CimSession # For '$ThisServer'"
                } else {
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-Win32Account`t`$CimSession = New-CimSession -ComputerName '$ThisServer' # For '$ThisServer'"
                    $CimSession = New-CimSession -ComputerName $ThisServer
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-Win32Account`tGet-CimInstance -ClassName Win32_Account -CimSession `$CimSession # For '$ThisServer'"
                }

                Get-CimInstance -ClassName Win32_Account -CimSession $CimSession

                Remove-CimSession -CimSession $CimSession

            }
        }
    }
}
