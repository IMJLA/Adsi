function Resolve-IdRefSearchDir {

    [OutputType([string])]

    param (

        # IdentityReference from an Access Control Entry
        # Expecting either a SID (S-1-5-18) or an NT account name (CONTOSO\User)
        [Parameter(Mandatory)]
        [string]$IdentityReference,

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to a thread-safe dictionary with string keys and object values
        #>
        [ref]$DirectoryEntryCache = ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        [string]$Name,

        [string]$DomainDn,

        [hashtable]$LogThis,

        [hashtable]$Log

    )

    $SearchPath = Add-DomainFqdnToLdapPath -DirectoryPath "LDAP://$DomainDn" -ThisFqdn $ThisFqdn -CimCache $CimCache @LogThis

    $SearchParams = @{
        CimCache            = $CimCache
        DebugOutputStream   = $DebugOutputStream
        DirectoryEntryCache = $DirectoryEntryCache
        DirectoryPath       = $SearchPath
        DomainsByNetbios    = $DomainsByNetbios
        Filter              = "(samaccountname=$Name)"
        PropertiesToLoad    = @('objectClass', 'distinguishedName', 'name', 'grouptype', 'description', 'managedby', 'member', 'objectClass', 'Department', 'Title')
        ThisFqdn            = $ThisFqdn
    }

    try {
        $DirectoryEntry = Search-Directory @SearchParams @LogThis
    } catch {

        $Log['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
        Write-LogMsg @Log -Text "'$IdentityReference' could not be resolved against its directory. Error: $($_.Exception.Message)"
        $Log['Type'] = $DebugOutputStream

    }

    $DirectoryEntryWithSidInfo = Add-SidInfo -InputObject $DirectoryEntry -DomainsBySid $DomainsBySid @Log
    return $DirectoryEntryWithSidInfo.SidString

}
