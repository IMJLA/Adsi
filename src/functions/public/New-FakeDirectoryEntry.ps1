function New-FakeDirectoryEntry {

    <#
    Used in place of a DirectoryEntry for certain WinNT security principals that do not have objects in the directory
    The WinNT provider only throws an error if you try to retrieve certain accounts/identities
    #>

    param (
        [string]$DirectoryPath,
        [string]$SID,
        [string]$Description,
        [string]$SchemaClassName,
        $InputObject,

        # Account names known to be impossible to resolve to a Directory Entry (currently based on testing on a non-domain-joined PC)
        [hashtable]$NameAllowList = @{
            'ALL APPLICATION PACKAGES'            = $null
            'ALL RESTRICTED APPLICATION PACKAGES' = $null
            'ANONYMOUS LOGON'                     = $null
            'Authenticated Users'                 = $null
            'BATCH'                               = $null
            'BUILTIN'                             = $null
            'CREATOR GROUP'                       = $null
            'CREATOR GROUP SERVER'                = $null
            'CREATOR OWNER'                       = $null
            'CREATOR OWNER SERVER'                = $null
            'DIALUP'                              = $null
            'ENTERPRISE DOMAIN CONTROLLERS'       = $null
            'Everyone'                            = $null
            'INTERACTIVE'                         = $null
            'internetExplorer'                    = $null
            'IUSR'                                = $null
            'LOCAL'                               = $null
            'LOCAL SERVICE'                       = $null
            'NETWORK'                             = $null
            'NETWORK SERVICE'                     = $null
            'OWNER RIGHTS'                        = $null
            'PROXY'                               = $null
            'RDS Endpoint Servers'                = $null
            'RDS Management Servers'              = $null
            'RDS Remote Access Servers'           = $null
            'REMOTE INTERACTIVE LOGON'            = $null
            'RESTRICTED'                          = $null
            'SELF'                                = $null
            'SERVICE'                             = $null
            'SYSTEM'                              = $null
            'TERMINAL SERVER USER'                = $null
        },

        # These are retrievable via the WinNT ADSI Provider which enables group member retrival so we don't want to return fake directory entries
        [hashtable]$NameBlockList = @{
            'Access Control Assistance Operators' = $null
            'Administrators'                      = $null
            'Backup Operators'                    = $null
            'Cryptographic Operators'             = $null
            'DefaultAccount'                      = $null
            'Distributed COM Users'               = $null
            'Event Log Readers'                   = $null
            'Guests'                              = $null
            'Hyper-V Administrators'              = $null
            'IIS_IUSRS'                           = $null
            'Network Configuration Operators'     = $null
            'Performance Log Users'               = $null
            'Performance Monitor Users'           = $null
            'Power Users'                         = $null
            'Remote Desktop Users'                = $null
            'Remote Management Users'             = $null
            'Replicator'                          = $null
            'System Managed Accounts Group'       = $null
            'Users'                               = $null
            'WinRMRemoteWMIUsers__'               = $null
        },

        # Unused but here for convenient splats
        [string]$Name,

        # Unused but here for convenient splats
        [string]$NTAccount

    )

    $LastSlashIndex = $DirectoryPath.LastIndexOf('/')
    $StartIndex = $LastSlashIndex + 1
    $Name = $DirectoryPath.Substring($StartIndex, $DirectoryPath.Length - $StartIndex)
    if (
        $NameBlockList.ContainsKey($Name) -or
        -not $NameAllowList.ContainsKey($Name) -or
        $InputObject.SidType -eq 4 -or
        $InputObject.SidType -eq 5
    ) {
        return $null
    }
    $Parent = $DirectoryPath.Substring(0, $LastSlashIndex)
    $SchemaEntry = [System.DirectoryServices.DirectoryEntry]

    $Properties = @{
        Name            = $Name
        Description     = $Description
        SchemaClassName = $SchemaClassName
    }

    ForEach ($Prop in ($InputObject | Get-Member -View All -MemberType Property, NoteProperty).Name) {
        $Properties[$Prop] = $InputObject.$Prop
    }

    $SID = $Properties['SID']
    if ($SID) {
        $Properties['objectSid'] = ConvertTo-SidByteArray -SidString $SID
    } else {
        $Properties['objectSid'] = $null
    }

    $TopLevelOnlyProperties = @{
        Parent      = $Parent
        Path        = $DirectoryPath
        SchemaEntry = $SchemaEntry
        Properties  = $Properties
    }

    $AllProperties = $Properties + $TopLevelOnlyProperties
    $Object = [PSCustomObject]$AllProperties
    Add-Member -InputObject $Object -Name RefreshCache -MemberType ScriptMethod -Value {}
    Add-Member -InputObject $Object -Name Invoke -MemberType ScriptMethod -Value {}
    return $Object

}
