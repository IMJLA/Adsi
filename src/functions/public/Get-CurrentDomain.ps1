function Get-CurrentDomain {
    <#
        .SYNOPSIS
        Use ADSI to get the current domain
        .DESCRIPTION
        Works only on domain-joined systems
        .INPUTS
        None
        .OUTPUTS
        [System.DirectoryServices.DirectoryEntry] The current domain

        .EXAMPLE
        Get-CurrentDomain

        Get the domain of the current computer
    #>
    [OutputType([System.DirectoryServices.DirectoryEntry])]
    $Obj = [adsi]::new()
    $Obj.RefreshCache({ 'objectSid' })
    Write-Output $Obj
}
