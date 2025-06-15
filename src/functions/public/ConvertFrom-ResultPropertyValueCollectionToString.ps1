function ConvertFrom-ResultPropertyValueCollectionToString {

    <#
    .SYNOPSIS

    Convert a ResultPropertyValueCollection to a string
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

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertFrom-ResultPropertyValueCollectionToString')]

    param (
        # ResultPropertyValueCollection object to convert to a string
        [System.DirectoryServices.ResultPropertyValueCollection]$ResultPropertyValueCollection


    )



    if ($null -ne $ResultPropertyValueCollection.Value) {
        $SubType = $ResultPropertyValueCollection.Value.GetType().FullName
    }

    switch ($SubType) {
        'System.Byte[]' { ConvertTo-DecStringRepresentation -ByteArray $ResultPropertyValueCollection.Value ; break }
        default { "$($ResultPropertyValueCollection.Value)" }
    }

}
