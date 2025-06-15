function ConvertFrom-SidString {
    <#
    .SYNOPSIS

    Converts a SID string to a DirectoryEntry object.

    .DESCRIPTION
    Attempts to resolve a security identifier (SID) string to its corresponding DirectoryEntry object
    by querying the directory service using the LDAP provider. This function is not currently in use
    by the Export-Permission module.

    .EXAMPLE
    ConvertFrom-SidString -SID 'S-1-5-21-3165297888-301567370-576410423-1103' -Cache $Cache

    Attempts to convert a SID string representing a user or group to its corresponding DirectoryEntry object
    by searching Active Directory using the LDAP provider. This allows you to obtain detailed information
    about a security principal when you only have its SID string representation.

    .INPUTS
    System.String

    .OUTPUTS
    System.DirectoryServices.DirectoryEntry

    .NOTES
    This function is not currently in use by Export-Permission
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertFrom-SidString')]

    param (

        # Security Identifier (SID) string to convert to a DirectoryEntry
        [string]$SID,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache
    )


    #[OutputType([System.Security.Principal.NTAccount])]


    #[System.Security.Principal.SecurityIdentifier]::new($SID)
    # Only works if SID is in the current domain...otherwise SID not found
    $DirectoryPath = "LDAP://<SID=$SID>"
    Write-LogMsg -Text "Get-DirectoryEntry -DirectoryPath '$DirectoryPath' -Cache `$Cache" -Cache $Cache
    Get-DirectoryEntry -DirectoryPath $DirectoryPath -Cache $Cache

}
