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
        [string]$ComputerName = (HOSTNAME.EXE),

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $Comp = Get-CachedCimInstance -ComputerName $ComputerName -ClassName 'Win32_ComputerSystem' -KeyProperty 'Name' -Cache $Cache

    if ($Comp.Domain -eq 'WORKGROUP') {

        Get-AdsiServer -Fqdn $ComputerName -Cache $Cache

    } else {

        Get-AdsiServer -Fqdn $Comp.Domain -Cache $Cache

    }

}
