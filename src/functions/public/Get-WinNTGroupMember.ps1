function Get-WinNTGroupMember {

    <#
        .SYNOPSIS
        Get members of a group from the WinNT provider
        .DESCRIPTION
        Get members of a group from the WinNT provider
        Convert them from COM objects into usable DirectoryEntry objects
        .INPUTS
        [System.DirectoryServices.DirectoryEntry]$DirectoryEntry
        .OUTPUTS
        [System.DirectoryServices.DirectoryEntry] for each group member
        .EXAMPLE
        [System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrators') | Get-WinNTGroupMember

        Get members of the local Administrators group
    #>

    [OutputType([System.DirectoryServices.DirectoryEntry])]

    param (

        # DirectoryEntry [System.DirectoryServices.DirectoryEntry] of the WinNT group whose members to get
        [Parameter(ValueFromPipeline)]
        $DirectoryEntry,

        # Properties of the group members to find in the directory
        [string[]]$PropertiesToLoad,

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

    begin {

        $Log = @{ ThisHostname = $ThisHostname ; Type = $DebugOutputStream ; Buffer = $Cache.Value['LogBuffer'] ; WhoAmI = $WhoAmI }
        $LogThis = @{ ThisHostname = $ThisHostname ; Cache = $Cache ; WhoAmI = $WhoAmI ; DebugOutputStream = $DebugOutputStream }

        # Add the bare minimum required properties (TODO: distinguished desirable but not mandatory properties e.g. Department)
        $PropertiesToLoad = $PropertiesToLoad + @(
            'Department',
            'description',
            'distinguishedName',
            'grouptype',
            'managedby',
            'member',
            'name',
            'objectClass',
            'objectSid',
            'operatingSystem',
            'primaryGroupToken',
            'samAccountName',
            'Title'
        )

        $PropertiesToLoad = $PropertiesToLoad |
        Sort-Object -Unique

        $GetSearch = @{ PropertiesToLoad = $PropertiesToLoad }

    }

    process {

        ForEach ($ThisDirEntry in $DirectoryEntry) {

            $LogSuffix = "# For '$($ThisDirEntry.Path)'"
            $Log['Suffix'] = " $LogSuffix"
            $ThisSplitPath = Split-DirectoryPath -DirectoryPath $ThisDirEntry.Path
            $SourceDomainNetbiosOrFqdn = $ThisSplitPath['Domain']
            Write-LogMsg @Log -Text "`$GroupDomain = Get-AdsiServer -Netbios '$SourceDomainNetbiosOrFqdn' -ThisFqdn '$ThisFqdn'" -Expand $LogThis -ExpandKeyMap @{ 'Cache' = '$Cache' }
            $GroupDomain = Get-AdsiServer -Netbios $SourceDomainNetbiosOrFqdn -ThisFqdn $ThisFqdn @LogThis

            if (-not $GroupDomain) {

                Write-LogMsg @Log -Text "`$GroupDomain = Get-AdsiServer -Fqdn '$SourceDomainNetbiosOrFqdn' -ThisFqdn '$ThisFqdn'" -Expand $LogThis -ExpandKeyMap @{ 'Cache' = '$Cache' }
                $GroupDomain = Get-AdsiServer -Fqdn $SourceDomainNetbiosOrFqdn -ThisFqdn $ThisFqdn @LogThis

            }

            if (
                $null -ne $ThisDirEntry.Properties['groupType'] -or
                $ThisDirEntry.schemaclassname -in @('group', 'SidTypeWellKnownGroup', 'SidTypeAlias')
            ) {

                Write-LogMsg @Log -Text "`$DirectoryMembers = Invoke-IADsGroupMembersMethod -DirectoryEntry `$ThisDirEntry"
                $DirectoryMembers = Invoke-IADsGroupMembersMethod -DirectoryEntry $ThisDirEntry
                #Write-LogMsg @Log -Text " # $(@($DirectoryMembers).Count) members found"

                $MembersToGet = @{
                    'WinNTMembers' = @()
                }

                Write-LogMsg @Log -Text "Find-WinNTGroupMember -ComObject `$DirectoryMembers -Out $MembersToGet -LogSuffix '$LogSuffix' -DirectoryEntry `$ThisDirEntry -GroupDomain `$GroupDomain -ThisFqdn '$ThisFqdn'" -Expand $LogThis -ExpandKeyMap @{ 'Cache' = '$Cache' }
                Find-WinNTGroupMember -ComObject $DirectoryMembers -Out $MembersToGet -LogSuffix $LogSuffix -DirectoryEntry $ThisDirEntry -GroupDomain $GroupDomain -ThisFqdn $ThisFqdn @LogThis

                # Get and Expand the directory entries for the WinNT group members
                ForEach ($ThisMember in $MembersToGet['WinNTMembers']) {

                    Write-LogMsg @Log -Text "`$MemberDirectoryEntry = Get-DirectoryEntry -DirectoryPath '$ThisMember' -ThisFqdn '$ThisFqdn'" -Expand $GetSearch, $LogThis -ExpandKeyMap @{ 'Cache' = '$Cache' }
                    $MemberDirectoryEntry = Get-DirectoryEntry -DirectoryPath $ThisMember -ThisFqdn $ThisFqdn @GetSearch @LogThis
                    Write-LogMsg @Log -Text "`$Expand-WinNTGroupMember = Get-DirectoryEntry -DirectoryEntry `$MemberDirectoryEntry -ThisFqdn '$ThisFqdn'" -Expand $LogThis -ExpandKeyMap @{ 'Cache' = '$Cache' }
                    Expand-WinNTGroupMember -DirectoryEntry $MemberDirectoryEntry -ThisFqdn $ThisFqdn @LogThis

                }

                # Remove the WinNTMembers key from the hashtable so the only remaining keys are distinguishedName(s) of LDAP directories
                $MembersToGet.Remove('WinNTMembers')

                # Get and Expand the directory entries for the LDAP group members
                ForEach ($MemberPath in $MembersToGet.Keys) {

                    $ThisMemberToGet = $MembersToGet[$MemberPath]
                    Write-LogMsg @Log -Text "`$MemberDirectoryEntries = Search-Directory -DirectoryPath '$MemberPath' -Filter '(|$ThisMemberToGet)' -ThisFqdn '$ThisFqdn'" -Expand $GetSearch, $LogThis @{ 'Cache' = '$Cache' }
                    $MemberDirectoryEntries = Search-Directory -DirectoryPath $MemberPath -Filter "(|$ThisMemberToGet)" -ThisFqdn $ThisFqdn @GetSearch @LogThis
                    Write-LogMsg @Log -Text "Expand-WinNTGroupMember -DirectoryEntry `$MemberDirectoryEntries -ThisFqdn '$ThisFqdn'" -Expand $LogThis -ExpandKeyMap @{ 'Cache' = '$Cache' }
                    Expand-WinNTGroupMember -DirectoryEntry $MemberDirectoryEntries -ThisFqdn $ThisFqdn @LogThis

                }

            } else {
                Write-LogMsg @Log -Text ' # Is not a group'
            }

        }

    }

}
