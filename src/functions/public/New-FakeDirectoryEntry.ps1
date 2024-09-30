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
            'Authenticated Users'                 = $null
            'BATCH'                               = $null
            'CREATOR OWNER'                       = $null
            'Everyone'                            = $null
            'INTERACTIVE'                         = $null
            'internetExplorer'                    = $null
            'LOCAL SERVICE'                       = $null
            'NETWORK SERVICE'                     = $null
            'RESTRICTED'                          = $null
            'RDS Endpoint Servers'                = $null
            'RDS Management Servers'              = $null
            'RDS Remote Access Servers'           = $null
            'SERVICE'                             = $null
            'SYSTEM'                              = $null
        },

        [string]$Name,

        # Unused but here for convenient splats
        [string]$NTAccount

    )

    $LastSlashIndex = $DirectoryPath.LastIndexOf('/')
    $StartIndex = $LastSlashIndex + 1
    $Name = $DirectoryPath.Substring($StartIndex, $DirectoryPath.Length - $StartIndex)
    if (-not $NameAllowList.ContainsKey($Name)) {
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
