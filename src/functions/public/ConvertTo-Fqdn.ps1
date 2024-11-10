function ConvertTo-Fqdn {

    <#
        .SYNOPSIS
        Convert a domain distinguishedName name or NetBIOS name to its FQDN
        .DESCRIPTION
        For the DistinguishedName parameter, uses PowerShell's -replace operator to perform the conversion
        For the NetBIOS parameter, uses ConvertTo-DistinguishedName to convert from NetBIOS to distinguishedName, then recursively calls this function to get the FQDN
        .INPUTS
        [System.String]$DistinguishedName
        .OUTPUTS
        [System.String] FQDN version of the distinguishedName
        .EXAMPLE
        ConvertTo-Fqdn -DistinguishedName 'DC=ad,DC=contoso,DC=com'
        ad.contoso.com

        Convert the domain distinguishedName 'DC=ad,DC=contoso,DC=com' to its FQDN format 'ad.contoso.com'
    #>

    [OutputType([System.String])]

    param (

        # distinguishedName of the domain
        [Parameter(
            ParameterSetName = 'DistinguishedName',
            ValueFromPipeline
        )]
        [string[]]$DistinguishedName,

        # NetBIOS name of the domain
        [Parameter(
            ParameterSetName = 'NetBIOS',
            ValueFromPipeline
        )]
        [string[]]$NetBIOS,

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    begin {

        #$Log = @{ ThisHostname = $ThisHostname ; Type = $DebugOutputStream ; Buffer = $Cache.Value['LogBuffer'] ; WhoAmI = $WhoAmI }
        $LogThis = @{ ThisHostname = $ThisHostname ; Cache = $Cache ; WhoAmI = $WhoAmI ; DebugOutputStream = $DebugOutputStream }
        $AddOrUpdateScriptblock = { param($key, $val) $val }

    }

    process {

        ForEach ($DN in $DistinguishedName) {
            $DN.Replace( ',DC=', '.' ).Replace( 'DC=', '' )
        }

        $DomainsByNetbios = $Cache.Value['DomainByNetbios']

        ForEach ($ThisNetBios in $NetBIOS) {

            $DomainObject = $null
            $TryGetValueResult = $DomainsByNetbios.Value.TryGetValue($ThisNetBios, [ref]$DomainObject)

            if (
                -not $TryGetValueResult -and
                -not [string]::IsNullOrEmpty($ThisNetBios)
            ) {

                #Write-LogMsg @Log -Text " # Domain NetBIOS cache miss for '$ThisNetBios'"
                $DomainObject = Get-AdsiServer -Netbios $ThisNetBios -ThisFqdn $ThisFqdn @LogThis
                $null = $DomainsByNetbios.Value.AddOrUpdate( $ThisNetBios, $DomainObject, $AddOrUpdateScriptblock ) #doesn't get-adsiserver already update the cache?

            }

            $DomainObject.Dns

        }

    }

}
