function Get-KnownSidByName {
    <#
    .SYNOPSIS
        Creates a hashtable of well-known SIDs indexed by their friendly names.
    .DESCRIPTION
        This function takes a hashtable of well-known SIDs (indexed by SID) and
        transforms it into a new hashtable where the keys are the friendly names
        of the SIDs. This makes it easier to look up SID information when you
        know the name but not the SID itself.
    #>

    param (
        # Hashtable containing well-known SIDs as keys with their properties as values
        [hashtable]$WellKnownSIDBySID
    )

    $WellKnownSIDByName = @{}

    ForEach ($KnownSID in $WellKnownSIDBySID.Keys) {

        $Known = $WellKnownSIDBySID[$KnownSID]
        $WellKnownSIDByName[$Known.Name] = $Known

    }

    return $WellKnownSIDByName

}
