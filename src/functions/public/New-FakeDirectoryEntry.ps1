function New-FakeDirectoryEntry {

    <#
    Used in place of a DirectoryEntry for certain WinNT security principals that do not have objects in the directory
    The WinNT provider only throws an error if you try to retrieve certain accounts/identities
    #>

    param (
        [string]$DirectoryPath,
        [string]$SID,
        [string]$Description,
        [string]$SchemaClassName
    )

    $LastSlashIndex = $DirectoryPath.LastIndexOf('/')
    $StartIndex = $LastSlashIndex + 1
    $Name = $DirectoryPath.Substring($StartIndex, $DirectoryPath.Length - $StartIndex)
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
