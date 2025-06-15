function Resolve-IdRefSID {

    <#
                This .Net method makes it impossible to redirect the error stream directly
                Wrapping it in a scriptblock (which is then executed with &) fixes the problem
                I don't understand exactly why

                The scriptblock will evaluate null if the SID cannot be translated, and the error stream redirection supresses the error (except in the transcript which catches it)
            #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Resolve-IdRefSID')]
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

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache,

        # Properties of each Account to display on the report
        [string[]]$AccountProperty = @('DisplayName', 'Company', 'Department', 'Title', 'Description')

    )

    $CachedWellKnownSID = Find-CachedWellKnownSID -IdentityReference $IdentityReference -DomainNetBIOS $ServerNetBIOS -DomainByNetbios $Cache.Value['DomainByNetbios']
    $AccountProperties = @{}

    if ($CachedWellKnownSID) {

        ForEach ($Prop in $CachedWellKnownSID.PSObject.Properties.GetEnumerator().Name) {
            $AccountProperties[$Prop] = $CachedWellKnownSID.$Prop
        }

        #Write-LogMsg -Text " # IdentityReference '$IdentityReference' # Well-known SID match" -Cache $Cache
        $NTAccount = $CachedWellKnownSID.IdentityReferenceNetBios
        $DomainNetBIOS = $ServerNetBIOS
        $DomainDns = ConvertTo-Fqdn -NetBIOS $DomainNetBIOS -Cache $Cache
        $DomainCacheResult = Get-AdsiServer -Fqdn $DomainDns -Cache $Cache
        $done = $true

    } else {
        $KnownSid = Get-KnownSid -SID $IdentityReference
    }

    if ($KnownSid) {

        ForEach ($Prop in $KnownSid.PSObject.Properties.GetEnumerator().Name) {
            $AccountProperties[$Prop] = $KnownSid.$Prop
        }

        #Write-LogMsg -Text " # IdentityReference '$IdentityReference' # Known SID pattern match" -Cache $Cache
        $NTAccount = $KnownSid.NTAccount
        $DomainNetBIOS = $ServerNetBIOS
        $DomainDns = ConvertTo-Fqdn -NetBIOS $DomainNetBIOS -Cache $Cache
        $DomainCacheResult = Get-AdsiServer -Fqdn $DomainDns -Cache $Cache
        $done = $true

    }

    if (-not $done) {


        #Write-LogMsg -Text " # IdentityReference '$IdentityReference' # No match with known SID patterns" -Cache $Cache
        # The SID of the domain is everything up to (but not including) the last hyphen
        $DomainSid = $IdentityReference.Substring(0, $IdentityReference.LastIndexOf('-'))
        Write-LogMsg -Text "[System.Security.Principal.SecurityIdentifier]::new('$IdentityReference').Translate([System.Security.Principal.NTAccount])" -Cache $Cache
        $SecurityIdentifier = [System.Security.Principal.SecurityIdentifier]::new($IdentityReference)

        try {


            $NTAccount = & { $SecurityIdentifier.Translate([System.Security.Principal.NTAccount]).Value } 2>$null

        } catch {

            $StartingLogType = $Cache.Value['LogType'].Value
            $Cache.Value['LogType'].Value = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
            Write-LogMsg -Text " # IdentityReference '$IdentityReference' # Unexpectedly could not translate SID to NTAccount using the [SecurityIdentifier]::Translate method: $($_.Exception.Message.Replace('Exception calling "Translate" with "1" argument(s): ',''))" -Cache $Cache
            $Cache.Value['LogType'].Value = $StartingLogType

        }

    }

    #Write-LogMsg -Text " # IdentityReference '$IdentityReference' # Translated NTAccount caption is '$NTAccount'" -Cache $Cache
    $DomainsBySid = $Cache.Value['DomainBySid']

    # Search the cache of domains, first by SID, then by NetBIOS name
    if (-not $DomainCacheResult) {
        $DomainCacheResult = $null
        $TryGetValueResult = $DomainsBySid.Value.TryGetValue($DomainSid, [ref]$DomainCacheResult)
    }

    $DomainsByNetbios = $Cache.Value['DomainByNetbios']

    if (-not $TryGetValueResult) {

        #Write-LogMsg -Text " # IdentityReference '$IdentityReference' # Domain SID cache miss for '$DomainSid'" -Cache $Cache
        $split = $NTAccount -split '\\'
        $DomainFromSplit = $split[0]

        if (

            $DomainFromSplit.Contains(' ') -or
            $DomainFromSplit -eq 'BUILTIN'

        ) {

            $NameFromSplit = $split[1]
            $DomainNetBIOS = $ServerNetBIOS
            $Caption = "$ServerNetBIOS\$NameFromSplit"
            $AccountProperties['SID'] = $IdentityReference
            $AccountProperties['Caption'] = $Caption
            $AccountProperties['Domain'] = $ServerNetBIOS
            $AccountProperties['Name'] = $NameFromSplit

            # This will be used to update the caches
            $Win32Acct = [PSCustomObject]$AccountProperties

        } else {
            $DomainNetBIOS = $DomainFromSplit
        }

        $DomainCacheResult = $null
        $TryGetValueResult = $DomainsByNetbios.Value.TryGetValue($DomainNetBIOS, [ref]$DomainCacheResult)

    }

    if ($DomainCacheResult) {

        $DomainNetBIOS = $DomainCacheResult.Netbios
        $DomainDns = $DomainCacheResult.Dns

    } else {

        #Write-LogMsg -Text " # IdentityReference '$IdentityReference' # Domain SID '$DomainSid' is unknown. Domain NetBIOS is '$DomainNetBIOS'" -Cache $Cache
        $DomainDns = ConvertTo-Fqdn -NetBIOS $DomainNetBIOS -Cache $Cache
        $DomainCacheResult = Get-AdsiServer -Fqdn $DomainDns -Cache $Cache

    }

    if (-not $DomainCacheResult) {
        $DomainCacheResult = $AdsiServer
    }

    # Update the caches
    if ($Win32Acct) {
        $DomainCacheResult.WellKnownSidBySid[$IdentityReference] = $Win32Acct
        $DomainCacheResult.WellKnownSidByName[$NameFromSplit] = $Win32Acct
        # TODO are these next 3 lines necessary or are the values already updated thanks to references?
        $Cache.Value['DomainByFqdn'].Value[$DomainCacheResult.Dns] = $DomainCacheResult
        $DomainsByNetbios.Value[$DomainCacheResult.Netbios] = $DomainCacheResult
        $DomainsBySid.Value[$DomainCacheResult.Sid] = $DomainCacheResult
    }

    if ($NTAccount) {

        # Recursively call this function to resolve the new IdentityReference we have
        $ResolveIdentityReferenceParams = @{
            AccountProperty   = $AccountProperty
            Cache             = $Cache
            IdentityReference = $NTAccount
            AdsiServer        = $DomainCacheResult
        }

        $Resolved = Resolve-IdentityReference @ResolveIdentityReferenceParams

    } else {

        if ($Win32Acct) {

            $AccountProperties['IdentityReference'] = $IdentityReference
            $AccountProperties['SIDString'] = $IdentityReference
            $AccountProperties['IdentityReferenceNetBios'] = "$DomainNetBIOS\$IdentityReference"
            $AccountProperties['IdentityReferenceDns'] = "$DomainDns\$IdentityReference"
            $Resolved = [PSCustomObject]$AccountProperties

        } else {

            $Resolved = [PSCustomObject]@{
                IdentityReference        = $IdentityReference
                SIDString                = $IdentityReference
                IdentityReferenceNetBios = "$DomainNetBIOS\$IdentityReference"
                IdentityReferenceDns     = "$DomainDns\$IdentityReference"
            }

        }

    }

    return $Resolved

}
