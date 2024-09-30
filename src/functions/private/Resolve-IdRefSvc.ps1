function Resolve-IdRefSvc {

    [OutputType([PSCustomObject])]
    param (

        # IdentityReference from an Access Control Entry
        # Expecting either a SID (S-1-5-18) or an NT account name (CONTOSO\User)
        [Parameter(Mandatory)]
        [string]$IdentityReference,

        # Object from Get-AdsiServer representing the directory server and its attributes
        [PSObject]$AdsiServer,

        # NetBIOS name of the ADSI server
        [string]$ServerNetBIOS = $AdsiServer.Netbios,

        # Name of the IdentityReference with the DOMAIN\ prefix removed
        [string]$Name,

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
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Log messages which have not yet been written to disk
        [hashtable]$LogBuffer = ([hashtable]::Synchronized(@{})),

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug'

    )

    $Log = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        Buffer       = $LogBuffer
        WhoAmI       = $WhoAmI
    }

    <#
    # Some of them are services (yes services can have SIDs, notably this includes TrustedInstaller but it is also common with SQL)
    if ($ServerNetBIOS -eq $ThisHostName) {

        Write-LogMsg @Log -Text "sc.exe showsid $Name"
        [string[]]$ScResult = & sc.exe showsid $Name

    } else {

        Write-LogMsg @Log -Text "Invoke-Command -ComputerName $ServerNetBIOS -ScriptBlock { & sc.exe showsid `$args[0] } -ArgumentList $Name"
        [string[]]$ScResult = Invoke-Command -ComputerName $ServerNetBIOS -ScriptBlock { & sc.exe showsid $args[0] } -ArgumentList $Name

    }
    $ScResultProps = @{}

    $ScResult |
    ForEach-Object {

        $Prop, $Value = ($_ -split ':').Trim()
        $ScResultProps[$Prop] = $Value

    }

    $SIDString = $ScResultProps['SERVICE SID']
    #>

    $ScShowSidResults = Invoke-ScShowSid -ServiceName $Name -ComputerName $ServerNetBIOS -ThisFqdn $ThisFqdn -ThisHostName $ThisHostName -Log $Log
    $ServiceSidAndStatus = ConvertFrom-ScShowSidResult -Result $ScShowSidResults
    $SIDString = $ServiceSidAndStatus.SID
    $Caption = "$ServerNetBIOS\$Name"

    $DomainCacheResult = $DomainsByNetbios[$ServerNetBIOS]

    if ($DomainCacheResult) {
        $DomainDns = $DomainCacheResult.Dns
    }

    if (-not $DomainDns) {
        $DomainDns = ConvertTo-Fqdn -NetBIOS $ServerNetBIOS -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LoggingParams
    }

    # Update the caches
    $Win32Svc = [PSCustomObject]@{
        SID     = $SIDString
        Caption = $Caption
        Domain  = $ServerNetBIOS
        Name    = $Name
    }

    Write-LogMsg @Log -Text " # Add '$Caption' to the 'Win32_AccountByCaption' cache for '$ServerNetBIOS'"
    $CimCache[$ServerNetBIOS]['Win32_ServiceByName'][$Name] = $Win32Svc

    Write-LogMsg @Log -Text " # Add '$SIDString' to the 'Win32_AccountBySID' cache for '$ServerNetBIOS'"
    $CimCache[$ServerNetBIOS]['Win32_ServiceBySID'][$SIDString] = $Win32Svc

    return [PSCustomObject]@{
        IdentityReference        = $IdentityReference
        SIDString                = $SIDString
        IdentityReferenceNetBios = $Caption
        IdentityReferenceDns     = "$DomainDns\$Name"
    }

}
