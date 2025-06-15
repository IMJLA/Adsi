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
    [System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrators') |
    Get-AdsiGroupMember |
    Expand-AdsiGroupMember

    Retrieves the members of the local Administrators group and then expands each member with additional
    information such as SID and domain information. Foreign security principals from trusted domains are
    resolved to their actual DirectoryEntry objects from the appropriate domain.
    .EXAMPLE
    [System.DirectoryServices.DirectoryEntry]::new('LDAP://ad.contoso.com/CN=Administrators,CN=BuiltIn,DC=ad,DC=contoso,DC=com') |
    Get-AdsiGroupMember |
    Expand-AdsiGroupMember -Cache $Cache

    Retrieves the members of the domain Administrators group and then expands each member with additional
    information such as SID and domain information. Foreign security principals from trusted domains are
    resolved to their actual DirectoryEntry objects from the appropriate domain.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Expand-AdsiGroupMember')]
    [OutputType([System.DirectoryServices.DirectoryEntry])]

    param (

        # Expecting a DirectoryEntry from the LDAP or WinNT providers, or a PSObject imitation from Get-DirectoryEntry
        [parameter(ValueFromPipeline)]
        $DirectoryEntry,

        # Properties of the group members to retrieve
        [string[]]$PropertiesToLoad = @('distinguishedName', 'groupType', 'member', 'name', 'objectClass', 'objectSid', 'primaryGroupToken', 'samAccountName'),

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    begin {

        $Log = @{ Cache = $Cache }
        $DomainSidRef = $Cache.Value['DomainBySid']
        $DomainBySid = $DomainSidRef.Value

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

        # The DomainBySid cache must be populated with trusted domains in order to translate foreign security principals
        if ( $DomainBySid.Keys.Count -lt 1 ) {

            Write-LogMsg @Log -Text '# No domains in the DomainBySid cache'

            ForEach ($TrustedDomain in (Get-TrustedDomain -Cache $Cache)) {
                #Write-LogMsg @Log -Text "Get-AdsiServer -Fqdn $($TrustedDomain.DomainFqdn)"
                $null = Get-AdsiServer -Fqdn $TrustedDomain.DomainFqdn -Cache $Cache
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
            $Suffix = " # for DirectoryEntry with path '$($Entry.Path)'"
            $Log['Suffix'] = $Suffix
            #Write-LogMsg @Log -Text "Status: Using ADSI to get info on group member $i`: $($Entry.Name)"

            if ($Entry.objectClass -contains 'foreignSecurityPrincipal') {

                if ($Entry.distinguishedName.Value -match '(?>^CN=)(?<SID>[^,]*)') {

                    #The SID of the domain is the SID of the user minus the last block of numbers
                    [string]$SID = $Matches.SID
                    $DomainSid = $SID.Substring(0, $Sid.LastIndexOf('-'))
                    $Domain = $null
                    $null = $DomainBySid.Value.TryGetValue($DomainSid, [ref]$Domain)
                    $Log['Suffix'] = " # foreignSecurityPrincipal's distinguishedName points to a SID $Suffix"
                    $DirectoryPath = "LDAP://$($Domain.Dns)/<SID=$SID>"
                    Write-LogMsg @Log -Text "`$Principal = Get-DirectoryEntry -DirectoryPath '$DirectoryPath' -Cache `$Cache"
                    $Principal = Get-DirectoryEntry -DirectoryPath $DirectoryPath -Cache $Cache

                    try {

                        Write-LogMsg @Log -Text "`$Principal.RefreshCache('$($PropertiesToLoad -join "','")')"
                        $null = $Principal.RefreshCache($PropertiesToLoad)

                    } catch {

                        $Principal = $Entry
                        Write-LogMsg @Log -Text " # SID '$SID' could not be retrieved from domain '$Domain'"

                    }

                    # Recursively enumerate group members
                    if ($Principal.properties['objectClass'].Value -contains 'group') {

                        $Log['Suffix'] = " # '$($Principal.properties['name'])' is a group in '$Domain' $Suffix"
                        Write-LogMsg @Log -Text "`$AdsiGroupWithMembers = Get-AdsiGroupMember -Group `$Principal -PropertiesToLoad @('$($PropertiesToLoad -join "','")') -Cache `$Cache"
                        $AdsiGroupWithMembers = Get-AdsiGroupMember -Group $Principal -PropertiesToLoad $PropertiesToLoad -Cache $Cache
                        $Log['Suffix'] = " # for $(@($AdsiGroupWithMembers.FullMembers).Count) members $Suffix"
                        Write-LogMsg @Log -Text "`$Principal = Expand-AdsiGroupMember -DirectoryEntry `$AdsiGroupWithMembers.FullMembers -PropertiesToLoad @('$($PropertiesToLoad -join "','")') -Cache `$Cache"
                        $Principal = Expand-AdsiGroupMember -DirectoryEntry $AdsiGroupWithMembers.FullMembers -PropertiesToLoad $PropertiesToLoad -Cache $Cache

                    }

                }

            } else {
                $Principal = $Entry
            }

            Write-LogMsg @Log -Text "Add-SidInfo -InputObject `$Principal -DomainsBySid [ref]`$Cache.Value['DomainBySid']"
            Add-SidInfo -InputObject $Principal -DomainsBySid $DomainSidRef

        }

    }

}
