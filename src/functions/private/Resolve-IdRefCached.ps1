function Resolve-IdRefCached {

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

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [ref]$DomainsByNetbios = ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [ref]$DomainsBySid = ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [ref]$DomainsByFqdn = ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Log messages which have not yet been written to disk
        [Parameter(Mandatory)]
        [ref]$LogBuffer,

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug'

    )

    #$Log = @{
    #    ThisHostname = $ThisHostname
    #    Type         = $DebugOutputStream
    #    Buffer       = $LogBuffer
    #    WhoAmI       = $WhoAmI
    #}

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
