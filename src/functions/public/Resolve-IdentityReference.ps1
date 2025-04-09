function Resolve-IdentityReference {

    <#
    .SYNOPSIS
    Use CIM and ADSI to lookup info about IdentityReferences from Access Control Entries that came from Discretionary Access Control Lists
    .DESCRIPTION
    Based on the IdentityReference proprety of each Access Control Entry:
    Resolve SID to NT account name and vise-versa
    Resolve well-known SIDs
    Resolve generic defaults like 'NT AUTHORITY' and 'BUILTIN' to the applicable computer or domain name
    .INPUTS
    None. Pipeline input is not accepted.
    .OUTPUTS
    [PSCustomObject] with IdentityReferenceNetBios,IdentityReferenceDns, and SIDString properties (each strings)
    .EXAMPLE
    Resolve-IdentityReference -IdentityReference 'BUILTIN\Administrator' -AdsiServer (Get-AdsiServer 'localhost')

    Get information about the local Administrator account
    #>

    [OutputType([PSCustomObject])]
    param (

        # IdentityReference from an Access Control Entry
        # Expecting either a SID (S-1-5-18) or an NT account name (CONTOSO\User)
        [Parameter(Mandatory)]
        [string]$IdentityReference,

        # Object from Get-AdsiServer representing the directory server and its attributes
        [PSObject]$AdsiServer,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache,

        # Properties of each Account to display on the report
        [string[]]$AccountProperty = @('DisplayName', 'Company', 'Department', 'Title', 'Description')

    )

    $ServerNetBIOS = $AdsiServer.Netbios
    $splat1 = @{ AdsiServer = $AdsiServer; ServerNetBIOS = $ServerNetBIOS }
    $splat2 = @{ IdentityReference = $IdentityReference }

    # Search for the IdentityReference in the cache of Win32_Account CIM instances and well-known SIDs on the ADSI server. Many cannot be translated with the Translate method.
    $CacheResult = Resolve-IdRefCached -IdentityReference $IdentityReference @splat1

    if ($null -ne $CacheResult) {

        #Write-LogMsg -Text " # IdentityReference '$IdentityReference' # Cache hit" -Cache $Cache
        return $CacheResult

    }

    #Write-LogMsg -Text " # IdentityReference '$IdentityReference' # Cache miss" -Cache $Cache

    <#
    If no match was found in any cache, the resolution method depends on the IdentityReference.
    First, determine whether the IdentityReference is an NTAccount (DOMAIN\Name vs Name).
    #>

    $LastSlashIndex = $IdentityReference.LastIndexOf('\')

    if ($LastSlashIndex -eq -1) {

        $Name = $IdentityReference
        $Domain = ''

    } else {

        $StartIndex = $LastSlashIndex + 1
        $Name = $IdentityReference.Substring( $StartIndex , $IdentityReference.Length - $StartIndex )
        $Domain = $IdentityReference.Substring( 0 , $StartIndex - 1 )

    }

    # Determine whether the IdentityReference's domain is a well-known SID authority.
    $ScriptBlocks = @{
        'NT SERVICE'                    = { Resolve-IdRefSvc -Name $Name -Cache $Cache @splat1 @splat2 }
        'APPLICATION PACKAGE AUTHORITY' = { Resolve-IdRefAppPkgAuth -Name $Name -Cache $Cache @splat1 @splat2 }
        'BUILTIN'                       = { Resolve-IdRefBuiltIn -Name $Name -Cache $Cache @splat1 @splat2 }
    }

    $ScriptToRun = $ScriptBlocks[$Domain]

    # If the IdentityReference's domain is a well-known SID authority, resolve the IdentityReference accordingly.
    if ($null -ne $ScriptToRun) {

        $KnownAuthorityResult = & $ScriptToRun

        if ($null -ne $KnownAuthorityResult) {

            #Write-LogMsg -Text " # IdentityReference '$IdentityReference' # Known SID authority used for successful IdentityReference resolution" -Cache $Cache
            return $KnownAuthorityResult

        }

    }

    # If the IdentityReference's domain is not a well-known SID authority, determine whether the IdentityReference is a Revision 1 SID.
    if ($Name.Substring(0, 4) -eq 'S-1-') {

        # If the IdentityReference is a Revision 1 SID, translate the SID to an NTAccount.
        $Resolved = Resolve-IdRefSID -AccountProperty $AccountProperty -Cache $Cache @splat1 @splat2
        return $Resolved

    }

    # If no match was found with any of the known patterns for SIDs or well-known SID authorities, the IdentityReference is an NTAccount.
    # Translate the NTAccount to a SID.
    if ($null -ne $ServerNetBIOS) {

        # Start by determining the domain DN and DNS name.
        $CacheResult = $null
        $TryGetValueResult = $Cache.Value['DomainByNetbios'].Value.TryGetValue( $ServerNetBIOS, [ref]$CacheResult )

        if ($TryGetValueResult) {
            #Write-LogMsg -Text " # IdentityReference '$IdentityReference' # Domain NetBIOS cache hit for '$ServerNetBIOS'" -Cache $Cache
        } else {

            #Write-LogMsg -Text " # IdentityReference '$IdentityReference' # Domain NetBIOS cache miss for '$ServerNetBIOS'" -Cache $Cache
            $CacheResult = Get-AdsiServer -Netbios $ServerNetBIOS -Cache $Cache

        }

        $DomainDn = $CacheResult.DistinguishedName
        $DomainDns = $CacheResult.Dns

        # Try to resolve the account against the server the Access Control Entry came from (which may or may not be the directory server for the account).
        $SIDString = ConvertTo-SidString -Name $Name -ServerNetBIOS $ServerNetBIOS -Cache $Cache

        if (-not $SIDString) {

            # Try to resolve the account against the domain indicated in its NT Account Name.
            # Add this domain to our list of known domains.
            $SIDString = Resolve-IdRefSearchDir -DomainDn $DomainDn -Name $Name -AccountProperty $AccountProperty -Cache $Cache @splat2

        }

        if (-not $SIDString) {

            # Try to find the DirectoryEntry object directly on the server.
            $SIDString = Resolve-IdRefGetDirEntry -Name $Name -Cache $Cache @splat1

        }

        # The IdentityReference is an unresolved SID (deleted account, account in a domain with a broken domain trust, etc.)
        if ( '' -eq "$Name" ) {

            $Name = $IdentityReference
            Write-LogMsg -Text " # IdentityReference '$IdentityReference' # No name could be parsed." -Cache $Cache

        } else {
            Write-LogMsg -Text " # IdentityReference '$IdentityReference' # Name parsed is '$Name'." -Cache $Cache
        }

        return [PSCustomObject]@{
            IdentityReference        = $IdentityReference
            SIDString                = $SIDString
            IdentityReferenceNetBios = "$ServerNetBIOS\$Name"
            IdentityReferenceDns     = "$DomainDns\$Name"
        }

    }

}
