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

        [hashtable]$DomainsByNetbios = [hashtable]::Synchronized(@{}),

        [hashtable]$KnownDomains = [hashtable]::Synchronized(@{})
    )
    process {
        ForEach ($DN in $DistinguishedName) {
            $DN -replace ',DC=', '.' -replace 'DC=', ''
        }

        ForEach ($ThisNetBios in $NetBIOS) {
            $DomainDn = $KnownDomains[$DomainNetBIOS]

            if (
                -not $DomainDn -and
                -not [string]::IsNullOrEmpty($DomainNetBIOS)
            ) {
                $KnownDomains[$DomainNetBIOS] = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -DomainsByNetbios $DomainsByNetbios
                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tConvertTo-Fqdn`tCache miss for domain $($DomainNetBIOS).  Adding its Distinguished Name to dictionary of known domains for future lookup"
            }

            $DomainDn = $KnownDomains[$DomainNetBIOS]
            ConvertTo-Fqdn -DistinguishedName $DomainDn
        }
    }
}
