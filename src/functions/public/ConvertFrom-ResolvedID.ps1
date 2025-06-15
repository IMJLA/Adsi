function ConvertFrom-ResolvedID {

    <#
    .SYNOPSIS

    Use ADSI to collect more information about the IdentityReference in NTFS Access Control Entries
    .DESCRIPTION
    Recursively retrieves group members and detailed information about them
    Use caching to reduce duplicate directory queries
    .INPUTS
    [System.Object]$IdentityReference
    .OUTPUTS
    [System.Object] The input object is returned with additional properties added:
        DirectoryEntry
        DomainDn
        DomainNetBIOS
        ObjectType
        Members (if the DirectoryEntry is a group).

    .EXAMPLE
    (Get-Acl).Access |
    Resolve-IdentityReference |
    Group-Object -Property IdentityReferenceResolved |
    ConvertFrom-ResolvedID

    Incomplete example but it shows the chain of functions to generate the expected input for this function.
    This example gets the ACL for an important folder, resolves each identity reference in the access entries,
    groups them by the resolved identity reference, and then converts each unique identity to a detailed
    principal object. This provides comprehensive information about each security principal including their
    directory entry, domain information, and group membership details, which is essential for thorough
    permission analysis and reporting.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertFrom-ResolvedID')]
    [OutputType([void])]

    param (

        # The NTFS AccessControlEntry object(s), grouped by their IdentityReference property
        # TODO: Use System.Security.Principal.NTAccount instead
        [string]$IdentityReference,

        # Do not get group members
        [switch]$NoGroupMembers,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache,

        # Properties of each Account to display on the report
        [string[]]$AccountProperty = @('DisplayName', 'Company', 'Department', 'Title', 'Description')

    )

    if ( -not $Cache.Value['PrincipalById'].Value[ $IdentityReference ] ) {

        $LogSuffix = "for resolved Identity Reference '$IdentityReference'"
        $LogSuffixComment = " # $LogSuffix"
        $Log = @{ 'Cache' = $Cache ; 'Suffix' = $LogSuffixComment }
        Write-LogMsg @Log -Text "`$AceGuids = `$Cache.Value['AceGuidByID'].Value['$IdentityReference'] # ADSI Principal cache miss"
        $AceGuidByID = $Cache.Value['AceGuidByID']
        $AceGuids = $AceGuidByID.Value[ $IdentityReference ]
        $split = $IdentityReference.Split('\')
        $DomainNetBIOS = $split[0]
        $SamAccountNameOrSid = $split[1]
        Write-LogMsg @Log -Text "`$CachedWellKnownSID = Find-CachedWellKnownSID -IdentityReference '$SamAccountNameOrSid' -DomainNetBIOS '$DomainNetBIOS' -DomainByNetbios `$Cache.Value['DomainByNetbios']"
        $CachedWellKnownSID = Find-CachedWellKnownSID -IdentityReference $SamAccountNameOrSid -DomainNetBIOS $DomainNetBIOS -DomainByNetbios $Cache.Value['DomainByNetbios']
        $DomainDn = $null

        $CommonSplat = @{
            'AceGuid'             = $AceGuids
            'AccountProperty'     = $AccountProperty
            'Cache'               = $Cache
            'DomainDn'            = $DomainDn
            'DomainNetBIOS'       = $DomainNetBIOS
            'IdentityReference'   = $IdentityReference
            'LogSuffixComment'    = $LogSuffixComment
            'SamAccountNameOrSid' = $SamAccountNameOrSid
        }

        $DirectoryEntryConversion = @{
            'CachedWellKnownSID' = $CachedWellKnownSID
        }

        Write-LogMsg @Log -Text '$DirectoryEntry = ConvertTo-DirectoryEntry' -Expand $DirectoryEntryConversion, $CommonSplat -ExpansionMap $Cache.Value['LogWellKnownMap'].Value
        $DirectoryEntry = ConvertTo-DirectoryEntry @DirectoryEntryConversion @CommonSplat

        $PermissionPrincipalConversion = @{
            'DirectoryEntry' = $DirectoryEntry
            'NoGroupMembers' = $NoGroupMembers
        }

        Write-LogMsg @Log -Text 'ConvertTo-PermissionPrincipal' -Expand $PermissionPrincipalConversion, $CommonSplat -ExpansionMap $Cache.Value['LogDirEntryMap'].Value
        ConvertTo-PermissionPrincipal @PermissionPrincipalConversion @CommonSplat

    }

}
