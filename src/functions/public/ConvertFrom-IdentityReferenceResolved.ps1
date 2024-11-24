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

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache,

        # The current domain
        # Can be passed as a parameter to reduce calls to Get-CurrentDomain
        [PSCustomObject]$CurrentDomain = (Get-CurrentDomain -Cache $Cache),

        # Properties of each Account to display on the report
        [string[]]$AccountProperty = @('DisplayName', 'Company', 'Department', 'Title', 'Description')

    )

    $PrincipalById = $Cache.Value['PrincipalById']

    if ( -not $PrincipalById.Value.TryGetValue( $IdentityReference, [ref]$null ) ) {

        $Log = @{ ThisHostname = $ThisHostname ; Type = $DebugOutputStream ; Buffer = $Cache.Value['LogBuffer'] ; WhoAmI = $WhoAmI }
        $LogSuffix = "for IdentityReference '$IdentityReference'"
        $LogSuffixComment = " # $LogSuffix"
        #Write-LogMsg @Log -Text " # ADSI Principal cache miss $LogSuffix"
        $LogThis = @{ ThisHostname = $ThisHostname ; Cache = $Cache ; WhoAmI = $WhoAmI ; DebugOutputStream = $DebugOutputStream }
        $AceGuidByID = $Cache.Value['AceGuidByID']
        $AccessControlEntries = $AceGuidByID.Value[ $IdentityReference ]
        $split = $IdentityReference.Split('\')
        $DomainNetBIOS = $split[0]
        $SamAccountNameOrSid = $split[1]
        $CachedWellKnownSID = Find-CachedWellKnownSID -IdentityReference $SamAccountNameOrSid -DomainNetBIOS $DomainNetBIOS -DomainByNetbios $Cache.Value['DomainByNetbios']
        [string]$DomainDn = $null

        $CommonSplat = @{
            AccessControlEntries = $AccessControlEntries
            DebugOutputStream    = $DebugOutputStream
            DomainDn             = $DomainDn
            DomainNetBIOS        = $DomainNetBIOS
            IdentityReference    = $IdentityReference
            Log                  = $Log
            LogSuffix            = $LogSuffix
            LogThis              = $LogThis
            SamAccountNameOrSid  = $SamAccountNameOrSid
            ThisFqdn             = $ThisFqdn
        }

        $DirectoryEntryConversion = @{
            AccountProperty    = $AccountProperty
            Cache              = $Cache
            CachedWellKnownSID = $CachedWellKnownSID
            CurrentDomain      = $CurrentDomain
            LogSuffixComment   = $LogSuffixComment
        }

        Write-LogMsg @Log -Text 'ConvertTo-DirectoryEntry' -Expand $DirectoryEntryConversion, $CommonSplat -Suffix $LogSuffixComment -ExpandKeyMap @{ Cache = '$Cache' }
        $DirectoryEntry = ConvertTo-DirectoryEntry @DirectoryEntryConversion @CommonSplat
        Pause # to debug and confirm DomainDn is populated
        $PermissionPrincipalConversion = @{
            DirectoryEntry = $DirectoryEntry
            NoGroupMembers = $NoGroupMembers
            PrincipalById  = $PrincipalById
        }

        Write-LogMsg @Log -Text 'ConvertTo-PermissionPrincipal' -Expand $PermissionPrincipalConversion, $CommonSplat -Suffix $LogSuffixComment
        ConvertTo-PermissionPrincipal @PermissionPrincipalConversion @CommonSplat

    }

}
