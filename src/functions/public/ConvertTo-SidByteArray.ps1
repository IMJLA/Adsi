function ConvertTo-SidByteArray {
    param (
        [Parameter(ValueFromPipeline)]
        [string]$SidString
    )
    process {
        $SID = [System.Security.Principal.SecurityIdentifier]::new($SidString)
        [byte[]]$Bytes = [byte[]]::new($SID.BinaryLength)
        $SID.GetBinaryForm($Bytes, 0)
        Write-Output $Bytes
    }
}
