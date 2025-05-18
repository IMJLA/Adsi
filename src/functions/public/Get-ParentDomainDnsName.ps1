function Get-ParentDomainDnsName {

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
