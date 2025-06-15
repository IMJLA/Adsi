function Resolve-IdRefAppPkgAuth {
    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Resolve-IdRefAppPkgAuth')]

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

    $Caption = "$ServerNetBIOS\$Name"
    $DomainCacheResult = $null
    $DomainsByNetbios = $Cache.Value['DomainByNetbios']
    $TryGetValueResult = $DomainsByNetbios.Value.TryGetValue($ServerNetBIOS, [ref]$DomainCacheResult)

    <#
    These SIDs cannot be resolved from the NTAccount name:
        PS C:> [System.Security.Principal.SecurityIdentifier]::new('S-1-15-2-1').Translate([System.Security.Principal.NTAccount]).Translate([System.Security.Principal.SecurityIdentifier])
        MethodInvocationException: Exception calling "Translate" with "1" argument(s): "Some or all identity references could not be translated."

    Even though resolving the reverse direction works:
        PS C:> [System.Security.Principal.SecurityIdentifier]::new('S-1-15-2-1').Translate([System.Security.Principal.NTAccount])

        Value
        -----
        APPLICATION PACKAGE AUTHORITY\ALL APPLICATION PACKAGES
    So we will instead hardcode a map of SIDs
    #>

    $Known = $Cache.Value['WellKnownSidByCaption'].Value[$IdentityReference]

    if ($null -eq $Known) {
        $Known = $DomainCacheResult.WellKnownSidByName[$Name]
    }

    $AccountProperties = @{}

    if ($null -ne $Known) {

        $SIDString = $Known.SID

        ForEach ($Prop in $Known.PSObject.Properties.GetEnumerator().Name) {
            $AccountProperties[$Prop] = $Known.$Prop
        }

    } else {
        $SIDString = $Name
    }

    if ($TryGetValueResult) {
        $DomainDns = $DomainCacheResult.Dns
    } else {

        Write-LogMsg -Text "ConvertTo-Fqdn -NetBIOS '$ServerNetBIOS' -Cache `$Cache # cache miss # IdentityReference '$IdentityReference' # Domain NetBIOS '$ServerNetBIOS'" -Cache $Cache
        $DomainDns = ConvertTo-Fqdn -NetBIOS $ServerNetBIOS -Cache $Cache
        Write-LogMsg -Text "Get-AdsiServer -Fqdn '$ServerNetBIOS' -Cache `$Cache # cache miss # IdentityReference '$IdentityReference' # Domain NetBIOS '$ServerNetBIOS'" -Cache $Cache
        $DomainCacheResult = Get-AdsiServer -Fqdn $DomainDns -Cache $Cache

    }

    $AccountProperties['SID'] = $SIDString
    $AccountProperties['Caption'] = $Caption
    $AccountProperties['Domain'] = $ServerNetBIOS
    $AccountProperties['Name'] = $Name
    $AccountProperties['IdentityReference'] = $IdentityReference
    $AccountProperties['SIDString'] = $SIDString
    $AccountProperties['IdentityReferenceNetBios'] = $Caption
    $AccountProperties['IdentityReferenceDns'] = "$DomainDns\$Name"
    $Win32Acct = [PSCustomObject]$AccountProperties

    # Update the caches
    $DomainCacheResult.WellKnownSidBySid[$SIDString] = $Win32Acct
    $DomainCacheResult.WellKnownSidByName[$Name] = $Win32Acct
    $Cache.Value['DomainByFqdn'].Value[$DomainCacheResult.Dns] = $DomainCacheResult
    $Cache.Value['DomainByNetbios'].Value[$DomainCacheResult.Netbios] = $DomainCacheResult
    $Cache.Value['DomainBySid'].Value[$DomainCacheResult.Sid] = $DomainCacheResult

    return $Win32Acct

}
