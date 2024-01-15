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
    $Obj = [adsi]::new()
    try { $null = $Obj.RefreshCache('objectSid') } catch {
        # Assume local computer/workgroup, use CIM rather than ADSI
        # TODO: Make this more efficient.  CIM Sessions, pass in hostname via param, etc.
        $ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
        $AdminAccount = Get-CimInstance -ClassName Win32_UserAccount -Filter "LocalAccount = 'True' AND SID LIKE 'S-1-5-21-%-500'"
        $Obj = [PSCustomObject]@{
            ObjectSid         = [PSCustomObject]@{
                Value = $AdminAccount.Sid.Substring(0, $AdminAccount.Sid.LastIndexOf('-')) | ConvertTo-SidByteArray
            }
            DistinguishedName = [PSCustomObject]@{
                Value = "DC=$(& HOSTNAME.EXE)"
            }
        }
    }
    return $Obj
}
