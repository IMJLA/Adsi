function Resolve-IdRefSearchDir {

    [OutputType([string])]

    param (

        # IdentityReference from an Access Control Entry
        # Expecting either a SID (S-1-5-18) or an NT account name (CONTOSO\User)
        [Parameter(Mandatory)]
        [string]$IdentityReference,

        [string]$Name,

        [string]$DomainDn,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $SearchPath = Add-DomainFqdnToLdapPath -DirectoryPath "LDAP://$DomainDn" -Cache $Cache

    $SearchParams = @{
        'Cache'            = $Cache
        'DirectoryPath'    = $SearchPath
        'Filter'           = "(samaccountname=$Name)"
        'PropertiesToLoad' = $AccountProperty + @('objectClass', 'distinguishedName', 'name', 'grouptype', 'member', 'objectClass')
    }

    try {
        $DirectoryEntry = Search-Directory @SearchParams
    } catch {

        $Log['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
        Write-LogMsg -Text "'$IdentityReference' could not be resolved against its directory. Error: $($_.Exception.Message)" -Cache $Cache
        $Log['Type'] = $LogThis['DebugOutputStream']

    }

    $DirectoryEntryWithSidInfo = Add-SidInfo -InputObject $DirectoryEntry -DomainsBySid $LogThis['Cache'].Value['DomainBySid']
    return $DirectoryEntryWithSidInfo.SidString

}