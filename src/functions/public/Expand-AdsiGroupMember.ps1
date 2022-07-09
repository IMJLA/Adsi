function Expand-AdsiGroupMember {
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
        [System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrators') | Get-AdsiGroupMember | Expand-AdsiGroupMember

        Need to fix example and add notes
    #>
    [OutputType([System.DirectoryServices.DirectoryEntry])]
    param (

        # Expecting a DirectoryEntry from the LDAP or WinNT providers, or a PSObject imitation from Get-DirectoryEntry
        [parameter(ValueFromPipeline)]
        $DirectoryEntry,

        # Properties of the group members to retrieve
        [string[]]$PropertiesToLoad = @('operatingSystem', 'objectSid', 'samAccountName', 'objectClass', 'distinguishedName', 'name', 'grouptype', 'description', 'managedby', 'member', 'objectClass', 'Department', 'Title'),

        <#
        Hashtable containing cached directory entries so they don't need to be retrieved from the directory again
        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable containing known domain SIDs as the keys and their names as the values
        $TrustedDomainSidNameMap = (Get-TrustedDomainSidNameMap -DirectoryEntryCache $DirectoryEntryCache)

    )

    begin {
        $i = 0
    }

    process {

        ForEach ($Entry in $DirectoryEntry) {

            $i++

            #$status = ("$(Get-Date -Format s)`t$(hostname)`tExpand-AdsiGroupMember`tStatus: Using ADSI to get info on group member $i`: " + $Entry.Name)
            #Write-Debug "  $status"

            $Principal = $null

            if ($Entry.objectClass -contains 'foreignSecurityPrincipal') {

                if ($Entry.distinguishedName.Value -match '(?>^CN=)(?<SID>[^,]*)') {

                    [string]$SID = $Matches.SID

                    #The SID of the domain is the SID of the user minus the last block of numbers
                    $DomainSid = $SID.Substring(0, $Sid.LastIndexOf("-"))
                    $Domain = $TrustedDomainSidNameMap[$DomainSid]

                    #$Success = $true
                    #try {
                    $Principal = Get-DirectoryEntry -DirectoryPath "LDAP://$($Domain.Dns)/<SID=$SID>" -DirectoryEntryCache $DirectoryEntryCache
                    #} catch {
                    #    $Success = $false
                    #    $Principal = $Entry
                    #    Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-AdsiGroupMember`t$SID could not be retrieved from $Domain"
                    #}

                    #if ($Success -eq $true) {

                    try {
                        $null = $Principal.RefreshCache($PropertiesToLoad)
                    } catch {
                        #$Success = $false
                        $Principal = $Entry
                        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-AdsiGroupMember`t$SID could not be retrieved from $Domain"
                    }

                    # Recursively enumerate group members
                    if ($Principal.properties['objectClass'].Value -contains 'group') {
                        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-AdsiGroupMember`t'$($Principal.properties['name'])' is a group in $Domain"
                        $Principal = ($Principal | Get-AdsiGroupMember -DirectoryEntryCache $DirectoryEntryCache).FullMembers | Expand-AdsiGroupMember -DirectoryEntryCache $DirectoryEntryCache -TrustedDomainSidNameMap $TrustedDomainSidNameMap

                    }

                    #}

                }

            } else {
                $Principal = $Entry
            }

            $Principal | Add-SidInfo -DirectoryEntryCache $DirectoryEntryCache -TrustedDomainSidNameMap $TrustedDomainSidNameMap

        }
    }

}
