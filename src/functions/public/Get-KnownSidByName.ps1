function Get-KnownSidByName {
    <#
    .SYNOPSIS
        Creates a hashtable of well-known SIDs indexed by their friendly names.
    .DESCRIPTION
        This function takes a hashtable of well-known SIDs (indexed by SID) and
        transforms it into a new hashtable where the keys are the friendly names
        of the SIDs. This makes it easier to look up SID information when you
        know the name but not the SID itself.
    .INPUTS
        System.Collections.Hashtable

        A hashtable containing SID strings as keys and information objects as values.
    .OUTPUTS
        System.Collections.Hashtable

        Returns a hashtable with friendly names as keys and SID information objects as values.
    .EXAMPLE
        $sidBySid = Get-KnownSidHashTable
        $sidByName = Get-KnownSidByName -WellKnownSIDBySID $sidBySid
        $administratorsInfo = $sidByName['Administrators']

        Creates a hashtable of well-known SIDs indexed by their friendly names and retrieves
        information about the Administrators group. This is useful when you need to look up
        SID information by name rather than by SID string.
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