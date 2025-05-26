function Get-SidTypeMap {

    <#
    .SYNOPSIS
    Returns a mapping of SID type numbers to their string representations.

    .DESCRIPTION
    The Get-SidTypeMap function provides a mapping between the numeric SID type values
    and their corresponding string representations. This is useful for translating
    SID type codes returned by various APIs to human-readable format.

    .EXAMPLE
    $sidTypeMap = Get-SidTypeMap
    $sidTypeMap[1]  # Returns 'user'

    .INPUTS
    None. This function does not accept pipeline input.

    .OUTPUTS
    [System.Collections.Hashtable] A hashtable mapping SID type numbers to string representations.
    #>

    return @{
        1 = 'user' #'SidTypeUser'
        2 = 'group' #'SidTypeGroup'
        3 = 'SidTypeDomain'
        4 = 'SidTypeAlias'
        5 = 'group' #'SidTypeWellKnownGroup'
        6 = 'SidTypeDeletedAccount'
        7 = 'SidTypeInvalid'
        8 = 'SidTypeUnknown'
        9 = 'computer' #'SidTypeComputer'
    }
}
