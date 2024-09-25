function Get-SidTypeMap {
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
