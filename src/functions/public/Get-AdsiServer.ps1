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

        # Remove the CIM session used to get ADSI server information
        [switch]$RemoveCimSession,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    begin {

        $Log = @{ ThisHostname = $ThisHostname ; Type = $DebugOutputStream ; Buffer = $Cache.Value['LogBuffer'] ; WhoAmI = $WhoAmI }
        $LogThis = @{ ThisHostname = $ThisHostname ; Cache = $Cache ; WhoAmI = $WhoAmI ; DebugOutputStream = $DebugOutputStream }
        $CimParams = @{ ThisFqdn = $ThisFqdn }
        $DomainsByFqdn = $Cache.Value['DomainByFqdn']
        $DomainsByNetbios = $Cache.Value['DomainByNetbios']
        $DomainsBySid = $Cache.Value['DomainBySid']
        $WellKnownSidBySid = $Cache.Value['WellKnownSidBySid']
        $WellKnownSidByName = $Cache.Value['WellKnownSidByName']

    }

    process {

        ForEach ($DomainFqdn in $Fqdn) {

            $OutputObject = $null
            $TryGetValueResult = $DomainsByFqdn.Value.TryGetValue($DomainFQDN, [ref]$OutputObject)

            if ($TryGetValueResult) {

                #Write-LogMsg @Log -Text " # Domain FQDN cache hit for '$DomainFqdn'"
                if ($OutputObject.AdsiProvider) {
                    $OutputObject
                    continue
                }

            }

            $TryGetValueResult = $DomainsByNetbios.Value.TryGetValue($DomainFQDN, [ref]$OutputObject)

            if ($TryGetValueResult) {

                #Write-LogMsg @Log -Text " # Domain NetBIOS cache hit for '$DomainNetbios'"
                if ($OutputObject.AdsiProvider) {
                    $OutputObject
                    continue
                }

            }

            Write-LogMsg @Log -Text "Find-AdsiProvider -AdsiServer '$DomainFqdn' -ThisFqdn '$ThisFqdn' # Domain FQDN cache miss for '$DomainFqdn'"
            $AdsiProvider = Find-AdsiProvider -AdsiServer $DomainFqdn -ThisFqdn $ThisFqdn @LogThis

            if ($null -eq $AdsiProvider) {
                $Log['Type'] = 'Warning'
                Write-LogMsg @Log -Text " # Could not find the ADSI provider for '$DomainFqdn'"
                $Log['Type'] = $DebugOutputStream
                continue
            }

            Write-LogMsg @Log -Text "ConvertTo-DistinguishedName -DomainFQDN '$DomainFqdn' -AdsiProvider '$AdsiProvider' # for '$DomainFqdn'"
            $DomainDn = ConvertTo-DistinguishedName -DomainFQDN $DomainFqdn -AdsiProvider $AdsiProvider -ThisFqdn $ThisFqdn @LogThis

            Write-LogMsg @Log -Text "ConvertTo-DomainSidString -DomainDnsName '$DomainFqdn' -ThisFqdn '$ThisFqdn' # for '$DomainFqdn'"
            $DomainSid = ConvertTo-DomainSidString -DomainDnsName $DomainFqdn -AdsiProvider $AdsiProvider -ThisFqdn $ThisFqdn @LogThis

            Write-LogMsg @Log -Text "ConvertTo-DomainNetBIOS -DomainFQDN '$DomainFqdn' # for '$DomainFqdn'"
            $DomainNetBIOS = ConvertTo-DomainNetBIOS -DomainFQDN $DomainFqdn -AdsiProvider $AdsiProvider -ThisFqdn $ThisFqdn @LogThis

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

            Write-LogMsg @Log -Text "Get-CachedCimInstance -ComputerName '$DomainFqdn' -ClassName 'Win32_Account' # for '$DomainFqdn'"
            $Win32Accounts = Get-CachedCimInstance -ComputerName $DomainFqdn -ClassName 'Win32_Account' -KeyProperty Caption -CacheByProperty @() @CimParams @LogThis

            Write-LogMsg @Log -Text "`$Win32Services = Get-CachedCimInstance -ComputerName '$DomainFqdn' -ClassName 'Win32_Service' # for '$DomainFqdn'"
            $Win32Services = Get-CachedCimInstance -ComputerName $DomainFqdn -ClassName 'Win32_Service' -KeyProperty Name -CacheByProperty @() @CimParams @LogThis

            Write-LogMsg @Log -Text "Resolve-ServiceNameToSID -InputObject `$Win32Services # for '$DomainFqdn'"
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

            $OutputObject = $null
            $TryGetValueResult = $DomainsByNetbios.Value.TryGetValue($DomainNetbios, [ref]$OutputObject)

            if ($TryGetValueResult) {

                #Write-LogMsg @Log -Text " # Domain NetBIOS cache hit for '$DomainNetbios'"
                if ($OutputObject.AdsiProvider) {
                    $OutputObject
                    continue
                }

            }

            $TryGetValueResult = $DomainsByFqdn.Value.TryGetValue($DomainNetbios, [ref]$OutputObject)

            if ($TryGetValueResult) {

                #Write-LogMsg @Log -Text " # Domain NetBIOS cache hit for '$DomainNetbios'"
                if ($OutputObject.AdsiProvider) {
                    $OutputObject
                    continue
                }

            }

            #Write-LogMsg @Log -Text "Get-CachedCimSession -ComputerName '$DomainNetbios' # Domain NetBIOS cache miss for '$DomainNetbios'"
            $CimSession = Get-CachedCimSession -ComputerName $DomainNetbios -ThisFqdn $ThisFqdn @LogThis

            Write-LogMsg @Log -Text "Find-AdsiProvider -AdsiServer '$DomainNetbios' # for '$DomainNetbios'"
            $AdsiProvider = Find-AdsiProvider -AdsiServer $DomainNetbios -ThisFqdn $ThisFqdn @LogThis

            if ($null -eq $AdsiProvider) {
                $Log['Type'] = 'Warning'
                Write-LogMsg @Log -Text " # Could not find the ADSI provider for '$DomainDnsName'"
                $Log['Type'] = $DebugOutputStream
                continue
            }

            Write-LogMsg @Log -Text "ConvertTo-DistinguishedName -Domain '$DomainNetBIOS' # for '$DomainNetbios'"
            $DomainDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -ThisFqdn $ThisFqdn @LogThis

            if ($DomainDn) {

                Write-LogMsg @Log -Text "ConvertTo-Fqdn -DistinguishedName '$DomainDn' # for '$DomainNetbios'"
                $DomainDnsName = ConvertTo-Fqdn -DistinguishedName $DomainDn -ThisFqdn $ThisFqdn @LogThis

            } else {

                $ParentDomainDnsName = Get-ParentDomainDnsName -DomainNetbios $DomainNetBIOS -CimSession $CimSession -ThisFqdn $ThisFqdn @LogThis
                $DomainDnsName = "$DomainNetBIOS.$ParentDomainDnsName"

            }

            Write-LogMsg @Log -Text "ConvertTo-DomainSidString -DomainDnsName '$DomainDnsName' -AdsiProvider '$AdsiProvider' -ThisFqdn '$ThisFqdn' # for '$DomainNetbios'"
            $DomainSid = ConvertTo-DomainSidString -DomainDnsName $DomainDnsName -AdsiProvider $AdsiProvider -ThisFqdn $ThisFqdn @LogThis

            Write-LogMsg @Log -Text "Get-CachedCimInstance -ComputerName '$DomainDnsName' -ClassName 'Win32_Account' # for '$DomainNetbios'"
            $Win32Accounts = Get-CachedCimInstance -ComputerName $DomainDnsName -ClassName 'Win32_Account' -KeyProperty Caption -CacheByProperty @('Caption', 'SID') @CimParams @LogThis

            Write-LogMsg @Log -Text "`$Win32Services = Get-CachedCimInstance -ComputerName '$DomainDnsName' -ClassName 'Win32_Service' # for '$DomainNetbios'"
            $Win32Services = Get-CachedCimInstance -ComputerName $DomainDnsName -ClassName 'Win32_Service' -KeyProperty Name -CacheByProperty @() @CimParams @LogThis

            Write-LogMsg @Log -Text "Resolve-ServiceNameToSID -InputObject `$Win32Services # for '$DomainNetbios'"
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
