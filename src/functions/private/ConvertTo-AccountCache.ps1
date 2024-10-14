function ConvertTo-AccountCache {

    param (
        $Account,
        [hashtable]$SidCache = @{},
        [hashtable]$NameCache = @{}
    )

    ForEach ($ThisAccount in $Account) {
        $SidCache[$ThisAccount.SID] = $ThisAccount
        $NameCache[$ThisAccount.Name] = $ThisAccount
    }

}
