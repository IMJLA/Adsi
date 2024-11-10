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
                    $DomainFqdn = ConvertTo-Fqdn -DistinguishedName $DomainDN -ThisFqdn $ThisFqdn @LogThis
                    $DomainLdapPath = "LDAP://$DomainFqdn/"

                    if ($ThisPath.Substring(0, $DomainLdapPath.Length) -eq $DomainLdapPath) {

                        #Write-LogMsg @Log -Text " # Domain FQDN already found in the directory path: '$ThisPath'"
                        $ThisPath

                    } else {
                        $ThisPath.Replace( 'LDAP://', $DomainLdapPath )
                    }
                } else {

                    #Write-LogMsg @Log -Text " # Domain DN not found in the directory path: '$ThisPath'"
                    $ThisPath

                }

            } else {

                #Write-LogMsg @Log -Text " # Not an expected directory path: '$ThisPath'"
                $ThisPath

            }

        }

    }

}
