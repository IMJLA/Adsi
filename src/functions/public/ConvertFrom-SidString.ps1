# This function is not currently in use by Export-Permission

function ConvertFrom-SidString {

    #[OutputType([System.Security.Principal.NTAccount])]

    param (

        [string]$SID,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    #[System.Security.Principal.SecurityIdentifier]::new($SID)
    # Only works if SID is in the current domain...otherwise SID not found
    $DirectoryPath = "LDAP://<SID=$SID>"
    Write-LogMsg -Text "Get-DirectoryEntry -DirectoryPath '$DirectoryPath' -Cache `$Cache" -Cache $Cache
    Get-DirectoryEntry -DirectoryPath $DirectoryPath -Cache $Cache

}
