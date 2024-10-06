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
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

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

        # Log messages which have not yet been written to disk
        [hashtable]$LogBuffer = ([hashtable]::Synchronized(@{})),

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug'

    )

    begin {

        $Log = @{
            ThisHostname = $ThisHostname
            Type         = $DebugOutputStream
            Buffer       = $LogBuffer
            WhoAmI       = $WhoAmI
        }

        $LogThis = @{
            ThisHostname = $ThisHostname
            LogBuffer    = $LogBuffer
            WhoAmI       = $WhoAmI
        }

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

        $MemberParams = @{
            DirectoryEntryCache = $DirectoryEntryCache
            DomainsByNetbios    = $DomainsByNetbios
            CimCache            = $CimCache
            ThisFqdn            = $ThisFqdn
        }

        $GetSearch = @{ PropertiesToLoad = $PropertiesToLoad }

        $ExpandParams = @{
            DomainsByFqdn = $DomainsByFqdn
            DomainsBySid  = $DomainsBySid
        }

    }

    process {

        ForEach ($ThisDirEntry in $DirectoryEntry) {

            $LogSuffix = "# For '$($ThisDirEntry.Path)'"
            $ThisSplitPath = Split-DirectoryPath -DirectoryPath $ThisDirEntry.Path
            $SourceDomain = $ThisSplitPath['Domain']

            if (
                $null -ne $ThisDirEntry.Properties['groupType'] -or
                $ThisDirEntry.schemaclassname -in @('group', 'SidTypeWellKnownGroup', 'SidTypeAlias')
            ) {

                $DirectoryMembers = Invoke-IADsGroupMembersMethod -DirectoryEntry $ThisDirEntry
                Write-LogMsg @Log -Text " # $(@($DirectoryMembers).Count) members found $LogSuffix"

                $MembersToGet = @{
                    'WinNTMembers' = @()
                }

                Find-WinNTGroupMember -ComObject $DirectoryMembers -Out $MembersToGet -LogSuffix $LogSuffix -DirectoryEntry $DirectoryEntry -SourceDomain $SourceDomain

                # Get and Expand the directory entries for the WinNT group members
                ForEach ($ThisMember in $MembersToGet['WinNTMembers']) {

                    Write-LogMsg @Log -Text "Get-DirectoryEntry -DirectoryPath '$ThisMember' $LogSuffix"
                    $MemberDirectoryEntry = Get-DirectoryEntry -DirectoryPath $ThisMember @GetSearch @MemberParams @LogThis
                    Expand-WinNTGroupMember -DirectoryEntry $MemberDirectoryEntry @MemberParams @ExpandParams @LogThis

                }

                # Remove the WinNTMembers key from the hashtable so the only remaining keys are distinguishedName(s) of LDAP directories
                $MembersToGet.Remove('WinNTMembers')

                # Get and Expand the directory entries for the LDAP group members
                ForEach ($MemberPath in $MembersToGet.Keys) {

                    $ThisMemberToGet = $MembersToGet[$MemberPath]
                    Write-LogMsg @Log -Text "Search-Directory -DirectoryPath '$MemberPath' -Filter '(|$ThisMemberToGet)' $LogSuffix"
                    $MemberDirectoryEntries = Search-Directory -DirectoryPath $MemberPath -Filter "(|$ThisMemberToGet)" @GetSearch @MemberParams @LogThis
                    Expand-WinNTGroupMember -DirectoryEntry $MemberDirectoryEntries @MemberParams @ExpandParams @LogThis

                }

            } else {
                Write-LogMsg @Log -Text " # Is not a group $LogSuffix"
            }

        }

    }

}
