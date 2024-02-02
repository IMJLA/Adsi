function Get-TrustedDomain {
    <#
        .SYNOPSIS
        Returns a dictionary of trusted domains by the current computer
        .DESCRIPTION
        Works only on domain-joined systems
        Use nltest to get the domain trust relationships for the domain of the current computer
        Use ADSI's LDAP provider to get each trusted domain's DNS name, NETBIOS name, and SID
        For each trusted domain the key is the domain's SID, or its NETBIOS name if the -KeyByNetbios switch parameter was used
        For each trusted domain the value contains the details retrieved with ADSI
        .INPUTS
        None. Pipeline input is not accepted.
        .OUTPUTS
        [PSCustomObject] One object per trusted domain, each with a DomainFqdn property and a DomainNetbios property

        .EXAMPLE
        Get-TrustedDomain

        Get the trusted domains of the current computer
        .NOTES
    #>
    [OutputType([PSCustomObject])]
    param (

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        $ThisHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug'

    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    # Redirect the error stream to null, errors are expected on non-domain-joined systems
    Write-LogMsg @LogParams -Text "$('& nltest /domain_trusts 2> $null')"
    #$nltestresults = & nltest /domain_trusts 2> $null
    $nltestresults = & nltest /domain_trusts 2>&1

    #$NlTestRegEx = '[\d]*: .*'
    $RegExForEachTrust = '(?<index>[\d]*): (?<netbios>\S*) (?<dns>\S*).*'
    ForEach ($Result in $nltestresults) {
        if ($Result.GetType() -eq [string]) {
            if ($Result -match $RegExForEachTrust) {
                [PSCustomObject]@{
                    DomainFqdn    = $Matches.dns
                    DomainNetbios = $Matches.netbios
                }
            }
        }
    }
}
