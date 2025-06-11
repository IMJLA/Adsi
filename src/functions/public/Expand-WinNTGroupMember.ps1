function Expand-WinNTGroupMember {
    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Expand-WinNTGroupMember')]

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

    Retrieves the members of the local Administrators group and then expands each member by adding
    additional information such as SID, domain information, and group membership details if the member
    is itself a group. This provides a complete hierarchical view of permissions.
    #>

    [OutputType([System.DirectoryServices.DirectoryEntry])]

    param (

        # Expecting a DirectoryEntry from the WinNT provider, or a PSObject imitation from Get-DirectoryEntry
        [Parameter(ValueFromPipeline)]
        $DirectoryEntry,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache,

        # Properties of each Account to display on the report
        [string[]]$AccountProperty = @('DisplayName', 'Company', 'Department', 'Title', 'Description')

    )

    begin {

        $Log = @{ 'Cache' = $Cache }
        $DomainBySid = [ref]$Cache.Value['DomainBySid']

        # Add the bare minimum required properties
        $PropertiesToLoad = $AccountProperty + @(
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

        $AdsiGroupSplat = @{
            'Cache'            = $Cache
            'PropertiesToLoad' = $PropertiesToLoad
        }

    }

    process {

        ForEach ($ThisEntry in $DirectoryEntry) {

            $ThisPath = $ThisEntry.Path
            $AdsiGroupSplat['DirectoryPath'] = $ThisPath
            $Suffix = " # for DirectoryEntry '$ThisPath'"
            $Log['Suffix'] = $Suffix

            if ( -not $ThisEntry.Properties ) {

                $StartingLogType = $Cache.Value['LogType'].Value
                $Cache.Value['LogType'].Value = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
                Write-LogMsg @Log -Text " # '$ThisEntry' has no properties"
                $Cache.Value['LogType'].Value = $StartingLogType

            } elseif ($ThisEntry.Properties['objectClass'] -contains 'group') {

                $Log['Suffix'] = " # Is an ADSI group $Suffix"
                Write-LogMsg @Log -Text "`$AdsiGroup = Get-AdsiGroup" -Expand $AdsiGroupSplat -ExpansionMap $Cache.Value['LogCacheMap'].Value
                $AdsiGroup = Get-AdsiGroup @AdsiGroupSplat
                $Log['Suffix'] = " # for $(@($AdsiGroup.FullMembers).Count) members $Suffix"
                Write-LogMsg @Log -Text "Add-SidInfo -InputObject `$AdsiGroup.FullMembers -DomainsBySid [ref]`$Cache.Value['DomainBySid']"
                Add-SidInfo -InputObject $AdsiGroup.FullMembers -DomainsBySid $DomainBySid

            } else {

                if ($ThisEntry.SchemaClassName -eq 'group') {

                    #Write-LogMsg @Log -Text " # Is a WinNT group"

                    if ($ThisEntry.GetType().FullName -eq 'System.Collections.Hashtable') {

                        $Log['Suffix'] = " # Is a special group with no direct memberships $Suffix"
                        Write-LogMsg @Log -Text "Add-SidInfo -InputObject `$ThisEntry -DomainsBySid [ref]`$Cache.Value['DomainBySid']"
                        Add-SidInfo -InputObject $ThisEntry -DomainsBySid $DomainBySid

                    }

                } else {

                    $Log['Suffix'] = " # Is a user account $Suffix"
                    Write-LogMsg @Log -Text "Add-SidInfo -InputObject `$ThisEntry -DomainsBySid [ref]`$Cache.Value['DomainBySid']"
                    Add-SidInfo -InputObject $ThisEntry -DomainsBySid $DomainBySid

                }

            }

        }

    }

}
