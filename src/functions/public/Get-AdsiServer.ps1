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
    [PSCustomObject] with AdsiProvider and WellKnownSidBySid properties
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

        # Remove the CIM session used to get ADSI server information
        [switch]$RemoveCimSession,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    begin {

        $Log = @{ Cache = $Cache }
        $DomainsByFqdn = $Cache.Value['DomainByFqdn']
        $DomainsByNetbios = $Cache.Value['DomainByNetbios']
        $DomainsBySid = $Cache.Value['DomainBySid']
        $WellKnownSidBySid = $Cache.Value['WellKnownSidBySid']
        $WellKnownSidByName = $Cache.Value['WellKnownSidByName']

    }

    process {

        ForEach ($DomainFqdn in $Fqdn) {

            $Log['Suffix'] = " # for domain FQDN '$DomainFqdn'"
            $OutputObject = $null
            $TryGetValueResult = $DomainsByFqdn.Value.TryGetValue($DomainFqdn, [ref]$OutputObject)

            if ($TryGetValueResult) {

                #Write-LogMsg @Log -Text " # Domain FQDN cache hit"
                if ($OutputObject.AdsiProvider) {
                    $OutputObject
                    continue
                }

            }

            $TryGetValueResult = $DomainsByNetbios.Value.TryGetValue($DomainFqdn, [ref]$OutputObject)

            if ($TryGetValueResult) {

                #Write-LogMsg @Log -Text " # Domain NetBIOS cache hit"
                if ($OutputObject.AdsiProvider) {
                    $OutputObject
                    continue
                }

            }

            Write-LogMsg @Log -Text "Find-AdsiProvider -AdsiServer '$DomainFqdn' -Cache `$Cache # Domain FQDN cache miss"
            $AdsiProvider = Find-AdsiProvider -AdsiServer $DomainFqdn -Cache $Cache

            if ($null -eq $AdsiProvider) {
                $StartingLogType = $Cache.Value['LogType'].Value
                $Cache.Value['LogType'].Value = 'Warning'
                Write-LogMsg @Log -Text ' # Could not find the ADSI provider'
                $Log['Type'] = $Cache.Value['LogType'].Value
                continue
            }

            Write-LogMsg @Log -Text "ConvertTo-DistinguishedName -DomainFQDN '$DomainFqdn' -AdsiProvider '$AdsiProvider' -Cache `$Cache"
            $DomainDn = ConvertTo-DistinguishedName -DomainFQDN $DomainFqdn -AdsiProvider $AdsiProvider -Cache $Cache

            Write-LogMsg @Log -Text "ConvertTo-DomainSidString -DomainDnsName '$DomainFqdn' -Cache `$Cache"
            $DomainSid = ConvertTo-DomainSidString -DomainDnsName $DomainFqdn -AdsiProvider $AdsiProvider -Cache $Cache

            Write-LogMsg @Log -Text "ConvertTo-DomainNetBIOS -DomainFQDN '$DomainFqdn' -AdsiProvider '$AdsiProvider' -Cache `$Cache"
            $DomainNetBIOS = ConvertTo-DomainNetBIOS -DomainFQDN $DomainFqdn -AdsiProvider $AdsiProvider -Cache $Cache

            <#
            PS C:\Users\Owner> wmic SYSACCOUNT get name,sid
                Name                           SID
                Everyone                       S-1-1-0
                LOCAL                          S-1-2-0
                CREATOR OWNER                  S-1-3-0
                CREATOR GROUP                  S-1-3-1
                CREATOR OWNER SERVER           S-1-3-2
                CREATOR GROUP SERVER           S-1-3-3
                OWNER RIGHTS                   S-1-3-4
                DIALUP                         S-1-5-1
                NETWORK                        S-1-5-2
                BATCH                          S-1-5-3
                INTERACTIVE                    S-1-5-4
                SERVICE                        S-1-5-6
                ANONYMOUS LOGON                S-1-5-7
                PROXY                          S-1-5-8
                SYSTEM                         S-1-5-18
                ENTERPRISE DOMAIN CONTROLLERS  S-1-5-9
                SELF                           S-1-5-10
                Authenticated Users            S-1-5-11
                RESTRICTED                     S-1-5-12
                TERMINAL SERVER USER           S-1-5-13
                REMOTE INTERACTIVE LOGON       S-1-5-14
                IUSR                           S-1-5-17
                LOCAL SERVICE                  S-1-5-19
                NETWORK SERVICE                S-1-5-20
                BUILTIN                        S-1-5-32

            PS C:\Users\Owner> $logonDomainSid = 'S-1-5-21-1340649458-2707494813-4121304102'
            PS C:\Users\Owner> ForEach ($SidType in [System.Security.Principal.WellKnownSidType].GetEnumNames()) {$var = [System.Security.Principal.WellKnownSidType]::$SidType; [System.Security.Principal.SecurityIdentifier]::new($var,$LogonDomainSid) |Add-Member -PassThru -NotePropertyMembers @{'WellKnownSidType' = $SidType}}

            #>

            Write-LogMsg @Log -Text "Get-CacheCimInstance -ComputerName '$DomainFqdn' -ClassName 'Win32_Account' -KeyProperty 'Caption' -CacheByProperty @() -Cache `$Cache"
            $Win32Accounts = Get-CacheCimInstance -ComputerName $DomainFqdn -ClassName 'Win32_Account' -KeyProperty 'Caption' -CacheByProperty @() -Cache $Cache

            Write-LogMsg @Log -Text "`$Win32Services = Get-CacheCimInstance -ComputerName '$DomainFqdn' -ClassName 'Win32_Service' -KeyProperty 'Name' -CacheByProperty @() -Cache `$Cache"
            $Win32Services = Get-CacheCimInstance -ComputerName $DomainFqdn -ClassName 'Win32_Service' -KeyProperty 'Name' -CacheByProperty @() -Cache $Cache

            Write-LogMsg @Log -Text "Resolve-ServiceNameToSID -InputObject `$Win32Services"
            $ResolvedWin32Services = Resolve-ServiceNameToSID -InputObject $Win32Services

            ConvertTo-AccountCache -Account $Win32Accounts -SidCache $WellKnownSidBySid -NameCache $WellKnownSidByName
            ConvertTo-AccountCache -Account $ResolvedWin32Services -SidCache $WellKnownSidBySid -NameCache $WellKnownSidByName

            $OutputObject = [PSCustomObject]@{
                DistinguishedName  = $DomainDn
                Dns                = $DomainFqdn
                Sid                = $DomainSid
                Netbios            = $DomainNetBIOS
                AdsiProvider       = $AdsiProvider
                WellKnownSidBySid  = $WellKnownSidBySid.Value
                WellKnownSidByName = $WellKnownSidByName.Value
            }

            $DomainsByFqdn.Value[$DomainFqdn] = $OutputObject
            $DomainsByNetbios.Value[$DomainNetBIOS] = $OutputObject
            $DomainsBySid.Value[$DomainSid] = $OutputObject
            $OutputObject

        }

        ForEach ($DomainNetbios in $Netbios) {

            $Log['Suffix'] = " # for domain NetBIOS '$DomainNetbios'"
            $OutputObject = $null
            $TryGetValueResult = $DomainsByNetbios.Value.TryGetValue($DomainNetbios, [ref]$OutputObject)

            if ($TryGetValueResult) {

                #Write-LogMsg @Log -Text " # Domain NetBIOS cache hit"
                if ($OutputObject.AdsiProvider) {
                    $OutputObject
                    continue
                }

            }

            $TryGetValueResult = $DomainsByFqdn.Value.TryGetValue($DomainNetbios, [ref]$OutputObject)

            if ($TryGetValueResult) {

                #Write-LogMsg @Log -Text " # Domain NetBIOS cache hit"
                if ($OutputObject.AdsiProvider) {
                    $OutputObject
                    continue
                }

            }

            Write-LogMsg @Log -Text "`$CimSession = Get-CacheCimSession -ComputerName '$DomainNetbios' -Cache `$Cache # Domain NetBIOS cache miss"
            $CimSession = Get-CacheCimSession -ComputerName $DomainNetbios -Cache $Cache

            Write-LogMsg @Log -Text "Find-AdsiProvider -AdsiServer '$DomainNetbios' -Cache `$Cache"
            $AdsiProvider = Find-AdsiProvider -AdsiServer $DomainNetbios -Cache $Cache

            if ($null -eq $AdsiProvider) {
                $StartingLogType = $Cache.Value['LogType'].Value
                $Cache.Value['LogType'].Value = 'Warning'
                Write-LogMsg @Log -Text " # Could not find the ADSI provider for '$DomainDnsName'"
                $Cache.Value['LogType'].Value = $StartingLogType
                continue
            }

            Write-LogMsg @Log -Text "ConvertTo-DistinguishedName -Domain '$DomainNetBIOS' -Cache `$Cache"
            $DomainDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -Cache $Cache

            if ($DomainDn) {

                Write-LogMsg @Log -Text "ConvertTo-Fqdn -DistinguishedName '$DomainDn' -Cache `$Cache"
                $DomainDnsName = ConvertTo-Fqdn -DistinguishedName $DomainDn -Cache $Cache

            } else {

                Write-LogMsg @Log -Text "Get-ParentDomainDnsName -DomainNetbios '$DomainNetBIOS' -CimSession `$CimSession -Cache `$Cache"
                $ParentDomainDnsName = Get-ParentDomainDnsName -DomainNetbios $DomainNetBIOS -CimSession $CimSession -Cache $Cache
                $DomainDnsName = "$DomainNetBIOS.$ParentDomainDnsName"

            }

            Write-LogMsg @Log -Text "ConvertTo-DomainSidString -DomainDnsName '$DomainDnsName' -AdsiProvider '$AdsiProvider' -Cache `$Cache"
            $DomainSid = ConvertTo-DomainSidString -DomainDnsName $DomainDnsName -AdsiProvider $AdsiProvider -Cache $Cache

            Write-LogMsg @Log -Text "Get-CacheCimInstance -ComputerName '$DomainDnsName' -ClassName 'Win32_Account' -KeyProperty 'Caption' -CacheByProperty @('Caption', 'SID') -Cache `$Cache"
            $Win32Accounts = Get-CacheCimInstance -ComputerName $DomainDnsName -ClassName 'Win32_Account' -KeyProperty 'Caption' -CacheByProperty @('Caption', 'SID') -Cache $Cache

            Write-LogMsg @Log -Text "`$Win32Services = Get-CacheCimInstance -ComputerName '$DomainDnsName' -ClassName 'Win32_Service' -KeyProperty 'Name' -CacheByProperty @() -Cache `$Cache"
            $Win32Services = Get-CacheCimInstance -ComputerName $DomainDnsName -ClassName 'Win32_Service' -KeyProperty 'Name' -CacheByProperty @() -Cache $Cache

            Write-LogMsg @Log -Text "Resolve-ServiceNameToSID -InputObject `$Win32Services"
            $ResolvedWin32Services = Resolve-ServiceNameToSID -InputObject $Win32Services

            ConvertTo-AccountCache -Account $Win32Accounts -SidCache $WellKnownSidBySid -NameCache $WellKnownSidByName
            ConvertTo-AccountCache -Account $ResolvedWin32Services -SidCache $WellKnownSidBySid -NameCache $WellKnownSidByName

            if ($RemoveCimSession) {
                Remove-CimSession -CimSession $CimSession
            }

            $OutputObject = [PSCustomObject]@{
                DistinguishedName  = $DomainDn
                Dns                = $DomainDnsName
                Sid                = $DomainSid # TODO : This should be a sid object since there is a sidstring property but downstream consumers first need to be updated to use sidstring
                SidString          = $DomainSid
                Netbios            = $DomainNetBIOS
                AdsiProvider       = $AdsiProvider
                Win32Accounts      = $Win32Accounts
                Win32Services      = $ResolvedWin32Services
                WellKnownSidBySid  = $WellKnownSidBySid.Value
                WellKnownSidByName = $WellKnownSidByName.Value
            }

            $DomainsByFqdn.Value[$DomainDnsName] = $OutputObject
            $DomainsByNetbios.Value[$DomainNetBIOS] = $OutputObject
            $DomainsBySid.Value[$DomainSid] = $OutputObject
            $OutputObject

        }

    }

}
