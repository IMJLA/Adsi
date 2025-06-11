function ConvertTo-AccountCache {
    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertTo-AccountCache')]

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
