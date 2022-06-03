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

    #$DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath,$($Credential.UserName),$($Credential.GetNetworkCredential().password))
    #$DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath)
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
    #$null = $DirectorySearcher.Dispose()
    #$null = $DirectoryEntry.Dispose()
    $Output = [System.DirectoryServices.SearchResult[]]::new($SearchResultCollection.Count)
    $SearchResultCollection.CopyTo($Output, 0)
    #$null = $SearchResultCollection.Dispose()
    Write-Output $Output

}
