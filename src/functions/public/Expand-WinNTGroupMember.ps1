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
        Hashtable containing cached directory entries so they don't need to be retrieved from the directory again
        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{}))

    )
    begin {}
    process {
        ForEach ($ThisEntry in $DirectoryEntry) {

            if (!($ThisEntry.Properties)) {
                Write-Warning "'$ThisEntry' has no properties"
            } elseif ($ThisEntry.Properties['objectClass'] -contains 'group') {

                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-WinNTGroupMember`t'$($ThisEntry.Path)' is an ADSI group"
                (Get-AdsiGroup -DirectoryEntryCache $DirectoryEntryCache -DirectoryPath $ThisEntry.Path -DomainsByNetbios $DomainsByNetbios).FullMembers |
                Add-SidInfo -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios

            } else {

                if ($ThisEntry.SchemaClassName -contains 'group') {
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-WinNTGroupMember`t'$($ThisEntry.Path)' is a WinNT group"

                    if ($ThisEntry.GetType().FullName -eq 'System.Collections.Hashtable') {
                        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-WinNTGroupMember`t'$($ThisEntry.Path)' is a special group with no direct memberships"
                        $ThisEntry | Add-SidInfo -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios
                    } else {
                        Get-WinNTGroupMember -DirectoryEntry $ThisEntry -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios
                    }

                } else {
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-WinNTGroupMember`t'$($ThisEntry.Path)' is a user account"
                    $ThisEntry | Add-SidInfo -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios
                }

            }

        }
    }
    end {}
}
