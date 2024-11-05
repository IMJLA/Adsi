function Expand-AdsiGroupMember {
    <#
        .SYNOPSIS
        Use the LDAP provider to add information about group members to a DirectoryEntry of a group for easier access
        .DESCRIPTION
        Recursively retrieves group members and detailed information about them
        Specifically gets the SID, and resolves foreign security principals to their DirectoryEntry from the trusted domain
        .INPUTS
        [System.DirectoryServices.DirectoryEntry]$DirectoryEntry
        .OUTPUTS
        [System.DirectoryServices.DirectoryEntry] Returned with member info added now (if the DirectoryEntry is a group).
        .EXAMPLE
        [System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrators') | Get-AdsiGroupMember | Expand-AdsiGroupMember

        Need to fix example and add notes
    #>
    [OutputType([System.DirectoryServices.DirectoryEntry])]
    param (

        # Expecting a DirectoryEntry from the LDAP or WinNT providers, or a PSObject imitation from Get-DirectoryEntry
        [parameter(ValueFromPipeline)]
        $DirectoryEntry,

        # Properties of the group members to retrieve
        [string[]]$PropertiesToLoad = (@('Department', 'description', 'distinguishedName', 'grouptype', 'managedby', 'member', 'name', 'objectClass', 'objectSid', 'operatingSystem', 'primaryGroupToken', 'samAccountName', 'Title')),

        <#
        Hashtable containing cached directory entries so they don't need to be retrieved from the directory again

        Defaults to a thread-safe dictionary with string keys and object values
        #>
        [ref]$DirectoryEntryCache = ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [ref]$DomainsByNetbios = ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid,

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [ref]$DomainsByFqdn = ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()),

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
        [Parameter(Mandatory)]
        [ref]$LogBuffer,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug'

    )
    begin {

        $LogParams = @{
            ThisHostname = $ThisHostname
            Type         = $DebugOutputStream
            Buffer       = $LogBuffer
            WhoAmI       = $WhoAmI
        }

        $LoggingParams = @{
            ThisHostname = $ThisHostname
            LogBuffer    = $LogBuffer
            WhoAmI       = $WhoAmI
        }

        # The DomainsBySID cache must be populated with trusted domains in order to translate foreign security principals
        if ( $DomainsBySid.Keys.Count -lt 1 ) {
            Write-LogMsg @LogParams -Text '# No valid DomainsBySid cache found'
            $DomainsBySid = ([hashtable]::Synchronized(@{}))

            $GetAdsiServerParams = @{
                DirectoryEntryCache = $DirectoryEntryCache
                DomainsByNetbios    = $DomainsByNetbios
                DomainsBySid        = $DomainsBySid
                DomainsByFqdn       = $DomainsByFqdn
                ThisFqdn            = $ThisFqdn
                CimCache            = $CimCache
            }

            Get-TrustedDomain |
            ForEach-Object {
                Write-LogMsg @LogParams -Text "Get-AdsiServer -Fqdn $($_.DomainFqdn)"
                $null = Get-AdsiServer -Fqdn $_.DomainFqdn @GetAdsiServerParams @LoggingParams
            }
        } else {
            Write-LogMsg @LogParams -Text '# Valid DomainsBySid cache found'
        }

        $CacheParams = @{
            DirectoryEntryCache = $DirectoryEntryCache
            DomainsByNetbios    = $DomainsByNetbios
            DomainsBySid        = $DomainsBySid
        }

        $i = 0
    }

    process {

        ForEach ($Entry in $DirectoryEntry) {

            $i++

            #$status = ("$(Get-Date -Format s)`t$ThisHostname`tExpand-AdsiGroupMember`tStatus: Using ADSI to get info on group member $i`: " + $Entry.Name)
            #Write-LogMsg @LogParams -Text "$status"

            $Principal = $null

            if ($Entry.objectClass -contains 'foreignSecurityPrincipal') {

                if ($Entry.distinguishedName.Value -match '(?>^CN=)(?<SID>[^,]*)') {

                    [string]$SID = $Matches.SID

                    #The SID of the domain is the SID of the user minus the last block of numbers
                    $DomainSid = $SID.Substring(0, $Sid.LastIndexOf('-'))
                    $Domain = $null
                    $TryGetValueResult = $DomainsBySid.Value.TryGetValue($DomainSid, [ref]$Domain)

                    $GetDirectoryEntryParams = @{
                        ThisFqdn          = $ThisFqdn
                        CimCache          = $CimCache
                        DebugOutputStream = $DebugOutputStream
                    }

                    $Principal = Get-DirectoryEntry -DirectoryPath "LDAP://$($Domain.Dns)/<SID=$SID>" @GetDirectoryEntryParams @CacheParams @LoggingParams

                    try {
                        $null = $Principal.RefreshCache($PropertiesToLoad)
                    } catch {
                        #$Success = $false
                        $Principal = $Entry
                        Write-LogMsg @LogParams -Text " # SID '$SID' could not be retrieved from domain '$Domain'"
                    }

                    # Recursively enumerate group members
                    if ($Principal.properties['objectClass'].Value -contains 'group') {
                        Write-LogMsg @LogParams -Text "'$($Principal.properties['name'])' is a group in '$Domain'"
                        $AdsiGroupWithMembers = Get-AdsiGroupMember -Group $Principal -CimCache $CimCache -DomainsByFqdn $DomainsByFqdn -ThisFqdn $ThisFqdn @CacheParams @LoggingParams
                        $Principal = Expand-AdsiGroupMember -DirectoryEntry $AdsiGroupWithMembers.FullMembers -CimCache $CimCache -DomainsByFqdn $DomainsByFqdn -ThisFqdn $ThisFqdn -ThisHostName $ThisHostName @CacheParams

                    }

                }

            } else {
                $Principal = $Entry
            }

            Add-SidInfo -InputObject $Principal -DomainsBySid $DomainsBySid @LoggingParams

        }
    }

}
