function ConvertTo-HexStringRepresentation {
    param (
        [byte[]]$SIDByteArray
    )
    $SIDByteArray |
    ForEach-Object {
        '{0:X}' -f $_
    }
}
