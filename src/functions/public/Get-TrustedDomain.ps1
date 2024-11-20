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

    # Errors are expected on non-domain-joined systems
    # Redirecting the error stream to null only suppresses the error in the console; it will still be in the transcript
    # Instead, redirect the error stream to the output stream and filter out the errors by type
    Write-LogMsg @Log -Text "$('& nltest /domain_trusts 2>&1')"
    $nltestresults = & nltest /domain_trusts 2>&1
    $RegExForEachTrust = '(?<index>[\d]*): (?<netbios>\S*) (?<dns>\S*).*'
    $DomainByFqdn = $Cache.Value['DomainByFqdn']
    $DomainByNetbios = $Cache.Value['DomainByNetbios']
    $AddOrUpdateScriptBlock = { param($key, $val) $val }

    ForEach ($Result in $nltestresults) {

        if ($Result.GetType() -eq [string]) {

            if ($Result -match $RegExForEachTrust) {

                $DN = ConvertTo-DistinguishedName -DomainFQDN $Matches.dns -AdsiProvider 'LDAP' -WhoAmI $WhoAmI -ThisHostName $ThisHostname -DebugOutputStream $DebugOutputStream -Cache $Cache

                $OutputObject = [PSCustomObject]@{
                    Netbios           = $Matches.dns
                    Dns               = $Matches.netbios
                    DistinguishedName = $DN
                }

                $null = $DomainByFqdn.Value.AddOrUpdate( $Matches.dns, $OutputObject, $AddOrUpdateScriptblock )
                $null = $DomainByNetbios.Value.AddOrUpdate( $atches.netbios, $OutputObject, $AddOrUpdateScriptblock )

            }

        }

    }
}
