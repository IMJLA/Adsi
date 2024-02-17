function Get-DirectoryEntryProperty {
    <#
    .SYNOPSIS
    Fill a hashtable with the properties of a DirectoryEntry
    .DESCRIPTION
    Recursively convert every property into a string, or a PSCustomObject (whose properties are all strings, or more PSCustomObjects)
    This obfuscates the troublesome PropertyCollection and PropertyValueCollection and Hashtable aspects of working with ADSI
    .NOTES
    # TODO: There is a faster way than Select-Object, just need to dig into the default formatting of DirectoryEntry to see how to get those properties
    #>

    param (
        [Parameter(
            Position = 0
        )]
        [System.DirectoryServices.DirectoryEntry]$DirectoryEntry,
        
        

        [hashtable]$PropertyDictionary = @{}
    )

    ForEach ($Prop in ($DirectoryEntry | Get-Member -View All -MemberType Property).Name) {
        $null = ConvertTo-SimpleProperty -InputObject $DirectoryEntry -Property $Prop -PropertyDictionary $PropertyDictionary
    }

}
