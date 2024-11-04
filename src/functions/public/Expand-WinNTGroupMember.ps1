function Expand-WinNTGroupMember {
    <#
        .SYNOPSIS
        Use the LDAP provider to add information about group members to a DirectoryEntry of a group for easier access
        .DESCRIPTION
        Recursively retrieves group members and detailed information about them
        .INPUTS
        [System.DirectoryServices.DirectoryEntry]$DirectoryEntry
        .OUTPUTS
        [System.DirectoryServices.DirectoryEntry] Returned with member info added now (if the DirectoryEntry is a group).
        .EXAMPLE
        [System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrators') | Get-WinNTGroupMember | Expand-WinNTGroupMember

        Need to fix example and add notes
    #>
    [OutputType([System.DirectoryServices.DirectoryEntry])]
    param (

        # Expecting a DirectoryEntry from the WinNT provider, or a PSObject imitation from Get-DirectoryEntry
        [Parameter(ValueFromPipeline)]
        $DirectoryEntry,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to a thread-safe dictionary with string keys and object values
        #>
        [ref]$DirectoryEntryCache = ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()),

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

    }

    process {

        ForEach ($ThisEntry in $DirectoryEntry) {

            if (!($ThisEntry.Properties)) {

                $LogParams['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
                Write-LogMsg @LogParams -Text " # '$ThisEntry' has no properties # For '$($ThisEntry.Path)'"
                $LogParams['Type'] = $DebugOutputStream

            } elseif ($ThisEntry.Properties['objectClass'] -contains 'group') {

                Write-LogMsg @LogParams -Text " # Is an ADSI group # For '$($ThisEntry.Path)'"
                $AdsiGroup = Get-AdsiGroup -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DirectoryPath $ThisEntry.Path -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LoggingParams
                Add-SidInfo -InputObject $AdsiGroup.FullMembers -DomainsBySid $DomainsBySid @LoggingParams

            } else {

                if ($ThisEntry.SchemaClassName -eq 'group') {

                    Write-LogMsg @LogParams -Text " # Is a WinNT group # For '$($ThisEntry.Path)'"

                    if ($ThisEntry.GetType().FullName -eq 'System.Collections.Hashtable') {

                        Write-LogMsg @LogParams -Text " # Is a special group with no direct memberships # '$($ThisEntry.Path)'"
                        Add-SidInfo -InputObject $ThisEntry -DomainsBySid $DomainsBySid @LoggingParams

                    } else {
                        # Commented while troubleshooting to avoid infinite loop. This line only seems necessary to handle nested WinNT groups; is that even possible?
                        # After commenting, it seems local group members are still being retrieved as expected.
                        #Get-WinNTGroupMember -DirectoryEntry $ThisEntry -CimCache $CimCache -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -ThisFqdn $ThisFqdn @LoggingParams
                    }

                } else {

                    Write-LogMsg @LogParams -Text " # Is a user account # For '$($ThisEntry.Path)'"
                    Add-SidInfo -InputObject $ThisEntry -DomainsBySid $DomainsBySid @LoggingParams

                }

            }

        }

    }

}
