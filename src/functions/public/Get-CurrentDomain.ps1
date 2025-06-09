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
    Get-CurrentDomain -Cache $Cache

    Retrieves the current domain of the computer running the script as a DirectoryEntry object.
    On domain-joined systems, this returns the Active Directory domain. On workgroup computers,
    it returns the local computer as the domain. The function caches the result to improve
    performance in subsequent operations involving the current domain.
    #>

    [OutputType([System.DirectoryServices.DirectoryEntry])]

    param (

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $ComputerName = $Cache.Value['ThisHostname'].Value
    $Suffix = " # for the computer running the script, named '$ComputerName'"
    Write-LogMsg -Text "Get-CachedCimInstance -ComputerName $ComputerName -ClassName 'Win32_ComputerSystem' -KeyProperty 'Name' -Cache `$Cache$Suffix" -Cache $Cache
    $Comp = Get-CachedCimInstance -ComputerName $ComputerName -ClassName 'Win32_ComputerSystem' -KeyProperty 'Name' -Cache $Cache

    if ($Comp.Domain -eq 'WORKGROUP') {

        Write-LogMsg -Text "Get-AdsiServer -Fqdn '$ComputerName' -Cache `$Cache" -Cache $Cache -Suffix " # is not domain-joined$Suffix"
        Get-AdsiServer -Fqdn $ComputerName -Cache $Cache
        $Cache.Value['ThisParentDomain'] = [ref]$Cache.Value['DomainByFqdn'].Value[$ComputerName]

    } else {

        Write-LogMsg -Text "Get-AdsiServer -Fqdn '$($Comp.Domain))' -Cache `$Cache" -Cache $Cache -Suffix " # is either domain-joined or joined to a custom-named workgroup$Suffix"
        Get-AdsiServer -Fqdn $Comp.Domain -Cache $Cache
        $Cache.Value['ThisParentDomain'] = [ref]$Cache.Value['DomainByFqdn'].Value[$Comp.Domain]

    }

}