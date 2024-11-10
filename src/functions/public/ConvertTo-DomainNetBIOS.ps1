function ConvertTo-DomainNetBIOS {
    param (
        [string]$DomainFQDN,

        [string]$AdsiProvider,

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $LogThis = @{ ThisHostname = $ThisHostname ; Cache = $Cache ; WhoAmI = $WhoAmI ; DebugOutputStream = $DebugOutputStream }
    $DomainCacheResult = $null
    $TryGetValueResult = $Cache.Value['DomainByFqdn'].Value.TryGetValue($DomainFQDN, [ref]$DomainCacheResult)

    if ($TryGetValueResult) {

        #Write-LogMsg @LogThis -Text " # Domain FQDN cache hit for '$DomainFQDN'"
        return $DomainCacheResult.Netbios

    }

    #Write-LogMsg @LogThis -Text " # Domain FQDN cache miss for '$DomainFQDN'"

    if ($AdsiProvider -eq 'LDAP') {

        $GetDirectoryEntryParams = @{
            DebugOutputStream = $DebugOutputStream
            ThisFqdn          = $ThisFqdn
            ThisHostname      = $ThisHostname
            WhoAmI            = $WhoAmI
        }

        $RootDSE = Get-DirectoryEntry -DirectoryPath "LDAP://$DomainFQDN/rootDSE" @GetDirectoryEntryParams @LogThis
        Write-LogMsg @LogThis -Text "`$RootDSE.InvokeGet('defaultNamingContext')"
        $DomainDistinguishedName = $RootDSE.InvokeGet('defaultNamingContext')
        Write-LogMsg @LogThis -Text "`$RootDSE.InvokeGet('configurationNamingContext')"
        $ConfigurationDN = $rootDSE.InvokeGet('configurationNamingContext')
        $partitions = Get-DirectoryEntry -DirectoryPath "LDAP://$DomainFQDN/cn=partitions,$ConfigurationDN" @GetDirectoryEntryParams @LogThis

        ForEach ($Child In $Partitions.Children) {

            If ($Child.nCName -contains $DomainDistinguishedName) {
                return $Child.nETBIOSName
            }

        }

    } else {

        $LengthOfNetBIOSName = $DomainFQDN.IndexOf('.')

        if ($LengthOfNetBIOSName -eq -1) {
            $DomainFQDN
        } else {
            $DomainFQDN.Substring(0, $LengthOfNetBIOSName)
        }

    }

}
