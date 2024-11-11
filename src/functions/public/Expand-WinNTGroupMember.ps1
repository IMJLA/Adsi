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
        $DomainBySid = [ref]$Cache.Value['DomainBySid']

    }

    process {

        ForEach ($ThisEntry in $DirectoryEntry) {

            if (!($ThisEntry.Properties)) {

                $Log['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
                Write-LogMsg @Log -Text " # '$ThisEntry' has no properties # For '$($ThisEntry.Path)'"
                $Log['Type'] = $DebugOutputStream

            } elseif ($ThisEntry.Properties['objectClass'] -contains 'group') {

                Write-LogMsg @Log -Text " # Is an ADSI group # For '$($ThisEntry.Path)'"
                $AdsiGroup = Get-AdsiGroup -DirectoryPath $ThisEntry.Path -ThisFqdn $ThisFqdn @LogThis
                Add-SidInfo -InputObject $AdsiGroup.FullMembers -DomainsBySid $DomainBySid

            } else {

                if ($ThisEntry.SchemaClassName -eq 'group') {

                    Write-LogMsg @Log -Text " # Is a WinNT group # For '$($ThisEntry.Path)'"

                    if ($ThisEntry.GetType().FullName -eq 'System.Collections.Hashtable') {

                        Write-LogMsg @Log -Text " # Is a special group with no direct memberships # '$($ThisEntry.Path)'"
                        Add-SidInfo -InputObject $ThisEntry -DomainsBySid $DomainBySid

                    }

                } else {

                    Write-LogMsg @Log -Text " # Is a user account # For '$($ThisEntry.Path)'"
                    Add-SidInfo -InputObject $ThisEntry -DomainsBySid $DomainBySid

                }

            }

        }

    }

}
