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

        # Account names known to be impossible to resolve to a Directory Entry (currently based on testing on a non-domain-joined PC)
        [hashtable]$NameAllowList = @{
            'ALL APPLICATION PACKAGES'  = $null
            'RDS Remote Access Servers' = $null
            'NETWORK SERVICE'           = $null
            'BATCH'                     = $null
            'RESTRICTED'                = $null
            'SERVICE'                   = $null
        },
        [string]$Name, #unused but here for convenient splats
        [string]$NTAccount #unused but here for convenient splats
    )

    $LastSlashIndex = $DirectoryPath.LastIndexOf('/')
    $StartIndex = $LastSlashIndex + 1
    $Name = $DirectoryPath.Substring($StartIndex, $DirectoryPath.Length - $StartIndex)
    if (-not $NameAllowList.ContainsKey($Name)) {
        return
    }
    $Parent = $DirectoryPath.Substring(0, $LastSlashIndex)
    $SchemaEntry = [System.DirectoryServices.DirectoryEntry]
    $objectSid = ConvertTo-SidByteArray -SidString $SID

    $Properties = @{
        Name            = $Name
        Description     = $Description
        objectSid       = $objectSid
        SchemaClassName = $SchemaClassName
    }

    $Object = [PSCustomObject]@{
        Name            = $Name
        Description     = $Description
        objectSid       = $objectSid
        SchemaClassName = $SchemaClassName
        Parent          = $Parent
        Path            = $DirectoryPath
        SchemaEntry     = $SchemaEntry
        Properties      = $Properties
    }

    Add-Member -InputObject $Object -Name RefreshCache -MemberType ScriptMethod -Value {}
    Add-Member -InputObject $Object -Name Invoke -MemberType ScriptMethod -Value {}
    return $Object

}
