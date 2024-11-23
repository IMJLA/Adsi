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
        $DomainSidRef = $Cache.Value['DomainBySid']
        $DomainBySid = $DomainSidRef.Value

        # The DomainBySid cache must be populated with trusted domains in order to translate foreign security principals
        if ( $DomainBySid.Keys.Count -lt 1 ) {

            Write-LogMsg @Log -Text '# No domains in the DomainBySid cache'

            ForEach ($TrustedDomain in (Get-TrustedDomain -Cache $Cache)) {
                #Write-LogMsg @Log -Text "Get-AdsiServer -Fqdn $($TrustedDomain.DomainFqdn)"
                $null = Get-AdsiServer -Fqdn $TrustedDomain.DomainFqdn -ThisFqdn $ThisFqdn @LogThis
            }

        } else {
            #Write-LogMsg @Log -Text '# Valid DomainBySid cache found'
        }

        $i = 0

    }

    process {

        ForEach ($Entry in $DirectoryEntry) {

            $i++
            $Principal = $null
            #Write-LogMsg @Log -Text "Status: Using ADSI to get info on group member $i`: $($Entry.Name)"

            if ($Entry.objectClass -contains 'foreignSecurityPrincipal') {

                if ($Entry.distinguishedName.Value -match '(?>^CN=)(?<SID>[^,]*)') {

                    #The SID of the domain is the SID of the user minus the last block of numbers
                    [string]$SID = $Matches.SID
                    $DomainSid = $SID.Substring(0, $Sid.LastIndexOf('-'))
                    $Domain = $null
                    $null = $DomainBySid.Value.TryGetValue($DomainSid, [ref]$Domain)
                    $Principal = Get-DirectoryEntry -DirectoryPath "LDAP://$($Domain.Dns)/<SID=$SID>" -ThisFqdn $ThisFqdn @LogThis

                    try {
                        $null = $Principal.RefreshCache($PropertiesToLoad)
                    } catch {

                        #$Success = $false
                        $Principal = $Entry
                        Write-LogMsg @Log -Text " # SID '$SID' could not be retrieved from domain '$Domain'"

                    }

                    # Recursively enumerate group members
                    if ($Principal.properties['objectClass'].Value -contains 'group') {

                        Write-LogMsg @Log -Text "'$($Principal.properties['name'])' is a group in '$Domain'"
                        $AdsiGroupWithMembers = Get-AdsiGroupMember -Group $Principal -ThisFqdn $ThisFqdn @LogThis
                        $Principal = Expand-AdsiGroupMember -DirectoryEntry $AdsiGroupWithMembers.FullMembers -ThisFqdn $ThisFqdn -ThisHostName $ThisHostName @LogThis

                    }

                }

            } else {
                $Principal = $Entry
            }

            Add-SidInfo -InputObject $Principal -DomainsBySid $DomainSidRef @LogThis

        }
    }

}
