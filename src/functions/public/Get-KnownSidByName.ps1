function Get-KnownSidByName {

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
