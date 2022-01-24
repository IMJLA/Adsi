function Search-Directory {
    param (
        
        [string]$DirectoryPath = (([adsisearcher]'').SearchRoot.Path),
        [string]$Filter,
        [int]$PageSize = 1000,
        [string[]]$PropertiesToLoad,
        [pscredential]$Credential,
        [string]$SearchScope = 'subtree',
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{}))

    )
    
    if ($Credential) {
        #$DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath,$($Credential.UserName),$($Credential.GetNetworkCredential().password))
        $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath -Credential $Credential -DirectoryEntryCache $DirectoryEntryCache
    }
    else {
        #$DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath)
        $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath -DirectoryEntryCache $DirectoryEntryCache
    }

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
    #$null = $DirectorySearcher.Dispose()
    #$null = $DirectoryEntry.Dispose()
    $Output = [System.DirectoryServices.SearchResult[]]::new($SearchResultCollection.Count)
    $SearchResultCollection.CopyTo($Output,0)
    #$null = $SearchResultCollection.Dispose()
    Write-Output $Output

}