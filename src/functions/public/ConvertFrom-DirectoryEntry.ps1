function ConvertFrom-DirectoryEntry {

    <#
    .SYNOPSIS
    Convert a DirectoryEntry to a PSCustomObject
    .DESCRIPTION
    Recursively convert every property into a string, or a PSCustomObject (whose properties are all strings, or more PSCustomObjects)
    This obfuscates the troublesome PropertyCollection and PropertyValueCollection and Hashtable aspects of working with ADSI
    #>

    param (

        # DirectoryEntry objects to convert to PSCustomObjects
        [Parameter(
            Position = 0
        )]
        [System.DirectoryServices.DirectoryEntry[]]$DirectoryEntry

    )

    ForEach ($ThisDirectoryEntry in $DirectoryEntry) {

        $OutputObject = @{}

        ForEach ($Prop in $ThisDirectoryEntry.PSObject.Properties.GetEnumerator().Name) {

            $null = ConvertTo-SimpleProperty -InputObject $ThisDirectoryEntry -Property $Prop -PropertyDictionary $OutputObject

        }

        [PSCustomObject]$OutputObject

    }

}
