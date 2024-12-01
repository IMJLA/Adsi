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

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $DirectoryEntryParameters = @{ 'Cache' = $Cache }

    if ($Credential) {
        $DirectoryEntryParameters['Credential'] = $Credential
    }

    if (($null -eq $DirectoryPath -or '' -eq $DirectoryPath)) {

        $CimParams = @{
            'Cache'        = $Cache
            'ComputerName' = $Cache.Value['ThisFqdn'].Value
        }

        $Workgroup = (Get-CachedCimInstance -ClassName 'Win32_ComputerSystem' -KeyProperty 'Name' @CimParams).Workgroup
        $DirectoryPath = "WinNT://$Workgroup/$($Cache.Value['ThisHostName'].Value))"

    }

    Write-LogMsg -Text "Get-DirectoryEntry -DirectoryPath '$DirectoryPath' -Cache `$Cache" -Expand $DirectoryEntryParameters -ExpansionMap $Cache.Value['LogCacheMap'].Value
    $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath @DirectoryEntryParameters
    Write-LogMsg -Text "`$DirectorySearcher = [System.DirectoryServices.DirectorySearcher]::new(([System.DirectoryServices.DirectoryEntry]::new('$DirectoryPath')))" -Cache $Cache
    $DirectorySearcher = [System.DirectoryServices.DirectorySearcher]::new($DirectoryEntry)

    if ($Filter) {
        Write-LogMsg -Text "`$DirectorySearcher.Filter = '$Filter'" -Cache $Cache
        $DirectorySearcher.Filter = $Filter
    }

    Write-LogMsg -Text "`$DirectorySearcher.PageSize = '$PageSize'" -Cache $Cache
    $DirectorySearcher.PageSize = $PageSize
    Write-LogMsg -Text "`$DirectorySearcher.SearchScope = '$SearchScope'" -Cache $Cache
    $DirectorySearcher.SearchScope = $SearchScope
    Write-LogMsg -Text "`$DirectorySearcher.PropertiesToLoad.AddRange(@('$($PropertiesToLoad -join "','")'))" -Cache $Cache
    $null = $DirectorySearcher.PropertiesToLoad.AddRange($PropertiesToLoad)
    Write-LogMsg -Text "`$DirectorySearcher.FindAll()" -Cache $Cache
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
