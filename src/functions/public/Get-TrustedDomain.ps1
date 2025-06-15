function Get-TrustedDomain {

    <#
    .SYNOPSIS

    Returns a dictionary of trusted domains by the current computer
    .DESCRIPTION
    Works only on domain-joined systems
    Use nltest to get the domain trust relationships for the domain of the current computer
    Use ADSI's LDAP provider to get each trusted domain's DNS name, NETBIOS name, and SID
    For each trusted domain the key is the domain's SID, or its NETBIOS name if the -KeyByNetbios switch parameter was used
    For each trusted domain the value contains the details retrieved with ADSI
    .INPUTS
    None. Pipeline input is not accepted.
    .OUTPUTS
    [PSCustomObject] One object per trusted domain, each with a DomainFqdn property and a DomainNetbios property

    .EXAMPLE
    Get-TrustedDomain -Cache $Cache

    Retrieves information about all domains trusted by the current domain-joined computer, including each domain's
    NetBIOS name, DNS name, and distinguished name. This information is essential for cross-domain identity resolution
    and permission analysis. The function stores the results in the provided cache to improve performance in
    subsequent operations involving these trusted domains.
    .NOTES
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Get-TrustedDomain')]

    [OutputType([PSCustomObject])]


    param (

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache


    )



    # Errors are expected on non-domain-joined systems
    # Redirecting the error stream to null only suppresses the error in the console; it will still be in the transcript
    # Instead, redirect the error stream to the output stream and filter out the errors by type
    Write-LogMsg -Text "$('& nltest /domain_trusts')" -Cache $Cache
    $nltestresults = & nltest /domain_trusts 2>&1
    $RegExForEachTrust = '(?<index>[\d]*): (?<netbios>\S*) (?<dns>\S*).*'
    $DomainByFqdn = $Cache.Value['DomainByFqdn']
    $DomainByNetbios = $Cache.Value['DomainByNetbios']

    ForEach ($Result in $nltestresults) {

        if ($Result.GetType() -eq [string]) {

            if ($Result -match $RegExForEachTrust) {

                $DN = ConvertTo-DistinguishedName -DomainFQDN $Matches.dns -AdsiProvider 'LDAP' -Cache $Cache

                $OutputObject = [PSCustomObject]@{
                    Netbios           = $Matches.netbios
                    Dns               = $Matches.dns
                    DistinguishedName = $DN
                }

                $DomainByFqdn.Value[$Matches.dns] = $OutputObject
                $DomainByNetbios.Value[$Matches.netbios] = $OutputObject

            }

        }

    }

}
