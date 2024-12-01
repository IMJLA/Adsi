function ConvertFrom-IdentityReferenceResolved {

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
    ConvertFrom-IdentityReferenceResolved

    Incomplete example but it shows the chain of functions to generate the expected input for this
    #>

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

        # The current domain
        # Can be passed as a parameter to reduce calls to Get-CurrentDomain
        [PSCustomObject]$CurrentDomain = (Get-CurrentDomain -Cache $Cache),

        # Properties of each Account to display on the report
        [string[]]$AccountProperty = @('DisplayName', 'Company', 'Department', 'Title', 'Description')

    )

    if ( -not $Cache.Value['PrincipalById'].Value[ $IdentityReference ] ) {

        $LogSuffix = "for resolved Identity Reference '$IdentityReference'"
        $LogSuffixComment = " # $LogSuffix"
        $Log = @{ 'Cache' = $Cache ; 'Suffix' = $LogSuffixComment }
        #Write-LogMsg @Log -Text " # ADSI Principal cache miss $LogSuffix"
        $AceGuidByID = $Cache.Value['AceGuidByID']
        $AccessControlEntries = $AceGuidByID.Value[ $IdentityReference ]
        $split = $IdentityReference.Split('\')
        $DomainNetBIOS = $split[0]
        $SamAccountNameOrSid = $split[1]
        Write-LogMsg @Log -Text "`$CachedWellKnownSID = Find-CachedWellKnownSID -IdentityReference '$SamAccountNameOrSid' -DomainNetBIOS '$DomainNetBIOS' -DomainByNetbios `$Cache.Value['DomainByNetbios']"
        $CachedWellKnownSID = Find-CachedWellKnownSID -IdentityReference $SamAccountNameOrSid -DomainNetBIOS $DomainNetBIOS -DomainByNetbios $Cache.Value['DomainByNetbios']
        $DomainDn = $null

        $CommonSplat = @{
            'AccessControlEntries' = $AccessControlEntries
            'AccountProperty'      = $AccountProperty
            'Cache'                = $Cache
            'DomainDn'             = $DomainDn
            'DomainNetBIOS'        = $DomainNetBIOS
            'IdentityReference'    = $IdentityReference
            'LogSuffixComment'     = $LogSuffixComment
            'SamAccountNameOrSid'  = $SamAccountNameOrSid
        }

        $DirectoryEntryConversion = @{
            'CachedWellKnownSID' = $CachedWellKnownSID
            'CurrentDomain'      = $CurrentDomain
        }

        Write-LogMsg @Log -Text '$DirectoryEntry = ConvertTo-DirectoryEntry' -Expand $DirectoryEntryConversion, $CommonSplat -MapKeyName 'LogWellKnownMap'
        $DirectoryEntry = ConvertTo-DirectoryEntry @DirectoryEntryConversion @CommonSplat

        $PermissionPrincipalConversion = @{
            'DirectoryEntry' = $DirectoryEntry
            'NoGroupMembers' = $NoGroupMembers
        }

        Write-LogMsg @Log -Text 'ConvertTo-PermissionPrincipal' -Expand $PermissionPrincipalConversion, $CommonSplat -MapKeyName 'LogDirEntryMap'
        ConvertTo-PermissionPrincipal @PermissionPrincipalConversion @CommonSplat

    }

}
