function ConvertTo-AccountCache {

    param (
        $Account,
        [hashtable]$SidCache = @{},
        [hashtable]$NameCache = @{}
    )

    ForEach ($ThisAccount in $Account) {
        $SidCache[$Account.SID] = $ThisAccount
        $NameCache[$Account.Name] = $ThisAccount
    }

}
