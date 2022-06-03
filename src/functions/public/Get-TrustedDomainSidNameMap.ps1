function Get-TrustedDomainSidNameMap {

    param (

        [Switch]$KeyByNetbios,

        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{}))

    )

    $Map = @{}
    
    # Previously I had this as the line below, but it did not capture all output streams so on a workgroup computer I saw:
    # Enumerating domain trusts failed: Status = 1722 0x6ba RPC_S_SERVER_UNAVAILABLE
    # I never figured out what output stream it was but instead just redirected all streams to the variable. Now it comes up null even when I expect that error but whatever.
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

    Write-Output $Map

}
