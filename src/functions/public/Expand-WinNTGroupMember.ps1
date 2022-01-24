function Expand-WinNTGroupMember {

    param (

        [Parameter(ValueFromPipeline)]
        $DirectoryEntry,

        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{}))

    )
    begin{}
    process {
        ForEach ($ThisEntry in $DirectoryEntry) {

            if (!($ThisEntry.Properties)) {
                Write-Warning "'$ThisEntry' has no properties"
            }            
            elseif ($ThisEntry.Properties['objectClass'] -contains 'group') {

                    Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-WinNTGroupMember`t$($ThisEntry.Path) is a group"

                    (Get-ADSIGroup -DirectoryEntryCache $DirectoryEntryCache -DirectoryPath $ThisEntry.Path).FullMembers |
                        Add-SidInfo -DirectoryEntryCache $DirectoryEntryCache
                         
            }
            else {

                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-WinNTGroupMember`t'$($ThisEntry.Path) is an account"
                $ThisEntry | Add-SidInfo -DirectoryEntryCache $DirectoryEntryCache

            }
            
        }
    }
    end{}
}