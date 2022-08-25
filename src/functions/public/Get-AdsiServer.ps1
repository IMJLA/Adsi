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
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName)

    )
    process {
        ForEach ($DomainFqdn in $Fqdn) {
            $OutputObject = $DomainsByFqdn[$DomainFqdn]
            if ($OutputObject) {
                Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$ThisHostname`t$(whoami)`tGet-AdsiServer`t # Domain FQDN cache hit for '$DomainFqdn'"
                $OutputObject
                continue
            }
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$ThisHostname`t$(whoami)`tGet-AdsiServer`t # Domain FQDN cache miss for '$DomainFqdn'"
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$ThisHostname`t$(whoami)`tGet-AdsiServer`tFind-AdsiProvider -AdsiServer '$DomainFqdn'"
            $AdsiProvider = Find-AdsiProvider -AdsiServer $DomainFqdn
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$ThisHostname`t$(whoami)`tGet-AdsiServer`tConvertTo-DistinguishedName -DomainFQDN '$DomainFqdn' -AdsiProvider '$AdsiProvider'"
            $DomainDn = ConvertTo-DistinguishedName -DomainFQDN $DomainFqdn -AdsiProvider $AdsiProvider
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$ThisHostname`t$(whoami)`tGet-AdsiServer`tConvertTo-DomainSidString -DomainDnsName '$DomainFqdn'"
            $DomainSid = ConvertTo-DomainSidString -DomainDnsName $DomainFqdn -AdsiProvider $AdsiProvider -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisHostName $ThisHostName -ThisFqdn $ThisFqdn
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$ThisHostname`t$(whoami)`tGet-AdsiServer`tConvertTo-DomainNetBIOS -DomainFQDN '$DomainFqdn'"
            $DomainNetBIOS = ConvertTo-DomainNetBIOS -DomainFQDN $DomainFqdn -AdsiProvider $AdsiProvider -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$ThisHostname`t$(whoami)`tGet-AdsiServer`tGet-Win32Account -ComputerName '$DomainFqdn'"
            $Win32Accounts = Get-Win32Account -ComputerName $DomainFqdn -Win32AccountsBySID $Win32AccountsBySID -ErrorAction SilentlyContinue

            $Win32Accounts |
            ForEach-Object {
                $Win32AccountsBySID["$($_.Domain)\$($_.SID)"] = $_
                $Win32AccountsByCaption["$($_.Domain)\$($_.Caption)"] = $_
            }

            $OutputObject = [PSCustomObject]@{
                DistinguishedName = $DomainDn
                Dns               = $DomainFqdn
                Sid               = $DomainSid
                Netbios           = $DomainNetBIOS
                AdsiProvider      = $AdsiProvider
                Win32Accounts     = $Win32Accounts
            }
            $DomainsBySid[$OutputObject.Sid] = $OutputObject
            $DomainsByNetbios[$OutputObject.Netbios] = $OutputObject
            $DomainsByFqdn[$DomainFqdn] = $OutputObject
            $OutputObject
        }

        ForEach ($DomainNetbios in $Netbios) {
            $OutputObject = $DomainsByNetbios[$DomainNetbios]
            if ($OutputObject) {
                Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$ThisHostname`t$(whoami)`tGet-AdsiServer`t # Domain NetBIOS cache hit for '$DomainNetbios'"
                $OutputObject
                continue
            }
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$ThisHostname`t$(whoami)`tGet-AdsiServer`t # Domain NetBIOS cache hit for '$DomainNetbios'"

            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$ThisHostname`t$(whoami)`tGet-AdsiServer`tFind-AdsiProvider -AdsiServer '$DomainDnsName'"
            $AdsiProvider = Find-AdsiProvider -AdsiServer $DomainDnsName

            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$ThisHostname`t$(whoami)`tGet-AdsiServer`tConvertTo-DistinguishedName -Domain '$DomainNetBIOS'"
            $DomainDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -DomainsByNetbios $DomainsByNetbios

            if ($DomainDn) {
                Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$ThisHostname`t$(whoami)`tGet-AdsiServer`tConvertTo-Fqdn -DistinguishedName '$DomainDn'"
                $DomainDnsName = ConvertTo-Fqdn -DistinguishedName $DomainDn -ThisHostName $ThisHostName -ThisFqdn $ThisFqdn
            } else {
                $CimSession = New-CimSession -ComputerName $DomainNetbios
                $ParentDomainDnsName = (Get-CimInstance -CimSession $CimSession -ClassName CIM_ComputerSystem).domain
                if ($ParentDomainDnsName -eq 'WORKGROUP' -or $null -eq $ParentDomainDnsName) {
                    $ParentDomainDnsName = (Get-DnsClientGlobalSetting -CimSession $CimSession).SuffixSearchList[0]
                }
                $DomainDnsName = "$DomainNetBIOS.$ParentDomainDnsName"
            }

            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$ThisHostname`t$(whoami)`tGet-AdsiServer`tConvertTo-DomainSidString -DomainDnsName '$DomainFqdn'"
            $DomainSid = ConvertTo-DomainSidString -DomainDnsName $DomainDnsName -AdsiProvider $AdsiProvider -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisHostName $ThisHostName -ThisFqdn $ThisFqdn

            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$ThisHostname`t$(whoami)`tGet-AdsiServer`tGet-Win32Account -ComputerName '$DomainDnsName'"
            $Win32Accounts = Get-Win32Account -ComputerName $DomainDnsName -Win32AccountsBySID $Win32AccountsBySID -ErrorAction SilentlyContinue

            $Win32Accounts |
            ForEach-Object {
                $Win32AccountsBySID["$($_.Domain)\$($_.SID)"] = $_
                $Win32AccountsByCaption["$($_.Domain)\$($_.Caption)"] = $_
            }

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
