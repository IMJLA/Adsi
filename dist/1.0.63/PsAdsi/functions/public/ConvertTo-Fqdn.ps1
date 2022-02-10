function ConvertTo-Fqdn {
    param (
        [Parameter(ValueFromPipeline)]
        [string[]]$DistinguishedName
    )
    process {
        ForEach ($DN in $DistinguishedName) {
            $DN -replace ',DC=', '.' -replace 'DC=', ''
        }
    }
}
