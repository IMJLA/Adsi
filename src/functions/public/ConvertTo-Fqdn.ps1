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
    ConvertTo-Fqdn -DistinguishedName 'DC=ad,DC=contoso,DC=com' -Cache $Cache

    Converts the domain distinguishedName 'DC=ad,DC=contoso,DC=com' to its FQDN format 'ad.contoso.com'.
    This is essential when working with LDAP directory paths that need to be converted to readable domain
    names or when constructing proper LDAP paths that require the FQDN of the domain for remote connections.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertTo-Fqdn')]

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

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache


    )




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

                #Write-LogMsg -Text " # Domain NetBIOS cache miss for '$ThisNetBios' -Cache `$Cache" -Cache $Cache
                $DomainObject = Get-AdsiServer -Netbios $ThisNetBios -Cache $Cache

            }

            $DomainObject.Dns

        }

    }

}
