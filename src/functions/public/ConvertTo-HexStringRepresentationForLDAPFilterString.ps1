function ConvertTo-HexStringRepresentationForLDAPFilterString {
    param (
        [byte[]]$SIDByteArray
    )
    $Hexes = $SIDByteArray |
        ForEach-Object {
            '{0:X}' -f $_
        } |
            ForEach-Object {
                if ($_.Length -eq 2) {
                    $_
                }
                else {
                    "0$_"
                }
            }
    "\$($Hexes -join '\')"
}