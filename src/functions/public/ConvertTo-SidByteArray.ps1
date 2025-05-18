function ConvertTo-SidByteArray {
    <#
    .SYNOPSIS
    Convert a SID from a string to binary format (byte array)
    .DESCRIPTION
    Uses the GetBinaryForm method of the [System.Security.Principal.SecurityIdentifier] class
    .INPUTS
    [System.String]$SidString
    .OUTPUTS
    [System.Byte] SID a a byte array
    .EXAMPLE
    ConvertTo-SidByteArray -SidString 'S-1-5-32-544'

    Converts the SID string for the built-in Administrators group ('S-1-5-32-544') to a byte array
    representation, which is required when working with directory services that expect SIDs in binary format.
    #>
    [OutputType([System.Byte[]])]
    param (
        # SID to convert to binary
        [Parameter(ValueFromPipeline)]
        [string[]]$SidString
    )
    process {
        ForEach ($ThisSID in $SidString) {
            $SID = [System.Security.Principal.SecurityIdentifier]::new($ThisSID)
            [byte[]]$Bytes = [byte[]]::new($SID.BinaryLength)
            $SID.GetBinaryForm($Bytes, 0)
            $Bytes
        }
    }
}
