function Get-TrustedDomainSidNameMap {
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
        [System.Collections.Hashtable] The current domain trust relationships

        .EXAMPLE
        Get-TrustedDomainSidNameMap

        Get the trusted domains of the current computer
    #>
    [OutputType([System.Collections.Hashtable])]
    param (

        # Key the dictionary by the domain NetBIOS names instead of SIDs
        [Switch]$KeyByNetbios,

        <#
        Hashtable containing cached directory entries so they don't have to be retrieved from the directory again
        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{}))

    )

    $Map = @{}

    # Redirect the error stream to null
    $nltestresults = & nltest /domain_trusts 2> $null
    $NlTestRegEx = '[\d]*: .*'
    $TrustRelationships = $nltestresults -match $NlTestRegEx

    foreach ($TrustRelationship in $TrustRelationships) {

        $RegEx = '(?<index>[\d]*): (?<netbios>\S*) (?<dns>\S*).*'
        if ($TrustRelationship -match $RegEx) {
            $DomainDnsName = $Matches.dns
            $DomainNetbios = $Matches.netbios
        }

        $DomainDirectoryEntry = Get-DirectoryEntry -DirectoryPath "LDAP://$DomainDnsName" -DirectoryEntryCache $DirectoryEntryCache

        $DistinguishedName = ConvertTo-DistinguishedName -Domain $DomainNetbios

        try {
            $DomainDirectoryEntry.RefreshCache({ "objectSid" })
            $DomainSid = [System.Security.Principal.SecurityIdentifier]::new([byte[]]$DomainDirectoryEntry.Properties["objectSid"].Value, 0).ToString()
            if ($KeyByNetbios -eq $true) {
                $Map[$DomainNetbios] = [pscustomobject]@{
                    Dns               = $DomainDnsName
                    Netbios           = $DomainNetbios
                    Sid               = $DomainSid
                    DistinguishedName = $DistinguishedName
                }
            } else {
                $Map[$DomainSid] = [pscustomobject]@{
                    Dns               = $DomainDnsName
                    Netbios           = $DomainNetbios
                    Sid               = $DomainSid
                    DistinguishedName = $DistinguishedName
                }
            }
        } catch {
            Write-Warning "$(Get-Date -Format s)`t$(hostname)`tGet-TrustedDomainSidNameMap`tDomain: '$DomainDnsName' - $($_.Exception.Message)"
        }
    }

    $LocalAccountSID = Get-CimInstance -Query "SELECT SID FROM Win32_UserAccount WHERE LocalAccount = 'True'" |
    Select-Object -First 1 -ExpandProperty SID
    $DomainSid = $LocalAccountSID.Substring(0, $LocalAccountSID.LastIndexOf("-"))
    $DomainNetBios = hostname
    $DomainDnsName = "$DomainNetbios.$((Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters').'NV Domain')"

    $Map[$DomainSid] = [pscustomobject]@{
        Dns     = $DomainDnsName
        Netbios = $DomainNetbios
        Sid     = $DomainSid
    }

    return $Map

}
