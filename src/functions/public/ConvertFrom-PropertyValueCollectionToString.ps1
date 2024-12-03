function ConvertFrom-PropertyValueCollectionToString {

    <#
    .SYNOPSIS
    Convert a PropertyValueCollection to a string
    .DESCRIPTION
    Useful when working with System.DirectoryServices and some other namespaces
    .INPUTS
    None. Pipeline input is not accepted.
    .OUTPUTS
    [System.String]
    .EXAMPLE
    $DirectoryEntry = [adsi]("WinNT://$(hostname)")
    $DirectoryEntry.Properties.Keys |
    ForEach-Object {
        ConvertFrom-PropertyValueCollectionToString -PropertyValueCollection $DirectoryEntry.Properties[$_]
    }

    For each property in a DirectoryEntry, convert its corresponding PropertyValueCollection to a string
    #>

    param (

        # This PropertyValueCollection will be converted to a string
        [System.DirectoryServices.PropertyValueCollection]$PropertyValueCollection

    )

    if ($null -ne $PropertyValueCollection.Value) {
        $SubType = $PropertyValueCollection.Value.GetType().FullName
    }

    switch ($SubType) {
        'System.Byte[]' { ConvertTo-DecStringRepresentation -ByteArray $PropertyValueCollection.Value ; break }
        default { "$($PropertyValueCollection.Value)" }
    }

}
