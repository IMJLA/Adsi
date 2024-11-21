function Get-KnownSidByName {

    param (
        [hashtable]$WellKnownSIDBySID
    )

    $WellKnownSIDByName = @{}

    ForEach ($KnownSID in $WellKnownSIDBySID.Keys) {

        $Known = $WellKnownSIDBySID[$KnownSID]
        $WellKnownSIDByName[$Known.Name] = $Known

    }

    return $WellKnownSIDByName

}
