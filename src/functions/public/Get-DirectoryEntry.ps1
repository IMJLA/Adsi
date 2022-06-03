function Get-DirectoryEntry {
    <#
        .SYNOPSIS
        Use Active Directory Service Interfaces to retrieve an object from a directory
        .DESCRIPTION
        Retrieve a directory entry using either the WinNT or LDAP provider for ADSI
        .INPUTS
        None. Pipeline input is not accepted.
        .OUTPUTS
        System.DirectoryServices.DirectoryEntry where possible
        PSCustomObject for security principals with no directory entry
        .EXAMPLE
        Get-DirectoryEntry
        distinguishedName : {DC=ad,DC=contoso,DC=com}
        Path              : LDAP://DC=ad,DC=contoso,DC=com

        As the current user on a domain-joined computer, bind to the current domain and retrieve the DirectoryEntry for the root of the domain
        .EXAMPLE
        Get-DirectoryEntry
        distinguishedName :
        Path              : WinNT://ComputerName

        As the current user on a workgroup computer, bind to the local system and retrieve the DirectoryEntry for the root of the directory
    #>
    [OutputType([System.DirectoryServices.DirectoryEntry], [PSCustomObject])]
    [CmdletBinding()]
    param (

        <#
        Path to the directory object to retrieve
        Defaults to the root of the current domain
        #>
        [string]$DirectoryPath = (([System.DirectoryServices.DirectorySearcher]::new()).SearchRoot.Path),

        <#
        Credentials to use to bind to the directory
        Defaults to the credentials of the current user
        #>
        [pscredential]$Credential,

        # Properties of the target object to retrieve
        [string[]]$PropertiesToLoad,

        <#
        Hashtable containing cached directory entries so they don't have to be retrieved from the directory again
        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{}))

    )

    $DirectoryEntry = $null
    if ($null -eq $DirectoryEntryCache[$DirectoryPath]) {
        <#
        The WinNT provider only throws an error if you try to retrieve certain accounts/identities
        We will create own dummy objects instead of performing the query
        #>
        switch -regex ($DirectoryPath) {

            '^WinNT\:\/\/[^\/]*\/CREATOR OWNER$' {
                $SidByteAray = 'S-1-3-0' | ConvertTo-SidByteArray
                $DirectoryEntry = [PSCustomObject]@{
                    Name            = 'CREATOR OWNER'
                    Description     = 'A SID to be replaced by the SID of the user who creates a new object. This SID is used in inheritable ACEs.'
                    objectSid       = $SidByteAray
                    Parent          = $DirectoryPath | Split-Path -Parent
                    Path            = $DirectoryPath
                    Properties      = @{
                        Name        = 'CREATOR OWNER'
                        Description = 'A SID to be replaced by the SID of the user who creates a new object. This SID is used in inheritable ACEs.'
                        objectSid   = $SidByteAray
                    }
                    SchemaClassName = 'User'
                    SchemaEntry     = [System.DirectoryServices.DirectoryEntry]
                }
                $DirectoryEntry | Add-Member -MemberType ScriptMethod -Name RefreshCache -Force -Value {}

            }
            '^WinNT\:\/\/[^\/]*\/SYSTEM$' {
                $SidByteAray = 'S-1-5-18' | ConvertTo-SidByteArray
                $DirectoryEntry = [PSCustomObject]@{
                    Name            = 'SYSTEM'
                    Description     = 'By default, the SYSTEM account is granted Full Control permissions to all files on an NTFS volume'
                    objectSid       = $SidByteAray
                    Parent          = $DirectoryPath | Split-Path -Parent
                    Path            = $DirectoryPath
                    Properties      = @{
                        Name        = 'SYSTEM'
                        Description = 'By default, the SYSTEM account is granted Full Control permissions to all files on an NTFS volume'
                        objectSid   = $SidByteAray
                    }
                    SchemaClassName = 'User'
                    SchemaEntry     = [System.DirectoryServices.DirectoryEntry]
                }
                $DirectoryEntry | Add-Member -MemberType ScriptMethod -Name RefreshCache -Force -Value {}

            }
            '^WinNT\:\/\/[^\/]*\/INTERACTIVE$' {
                $SidByteAray = 'S-1-5-4' | ConvertTo-SidByteArray
                $DirectoryEntry = [PSCustomObject]@{
                    Name            = 'INTERACTIVE'
                    Description     = 'Users who log on for interactive operation. This is a group identifier added to the token of a process when it was logged on interactively.'
                    objectSid       = $SidByteAray
                    Parent          = $DirectoryPath | Split-Path -Parent
                    Path            = $DirectoryPath
                    Properties      = @{
                        Name        = 'INTERACTIVE'
                        Description = 'Users who log on for interactive operation. This is a group identifier added to the token of a process when it was logged on interactively.'
                        objectSid   = $SidByteAray
                    }
                    SchemaClassName = 'Group'
                    SchemaEntry     = [System.DirectoryServices.DirectoryEntry]
                }
                $DirectoryEntry | Add-Member -MemberType ScriptMethod -Name RefreshCache -Force -Value {}

            }
            '^WinNT\:\/\/[^\/]*\/Authenticated Users$' {
                $SidByteAray = 'S-1-5-11' | ConvertTo-SidByteArray
                $DirectoryEntry = [PSCustomObject]@{
                    Name            = 'Authenticated Users'
                    Description     = 'Any user who accesses the system through a sign-in process has the Authenticated Users identity.'
                    objectSid       = $SidByteAray
                    Parent          = $DirectoryPath | Split-Path -Parent
                    Path            = $DirectoryPath
                    Properties      = @{
                        Name        = 'Authenticated Users'
                        Description = 'Any user who accesses the system through a sign-in process has the Authenticated Users identity.'
                        objectSid   = $SidByteAray
                    }
                    SchemaClassName = 'Group'
                    SchemaEntry     = [System.DirectoryServices.DirectoryEntry]
                }
                $DirectoryEntry | Add-Member -MemberType ScriptMethod -Name RefreshCache -Force -Value {}
            }
            '^$' {
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-DirectoryEntry`t$(hostname) does not appear to be domain-joined since the SearchRoot Path is empty. Defaulting to WinNT provider for localhost instead."
                $Workgroup = (Get-CimInstance -ClassName Win32_ComputerSystem).Workgroup
                $DirectoryPath = "WinNT://$Workgroup/$(hostname)"
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-DirectoryEntry`t[System.DirectoryServices.DirectoryEntry]::new('$DirectoryPath')"
                if ($Credential) {
                    $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath, $($Credential.UserName), $($Credential.GetNetworkCredential().password))
                } else {
                    $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath)
                }

                $SampleUser = $DirectoryEntry.PSBase.Children |
                Where-Object -FilterScript { $_.schemaclassname -eq 'user' } |
                Select-Object -First 1 |
                Add-SidInfo

                $DirectoryEntry | Add-Member -MemberType NoteProperty -Name 'Domain' -Value $SampleUser.Domain -Force

            }
            default {

                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-DirectoryEntry`t[System.DirectoryServices.DirectoryEntry]::new('$DirectoryPath')"
                if ($Credential) {
                    $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath, $($Credential.UserName), $($Credential.GetNetworkCredential().password))
                } else {
                    $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath)
                }

            }

        }

        $DirectoryEntryCache[$DirectoryPath] = $DirectoryEntry
    } else {
        #Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-DirectoryEntry`tDirectoryEntryCache hit for '$DirectoryPath'"
        $DirectoryEntry = $DirectoryEntryCache[$DirectoryPath]
    }

    try {
        if ($PropertiesToLoad) {
            # If the $DirectoryPath was invalid, this line will return an error
            $null = $DirectoryEntry.RefreshCache($PropertiesToLoad)
        }

        Write-Output $DirectoryEntry
    } catch {
        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tGet-DirectoryEntry`t'$DirectoryPath' could not be retrieved."

        # Ensure that the error message appears on 1 line
        # Use .Trim() to remove leading and trailing whitespace
        # Use -replace to remove an errant line break in the following specific error I encountered: The following exception occurred while retrieving member "RefreshCache": "The group name could not be found.`r`n"
        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tGet-DirectoryEntry`t'$($_.Exception.Message.Trim() -replace '\s"',' "')"
    }

}
