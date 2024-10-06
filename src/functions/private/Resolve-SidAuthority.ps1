function Resolve-SidAuthority {

    param (

        # A DirectoryPath which has been split on the / character then parsed into a dictionary of constituent components
        # Must have a Domain key
        [hashtable]$DirectorySplit,

        # DirectoryEntry [System.DirectoryServices.DirectoryEntry] object whose Parent's Name will be used as the replacement Authority.
        $DirectoryEntry,

        # Well-Known local SID authorities to replace with the computer name in the InputObject string.
        [hashtable]$AuthoritiesToReplaceWithParentName = @{
            'APPLICATION PACKAGE AUTHORITY' = $null
            'BUILTIN'                       = $null
            'CREATOR SID AUTHORITY'         = $null
            'LOCAL SID AUTHORITY'           = $null
            'Non-unique Authority'          = $null
            'NT AUTHORITY'                  = $null
            'NT SERVICE'                    = $null
            'NT VIRTUAL MACHINE'            = $null
            'NULL SID AUTHORITY'            = $null
            'WORLD SID AUTHORITY'           = $null
        }

    )

    $Domain = $DirectorySplit['Domain']

    # Replace the well-known SID authorities with the computer name
    if ($AuthoritiesToReplaceWithParentName.ContainsKey($Domain)) {

        # This function may be unnecessary.  See comments of the private function for details.
        $ParentName = Get-DirectoryEntryParentName -DirectoryEntry $DirectoryEntry
        $DirectorySplit['ResolvedDomain'] = $ParentName
        $DirectorySplit['ResolvedDirectoryPath'] = $DirectorySplit['DirectoryPath'].Replace($Domain, $ParentName)

    } else {

        $DirectorySplit['ResolvedDomain'] = $Domain
        $DirectorySplit['ResolvedDirectoryPath'] = $DirectorySplit['DirectoryPath']

    }

}
