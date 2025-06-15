function Resolve-IdRefCached {
    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Resolve-IdRefCached')]
    [OutputType([PSCustomObject])]

    param (

        # IdentityReference from an Access Control Entry
        # Expecting either a SID (S-1-5-18) or an NT account name (CONTOSO\User)
        [Parameter(Mandatory)]
        [string]$IdentityReference,

        # Object from Get-AdsiServer representing the directory server and its attributes
        [PSObject]$AdsiServer,

        # NetBIOS name of the ADSI server
        [string]$ServerNetBIOS = $AdsiServer.Netbios

    )

    ForEach ($Cache in 'WellKnownSidBySid', 'WellKnownSIDByName') {

        if ($AdsiServer.$Cache) {

            #Write-LogMsg @Log -Text " # '$Cache' cache exists for '$ServerNetBIOS' for '$IdentityReference'"
            $CacheResult = $AdsiServer.$Cache[$IdentityReference]

            if ($CacheResult) {

                #Write-LogMsg @Log -Text " # '$Cache' cache hit on '$ServerNetBIOS': $($CacheResult.Name) for '$IdentityReference'"

                return [PSCustomObject]@{
                    IdentityReference        = $IdentityReference
                    SIDString                = $CacheResult.SID
                    IdentityReferenceNetBios = "$ServerNetBIOS\$($CacheResult.Name)"
                    IdentityReferenceDns     = "$($AdsiServer.Dns)\$($CacheResult.Name)"
                }

            } else {
                #Write-LogMsg @Log -Text " # '$Cache' cache miss on '$ServerNetBIOS' for '$IdentityReference'"
            }

        } else {
            #Write-LogMsg @Log -Text " # No '$Cache' cache for '$ServerNetBIOS' for '$IdentityReference'"
        }

    }

}
