function Search-Directory {
    <#
        .SYNOPSIS
        Use Active Directory Service Interfaces to search an LDAP directory
        .DESCRIPTION
        Find directory entries using the LDAP provider for ADSI (the WinNT provider does not support searching)
        Provides a wrapper around the [System.DirectoryServices.DirectorySearcher] class
        .INPUTS
        None. Pipeline input is not accepted.
        .OUTPUTS
        [System.DirectoryServices.DirectoryEntry]
        .EXAMPLE
        Search-Directory -Filter ''

        As the current user on a domain-joined computer, bind to the current domain and search for all directory entries matching the LDAP filter
    #>
    param (

        <#
        Path to the directory object to retrieve
        Defaults to the root of the current domain
        #>
        [string]$DirectoryPath = (([adsisearcher]'').SearchRoot.Path),

        # Filter for the LDAP search
        [string]$Filter,

        # Number of records per page of results
        [int]$PageSize = 1000,

        # Additional properties to return
        [string[]]$PropertiesToLoad,

        # Credentials to use
        [pscredential]$Credential,

        # Scope of the search
        [string]$SearchScope = 'subtree',

        <#
        Hashtable containing cached directory entries so they don't have to be retrieved from the directory again
        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{}))

    )

    $DirectoryEntryParameters = @{
        DirectoryEntryCache = $DirectoryEntryCache
    }

    if ($Credential) {
        $DirectoryEntryParameters['Credential'] = $Credential
    }

    if (($null -eq $DirectoryPath -or '' -eq $DirectoryPath)) {
        $Workgroup = (Get-CimInstance -ClassName Win32_ComputerSystem).Workgroup
        $DirectoryPath = "WinNT://$Workgroup/$(hostname)"
    }
    $DirectoryEntryParameters['DirectoryPath'] = $DirectoryPath

    $DirectoryEntry = Get-DirectoryEntry @DirectoryEntryParameters

    $DirectorySearcher = [System.DirectoryServices.DirectorySearcher]::new($DirectoryEntry)

    if ($Filter) {
        $DirectorySearcher.Filter = $Filter
    }

    $DirectorySearcher.PageSize = $PageSize
    $DirectorySearcher.SearchScope = $SearchScope

    ForEach ($Property in $PropertiesToLoad) {
        $null = $DirectorySearcher.PropertiesToLoad.Add($Property)
    }

    $SearchResultCollection = $DirectorySearcher.FindAll()
    # TODO: Fix this.  Problems in integration testing trying to use the objects later if I dispose them here now.
    # Error: Cannot access a disposed object.
    #$null = $DirectorySearcher.Dispose()
    #$null = $DirectoryEntry.Dispose()
    $Output = [System.DirectoryServices.SearchResult[]]::new($SearchResultCollection.Count)
    $SearchResultCollection.CopyTo($Output, 0)
    #$null = $SearchResultCollection.Dispose()
    return $Output

}
