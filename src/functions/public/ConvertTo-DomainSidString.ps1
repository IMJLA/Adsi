function ConvertTo-DomainSidString {

    param (

        # Domain DNS name to convert to the domain's SID
        [Parameter(Mandatory)]
        [string]$DomainDnsName,

        <#
        AdsiProvider (WinNT or LDAP) of the servers associated with the provided FQDNs or NetBIOS names

        This parameter can be used to reduce calls to Find-AdsiProvider

        Useful when that has been done already but the DomainsByFqdn and DomainsByNetbios caches have not been updated yet
        #>
        [string]$AdsiProvider,

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

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $LogSuffix = "# for domain FQDN '$DomainDnsName'"
    $Log = @{ ThisHostname = $ThisHostname ; Type = $DebugOutputStream ; Buffer = $Cache.Value['LogBuffer'] ; WhoAmI = $WhoAmI ; Suffix = " $LogSuffix" }
    $LogThis = @{ ThisHostname = $ThisHostname ; Cache = $Cache ; WhoAmI = $WhoAmI ; DebugOutputStream = $DebugOutputStream }
    $CacheResult = $null
    $null = $Cache.Value['DomainByFqdn'].Value.TryGetValue($DomainDnsName, [ref]$CacheResult)

    if ($CacheResult.Sid) {

        #Write-LogMsg @Log -Text " # Domain FQDN cache hit"
        return $CacheResult.Sid

    }
    #Write-LogMsg @Log -Text " # Domain FQDN cache miss"

    if (
        -not $AdsiProvider -or
        $AdsiProvider -eq 'LDAP'
    ) {

        Write-LogMsg @Log -Text "Get-DirectoryEntry -DirectoryPath 'LDAP://$DomainDnsName' -ThisFqdn '$ThisFqdn'" -Expand $LogThis -ExpandKeyMap @{ 'Cache' = '$Cache' }
        $DomainDirectoryEntry = Get-DirectoryEntry -DirectoryPath "LDAP://$DomainDnsName" -ThisFqdn $ThisFqdn @LogThis

        try {
            $null = $DomainDirectoryEntry.RefreshCache('objectSid')
        } catch {

            Write-LogMsg @Log -Text "Find-LocalAdsiServerSid -ComputerName '$DomainDnsName' -ThisFqdn '$ThisFqdn' # LDAP connection failed - $($_.Exception.Message.Replace("`r`n",' ').Trim())" -Expand $LogThis -ExpandKeyMap @{ 'Cache' = '$Cache' }
            $DomainSid = Find-LocalAdsiServerSid -ComputerName $DomainDnsName -ThisFqdn $ThisFqdn @LogThis
            return $DomainSid

        }

    } else {

        Write-LogMsg @Log -Text "Find-LocalAdsiServerSid -ComputerName '$DomainDnsName' -ThisFqdn '$ThisFqdn'" -Expand $LogThis -ExpandKeyMap @{ 'Cache' = '$Cache' }
        $DomainSid = Find-LocalAdsiServerSid -ComputerName $DomainDnsName -ThisFqdn $ThisFqdn @LogThis
        return $DomainSid

    }

    $DomainSid = $null

    if ($DomainDirectoryEntry.Properties) {

        $objectSIDProperty = $DomainDirectoryEntry.Properties['objectSid']

        if ($objectSIDProperty.Value) {
            $SidByteArray = [byte[]]$objectSIDProperty.Value
        } else {
            $SidByteArray = [byte[]]$objectSIDProperty
        }

    } else {
        $SidByteArray = [byte[]]$DomainDirectoryEntry.objectSid
    }

    Write-LogMsg @Log -Text "[System.Security.Principal.SecurityIdentifier]::new([byte[]]@($($SidByteArray -join ',')), 0).ToString()"
    $DomainSid = [System.Security.Principal.SecurityIdentifier]::new($SidByteArray, 0).ToString()

    if ($DomainSid) {
        return $DomainSid
    } else {

        $Log['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
        Write-LogMsg @Log -Text ' # Could not find valid SID for LDAP Domain'

    }

}
