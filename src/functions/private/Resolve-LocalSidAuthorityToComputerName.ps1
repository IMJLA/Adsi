function Resolve-LocalSidAuthorityToComputerName {

    param (

        # A DirectoryPath or IdentityReference
        [string]$InputObject,

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
        },

        # Computer name to use to replace the well-known local SID authorities in the InputObject string.
        [string]$ComputerName,

        # DirectoryEntry [System.DirectoryServices.DirectoryEntry] of the directory entry so its parent can be retrieved
        $DirectoryEntry

    )

    # Replace the well-known SID authorities with the computer name
    if ($AuthoritiesToReplaceWithParentName.ContainsKey($ComputerName)) {

        pause

        # This may be unnecessary.  See comments of the private function for details.
        $ParentName = Get-DirectoryEntryParentName -DirectoryEntry $DirectoryEntry

        return $InputObject.Replace($ComputerName, $ParentName)

    }
}
