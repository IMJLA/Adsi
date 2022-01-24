function Add-SidInfo {

    param (
        
        # Expecting a DirectoryEntry from the LDAP or WinNT providers
        # Must contain the objectSid property
        [Parameter(ValueFromPipeline)]
        $InputObject,

        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        $TrustedDomainSidNameMap = (Get-TrustedDomainSidNameMap -DirectoryEntryCache $DirectoryEntryCache)

    )

    begin {}

    process {
        ForEach ($Object in $InputObject) {
            if ($Object -eq $null) {continue}
            elseif ($Object.objectSid.Value) {
                [string]$SID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]$Object.objectSid.Value,0)
            }
            elseif ($Object.Properties['objectSid'].Value) {
                [string]$SID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]$Object.Properties['objectSid'].Value,0)
            }
            elseif ($Object.Properties['objectSid']) {
                [string]$SID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]($Object.Properties['objectSid'] | %{$_}),0)
            }

            if ($Object.Properties['samaccountname']) {
                $SamAccountName = $Object.Properties['samaccountname']
            }
            else {
                #DirectoryEntries from the WinNT provider for local accounts do not have a samaccountname attribute so we use name instead
                $SamAccountName = $Object.Properties['name']
            }

            # The SID of the domain is the SID of the user minus the last block of numbers
            $DomainSid = $SID.Substring(0,$Sid.LastIndexOf("-"))

            # Lookup other information about the domain using its SID as the key
            $DomainObject = $TrustedDomainSidNameMap[$DomainSid]

            #Write-Debug "$SamAccountName`t$SID"
                                                
            $Object |
                Add-Member -PassThru -Force @{
                    SidString = $SID
                    Domain = $DomainObject
                    SamAccountName = $SamAccountName
                }
        }
    }

    end{
    
    }
}