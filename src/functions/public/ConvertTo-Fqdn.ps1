function ConvertTo-Fqdn {
    <#
        .SYNOPSIS
        Convert a domain distinguishedName name to its FQDN
        .DESCRIPTION
        Uses PowerShell's -replace operator to perform the conversion
        .INPUTS
        [System.String] DistinguishedName parameter
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
        [Parameter(ValueFromPipeline)]
        [string[]]$DistinguishedName
    )
    process {
        ForEach ($DN in $DistinguishedName) {
            $DN -replace ',DC=', '.' -replace 'DC=', ''
        }
    }
}
