function Resolve-IdRefSearchDir {

    [OutputType([string])]

    param (

        # IdentityReference from an Access Control Entry
        # Expecting either a SID (S-1-5-18) or an NT account name (CONTOSO\User)
        [Parameter(Mandatory)]
        [string]$IdentityReference,

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        [string]$Name,

        [string]$DomainDn,

        [hashtable]$Log,

        [hashtable]$LogThis

    )

    $SearchPath = Add-DomainFqdnToLdapPath -DirectoryPath "LDAP://$DomainDn" -ThisFqdn $ThisFqdn @LogThis

    $SearchParams = @{
        DirectoryPath    = $SearchPath
        Filter           = "(samaccountname=$Name)"
        PropertiesToLoad = @('objectClass', 'distinguishedName', 'name', 'grouptype', 'description', 'managedby', 'member', 'objectClass', 'Department', 'Title')
        ThisFqdn         = $ThisFqdn
    }

    try {
        $DirectoryEntry = Search-Directory @SearchParams @LogThis
    } catch {

        $Log['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
        Write-LogMsg @Log -Text "'$IdentityReference' could not be resolved against its directory. Error: $($_.Exception.Message)"
        $Log['Type'] = $LogThis['DebugOutputStream']

    }

    $DirectoryEntryWithSidInfo = Add-SidInfo -InputObject $DirectoryEntry @LogThis
    return $DirectoryEntryWithSidInfo.SidString

}
