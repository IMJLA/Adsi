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

                    $Properties = @{
                        IdentityReference        = $IdentityReference
                        SIDString                = $WellKnownSidCacheResult.SID
                        IdentityReferenceNetBios = "$DomainNetBIOS\$($WellKnownSidCacheResult.Name)"
                        IdentityReferenceDns     = "$($DomainNetbiosCacheResult.Dns)\$($WellKnownSidCacheResult.Name)"
                    }

                    ForEach ($Prop in $WellKnownSidCacheResult.PSObject.Properties.GetEnumerator().Name) {
                        $Properties[$Prop] = $WellKnownSidCacheResult.$Prop
                    }

                    return [PSCustomObject]$Properties

                } else {
                    #Write-LogMsg @LogParams -Text " # '$Cache' cache miss for '$IdentityReference' on '$DomainNetBIOS'"
                }

            } else {
                #Write-LogMsg @LogParams -Text " # No '$Cache' cache found for '$DomainNetBIOS'"
            }

        }

    } else {
        #Write-LogMsg @LogParams -Text " # Domain NetBIOS cache miss for '$DomainNetBIOS'"
    }

}
