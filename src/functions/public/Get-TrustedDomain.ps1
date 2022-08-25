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
        Get-TrustedDomain

        Get the trusted domains of the current computer
        .NOTES
    #>
    [OutputType([PSCustomObject])]
    param (
        $ThisHostname = (HOSTNAME.EXE)
    )
    # Redirect the error stream to null, errors are expected on non-domain-joined systems
    Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-TrustedDomain`t$('& nltest /domain_trusts 2> $null')"
    $nltestresults = & nltest /domain_trusts 2> $null
    $NlTestRegEx = '[\d]*: .*'
    $TrustRelationships = $nltestresults -match $NlTestRegEx

    $RegExForEachTrust = '(?<index>[\d]*): (?<netbios>\S*) (?<dns>\S*).*'
    foreach ($TrustRelationship in $TrustRelationships) {
        if ($TrustRelationship -match $RegExForEachTrust) {
            [PSCustomObject]@{
                DomainFqdn    = $Matches.dns
                DomainNetbios = $Matches.netbios
            }
        } else {
            continue
        }
    }
}
