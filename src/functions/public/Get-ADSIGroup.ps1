function Get-ADSIGroup {
    <#
        .SYNOPSIS
        Get the directory entries for a group and its members using ADSI
        .DESCRIPTION
        Uses the ADSI components to search a directory for a group, then get its members
        Both the WinNT and LDAP providers are supported
        .INPUTS
        None.
        .OUTPUTS
        [System.DirectoryServices.DirectoryEntry] for each group memeber
        .EXAMPLE
        Get-ADSIGroup -DirectoryPath 'WinNT://WORKGROUP/localhost' -GroupName Administrators

        Get members of the local Administrators group
        .EXAMPLE
        Get-ADSIGroup -GroupName Administrators

        On a domain-joined computer, this will get members of the domain's Administrators group
        On a workgroup computer, this will get members of the local Administrators group
    #>
    [OutputType([System.DirectoryServices.DirectoryEntry])]

    param (

        <#
        Path to the directory object to retrieve
        Defaults to the root of the current domain
        #>
        [string]$DirectoryPath = (([System.DirectoryServices.DirectorySearcher]::new()).SearchRoot.Path),

        # Name (CN or Common Name) of the group to retrieve
        [string]$GroupName,

        # Properties of the group and its members to find in the directory
        <#
        [string[]]$PropertiesToLoad = @(
            'department',
            'description',
            'distinguishedName',
            'grouptype',
            'managedby',
            'member',
            'name',
            'objectClass',
            'objectSid',
            'operatingSystem',
            'samAccountName',
            'title'
        ),
        #>
        [string[]]$PropertiesToLoad,

        <#
        Hashtable containing cached directory entries so they don't have to be retrieved from the directory again
        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{}))

    )

    $GroupParams = @{
        DirectoryEntryCache = $DirectoryEntryCache
        DirectoryPath       = $DirectoryPath
        PropertiesToLoad    = $PropertiesToLoad
    }
    $GroupMemberParams = @{
        DirectoryEntryCache = $DirectoryEntryCache
        PropertiesToLoad    = $PropertiesToLoad
    }

    switch -Regex ($DirectoryPath) {
        '^WinNT' {
            $GroupParams['DirectoryPath'] = "$DirectoryPath/$GroupName"
            Get-DirectoryEntry @GroupParams |
            Get-WinNTGroupMember @GroupMemberParams
        }
        '^$' {
            # This is expected for a workgroup computer
            $GroupParams['DirectoryPath'] = "WinNT://localhost/$GroupName"
            Get-DirectoryEntry @GroupParams |
            Get-WinNTGroupMember @GroupMemberParams
        }
        default {
            if ($GroupName) {
                $GroupParams['Filter'] = "(&(objectClass=group)(cn=$GroupName))"
            } else {
                $GroupParams['Filter'] = "(objectClass=group)"
            }
            Search-Directory @GroupParams |
            Get-ADSIGroupMember @GroupMemberParams
        }
    }

}
