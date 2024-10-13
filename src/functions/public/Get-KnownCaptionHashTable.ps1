function Get-KnownCaptionHashTable {

    param (
        [hashtable]$WellKnownSidBySid = (Get-KnownSidHashTable)
    )

    $WellKnownSidByCaption = @{}

    ForEach ($KnownSID in $WellKnownSidBySid.Keys) {

        $Known = $WellKnownSidBySid[$KnownSID]
        $WellKnownSidByCaption[$Known.NTAccount] = $Known

    }

    return $WellKnownSidByCaption

}
