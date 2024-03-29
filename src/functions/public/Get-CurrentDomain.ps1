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

        # Name of the computer to query via CIM
        [string]$ComputerName,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

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

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug'

    )
    $Obj = [adsi]::new()
    try {
        $null = $Obj.RefreshCache('objectSid')
    } catch {

        # Assume local computer/workgroup, use CIM rather than ADSI

        $LoggingParams = @{
            ThisHostname = $ThisHostname
            LogMsgCache  = $LogMsgCache
            WhoAmI       = $WhoAmI
        }

        $SIDString = Find-LocalAdsiServerSid -ComputerName $ComputerName -ThisFqdn $ThisFqdn -CimCache $CimCache @LoggingParams
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

    }

    # Include specific desired properties
    if (-not $OutputProperties) {
        # Convert the objectSID attribute (byte array) to a security descriptor string formatted according to SDDL syntax (Security Descriptor Definition Language)
        Write-LogMsg @LogParams -Text '[System.Security.Principal.SecurityIdentifier]::new([byte[]]$CurrentDomain.objectSid.Value, 0)'
        $OutputProperties = @{
            SIDString = & { [System.Security.Principal.SecurityIdentifier]::new([byte[]]$CurrentDomain.objectSid.Value, 0) } 2>$null
        }

        # Get any existing properties for inclusion later
        $InputProperties = (Get-Member -InputObject $Obj[0] -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name

        # Include any existing properties found earlier
        ForEach ($ThisProperty in $InputProperties) {
            $OutputProperties[$ThisProperty] = $ThisPrincipal.$ThisProperty
        }
    }

    # Output the object
    [PSCustomObject]$OutputProperties

}
