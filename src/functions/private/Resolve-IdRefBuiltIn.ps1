function Resolve-IdRefBuiltIn {
    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Resolve-IdRefBuiltIn')]
    [OutputType([PSCustomObject])]

    param (

        # IdentityReference from an Access Control Entry
        # Expecting either a SID (S-1-5-18) or an NT account name (CONTOSO\User)
        [Parameter(Mandatory)]
        [string]$IdentityReference,

        # Object from Get-AdsiServer representing the directory server and its attributes
        [PSObject]$AdsiServer,

        # NetBIOS name of the ADSI server
        [string]$ServerNetBIOS = $AdsiServer.Netbios,

        # Name of the IdentityReference with the DOMAIN\ prefix removed
        [string]$Name,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )


    # Some built-in groups such as BUILTIN\Users and BUILTIN\Administrators are not in the CIM class or translatable with the NTAccount.Translate() method
    # But they may have real DirectoryEntry objects
    # Try to find the DirectoryEntry object locally on the server
    $DirectoryPath = "$($AdsiServer.AdsiProvider)`://$ServerNetBIOS/$Name"

    if ($Name.Substring(0, 4) -eq 'S-1-') {

        $SIDString = $Name
        $Caption = $IdentityReference

    } else {

        Write-LogMsg -Text "Get-DirectoryEntry -DirectoryPath '$DirectoryPath' -Cache `$Cache" -Cache $Cache
        $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath -Cache $Cache
        $SIDString = (Add-SidInfo -InputObject $DirectoryEntry -DomainsBySid $Cache.Value['DomainBySid']).SidString
        $Caption = "$ServerNetBIOS\$Name"

    }

    $DomainDns = $AdsiServer.Dns
    $DomainCacheResult = Get-AdsiServer -Fqdn $DomainDns -Cache $Cache

    # Update the caches
    $Win32Acct = [PSCustomObject]@{
        SID     = $SIDString
        Caption = $Caption
        Domain  = $ServerNetBIOS
        Name    = $Name
    }

    # Update the caches
    $DomainCacheResult.WellKnownSidBySid[$SIDString] = $Win32Acct
    $DomainCacheResult.WellKnownSidByName[$Name] = $Win32Acct
    $Cache.Value['DomainByFqdn'].Value[$DomainCacheResult.Dns] = $DomainCacheResult
    $Cache.Value['DomainByNetbios'].Value[$DomainCacheResult.Netbios] = $DomainCacheResult
    $Cache.Value['DomainBySid'].Value[$DomainCacheResult.Sid] = $DomainCacheResult

    return [PSCustomObject]@{
        IdentityReference        = $IdentityReference
        SIDString                = $SIDString
        IdentityReferenceNetBios = $Caption
        IdentityReferenceDns     = "$DomainDns\$Name"
    }

}
