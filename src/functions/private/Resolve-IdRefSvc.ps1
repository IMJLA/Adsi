function Resolve-IdRefSvc {
    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Resolve-IdRefSvc')]
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


    $SIDString = ConvertTo-ServiceSID -ServiceName $Name
    $Caption = "$ServerNetBIOS\$Name"
    $DomainCacheResult = $null
    $DomainsByNetbios = $Cache.Value['DomainByNetbios']
    $TryGetValueResult = $DomainsByNetbios.Value.TryGetValue($ServerNetBIOS, [ref]$DomainCacheResult)

    if ($TryGetValueResult) {
        $DomainDns = $DomainCacheResult.Dns
    } else {

        Write-LogMsg -Text " # Domain NetBIOS cache miss for '$ServerNetBIOS' # For '$IdentityReference'" -Cache $Cache
        $DomainDns = ConvertTo-Fqdn -NetBIOS $ServerNetBIOS -Cache $Cache
        $DomainCacheResult = Get-AdsiServer -Fqdn $DomainDns -Cache $Cache

    }

    # Update the caches
    $Win32Svc = [PSCustomObject]@{
        SID     = $SIDString
        Caption = $Caption
        Domain  = $ServerNetBIOS
        Name    = $Name
    }

    # Update the caches
    $DomainCacheResult.WellKnownSidBySid[$SIDString] = $Win32Svc
    $DomainCacheResult.WellKnownSidByName[$Name] = $Win32Svc
    $Cache.Value['DomainByFqdn'].Value[$DomainCacheResult.Dns] = $DomainCacheResult
    $DomainsByNetbios.Value[$DomainCacheResult.Netbios] = $DomainCacheResult
    $Cache.Value['DomainBySid'].Value[$DomainCacheResult.Sid] = $DomainCacheResult

    return [PSCustomObject]@{
        IdentityReference        = $IdentityReference
        SIDString                = $SIDString
        IdentityReferenceNetBios = $Caption
        IdentityReferenceDns     = "$DomainDns\$Name"
    }

}
