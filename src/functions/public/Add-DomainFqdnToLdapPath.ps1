function Add-DomainFqdnToLdapPath {

    <#
    .SYNOPSIS
    Add a domain FQDN to an LDAP directory path as the server address so the new path can be used for remote queries
    .DESCRIPTION
    Uses RegEx to:
        - Match the Domain Components from the Distinguished Name in the LDAP directory path
        - Convert the Domain Components to an FQDN
        - Insert them into the directory path as the server address
    .INPUTS
    [System.String]$DirectoryPath
    .OUTPUTS
    [System.String] Complete LDAP directory path including server address
    .EXAMPLE
    Add-DomainFqdnToLdapPath -DirectoryPath 'LDAP://CN=user1,OU=UsersOU,DC=ad,DC=contoso,DC=com'
    LDAP://ad.contoso.com/CN=user1,OU=UsersOU,DC=ad,DC=contoso,DC=com

    Add the domain FQDN to a single LDAP directory path
    #>

    [OutputType([System.String])]

    param (

        # Incomplete LDAP directory path containing a distinguishedName but lacking a server address
        [Parameter(ValueFromPipeline)]
        [string[]]$DirectoryPath,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    begin {
        $DomainRegEx = '(?i)DC=\w{1,}?\b'
    }

    process {

        ForEach ($ThisPath in $DirectoryPath) {

            if ($ThisPath.Substring(0, 7) -eq 'LDAP://') {

                $RegExMatches = $null
                $RegExMatches = [regex]::Matches($ThisPath, $DomainRegEx)

                if ($RegExMatches) {

                    $DomainDN = $null
                    $DomainFqdn = $null
                    $RegExMatches = ForEach ($Match in $RegExMatches) { $Match.Value }
                    $DomainDN = $RegExMatches -join ','
                    $DomainFqdn = ConvertTo-Fqdn -DistinguishedName $DomainDN -Cache $Cache
                    $DomainLdapPath = "LDAP://$DomainFqdn/"

                    if ($ThisPath.Substring(0, $DomainLdapPath.Length) -eq $DomainLdapPath) {

                        #Write-LogMsg -Text " # Domain FQDN already found in the directory path: '$ThisPath'" -Cache $Cache
                        $ThisPath

                    } else {
                        $ThisPath.Replace( 'LDAP://', $DomainLdapPath )
                    }
                } else {

                    #Write-LogMsg -Text " # Domain DN not found in the directory path: '$ThisPath'" -Cache $Cache
                    $ThisPath

                }

            } else {

                #Write-LogMsg -Text " # Not an expected directory path: '$ThisPath'" -Cache $Cache
                $ThisPath

            }

        }

    }

}
