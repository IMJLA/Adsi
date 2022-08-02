function Add-Win32AccountToCache {
    param (
        [hashtable]$SidCache,

        [hashtable]$CaptionCache,

        [hashtable]$AdsiServerCache
    )

    ForEach ($ThisKey in $AdsiServerCache.Keys) {
        $AdsiServer = $AdsiServerCache[$ThisKey]
        ForEach ($ThisSubkey in $AdsiServer.WellKnownSIDs.Keys) {
            $ThisValue = $AdsiServer.WellKnownSIDs[$ThisSubkey]
            $Win32AccountsBySID["$($ThisValue.Domain)\$($ThisValue.SID)"] = $ThisValue
            $Win32AccountsByCaption["$($ThisValue.Domain)\$($ThisValue.Caption)"] = $ThisValue
        }
    }
}
