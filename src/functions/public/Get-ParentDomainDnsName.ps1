function Get-ParentDomainDnsName {
    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Get-ParentDomainDnsName')]

    <#
    .SYNOPSIS
        Gets the DNS name of the parent domain for a given computer or domain.
    .DESCRIPTION
        This function retrieves the DNS name of the parent domain for a specified domain
        or computer using CIM queries. For workgroup computers or when no parent domain
        is found, it falls back to using the primary DNS suffix from the client's global
        DNS settings. The function uses caching to improve performance during repeated calls.
    .EXAMPLE
        $Cache = @{}
        Get-ParentDomainDnsName -DomainNetbios "CORPDC01" -Cache ([ref]$Cache)

        Remark: This example retrieves the parent domain DNS name for a domain controller named "CORPDC01".
        The function will first attempt to get the domain information via CIM queries to the specified computer.
        Results are stored in the $Cache variable to improve performance if the function is called again
        with the same parameters. For domain controllers, this will typically return the forest root domain name.
    #>

    param (

        # NetBIOS name of the domain whose parent domain DNS to return
        [string]$DomainNetbios,

        # Existing CIM session to the computer (to avoid creating redundant CIM sessions)
        [CimSession]$CimSession,

        # Switch to remove the CIM session when done
        [switch]$RemoveCimSession,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache


    )

    if (-not $CimSession) {
        Write-LogMsg -Text "Get-CachedCimSession -ComputerName '$DomainNetbios' -Cache `$Cache" -Cache $Cache
        $CimSession = Get-CachedCimSession -ComputerName $DomainNetbios -Cache $Cache
    }

    Write-LogMsg -Text "((Get-CachedCimInstance -ComputerName '$DomainNetbios' -ClassName CIM_ComputerSystem -Cache `$Cache).domain # for '$DomainNetbios'" -Cache $Cache
    $ParentDomainDnsName = (Get-CachedCimInstance -ComputerName $DomainNetbios -ClassName CIM_ComputerSystem -KeyProperty Name -Cache $Cache).domain

    if ($ParentDomainDnsName -eq 'WORKGROUP' -or $null -eq $ParentDomainDnsName) {
        # For workgroup computers there is no parent domain DNS (workgroups operate on NetBIOS)
        # There could also be unexpeted scenarios where the parent domain DNS is null
        # In these cases, we will use the primary DNS search suffix (that is where the OS would attempt to register DNS records for the computer)
        Write-LogMsg -Text "(Get-DnsClientGlobalSetting -CimSession `$CimSession).SuffixSearchList[0] # for '$DomainNetbios'" -Cache $Cache
        $ParentDomainDnsName = (Get-DnsClientGlobalSetting -CimSession $CimSession).SuffixSearchList[0]
    }

    if ($RemoveCimSession) {
        Remove-CimSession -CimSession $CimSession
    }

    return $ParentDomainDnsName
}
