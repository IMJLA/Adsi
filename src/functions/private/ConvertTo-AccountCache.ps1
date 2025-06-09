function ConvertTo-AccountCache {

    param (
        $Account,
        [ref]$SidCache,
        [ref]$NameCache
    )

    ForEach ($ThisAccount in $Account) {
        $SidCache.Value[$ThisAccount.SID] = $ThisAccount
        $NameCache.Value[$ThisAccount.Name] = $ThisAccount
    }

}