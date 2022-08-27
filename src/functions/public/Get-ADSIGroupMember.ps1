function Get-AdsiGroupMember {
    <#
        .SYNOPSIS
        Get members of a group from the LDAP provider
        .DESCRIPTION
        Use ADSI to get members of a group from the LDAP provider
        Return the group's DirectoryEntry plus a FullMembers property containing the member DirectoryEntries
        .INPUTS
        [System.DirectoryServices.DirectoryEntry]$DirectoryEntry
        .OUTPUTS
        [System.DirectoryServices.DirectoryEntry] plus a FullMembers property
        .EXAMPLE
        [System.DirectoryServices.DirectoryEntry]::new('LDAP://ad.contoso.com/CN=Administrators,CN=BuiltIn,DC=ad,DC=contoso,DC=com') | Get-AdsiGroupMember

        Get members of the domain Administrators group
    #>
    [OutputType([System.DirectoryServices.DirectoryEntry])]
    param (

        # Directory entry of the LDAP group whose members to get
        [Parameter(ValueFromPipeline)]
        $Group,

        # Properties of the group members to find in the directory
        [string[]]$PropertiesToLoad,

        <#
        Hashtable containing cached directory entries so they don't have to be retrieved from the directory again
        Uses a thread-safe hashtable by default
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

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages

    )
    begin {

        $LogParams = @{
            ThisHostname = $ThisHostname
            Type         = 'Debug'
            LogMsgCache  = $LogMsgCache
            WhoAmI       = $WhoAmI
        }

        $LoggingParams = @{
            ThisHostname = $ThisHostname
            LogMsgCache  = $LogMsgCache
            WhoAmI       = $WhoAmI
        }

        $PathRegEx = '(?<Path>LDAP:\/\/[^\/]*)'
        $DomainRegEx = '(?i)DC=\w{1,}?\b'

        $SearchParameters = @{
            PropertiesToLoad    = $PropertiesToLoad
            DirectoryEntryCache = $DirectoryEntryCache
            DomainsByNetbios    = $DomainsByNetbios
        }

    }
    process {

        foreach ($ThisGroup in $Group) {

            # Recursive search
            $SearchParameters['Filter'] = "(memberof:1.2.840.113556.1.4.1941:=$($ThisGroup.Properties['distinguishedname']))"

            # Non-recursive search
            #$SearchParameters['Filter'] = "(memberof=$($ThisGroup.Properties['distinguishedname']))"

            if ($ThisGroup.Path -match $PathRegEx) {

                $SearchParameters['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath $Matches.Path -ThisFqdn $ThisFqdn @LoggingParams

                if ($ThisGroup.Path -match $DomainRegEx) {
                    $Domain = ([regex]::Matches($ThisGroup.Path, $DomainRegEx) | ForEach-Object { $_.Value }) -join ','
                    $SearchParameters['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath "LDAP://$Domain" -ThisFqdn $ThisFqdn @LoggingParams
                } else {
                    $SearchParameters['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath $ThisGroup.Path -ThisFqdn $ThisFqdn @LoggingParams
                }

            } else {
                $SearchParameters['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath $ThisGroup.Path -ThisFqdn $ThisFqdn @LoggingParams
            }

            #Write-LogMsg @LogParams -Text "$($SearchParameters['Filter'])"

            $GroupMemberSearch = Search-Directory @SearchParameters

            if ($GroupMemberSearch.Count -gt 0) {

                $CurrentADGroupMembers = $GroupMemberSearch | ForEach-Object {
                    $FQDNPath = Add-DomainFqdnToLdapPath -DirectoryPath $_.Path -ThisFqdn $ThisFqdn @LoggingParams
                    Get-DirectoryEntry -DirectoryPath $FQDNPath -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid @LoggingParams
                }

            } else {
                $CurrentADGroupMembers = $null
            }

            Write-LogMsg @LogParams -Text "$($ThisGroup.Properties.name) has $(($CurrentADGroupMembers | Measure-Object).Count) members"

            $ProcessedGroupMembers = Expand-AdsiGroupMember -DirectoryEntry $CurrentADGroupMembers -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsBySid $DomainsBySid -DomainsByNetbios $DomainsByNetbios -ThisFqdn $ThisFqdn @LoggingParams

            Add-Member -InputObject $ThisGroup -MemberType NoteProperty -Name FullMembers -Value $ProcessedGroupMembers -Force -PassThru

        }
    }
    end {}
}
