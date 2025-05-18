function Get-KnownCaptionHashTable {

    param (
        # Hashtable of well-known Security Identifiers (SIDs) with their properties
        [hashtable]$WellKnownSidBySid = (Get-KnownSidHashTable)
    )

    $WellKnownSidByCaption = @{}

    ForEach ($KnownSID in $WellKnownSidBySid.Keys) {

        $Known = $WellKnownSidBySid[$KnownSID]
        $WellKnownSidByCaption[$Known.NTAccount] = $Known

    }

    return $WellKnownSidByCaption

}
