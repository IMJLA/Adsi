function New-FakeDirectoryEntry {

    <#
    Used in place of a DirectoryEntry for certain WinNT security principals that do not have objects in the directory
    The WinNT provider only throws an error if you try to retrieve certain accounts/identities
    #>
    
    param (
        [string]$DirectoryPath
    )

    $LastSlashIndex = $DirectoryPath.LastIndexOf('/')
    $StartIndex = $LastSlashIndex + 1
    $Name = $DirectoryPath.Substring($StartIndex, $DirectoryPath.Length - $StartIndex)
    $Parent = $DirectoryPath.Substring(0, $LastSlashIndex)
    $Path = $DirectoryPath
    $SchemaEntry = [System.DirectoryServices.DirectoryEntry]
    switch -regex ($DirectoryPath) {

        'CREATOR OWNER$' {
            $objectSid = ConvertTo-SidByteArray -SidString 'S-1-3-0'
            $Description = 'A SID to be replaced by the SID of the user who creates a new object. This SID is used in inheritable ACEs.'
            $SchemaClassName = 'user'
        }
        'SYSTEM$' {
            $objectSid = ConvertTo-SidByteArray -SidString 'S-1-5-18'
            $Description = 'By default, the SYSTEM account is granted Full Control permissions to all files on an NTFS volume'
            $SchemaClassName = 'user'
        }
        'INTERACTIVE$' {
            $objectSid = ConvertTo-SidByteArray -SidString 'S-1-5-4'
            $Description = 'Users who log on for interactive operation. This is a group identifier added to the token of a process when it was logged on interactively.'
            $SchemaClassName = 'group'
        }
        'Authenticated Users$' {
            $objectSid = ConvertTo-SidByteArray -SidString 'S-1-5-11'
            $Description = 'Any user who accesses the system through a sign-in process has the Authenticated Users identity.'
            $SchemaClassName = 'group'
        }
        'TrustedInstaller$' {
            $objectSid = ConvertTo-SidByteArray -SidString 'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'
            $Description = 'Most of the operating system files are owned by the TrustedInstaller security identifier (SID)'
            $SchemaClassName = 'user'
        }
        'ALL APPLICATION PACKAGES$' {
            $objectSid = ConvertTo-SidByteArray -SidString 'S-1-15-2-1'
            $Description = 'All applications running in an app package context. SECURITY_BUILTIN_PACKAGE_ANY_PACKAGE'
            $SchemaClassName = 'group'
        }
        'ALL RESTRICTED APPLICATION PACKAGES$' {
            $objectSid = ConvertTo-SidByteArray -SidString 'S-1-15-2-2'
            $Description = 'SECURITY_BUILTIN_PACKAGE_ANY_RESTRICTED_PACKAGE'
            $SchemaClassName = 'group'
        }
        'Everyone$' {
            $objectSid = ConvertTo-SidByteArray -SidString 'S-1-1-0'
            $Description = "A group that includes all users; aka 'World'."
            $SchemaClassName = 'group'
        }
        'LOCAL SERVICE$' {
            $objectSid = ConvertTo-SidByteArray -SidString 'S-1-5-19'
            $Description = 'A local service account'
            $SchemaClassName = 'user'
        }
        'NETWORK SERVICE$' {
            $objectSid = ConvertTo-SidByteArray -SidString 'S-1-5-20'
            $Description = 'A network service account'
            $SchemaClassName = 'user'
        }
    }

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
        Path            = $Path
        SchemaEntry     = $SchemaEntry
        Properties      = $Properties
    }
    Add-Member -InputObject $Object -Name RefreshCache -MemberType ScriptMethod -Value {}
    Add-Member -InputObject $Object -Name Invoke -MemberType ScriptMethod -Value {}
    return $Object

}
