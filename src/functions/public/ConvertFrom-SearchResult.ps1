function ConvertFrom-SearchResult {

    <#
    .SYNOPSIS

    Convert a SearchResult to a PSCustomObject
    .DESCRIPTION
    Recursively convert every property into a string, or a PSCustomObject (whose properties are all strings, or more PSCustomObjects)
    This obfuscates the troublesome ResultPropertyCollection and ResultPropertyValueCollection and Hashtable aspects of working with ADSI searches
    .INPUTS
    System.DirectoryServices.SearchResult[]

    Accepts SearchResult objects from a directory search via the pipeline.
    .OUTPUTS
    PSCustomObject

    Returns PSCustomObject instances with simplified properties.
    .EXAMPLE
    $DirectorySearcher = [System.DirectoryServices.DirectorySearcher]::new("LDAP://DC=contoso,DC=com")
    $DirectorySearcher.Filter = "(objectClass=user)"
    $SearchResults = $DirectorySearcher.FindAll()
    $SearchResults | ConvertFrom-SearchResult

    Performs a search in Active Directory for all user objects, then converts each SearchResult
    into a PSCustomObject with simplified properties. This makes it easier to work with the
    search results in PowerShell by flattening complex nested property collections into
    regular object properties.
    .NOTES
    # TODO: There is a faster way than Select-Object, just need to dig into the default formatting of SearchResult to see how to get those properties
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertFrom-SearchResult')]

    param (

        # SearchResult objects to convert to PSCustomObjects
        [Parameter(
            Position = 0,
            ValueFromPipeline
        )]
        [System.DirectoryServices.SearchResult[]]$SearchResult

    )



    process {

        ForEach ($ThisSearchResult in $SearchResult) {

            $OutputObject = @{}

            # Enumerate the keys of the ResultPropertyCollection
            ForEach ($ThisProperty in $ThisSearchResult.Properties.Keys) {
                $null = ConvertTo-SimpleProperty -InputObject $ThisSearchResult.Properties -Property $ThisProperty -PropertyDictionary $ThisObject
            }

            # We will allow any existing properties to override members of the ResultPropertyCollection
            ForEach ($ThisProperty in $ThisSearchResult.PSObject.Properties.GetEnumerator().Name) {
                $null = ConvertTo-SimpleProperty -InputObject $ThisSearchResult -Property $ThisProperty -PropertyDictionary $OutputObject
            }

            [PSCustomObject]$OutputObject

        }

    }

}
