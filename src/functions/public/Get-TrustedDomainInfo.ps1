function Get-TrustedDomainInfo {
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
        Get-TrustedDomainInfo

        Get the trusted domains of the current computer
        .NOTES
        TODO: Audit usage of this function, have it return objects instead of hashtable, since it updates the threadsafe hashtables instead
    #>
    [OutputType([System.Collections.Hashtable])]
    param (

        # Key the dictionary by the domain NetBIOS names instead of SIDs
        [Switch]$KeyByNetbios,

        # Cache of known directory servers to reduce duplicate queries
        [hashtable]$AdsiServersByDns = [hashtable]::Synchronized(@{}),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{}))

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
        } else {
            continue
        }

        $OutputObject = Get-DomainInfo -DomainDnsName $DomainDnsName -AdsiServersByDns $AdsiServersByDns -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
        $DomainsBySID[$DomainSid] = $OutputObject
        $DomainsByNetbios[$DomainNetbios] = $OutputObject
        $DomainsByFqdn[$DomainDnsName] = $OutputObject
        if ($KeyByNetbios -eq $true) {
            $Map[$DomainNetbios] = $OutputObject
        } else {
            $Map[$DomainSid] = $OutputObject
        }
    }

    # Add the WinNT domain of the local computer as well
    $LocalAccountSID = (Get-CimInstance -Query "SELECT SID FROM Win32_UserAccount WHERE LocalAccount = 'True'").SID[0]
    $DomainSid = $LocalAccountSID.Substring(0, $LocalAccountSID.LastIndexOf("-"))
    $DomainNetBios = hostname
    $DomainDnsName = "$DomainNetbios.$((Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters').'NV Domain')"
    $OutputObject = [pscustomobject]@{
        Dns               = $DomainDnsName
        Netbios           = $DomainNetbios
        Sid               = $DomainSid
        DistinguishedName = $null
    }
    $DomainsBySID[$DomainSid] = $OutputObject
    $DomainsByNetbios[$DomainNetbios] = $OutputObject
    $DomainsByFqdn[$DomainDnsName] = $OutputObject
    if ($KeyByNetbios -eq $true) {
        $Map[$DomainNetbios] = $OutputObject
    } else {
        $Map[$DomainSid] = $OutputObject
    }

    return $Map

}
