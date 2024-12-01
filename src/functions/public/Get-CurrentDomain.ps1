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

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $ComputerName = $Cache.Value['ThisHostname'].Value
    Write-LogMsg -Text "Get-CachedCimInstance -ComputerName $ComputerName -ClassName 'Win32_ComputerSystem' -KeyProperty 'Name' -Cache `$Cache" -Cache $Cache
    $Comp = Get-CachedCimInstance -ComputerName $ComputerName -ClassName 'Win32_ComputerSystem' -KeyProperty 'Name' -Cache $Cache

    if ($Comp.Domain -eq 'WORKGROUP') {

        Write-Log -Text "Get-AdsiServer -Fqdn '$ComputerName' -Cache `$Cache" -Cache $Cache
        Get-AdsiServer -Fqdn $ComputerName -Cache $Cache
        $Cache.Value['ThisParentDomain'] = [ref]$Cache.Value['DomainByFqdn'].Value[$ComputerName]

    } else {

        Write-Log -Text "Get-AdsiServer -Fqdn '$($Comp.Domain))' -Cache `$Cache" -Cache $Cache
        Get-AdsiServer -Fqdn $Comp.Domain -Cache $Cache
        $Cache.Value['ThisParentDomain'] = [ref]$Cache.Value['DomainByFqdn'].Value[$Comp.Domain]

    }

}
