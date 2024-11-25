function Get-AdsiGroup {
    <#
        .SYNOPSIS
        Get the directory entries for a group and its members using ADSI
        .DESCRIPTION
        Uses the ADSI components to search a directory for a group, then get its members
        Both the WinNT and LDAP providers are supported
        .INPUTS
        None. Pipeline input is not accepted.
        .OUTPUTS
        [System.DirectoryServices.DirectoryEntry] for each group memeber
        .EXAMPLE
        Get-AdsiGroup -DirectoryPath 'WinNT://WORKGROUP/localhost' -GroupName Administrators

        Get members of the local Administrators group
        .EXAMPLE
        Get-AdsiGroup -GroupName Administrators

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

        # Properties of the group members to retrieve
        [string[]]$PropertiesToLoad = @('distinguishedName', 'groupType', 'member', 'name', 'objectClass', 'objectSid', 'primaryGroupToken', 'samAccountName'),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $Log = @{ ThisHostname = $ThisHostname ; Type = $DebugOutputStream ; Buffer = $Cache.Value['LogBuffer'] ; WhoAmI = $WhoAmI }
    $LogThis = @{ ThisHostname = $ThisHostname ; Cache = $Cache ; WhoAmI = $WhoAmI ; DebugOutputStream = $DebugOutputStream }

    $GroupParams = @{
        DirectoryPath    = $DirectoryPath
        PropertiesToLoad = $PropertiesToLoad
        ThisFqdn         = $ThisFqdn
    }

    $GroupMemberParams = @{
        PropertiesToLoad = $PropertiesToLoad
        ThisFqdn         = $ThisFqdn
    }

    # Add the bare minimum required properties
    $PropertiesToLoad = $PropertiesToLoad + @(
        'distinguishedName',
        'grouptype',
        'member',
        'name',
        'objectClass',
        'objectSid',
        'primaryGroupToken',
        'samAccountName'
    )

    $PropertiesToLoad = $PropertiesToLoad |
    Sort-Object -Unique

    switch -Regex ($DirectoryPath) {
        '^WinNT' {
            $GroupParams['DirectoryPath'] = "$DirectoryPath/$GroupName"
            Write-LogMsg -Text 'Get-DirectoryEntry' -Expand $GroupParams, $LogThis -ExpandKeyMap @{ 'Cache' = '$Cache' }
            $GroupMemberParams['DirectoryEntry'] = Get-DirectoryEntry @GroupParams @LogThis
            Write-LogMsg -Text 'Get-WinNTGroupMember' -Expand $GroupMemberParams, $LogThis -ExpandKeyMap @{ 'Cache' = '$Cache' }
            $FullMembers = Get-WinNTGroupMember @GroupMemberParams @LogThis
            break
        }
        '^$' {
            # This is expected for a workgroup computer
            $GroupParams['DirectoryPath'] = "WinNT://localhost/$GroupName"
            Write-LogMsg -Text 'Get-DirectoryEntry' -Expand $GroupParams, $LogThis -ExpandKeyMap @{ 'Cache' = '$Cache' }
            $GroupMemberParams['DirectoryEntry'] = Get-DirectoryEntry @GroupParams @LogThis
            Write-LogMsg -Text 'Get-WinNTGroupMember' -Expand $GroupMemberParams, $LogThis -ExpandKeyMap @{ 'Cache' = '$Cache' }
            $FullMembers = Get-WinNTGroupMember @GroupMemberParams @LogThis
            break
        }
        default {

            if ($GroupName) {
                $GroupParams['Filter'] = "(&(objectClass=group)(cn=$GroupName))"
            } else {
                $GroupParams['Filter'] = '(objectClass=group)'
            }

            Write-LogMsg -Text 'Search-Directory' -Expand $GroupParams, $LogThis -ExpandKeyMap @{ 'Cache' = '$Cache' }
            $GroupMemberParams['Group'] = Search-Directory @GroupParams @LogThis
            Write-LogMsg -Text 'Get-AdsiGroupMember' -Expand $GroupMemberParams, $LogThis -ExpandKeyMap @{ 'Cache' = '$Cache' }
            $FullMembers = Get-AdsiGroupMember @GroupMemberParams @LogThis

        }

    }

    return $FullMembers

}
