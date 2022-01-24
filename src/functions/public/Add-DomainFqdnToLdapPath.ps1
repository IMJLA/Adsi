function Add-DomainFqdnToLdapPath {
    param (
        [Parameter(ValueFromPipeline)]
        [string[]]$DirectoryPath
    )
    begin {
        $PathRegEx = '(?<Path>LDAP:\/\/[^\/]*)'
        $DomainRegEx = '(?i)DC=\w{1,}?\b'
    }
    process {

        ForEach ($ThisPath in $DirectoryPath) {

            if ($ThisPath -match $PathRegEx) {
            
                #$NewPath = $Matches.Path
                
                if ($ThisPath -match $DomainRegEx) {
                    $DomainDN = $null
                    $DomainFqdn = $null
                    $DomainDN = ([regex]::Matches($ThisPath,$DomainRegEx) | ForEach-Object {$_.Value}) -join ','
                    $DomainFqdn = $DomainDN | ConvertTo-Fqdn
                    if ($ThisPath -match "LDAP:\/\/$DomainFqdn\/") {
                        #Write-Debug "Domain FQDN already found in the directory path: $($ThisPath)"
                        $FQDNPath = $ThisPath
                    }
                    else {
                        $FQDNPath = $ThisPath -replace 'LDAP:\/\/',"LDAP://$DomainFqdn/"
                    }
                }
                else {
                    #Write-Debug "Domain DN not found in the directory path: $($ThisPath)"
                    $FQDNPath = $ThisPath
                }
            }
            else {
                #Write-Debug "Not an expected directory path: $($ThisPath)"
                $FQDNPath = $ThisPath
            }

            Write-Output $FQDNPath
        }
    }
}