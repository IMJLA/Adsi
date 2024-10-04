function Find-CachedWellKnownSID {

    param (
        [hashtable]$DomainsByNetbios,
        [string]$IdentityReference,
        [string]$DomainNetBIOS
    )

    $DomainNetbiosCacheResult = $DomainsByNetbios[$DomainNetBIOS]

    if ($DomainNetbiosCacheResult) {

        ForEach ($Cache in 'WellKnownSidBySid', 'WellKnownSIDByName') {

            if ($DomainNetbiosCacheResult.$Cache) {

                $WellKnownSidCacheResult = $DomainNetbiosCacheResult.$Cache[$IdentityReference]

                if ($WellKnownSidCacheResult) {

                    $CombinedProperties = $WellKnownSidCacheResult + @{
                        IdentityReference        = $IdentityReference
                        SIDString                = $WellKnownSidCacheResult.SID
                        IdentityReferenceNetBios = "$DomainNetBIOS\$($WellKnownSidCacheResult.Name)"
                        IdentityReferenceDns     = "$($DomainNetbiosCacheResult.Dns)\$($WellKnownSidCacheResult.Name)"
                    }

                    return [PSCustomObject]$CombinedProperties

                } else {
                    if ($IdentityReference -like "*SDDL*") { pause }
                    Write-LogMsg @LogParams -Text " # '$Cache' cache miss for '$IdentityReference' on '$DomainNetBIOS'"
                }

            } else {
                Write-LogMsg @LogParams -Text " # Cache miss for '$Cache' on '$DomainNetBIOS'"
            }

        }

    } else {
        Write-LogMsg @LogParams -Text " # Domain NetBIOS cache miss for '$DomainNetBIOS'"
    }

}
