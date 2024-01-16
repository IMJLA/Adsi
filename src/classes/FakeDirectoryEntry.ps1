class FakeDirectoryEntry {

    [string]$Name
    [string]$Parent
    [string]$Path
    [type]$SchemaEntry
    [byte[]]$objectSid
    [string]$Description
    [hashtable]$Properties
    [string]$SchemaClassName

    FakeDirectoryEntry (
        [string]$DirectoryPath
    ) {

        $LastSlashIndex = $DirectoryPath.LastIndexOf('/')
        $StartIndex = $LastSlashIndex + 1
        $This.Name = $DirectoryPath.Substring($StartIndex, $DirectoryPath.Length - $StartIndex)
        $This.Parent = $DirectoryPath.Substring(0, $LastSlashIndex)
        $This.Path = $DirectoryPath
        $This.SchemaEntry = [System.DirectoryServices.DirectoryEntry]
        switch -regex ($DirectoryPath) {

            'CREATOR OWNER$' {
                $This.objectSid = ConvertTo-SidByteArray -SidString 'S-1-3-0'
                $This.Description = 'A SID to be replaced by the SID of the user who creates a new object. This SID is used in inheritable ACEs.'
                $This.Properties = @{
                    Name        = $This.Name
                    Description = $This.Description
                    objectSid   = $This.objectSid
                }
                $This.SchemaClassName = 'user'
            }
            'SYSTEM$' {
                $This.objectSid = ConvertTo-SidByteArray -SidString 'S-1-5-18'
                $This.Description = 'By default, the SYSTEM account is granted Full Control permissions to all files on an NTFS volume'
                $This.Properties = @{
                    Name        = $This.Name
                    Description = $This.Description
                    objectSid   = $This.objectSid
                }
                $This.SchemaClassName = 'user'
            }
            'INTERACTIVE$' {
                $This.objectSid = ConvertTo-SidByteArray -SidString 'S-1-5-4'
                $This.Description = 'Users who log on for interactive operation. This is a group identifier added to the token of a process when it was logged on interactively.'
                $This.Properties = @{
                    Name        = $This.Name
                    Description = $This.Description
                    objectSid   = $This.objectSid
                }
                $This.SchemaClassName = 'group'
            }
            'Authenticated Users$' {
                $This.objectSid = ConvertTo-SidByteArray -SidString 'S-1-5-11'
                $This.Description = 'Any user who accesses the system through a sign-in process has the Authenticated Users identity.'
                $This.Properties = @{
                    Name        = $This.Name
                    Description = $This.Description
                    objectSid   = $This.objectSid
                }
                $This.SchemaClassName = 'group'
            }
            'TrustedInstaller$' {
                $This.objectSid = ConvertTo-SidByteArray -SidString 'S-1-5-11'
                $This.Description = 'Most of the operating system files are owned by the TrustedInstaller security identifier (SID)'
                $This.Properties = @{
                    Name        = $This.Name
                    Description = $This.Description
                    objectSid   = $This.objectSid
                }
                $This.SchemaClassName = 'user'
            }
        }
    }

    [void]RefreshCache([string[]]$Nonsense) {}
    [void]Invoke([string]$Nonsense) {}

}
