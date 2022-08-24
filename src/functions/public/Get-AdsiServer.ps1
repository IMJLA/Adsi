function Get-AdsiServer {
    <#
        .SYNOPSIS
        Get information about a directory server including the ADSI provider it hosts and its well-known SIDs
        .DESCRIPTION
        Uses the ADSI provider to query the server using LDAP first, then WinNT upon failure
        Uses WinRM to query the CIM class Win32_SystemAccount for well-known SIDs
        .INPUTS
        [System.String]$Fqdn
        .OUTPUTS
        [PSCustomObject] with AdsiProvider and WellKnownSIDs properties
        .EXAMPLE
        Get-AdsiServer -Fqdn localhost

        Find the ADSI provider of the local computer
        .EXAMPLE
        Get-AdsiServer -Fqdn 'ad.contoso.com'

        Find the ADSI provider of the AD domain 'ad.contoso.com'
    #>
    [OutputType([System.String])]

    param (

        # IP address or hostname of the directory server whose ADSI provider type to determine
        [Parameter(ValueFromPipeline)]
        [string[]]$Fqdn,

        # NetBIOS name of the ADSI server whose information to determine
        [string[]]$Netbios,

        # Cache of known Win32_Account instances keyed by domain and SID
        [hashtable]$Win32AccountsBySID = ([hashtable]::Synchronized(@{})),

        # Cache of known Win32_Account instances keyed by domain (e.g. CONTOSO) and Caption (NTAccount name e.g. CONTOSO\User1)
        [hashtable]$Win32AccountsByCaption = ([hashtable]::Synchronized(@{})),

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

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName,AdsiProvider,Win32Accounts properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{}))

    )
    process {
        ForEach ($ThisServer in $Fqdn) {
            $OutputObject = $DomainsByFqdn[$ThisServer]
            #####if (-not $AdsiServersByDns[$ThisServer]) {
            if ($OutputObject) {
                Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`t # Domain FQDN cache hit for '$ThisServer'"
                $OutputObject
                continue
            }
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`t # Domain FQDN cache miss for '$ThisServer'"
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`tConvertTo-DistinguishedName -DomainFQDN '$ThisServer'"
            $DomainDn = ConvertTo-DistinguishedName -DomainFQDN $ThisServer
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`tConvertTo-DomainSidString -DomainDnsName '$ThisServer'"
            $DomainSid = ConvertTo-DomainSidString -DomainDnsName $ThisServer -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`tFind-AdsiProvider -AdsiServer '$ThisServer'"
            $AdsiProvider = Find-AdsiProvider -AdsiServer $ThisServer
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`tConvertTo-DomainNetBIOS -DomainFQDN '$ThisServer'"
            $DomainNetBIOS = ConvertTo-DomainNetBIOS -DomainFQDN $ThisServer -AdsiProvider $AdsiProvider -AdsiServersByDns $AdsiServersByDns -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`tGet-Win32Account -ComputerName '$ThisServer'"
            $Win32Accounts = Get-Win32Account -ComputerName $ThisServer -Win32AccountsBySID $Win32AccountsBySID -AdsiServersByDns $AdsiServersByDns -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetBios -DomainsBySid $DomainsBySid -ErrorAction SilentlyContinue
            <#
            #####$AdsiServersByDns[$ThisServer] = [pscustomobject]@{
            #####    AdsiProvider = $AdsiProvider
            #####    ServerName   = $ThisServer
            #####}

            # Attempt to use CIM to populate the account caches with known instances of the Win32_Account class on $ThisServer
            # Note: CIM is not expected to be reachable on domain controllers or other scenarios
            # Because this does not interfere with returning the ADSI Server's PSCustomObject with the AdsiProvider, -ErrorAction SilentlyContinue was used
            #####$null = Get-WellKnownSid -CimServerName $ThisServer -Win32AccountsBySID $Win32AccountsBySID -AdsiServersByDns $AdsiServersByDns -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetBios -DomainsBySid $DomainsBySid -ErrorAction SilentlyContinue |
            #####$Win32Accounts |
            #####ForEach-Object {
            #####    $Win32AccountsBySID["$($_.Domain)\$($_.SID)"] = $_
            #####    $Win32AccountsByCaption["$($_.Domain)\$($_.Caption)"] = $_
            #####}
            #>
            $OutputObject = [PSCustomObject]@{
                DistinguishedName = $DomainDn
                Dns               = $DomainDnsName
                Sid               = $DomainSid
                Netbios           = $DomainNetBIOS
                AdsiProvider      = $AdsiProvider
                Win32Accounts     = $Win32Accounts
            }
            $DomainsBySid[$OutputObject.Sid] = $OutputObject
            $DomainsByNetbios[$OutputObject.Netbios] = $OutputObject
            $DomainsByFqdn[$OutputObject.Dns] = $OutputObject
            $OutputObject
            #####$AdsiServersByDns[$ThisServer]
        }

        ForEach ($DomainNetbios in $Netbios) {
            $OutputObject = $DomainsByNetbios[$DomainNetbios]
            if ($OutputObject) {
                Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`t # Domain NetBIOS cache hit for '$DomainNetbios'"
                $OutputObject
                continue
            }
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`t # Domain NetBIOS cache hit for '$DomainNetbios'"
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`tConvertTo-DistinguishedName -Domain '$DomainNetBIOS'"
            $DomainDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -DomainsByNetbios $DomainsByNetbios
            if ($DomainDn) {
                Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`tConvertTo-Fqdn -DistinguishedName '$DomainDn'"
                $DomainDnsName = ConvertTo-Fqdn -DistinguishedName $DomainDn
            } else {
                $CimSession = New-CimSession -ComputerName $DomainNetbios
                $ParentDomainDnsName = (Get-CimInstance -CimSession $CimSession -ClassName CIM_ComputerSystem).domain
                if ($ParentDomainDnsName -eq 'WORKGROUP' -or $null -eq $ParentDomainDnsName) {
                    $ParentDomainDnsName = (Get-DnsClientGlobalSetting -CimSession $CimSession).SuffixSearchList[0]
                }
                $DomainDnsName = "$DomainNetBIOS.$ParentDomainDnsName"
            }
            $DomainSid = ConvertTo-DomainSidString -DomainDnsName $DomainDnsName -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`tFind-AdsiProvider -AdsiServer '$ThisServer'"
            $AdsiProvider = Find-AdsiProvider -AdsiServer $ThisServer
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`tGet-Win32Account -ComputerName '$ThisServer'"
            $Win32Accounts = Get-Win32Account -ComputerName $ThisServer -Win32AccountsBySID $Win32AccountsBySID -AdsiServersByDns $AdsiServersByDns -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetBios -DomainsBySid $DomainsBySid -ErrorAction SilentlyContinue

            $OutputObject = [PSCustomObject]@{
                DistinguishedName = $DomainDn
                Dns               = $DomainDnsName
                Sid               = $DomainSid
                Netbios           = $DomainNetBIOS
                AdsiProvider      = $AdsiProvider
                Win32Accounts     = $Win32Accounts
            }
            $DomainsBySid[$OutputObject.Sid] = $OutputObject
            $DomainsByNetbios[$OutputObject.Netbios] = $OutputObject
            $DomainsByFqdn[$OutputObject.Dns] = $OutputObject
            $OutputObject
        }
    }
}
