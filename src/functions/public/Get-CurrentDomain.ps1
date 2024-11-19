function Get-CurrentDomain {

    <#
        .SYNOPSIS
        Use ADSI to get the current domain
        .DESCRIPTION
        Works only on domain-joined systems, otherwise returns nothing
        .INPUTS
        None. Pipeline input is not accepted.
        .OUTPUTS
        [System.DirectoryServices.DirectoryEntry] The current domain

        .EXAMPLE
        Get-CurrentDomain

        Get the domain of the current computer
    #>

    [OutputType([System.DirectoryServices.DirectoryEntry])]

    param (

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        # Name of the computer to query via CIM
        [string]$ComputerName = $ThisHostName,

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

    $Log = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        Buffer       = $Cache.Value['LogBuffer']
        WhoAmI       = $WhoAmI
    }

    $CimParams = @{
        Cache             = $Cache
        ComputerName      = $ComputerName
        DebugOutputStream = $DebugOutputStream
        ThisFqdn          = $ThisFqdn
        ThisHostname      = $ThisHostname
        WhoAmI            = $WhoAmI
    }

    $Comp = Get-CachedCimInstance -ClassName Win32_ComputerSystem -KeyProperty Name @CimParams

    if ($Comp.Domain -eq 'WORKGROUP') {

        # Use CIM to find the domain
        $SIDString = Find-LocalAdsiServerSid @CimParams
        $SID = $SIDString | ConvertTo-SidByteArray

        $OutputProperties = @{
            SIDString         = $SIDString
            ObjectSid         = [PSCustomObject]@{
                Value = $Sid
            }
            DistinguishedName = [PSCustomObject]@{
                Value = "DC=$ComputerName"
            }
        }

    } else {

        # Use ADSI to find the domain

        Write-LogMsg @Log -Text "[adsi]::new().RefreshCache('objectSid')"
        $CurrentDomain = [adsi]::new()
        try {
            $null = $CurrentDomain.RefreshCache('objectSid')
        } catch {
            Write-LogMsg @Log -Text " # $($_.Exception.Message) # for '$ComputerName'"
            return
        }

        # Convert the objectSID attribute (byte array) to a security descriptor string formatted according to SDDL syntax (Security Descriptor Definition Language)
        Write-LogMsg @Log -Text "[System.Security.Principal.SecurityIdentifier]::new([byte[]]$CurrentDomain.objectSid.Value, 0)# for '$ComputerName'"
        $OutputProperties = @{
            SIDString = & { [System.Security.Principal.SecurityIdentifier]::new([byte[]]$CurrentDomain.objectSid.Value, 0) } 2>$null
        }

        # Get any existing properties for inclusion later
        if ($CurrentDomain -is [System.Collections.IEnumerable]) {
            $FirstDomain = $CurrentDomain[0]
        } else {
            $FirstDomain = $CurrentDomain
        }

        $InputProperties = $FirstDomain.PSObject.Properties.GetEnumerator().Name

        # Include any existing properties found earlier
        ForEach ($ThisProperty in $InputProperties) {
            $OutputProperties[$ThisProperty] = $FirstDomain.$ThisProperty
        }

    }

    # Output the object
    $OutputObject = [PSCustomObject]$OutputProperties
    $AddOrUpdateScriptBlock = { param($key, $val) $val }
    $null = $Cache.Value['DomainByFqdn'].Value.AddOrUpdate( $DomainDnsName, $OutputObject, $AddOrUpdateScriptblock )
    $null = $Cache.Value['DomainByNetbios'].Value.AddOrUpdate( $DomainNetBIOS, $OutputObject, $AddOrUpdateScriptblock )
    $null = $Cache.Value['DomainBySid'].Value.AddOrUpdate( $DomainSid, $OutputObject, $AddOrUpdateScriptblock )

}
