
function Add-DomainFqdnToLdapPath {
    <#
        .SYNOPSIS
        Add a domain FQDN to an LDAP directory path as the server address so the new path can be used for remote queries
        .DESCRIPTION
        Uses RegEx to:
            - Match the Domain Components from the Distinguished Name in the LDAP directory path
            - Convert the Domain Components to an FQDN
            - Insert them into the directory path as the server address
        .INPUTS
        [System.String]$DirectoryPath
        .OUTPUTS
        [System.String] Complete LDAP directory path including server address
        .EXAMPLE
        Add-DomainFqdnToLdapPath -DirectoryPath 'LDAP://CN=user1,OU=UsersOU,DC=ad,DC=contoso,DC=com'
        LDAP://ad.contoso.com/CN=user1,OU=UsersOU,DC=ad,DC=contoso,DC=com

        Add the domain FQDN to a single LDAP directory path
    #>
    [OutputType([System.String])]
    param (

        # Incomplete LDAP directory path containing a distinguishedName but lacking a server address
        [Parameter(ValueFromPipeline)]
        [string[]]$DirectoryPath

    )
    begin {

        $PathRegEx = '(?<Path>LDAP:\/\/[^\/]*)'
        $DomainRegEx = '(?i)DC=\w{1,}?\b'

    }
    process {

        ForEach ($ThisPath in $DirectoryPath) {

            if ($ThisPath -match $PathRegEx) {

                if ($ThisPath -match $DomainRegEx) {
                    $DomainDN = $null
                    $DomainFqdn = $null
                    $DomainDN = ([regex]::Matches($ThisPath, $DomainRegEx) | ForEach-Object { $_.Value }) -join ','
                    $DomainFqdn = ConvertTo-Fqdn -DistinguishedName $DomainDN
                    if ($ThisPath -match "LDAP:\/\/$DomainFqdn\/") {
                        #Write-Debug -Message " # Domain FQDN already found in the directory path: '$ThisPath'"
                        $ThisPath
                    } else {
                        $ThisPath -replace 'LDAP:\/\/', "LDAP://$DomainFqdn/"
                    }
                } else {
                    #Write-Debug -Message " # Domain DN not found in the directory path: '$ThisPath'"
                    $ThisPath
                }
            } else {
                #Write-Debug -Message " # Not an expected directory path: '$ThisPath'"
                $ThisPath
            }
        }
    }
}
function Add-SidInfo {
    <#
        .SYNOPSIS
        Add some useful properties to a DirectoryEntry object for easier access
        .DESCRIPTION
        Add SidString, Domain, and SamAccountName NoteProperties to a DirectoryEntry
        .INPUTS
        [System.DirectoryServices.DirectoryEntry] or a [PSCustomObject] imitation. InputObject parameter.  Must contain the objectSid property.
        .OUTPUTS
        [System.DirectoryServices.DirectoryEntry] or a [PSCustomObject] imitation. Whatever was input, but with three extra properties added now.
        .EXAMPLE
        [System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrator') | Add-SidInfo
        distinguishedName :
        Path              : WinNT://localhost/Administrator

        The output object's default format is not modified so with default formatting it appears identical to the original.
        Upon closer inspection it now has SidString, Domain, and SamAccountName properties.
    #>
    [OutputType([System.DirectoryServices.DirectoryEntry[]], [PSCustomObject[]])]
    param (

        # Expecting a [System.DirectoryServices.DirectoryEntry] from the LDAP or WinNT providers, or a [PSCustomObject] imitation from Get-DirectoryEntry.
        # Must contain the objectSid property
        [Parameter(ValueFromPipeline)]
        $InputObject,

        <#
        Hashtable containing cached directory entries so they don't have to be retrieved from the directory again
        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{}))

    )

    begin {}

    process {
        ForEach ($Object in $InputObject) {
            $SID = $null
            $SamAccountName = $null
            $DomainObject = $null

            if ($null -eq $Object) { continue }
            elseif ($Object.objectSid.Value ) {
                # With WinNT directory entries for the root (WinNT://localhost), objectSid is a method rather than a property
                # So we need to filter out those instances here to avoid this error:
                # The following exception occurred while retrieving the string representation for method "objectSid":
                # "Object reference not set to an instance of an object."
                if ( $Object.objectSid.Value.GetType().FullName -ne 'System.Management.Automation.PSMethod' ) {
                    [string]$SID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]$Object.objectSid.Value, 0)
                }
            } elseif ($Object.objectSid) {
                # With WinNT directory entries for the root (WinNT://localhost), objectSid is a method rather than a property
                # So we need to filter out those instances here to avoid this error:
                # The following exception occurred while retrieving the string representation for method "objectSid":
                # "Object reference not set to an instance of an object."
                if ($Object.objectSid.GetType().FullName -ne 'System.Management.Automation.PSMethod') {
                    [string]$SID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]$Object.objectSid, 0)
                }
            } elseif ($Object.Properties) {
                if ($Object.Properties['objectSid'].Value) {
                    [string]$SID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]$Object.Properties['objectSid'].Value, 0)
                } elseif ($Object.Properties['objectSid']) {
                    [string]$SID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]($Object.Properties['objectSid'] | ForEach-Object { $_ }), 0)
                }
                if ($Object.Properties['samaccountname']) {
                    $SamAccountName = $Object.Properties['samaccountname']
                } else {
                    #DirectoryEntries from the WinNT provider for local accounts do not have a samaccountname attribute so we use name instead
                    $SamAccountName = $Object.Properties['name']
                }
            } elseif ($Object.objectSid) {
                [string]$SID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]$Object.objectSid, 0)
            }

            if ($Object.Domain.Sid) {
                #if ($Object.Domain.GetType().FullName -ne 'System.Management.Automation.PSMethod') {
                # This would only have come from Add-SidInfo in the first place
                # This means it was added with Add-Member in Get-DirectoryEntry for the root of the computer's directory
                if ($null -eq $SID) {
                    [string]$SID = $Object.Domain.Sid
                }
                $DomainObject = $Object.Domain
                #}
            }
            if (-not $DomainObject) {
                # The SID of the domain is the SID of the user minus the last block of numbers
                $DomainSid = $SID.Substring(0, $Sid.LastIndexOf("-"))

                # Lookup other information about the domain using its SID as the key
                $DomainObject = $DomainsBySid[$DomainSid]
            }

            #Write-Debug -Message "$SamAccountName`t$SID"

            $Object |
            Add-Member -PassThru -Force @{
                SidString      = $SID
                Domain         = $DomainObject
                SamAccountName = $SamAccountName
            }
        }
    }

    end {

    }
}
function ConvertFrom-DirectoryEntry {
    <#
    .SYNOPSIS
    Convert a DirectoryEntry to a PSCustomObject
    .DESCRIPTION
    Recursively convert every property into a string, or a PSCustomObject (whose properties are all strings, or more PSCustomObjects)
    This obfuscates the troublesome PropertyCollection and PropertyValueCollection and Hashtable aspects of working with ADSI
    .NOTES
    # TODO: There is a faster way than Select-Object, just need to dig into the default formatting of DirectoryEntry to see how to get those properties
    #>

    param (
        [Parameter(
            Position = 0,
            ValueFromPipeline
        )]
        [System.DirectoryServices.DirectoryEntry[]]$DirectoryEntry
    )

    process {
        ForEach ($ThisDirectoryEntry in $DirectoryEntry) {
            $ObjectWithProperties = $ThisDirectoryEntry |
            Select-Object -Property *

            $ObjectNoteProperties = $ObjectWithProperties |
            Get-Member -MemberType Property, CodeProperty, ScriptProperty, NoteProperty

            $ThisObject = @{}
            ForEach ($ThisObjProperty in $ObjectNoteProperties) {
                $ThisObject = ConvertTo-SimpleProperty -InputObject $ObjectWithProperties -Property $ThisObjProperty.Name -PropertyDictionary $ThisObject
            }

            [PSCustomObject]$ThisObject
        }
    }
}
function ConvertFrom-PropertyValueCollectionToString {
    <#
        .SYNOPSIS
        Convert a PropertyValueCollection to a string
        .DESCRIPTION
        Useful when working with System.DirectoryServices and some other namespaces
        .INPUTS
        None. Pipeline input is not accepted.
        .OUTPUTS
        [System.String]
        .EXAMPLE
        $DirectoryEntry = [adsi]("WinNT://$(hostname)")
        $DirectoryEntry.Properties.Keys |
        ForEach-Object {
            ConvertFrom-PropertyValueCollectionToString -PropertyValueCollection $DirectoryEntry.Properties[$_]
        }

        For each property in a DirectoryEntry, convert its corresponding PropertyValueCollection to a string
    #>
    param (
        [System.DirectoryServices.PropertyValueCollection]$PropertyValueCollection
    )
    $SubType = & { $PropertyValueCollection.Value.GetType().FullName } 2>$null
    switch ($SubType) {
        'System.Byte[]' { ConvertTo-DecStringRepresentation -ByteArray $PropertyValueCollection.Value }
        default { "$($PropertyValueCollection.Value)" }
    }
}
function ConvertTo-DecStringRepresentation {
    <#
        .SYNOPSIS
        Convert a byte array to a string representation of its decimal format
        .DESCRIPTION
        Uses the custom format operator -f to format each byte as a string decimal representation
        .INPUTS
        [System.Byte[]]$ByteArray
        .OUTPUTS
        [System.String] Array of strings representing the byte array's decimal values
        .EXAMPLE
        ConvertTo-DecStringRepresentation -ByteArray $Bytes

        Convert the binary SID $Bytes to a decimal string representation
    #>
    [OutputType([System.String])]
    param (
        # Byte array.  Often the binary format of an objectSid or LoginHours
        [byte[]]$ByteArray
    )

    $ByteArray |
    ForEach-Object {
        '{0}' -f $_
    }
}
function ConvertTo-DistinguishedName {
    <#
        .SYNOPSIS
        Convert a domain NetBIOS name to its distinguishedName
        .DESCRIPTION
        https://docs.microsoft.com/en-us/windows/win32/api/iads/nn-iads-iadsnametranslate
        .INPUTS
        [System.String]$Domain
        .OUTPUTS
        [System.String] distinguishedName of the domain
        .EXAMPLE
        ConvertTo-DistinguishedName -Domain 'CONTOSO'
        DC=ad,DC=contoso,DC=com

        Resolve the NetBIOS domain 'CONTOSO' to its distinguishedName 'DC=ad,DC=contoso,DC=com'
    #>
    [OutputType([System.String])]
    param (
        # NetBIOS name of the domain
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'NetBIOS')]
        [string[]]$Domain,

        [Parameter(ParameterSetName = 'NetBIOS')]
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # NetBIOS name of the domain
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'FQDN')]
        [string[]]$DomainFQDN,

        # Type of initialization to be performed
        # Will be translated to the corresponding integer for use as the lnSetType parameter of the IADsNameTranslate::Init method (iads.h)
        # https://docs.microsoft.com/en-us/windows/win32/api/iads/ne-iads-ads_name_inittype_enum
        [string]$InitType = 'ADS_NAME_INITTYPE_GC',

        # Format of the name of the directory object that will be used for the input
        # Will be translated to the corresponding integer for use as the lnSetType parameter of the IADsNameTranslate::Set method (iads.h)
        # https://docs.microsoft.com/en-us/windows/win32/api/iads/ne-iads-ads_name_type_enum
        [string]$InputType = 'ADS_NAME_TYPE_NT4',

        # Format of the name of the directory object that will be used for the output
        # Will be translated to the corresponding integer for use as the lnSetType parameter of the IADsNameTranslate::Get method (iads.h)
        # https://docs.microsoft.com/en-us/windows/win32/api/iads/ne-iads-ads_name_type_enum
        [string]$OutputType = 'ADS_NAME_TYPE_1779',

        <#
        AdsiProvider (WinNT or LDAP) of the servers associated with the provided FQDNs or NetBIOS names

        This parameter can be used to reduce calls to Find-AdsiProvider

        Useful when that has been done already but the DomainsByFqdn and DomainsByNetbios caches have not been updated yet
        #>
        [string]$AdsiProvider

    )
    begin {

        $ThisHostname = HOSTNAME.EXE

        # Declare constants for these Windows enums
        # We need to because PowerShell makes it hard to directly use the Win32 API and read the enum definition
        # Use hashtables instead of enums since this use case is so simple
        $ADS_NAME_INITTYPE_dict = @{
            ADS_NAME_INITTYPE_DOMAIN = 1 #Initializes a NameTranslate object by setting the domain that the object binds to.
            ADS_NAME_INITTYPE_SERVER = 2 #Initializes a NameTranslate object by setting the server that the object binds to.
            ADS_NAME_INITTYPE_GC     = 3 #Initializes a NameTranslate object by locating the global catalog that the object binds to.
        }
        $ADS_NAME_TYPE_dict = @{
            ADS_NAME_TYPE_1779                    = 1 #Name format as specified in RFC 1779. For example, "CN=Jeff Smith,CN=users,DC=Fabrikam,DC=com".
            ADS_NAME_TYPE_CANONICAL               = 2 #Canonical name format. For example, "Fabrikam.com/Users/Jeff Smith".
            ADS_NAME_TYPE_NT4                     = 3 #Account name format used in Windows. For example, "Fabrikam\JeffSmith".
            ADS_NAME_TYPE_DISPLAY                 = 4 #Display name format. For example, "Jeff Smith".
            ADS_NAME_TYPE_DOMAIN_SIMPLE           = 5 #Simple domain name format. For example, "JeffSmith@Fabrikam.com".
            ADS_NAME_TYPE_ENTERPRISE_SIMPLE       = 6 #Simple enterprise name format. For example, "JeffSmith@Fabrikam.com".
            ADS_NAME_TYPE_GUID                    = 7 #Global Unique Identifier format. For example, "{95ee9fff-3436-11d1-b2b0-d15ae3ac8436}".
            ADS_NAME_TYPE_UNKNOWN                 = 8 #Unknown name type. The system will estimate the format. This element is a meaningful option only with the IADsNameTranslate.Set or the IADsNameTranslate.SetEx method, but not with the IADsNameTranslate.Get or IADsNameTranslate.GetEx method.
            ADS_NAME_TYPE_USER_PRINCIPAL_NAME     = 9 #User principal name format. For example, "JeffSmith@Fabrikam.com".
            ADS_NAME_TYPE_CANONICAL_EX            = 10 #Extended canonical name format. For example, "Fabrikam.com/Users Jeff Smith".
            ADS_NAME_TYPE_SERVICE_PRINCIPAL_NAME  = 11 #Service principal name format. For example, "www/www.fabrikam.com@fabrikam.com".
            ADS_NAME_TYPE_SID_OR_SID_HISTORY_NAME = 12 #A SID string, as defined in the Security Descriptor Definition Language (SDDL), for either the SID of the current object or one from the object SID history. For example, "O:AOG:DAD:(A;;RPWPCCDCLCSWRCWDWOGA;;;S-1-0-0)"
        }
        $ChosenInitType = $ADS_NAME_INITTYPE_dict[$InitType]
        $ChosenInputType = $ADS_NAME_TYPE_dict[$InputType]
        $ChosenOutputType = $ADS_NAME_TYPE_dict[$OutputType]

    }
    process {
        ForEach ($ThisDomain in $Domain) {
            $DomainCacheResult = $DomainsByNetbios[$ThisDomain]
            if ($DomainCacheResult) {
                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tConvertTo-DistinguishedName`t# Domain NetBIOS cache hit for '$ThisDomain'"
                #ConvertTo-DistinguishedName -DomainFQDN $DomainCacheResult.Dns -AdsiProvider $DomainCacheResult.AdsiProvider
                $DomainCacheResult.DistinguishedName
            } else {
                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tConvertTo-DistinguishedName`t# Domain NetBIOS cache miss for '$ThisDomain'. Available keys: $($DomainsByNetBios.Keys -join ',')"
                Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostname`tConvertTo-DistinguishedName`t`$IADsNameTranslateComObject = New-Object -comObject 'NameTranslate' # For '$ThisDomain'"
                $IADsNameTranslateComObject = New-Object -comObject "NameTranslate"
                Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostname`tConvertTo-DistinguishedName`t`$IADsNameTranslateInterface = `$IADsNameTranslateComObject.GetType() # For '$ThisDomain'"
                $IADsNameTranslateInterface = $IADsNameTranslateComObject.GetType()
                Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostname`tConvertTo-DistinguishedName`t`$null = `$IADsNameTranslateInterface.InvokeMember('Init', 'InvokeMethod', `$Null, `$IADsNameTranslateComObject, ($ChosenInitType, `$Null)) # For '$ThisDomain'"
                $null = $IADsNameTranslateInterface.InvokeMember("Init", "InvokeMethod", $Null, $IADsNameTranslateComObject, ($ChosenInitType, $Null))

                # For a non-domain-joined system there is no DistinguishedName for the domain
                # Suppress errors when calling these next 2 methods
                #     Exception calling "InvokeMember" with "5" argument(s): "Name translation: Could not find the name or insufficient right to see name. (Exception from HRESULT: 0x80072116)"
                Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostname`tConvertTo-DistinguishedName`t`$null = `$IADsNameTranslateInterface.InvokeMember('Set', 'InvokeMethod', `$Null, `$IADsNameTranslateComObject, ($ChosenInputType, '$ThisDomain\')) # For '$ThisDomain'"
                $null = { $IADsNameTranslateInterface.InvokeMember("Set", "InvokeMethod", $Null, $IADsNameTranslateComObject, ($ChosenInputType, "$ThisDomain\")) } 2>$null
                #     Exception calling "InvokeMember" with "5" argument(s): "Unspecified error (Exception from HRESULT: 0x80004005 (E_FAIL))"
                Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostname`tConvertTo-DistinguishedName`t`$IADsNameTranslateInterface.InvokeMember('Get', 'InvokeMethod', `$Null, `$IADsNameTranslateComObject, $ChosenOutputType) # For '$ThisDomain'"
                $null = { $null = { $IADsNameTranslateInterface.InvokeMember("Get", "InvokeMethod", $Null, $IADsNameTranslateComObject, $ChosenOutputType) } 2>$null } 2>$null
            }
        }
        ForEach ($ThisDomain in $DomainFQDN) {
            $DomainCacheResult = $DomainsByFqdn[$ThisDomain]
            if ($DomainCacheResult) {
                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tConvertTo-DistinguishedName`t# Domain FQDN cache hit for '$ThisDomain'"
                $DomainCacheResult.DistinguishedName
            } else {
                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tConvertTo-DistinguishedName`t# Domain FQDN cache miss for '$ThisDomain'"
                if (-not $AdsiProvider) {
                    $AdsiProvider = Find-AdsiProvider -AdsiServer $ThisDomain
                }
                if ($AdsiProvider -ne 'WinNT') {
                    "dc=$($ThisDomain -replace '\.',',dc=')"
                }
            }
        }
    }
}
function ConvertTo-DomainNetBIOS {
    param (
        [string]$DomainFQDN,

        [string]$AdsiProvider,

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{}))

    )

    $DomainCacheResult = $DomainsByFqdn[$DomainFQDN]
    if ($DomainCacheResult) {
        Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tConvertTo-DomainNetBIOS`t # Domain FQDN cache hit for '$DomainFQDN'"
        return $DomainCacheResult.Netbios
    }

    Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tConvertTo-DomainNetBIOS`t # Domain FQDN cache miss for '$DomainFQDN'"

    $ThisHostName = HOSTNAME.EXE

    if ($AdsiProvider -eq 'LDAP') {
        $RootDSE = Get-DirectoryEntry -DirectoryPath "LDAP://$DomainFQDN/rootDSE" -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
        Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tConvertTo-DomainNetBIOS`t`$RootDSE.InvokeGet('defaultNamingContext')"
        $DomainDistinguishedName = $RootDSE.InvokeGet("defaultNamingContext")
        Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tConvertTo-DomainNetBIOS`t`$RootDSE.InvokeGet('configurationNamingContext')"
        $ConfigurationDN = $rootDSE.InvokeGet("configurationNamingContext")
        $partitions = Get-DirectoryEntry -DirectoryPath "LDAP://$DomainFQDN/cn=partitions,$ConfigurationDN" -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid

        ForEach ($Child In $Partitions.Children) {
            If ($Child.nCName -contains $DomainDistinguishedName) {
                return $Child.nETBIOSName
            }
        }
    } else {
        $LengthOfNetBIOSName = $DomainFQDN.IndexOf('.')
        $DomainFQDN.Substring(0, $LengthOfNetBIOSName)
    }

}
function ConvertTo-DomainSidString {
    param (

        # Domain DNS name to convert to the domain's SID
        [Parameter(Mandatory)]
        [string]$DomainDnsName,

        <#
        Hashtable containing cached directory entries so they don't have to be retrieved from the directory again

        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

        <#
        AdsiProvider (WinNT or LDAP) of the servers associated with the provided FQDNs or NetBIOS names

        This parameter can be used to reduce calls to Find-AdsiProvider

        Useful when that has been done already but the DomainsByFqdn and DomainsByNetbios caches have not been updated yet
        #>
        [string]$AdsiProvider

    )

    $CacheResult = $DomainsByFqdn[$DomainDnsName]
    if ($CacheResult) {
        Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tConvertTo-DomainSidString`t # Domain FQDN cache hit for '$DomainDnsName'"
        return $CacheResult.Sid
    }
    Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tConvertTo-DomainSidString`t # Domain FQDN cache miss for '$DomainDnsName'"

    if (
        -not $AdsiProvider -or
        $AdsiProvider -eq 'LDAP'
    ) {
        $DomainDirectoryEntry = Get-DirectoryEntry -DirectoryPath "LDAP://$DomainDnsName" -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
        try {
            $null = $DomainDirectoryEntry.RefreshCache('objectSid')
        } catch {
            Write-Debug "$(Get-Date -Format s)`t$(hostname)`tConvertTo-DomainSidString`t # LDAP connection failed to '$DomainDnsName' - $($_.Exception.Message)"
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tConvertTo-DomainSidString`tFind-LocalAdsiServerSid -ComputerName '$DomainDnsName'"
            $DomainSid = Find-LocalAdsiServerSid -ComputerName $DomainDnsName
            return $DomainSid
        }
    } else {
        Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tConvertTo-DomainSidString`tFind-LocalAdsiServerSid -ComputerName '$DomainDnsName'"
        $DomainSid = Find-LocalAdsiServerSid -ComputerName $DomainDnsName
        return $DomainSid
    }

    $DomainSid = $null

    if ($DomainDirectoryEntry.Properties) {
        $objectSIDProperty = $DomainDirectoryEntry.Properties['objectSid']
        if ($objectSIDProperty.Value) {
            $SidByteArray = [byte[]]$objectSIDProperty.Value
        } else {
            $SidByteArray = [byte[]]$objectSIDProperty
        }
    } else {
        $SidByteArray = [byte[]]$DomainDirectoryEntry.objectSid
    }

    Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tConvertTo-DomainSidString`t[System.Security.Principal.SecurityIdentifier]::new([byte[]]@($($SidByteArray -join ',')), 0).ToString()"
    $DomainSid = [System.Security.Principal.SecurityIdentifier]::new($SidByteArray, 0).ToString()

    if ($DomainSid) {
        return $DomainSid
    } else {
        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tConvertTo-DomainSidString`t # LDAP Domain: '$DomainDnsName' has an invalid SID - $($_.Exception.Message)"
    }

}
function ConvertTo-Fqdn {
    <#
        .SYNOPSIS
        Convert a domain distinguishedName name or NetBIOS name to its FQDN
        .DESCRIPTION
        For the DistinguishedName parameter, uses PowerShell's -replace operator to perform the conversion
        For the NetBIOS parameter, uses ConvertTo-DistinguishedName to convert from NetBIOS to distinguishedName, then recursively calls this function to get the FQDN
        .INPUTS
        [System.String]$DistinguishedName
        .OUTPUTS
        [System.String] FQDN version of the distinguishedName
        .EXAMPLE
        ConvertTo-Fqdn -DistinguishedName 'DC=ad,DC=contoso,DC=com'
        ad.contoso.com

        Convert the domain distinguishedName 'DC=ad,DC=contoso,DC=com' to its FQDN format 'ad.contoso.com'
    #>
    [OutputType([System.String])]
    param (
        # distinguishedName of the domain
        [Parameter(
            ParameterSetName = 'DistinguishedName',
            ValueFromPipeline
        )]
        [string[]]$DistinguishedName,

        # NetBIOS name of the domain
        [Parameter(
            ParameterSetName = 'NetBIOS',
            ValueFromPipeline
        )]
        [string[]]$NetBIOS,

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{}))

    )
    process {
        ForEach ($DN in $DistinguishedName) {
            $DN -replace ',DC=', '.' -replace 'DC=', ''
        }

        ForEach ($ThisNetBios in $NetBIOS) {
            $DomainObject = $DomainsByNetbios[$DomainNetBIOS]

            if (
                -not $DomainObject -and
                -not [string]::IsNullOrEmpty($DomainNetBIOS)
            ) {
                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tConvertTo-Fqdn`t # Domain NetBIOS cache miss for '$DomainNetBIOS'"
                $DomainObject = Get-AdsiServer -Netbios $DomainNetBIOS  -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
                $DomainsByNetbios[$DomainNetBIOS] = $DomainObject
            }

            $DomainObject.Dns
        }
    }
}
function ConvertTo-HexStringRepresentation {
    <#
        .SYNOPSIS
        Convert a SID from byte array format to a string representation of its hexadecimal format
        .DESCRIPTION
        Uses the custom format operator -f to format each byte as a string hex representation
        .INPUTS
        [System.Byte[]]$SIDByteArray
        .OUTPUTS
        [System.String] SID as an array of strings representing the byte array's hexadecimal values
        .EXAMPLE
        ConvertTo-HexStringRepresentation -SIDByteArray $Bytes

        Convert the binary SID $Bytes to a hexadecimal string representation
    #>
    [OutputType([System.String[]])]
    param (
        # SID
        [byte[]]$SIDByteArray
    )

    $SIDHexString = $SIDByteArray |
    ForEach-Object {
        '{0:X}' -f $_
    }
    return $SIDHexString
}
function ConvertTo-HexStringRepresentationForLDAPFilterString {
    <#
        .SYNOPSIS
        Convert a SID from byte array format to a string representation of its hexadecimal format, properly formatted for an LDAP filter string
        .DESCRIPTION
        Uses the custom format operator -f to format each byte as a string hex representation
        .INPUTS
        [System.Byte[]]$SIDByteArray
        .OUTPUTS
        [System.String] SID as an array of strings representing the byte array's hexadecimal values
        .EXAMPLE
        ConvertTo-HexStringRepresentationForLDAPFilterString -SIDByteArray $Bytes

        Convert the binary SID $Bytes to a hexadecimal string representation, formatted for use in an LDAP filter string
    #>
    [OutputType([System.String])]
    param (
        # SID to convert to a hex string
        [byte[]]$SIDByteArray
    )
    $Hexes = $SIDByteArray |
    ForEach-Object {
        '{0:X}' -f $_
    } |
    ForEach-Object {
        if ($_.Length -eq 2) {
            $_
        } else {
            "0$_"
        }
    }
    "\$($Hexes -join '\')"
}
function ConvertTo-SidByteArray {
    <#
        .SYNOPSIS
        Convert a SID from a string to binary format (byte array)
        .DESCRIPTION
        Uses the GetBinaryForm method of the [System.Security.Principal.SecurityIdentifier] class
        .INPUTS
        [System.String]$SidString
        .OUTPUTS
        [System.Byte] SID a a byte array
        .EXAMPLE
        ConvertTo-SidByteArray -SidString $SID

        Convert the SID string to a byte array
    #>
    [OutputType([System.Byte[]])]
    param (
        # SID to convert to binary
        [Parameter(ValueFromPipeline)]
        [string[]]$SidString
    )
    process {
        ForEach ($ThisSID in $SidString) {
            $SID = [System.Security.Principal.SecurityIdentifier]::new($ThisSID)
            [byte[]]$Bytes = [byte[]]::new($SID.BinaryLength)
            $SID.GetBinaryForm($Bytes, 0)
            $Bytes
        }
    }
}
function Expand-AdsiGroupMember {
    <#
        .SYNOPSIS
        Use the LDAP provider to add information about group members to a DirectoryEntry of a group for easier access
        .DESCRIPTION
        Recursively retrieves group members and detailed information about them
        .INPUTS
        [System.DirectoryServices.DirectoryEntry]$DirectoryEntry
        .OUTPUTS
        [System.DirectoryServices.DirectoryEntry] Returned with member info added now (if the DirectoryEntry is a group).
        .EXAMPLE
        [System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrators') | Get-AdsiGroupMember | Expand-AdsiGroupMember

        Need to fix example and add notes
    #>
    [OutputType([System.DirectoryServices.DirectoryEntry])]
    param (

        # Expecting a DirectoryEntry from the LDAP or WinNT providers, or a PSObject imitation from Get-DirectoryEntry
        [parameter(ValueFromPipeline)]
        $DirectoryEntry,

        # Properties of the group members to retrieve
        [string[]]$PropertiesToLoad = @('operatingSystem', 'objectSid', 'samAccountName', 'objectClass', 'distinguishedName', 'name', 'grouptype', 'description', 'managedby', 'member', 'objectClass', 'Department', 'Title'),

        <#
        Hashtable containing cached directory entries so they don't need to be retrieved from the directory again

        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{}))

    )

    begin {
        $i = 0
    }

    process {

        ForEach ($Entry in $DirectoryEntry) {

            $i++

            #$status = ("$(Get-Date -Format s)`t$(hostname)`tExpand-AdsiGroupMember`tStatus: Using ADSI to get info on group member $i`: " + $Entry.Name)
            #Write-Debug -Message "  $status"

            $Principal = $null

            if ($Entry.objectClass -contains 'foreignSecurityPrincipal') {

                if ($Entry.distinguishedName.Value -match '(?>^CN=)(?<SID>[^,]*)') {

                    [string]$SID = $Matches.SID

                    #The SID of the domain is the SID of the user minus the last block of numbers
                    $DomainSid = $SID.Substring(0, $Sid.LastIndexOf("-"))
                    $Domain = $DomainsBySid[$DomainSid]

                    $Principal = Get-DirectoryEntry -DirectoryPath "LDAP://$($Domain.Dns)/<SID=$SID>" -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid

                    try {
                        $null = $Principal.RefreshCache($PropertiesToLoad)
                    } catch {
                        #$Success = $false
                        $Principal = $Entry
                        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-AdsiGroupMember`t$SID could not be retrieved from $Domain"
                    }

                    # Recursively enumerate group members
                    if ($Principal.properties['objectClass'].Value -contains 'group') {
                        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-AdsiGroupMember`t'$($Principal.properties['name'])' is a group in $Domain"
                        $AdsiGroupWithMembers = Get-AdsiGroupMember -Group $Principal -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
                        $Principal = Expand-AdsiGroupMember -DirectoryEntry $AdsiGroupWithMembers.FullMembers -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsBySid $DomainsBySid -DomainsByNetbios $DomainsByNetbios

                    }

                }

            } else {
                $Principal = $Entry
            }

            Add-SidInfo -InputObject $Principal -DirectoryEntryCache $DirectoryEntryCache -DomainsBySid $DomainsBySid -DomainsByNetbios $DomainsByNetbios

        }
    }

}
function Expand-IdentityReference {
    <#
        .SYNOPSIS
        Use ADSI to collect more information about the IdentityReference in NTFS Access Control Entries
        .DESCRIPTION
        Recursively retrieves group members and detailed information about them
        Use caching to reduce duplicate directory queries
        .INPUTS
        [System.Object]$AccessControlEntry
        .OUTPUTS
        [System.Object] The input object is returned with additional properties added:
            DirectoryEntry
            DomainDn
            DomainNetBIOS
            ObjectType
            Members (if the DirectoryEntry is a group).

        .EXAMPLE
        (Get-Acl).Access |
        Resolve-IdentityReference |
        Group-Object -Property IdentityReferenceResolved |
        Expand-IdentityReference

        Incomplete example but it shows the chain of functions to generate the expected input for this
    #>
    [OutputType([System.Object])]
    param (

        # The NTFS AccessControlEntry object(s), grouped by their IdentityReference property
        # TODO: Use System.Security.Principal.NTAccount instead
        [Parameter(ValueFromPipeline)]
        [System.Object[]]$AccessControlEntry,

        # Do not get group members
        [switch]$NoGroupMembers,

        # Thread-safe hashtable to use for caching directory entries and avoiding duplicate directory queries
        [hashtable]$IdentityReferenceCache = ([hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{}))

    )

    begin {

        #Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$(($AccessControlEntry | Measure).Count) unique IdentityReferences found in the $(($AccessControlEntry | Measure).Count) ACEs"

        # Get the SID of the current domain
        $CurrentDomain = (Get-CurrentDomain)

        # Convert the objectSID attribute (byte array) to a security descriptor string formatted according to SDDL syntax (Security Descriptor Definition Language)
        [string]$CurrentDomainSID = & { [System.Security.Principal.SecurityIdentifier]::new([byte[]]$CurrentDomain.objectSid.Value, 0) } 2>$null

        #$i = 0

    }

    process {

        ForEach ($ThisIdentity in $AccessControlEntry) {

            if (-not $ThisIdentity) {
                continue
            }

            $ThisIdentityGroup = $ThisIdentity.Group

            #$i++
            #Calculate the completion percentage, and format it to show 0 decimal places
            #$percentage = "{0:N0}" -f (($i / ($AccessControlEntry.Count)) * 100)

            #Display the progress bar
            #$status = $percentage + "% - Using ADSI to get info on NTFS IdentityReference $i of " + $AccessControlEntry.Count + ": " + $ThisIdentity.Name
            #Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`tStatus: $status"

            #Write-Progress -Activity ("Unique IdentityReferences: " + $AccessControlEntry.Count) -Status $status -PercentComplete $percentage

            if ($null -eq $IdentityReferenceCache[$ThisIdentity.Name]) {

                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # IdentityReferenceCache miss for '$($ThisIdentity.Name)'"

                $DomainDN = $null
                $DirectoryEntry = $null
                $Members = $null

                $GetDirectoryEntryParams = @{
                    DirectoryEntryCache = $DirectoryEntryCache
                    DomainsByNetbios    = $DomainsByNetbios
                }
                $SearchDirectoryParams = @{
                    DirectoryEntryCache = $DirectoryEntryCache
                    DomainsByNetbios    = $DomainsByNetbios
                }

                $StartingIdentityName = $ThisIdentity.Name
                $split = $StartingIdentityName.Split('\')
                $domainNetbiosString = $split[0]
                $name = $split[1]

                if (
                    $null -ne $name -and
                    @($ThisIdentity.Group.AdsiProvider)[0] -eq 'LDAP'
                ) {
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # '$StartingIdentityName' is a domain security principal"

                    $DomainNetbiosCacheResult = $DomainsByNetbios[$domainNetbiosString]
                    if ($DomainNetbiosCacheResult) {
                        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # Domain NetBIOS cache hit for '$domainNetbiosString' for '$StartingIdentityName'"
                        $DomainDn = $DomainNetbiosCacheResult.DistinguishedName
                        $SearchDirectoryParams['DirectoryPath'] = "LDAP://$($DomainNetbiosCacheResult.Dns)/$DomainDn"
                    } else {
                        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # Domain NetBIOS cache miss for '$domainNetbiosString' for '$StartingIdentityName'"
                        if ( -not [string]::IsNullOrEmpty($domainNetbiosString) ) {
                            $DomainDn = ConvertTo-DistinguishedName -Domain $domainNetbiosString -DomainsByNetbios $DomainsByNetbios
                        }
                        $SearchDirectoryParams['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath "LDAP://$domainNetbiosString"
                    }

                    # Search the domain for the principal
                    $SearchDirectoryParams['Filter'] = "(samaccountname=$Name)"
                    $SearchDirectoryParams['PropertiesToLoad'] = @(
                        'objectClass',
                        'distinguishedName',
                        'name',
                        'grouptype',
                        'description',
                        'managedby',
                        'member',
                        'objectClass',
                        'Department',
                        'Title'
                    )
                    try {
                        $DirectoryEntry = Search-Directory @SearchDirectoryParams
                    } catch {
                        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # '$StartingIdentityName' could not be resolved against its directory"
                        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # $($_.Exception.Message) for '$StartingIdentityName"
                    }

                } elseif (
                    $StartingIdentityName.Substring(0, $StartingIdentityName.LastIndexOf('-') + 1) -eq $CurrentDomainSID
                    #((($StartingIdentityName -split '-') | Select-Object -SkipLast 1) -join '-') -eq $CurrentDomainSID
                ) {
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # '$StartingIdentityName' is an unresolved SID from the current domain"

                    # Get the distinguishedName and netBIOSName of the current domain.  This also determines whether the domain is online.
                    $DomainDN = $CurrentDomain.distinguishedName.Value
                    $DomainFQDN = ConvertTo-Fqdn -DistinguishedName $DomainDN

                    $SearchDirectoryParams['DirectoryPath'] = "LDAP://$DomainFQDN/cn=partitions,cn=configuration,$DomainDn"
                    $SearchDirectoryParams['Filter'] = "(&(objectcategory=crossref)(dnsroot=$DomainFQDN)(netbiosname=*))"
                    $SearchDirectoryParams['PropertiesToLoad'] = 'netbiosname'

                    $DomainCrossReference = Search-Directory @SearchDirectoryParams
                    if ($DomainCrossReference.Properties ) {
                        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t# The domain '$DomainFQDN' is online for '$StartingIdentityName'"
                        [string]$domainNetbiosString = $DomainCrossReference.Properties['netbiosname']
                        # TODO: The domain is online, so let's see if any domain trusts have issues?  Determine if SID is foreign security principal?
                        # TODO: What if the foreign security principal exists but the corresponding domain trust is down?  Don't want to recommend deletion of the ACE in that case.
                    }
                    $SidObject = [System.Security.Principal.SecurityIdentifier]::new($StartingIdentityName)
                    $SidBytes = [byte[]]::new($SidObject.BinaryLength)
                    $null = $SidObject.GetBinaryForm($SidBytes, 0)
                    $ObjectSid = ConvertTo-HexStringRepresentationForLDAPFilterString -SIDByteArray $SidBytes
                    $SearchDirectoryParams['DirectoryPath'] = "LDAP://$DomainFQDN/$DomainDn"
                    $SearchDirectoryParams['Filter'] = "(objectsid=$ObjectSid)"
                    $SearchDirectoryParams['PropertiesToLoad'] = @(
                        'objectClass',
                        'distinguishedName',
                        'name',
                        'grouptype',
                        'description',
                        'managedby',
                        'member',
                        'objectClass',
                        'Department',
                        'Title'
                    )
                    try {
                        $DirectoryEntry = Search-Directory @SearchDirectoryParams
                    } catch {
                        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # '$StartingIdentityName' could not be resolved against its directory"
                        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # $($_.Exception.Message) for '$StartingIdentityName'"
                    }


                } else {

                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # '$StartingIdentityName' is a local security principal or unresolved SID"

                    if ($null -eq $name) { $name = $StartingIdentityName }

                    if ($name -like "S-1-*") {
                        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) is an unresolved SID"

                        # The SID of the domain is the SID of the user minus the last block of numbers
                        $DomainSid = $name.Substring(0, $name.LastIndexOf("-"))

                        # Determine if SID belongs to current domain
                        if ($DomainSid -eq $CurrentDomainSID) {
                            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) belongs to the current domain.  Could be a deleted user.  ?possibly a foreign security principal corresponding to an offline trusted domain or deleted user in the trusted domain?"
                        } else {
                            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) does not belong to the current domain. Could be a local security principal or belong to an unresolvable domain."
                        }

                        # Lookup other information about the domain using its SID as the key
                        $DomainObject = $DomainsBySID[$DomainSid]
                        if ($DomainObject) {
                            $GetDirectoryEntryParams['DirectoryPath'] = "WinNT://$($DomainObject.Dns)/Users,group"
                            $domainNetbiosString = $DomainObject.Netbios
                        } else {
                            $GetDirectoryEntryParams['DirectoryPath'] = "WinNT://$domainNetbiosString/Users,group"
                        }

                        try {
                            $UsersGroup = Get-DirectoryEntry @GetDirectoryEntryParams
                        } catch {
                            Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`tCould not get '$($GetDirectoryEntryParams['DirectoryPath'])' using PSRemoting"
                            Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$_"
                        }
                        $MembersOfUsersGroup = Get-WinNTGroupMember -DirectoryEntry $UsersGroup -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid

                        $DirectoryEntry = $MembersOfUsersGroup |
                        Where-Object -FilterScript { ($name -eq [System.Security.Principal.SecurityIdentifier]::new([byte[]]$_.Properties['objectSid'].Value, 0)) }

                        if ($DirectoryEntry.Name) {
                            $AccountName = $DirectoryEntry.Name
                        } else {
                            if ($DirectoryEntry.Properties) {
                                if ($DirectoryEntry.Properties['name'].Value) {
                                    $AccountName = $DirectoryEntry.Properties['name'].Value
                                } else {
                                    $AccountName = $DirectoryEntry.Properties['name']
                                }
                            }
                        }

                        $ThisIdentity = [pscustomobject]@{
                            Count = $(($ThisIdentityGroup | Measure-Object).Count)
                            Name  = "$domainNetbiosString\" + $AccountName
                            Group = $ThisIdentityGroup
                            # Unclear why this was filtered so I have removed it to see what happens
                            #Group = $ThisIdentityGroup | Where-Object -FilterScript { ($_.SourceAccessList.Path -split '\\')[2] -eq $domainNetbiosString } # Should be already Resolved to a UNC path so it reflects the server name
                        }

                    } else {
                        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # '$StartingIdentityName' is a local security principal"
                        $DomainNetbiosCacheResult = $DomainsByNetbios[$domainNetbiosString]
                        if ($DomainNetbiosCacheResult) {
                            $GetDirectoryEntryParams['DirectoryPath'] = "WinNT://$($DomainNetbiosCacheResult.Dns)/$name"
                        } else {
                            $GetDirectoryEntryParams['DirectoryPath'] = "WinNT://$domainNetbiosString/$name"
                        }
                        try {
                            $GetDirectoryEntryParams['PropertiesToLoad'] = 'members'
                            $DirectoryEntry = Get-DirectoryEntry @GetDirectoryEntryParams
                        } catch {
                            Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($GetDirectoryEntryParams['DirectoryPath']) could not be resolved for '$StartingIdentityName'"
                        }
                    }
                }

                $ObjectType = $null
                if ($null -ne $DirectoryEntry) {

                    if (
                        $DirectoryEntry.Properties['objectClass'] -contains 'group' -or
                        $DirectoryEntry.SchemaClassName -eq 'group'
                    ) {
                        $ObjectType = 'Group'
                    } else {
                        $ObjectType = 'User'
                    }

                    if ($NoGroupMembers -eq $false) {

                        if (
                            # WinNT DirectoryEntries do not contain an objectClass property
                            # If this property exists it is an LDAP DirectoryEntry rather than WinNT
                            $DirectoryEntry.Properties['objectClass'] -contains 'group'
                        ) {
                            # Retrieve the members of groups from the LDAP provider
                            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # $($DirectoryEntry.Path) is an LDAP security principal for '$StartingIdentityName'"
                            $Members = (Get-AdsiGroupMember -Group $DirectoryEntry -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid).FullMembers
                        } else {
                            # Retrieve the members of groups from the WinNT provider
                            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # $($DirectoryEntry.Path) is a WinNT security principal for '$StartingIdentityName'"
                            if ( $DirectoryEntry.SchemaClassName -eq 'group') {
                                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # $($DirectoryEntry.Path) is a WinNT group for '$StartingIdentityName'"
                                $Members = Get-WinNTGroupMember -DirectoryEntry $DirectoryEntry -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
                            }

                        }

                        # (Get-AdsiGroupMember).FullMembers or Get-WinNTGroupMember could return an array with null members so we must verify that is not true
                        if ($Members) {
                            $Members |
                            ForEach-Object {

                                if ($_.Domain) {

                                    Add-Member -InputObject $_ -Force -NotePropertyMembers @{
                                        Group = $ThisIdentityGroup
                                    }

                                } else {

                                    Add-Member -InputObject $_ -Force -NotePropertyMembers @{
                                        Group  = $ThisIdentityGroup
                                        Domain = [pscustomobject]@{
                                            Dns     = $domainNetbiosString
                                            Netbios = $domainNetbiosString
                                            Sid     = ($name -split '-') | Select-Object -Last 1
                                        }
                                    }

                                }
                            }
                        }

                        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # $($DirectoryEntry.Path) has $(($Members | Measure-Object).Count) members for '$StartingIdentityName'"

                    }
                } else {
                    Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # '$StartingIdentityName' could not be matched to a DirectoryEntry"
                }

                Add-Member -InputObject $ThisIdentity -Force -NotePropertyMembers @{
                    DomainDn       = $DomainDn
                    DomainNetbios  = $DomainNetBiosString
                    ObjectType     = $ObjectType
                    DirectoryEntry = $DirectoryEntry
                    Members        = $Members
                }
                $IdentityReferenceCache[$StartingIdentityName] = $ThisIdentity

            } else {
                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t # IdentityReferenceCache hit for '$($ThisIdentity.Name)'"
                $null = $IdentityReferenceCache[$ThisIdentity.Name].Group.Add($ThisIdentityGroup)
                $ThisIdentity = $IdentityReferenceCache[$ThisIdentity.Name]
            }

            $ThisIdentity

        }

    }

}
function Expand-WinNTGroupMember {
    <#
        .SYNOPSIS
        Use the LDAP provider to add information about group members to a DirectoryEntry of a group for easier access
        .DESCRIPTION
        Recursively retrieves group members and detailed information about them
        .INPUTS
        [System.DirectoryServices.DirectoryEntry]$DirectoryEntry
        .OUTPUTS
        [System.DirectoryServices.DirectoryEntry] Returned with member info added now (if the DirectoryEntry is a group).
        .EXAMPLE
        [System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrators') | Get-WinNTGroupMember | Expand-WinNTGroupMember

        Need to fix example and add notes
    #>
    [OutputType([System.DirectoryServices.DirectoryEntry])]
    param (

        # Expecting a DirectoryEntry from the WinNT provider, or a PSObject imitation from Get-DirectoryEntry
        [Parameter(ValueFromPipeline)]
        $DirectoryEntry,

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{}))

    )
    begin {}
    process {
        ForEach ($ThisEntry in $DirectoryEntry) {

            if (!($ThisEntry.Properties)) {
                Write-Warning "'$ThisEntry' has no properties"
            } elseif ($ThisEntry.Properties['objectClass'] -contains 'group') {

                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-WinNTGroupMember`t'$($ThisEntry.Path)' is an ADSI group"
                (Get-AdsiGroup -DirectoryEntryCache $DirectoryEntryCache -DirectoryPath $ThisEntry.Path -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid).FullMembers |
                Add-SidInfo -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid

            } else {

                if ($ThisEntry.SchemaClassName -eq 'group') {
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-WinNTGroupMember`t'$($ThisEntry.Path)' is a WinNT group"

                    if ($ThisEntry.GetType().FullName -eq 'System.Collections.Hashtable') {
                        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-WinNTGroupMember`t'$($ThisEntry.Path)' is a special group with no direct memberships"
                        Add-SidInfo -InputObject $ThisEntry -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
                    } else {
                        Get-WinNTGroupMember -DirectoryEntry $ThisEntry -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
                    }

                } else {
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tExpand-WinNTGroupMember`t'$($ThisEntry.Path)' is a user account"
                    $ThisEntry | Add-SidInfo -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
                }

            }

        }
    }
}
function Find-AdsiProvider {
    <#
        .SYNOPSIS
        Determine whether a directory server is an LDAP or a WinNT server
        .DESCRIPTION
        Uses the ADSI provider to attempt to query the server using LDAP first, then WinNT second
        .INPUTS
        [System.String] AdsiServer parameter.
        .OUTPUTS
        [System.String] Possible return values are:
            None
            LDAP
            WinNT
        .EXAMPLE
        Find-AdsiProvider -AdsiServer localhost

        Find the ADSI provider of the local computer
        .EXAMPLE
        Find-AdsiProvider -AdsiServer 'ad.contoso.com'

        Find the ADSI provider of the AD domain 'ad.contoso.com'
    #>
    [OutputType([System.String])]

    param (

        # IP address or hostname of the directory server whose ADSI provider type to determine
        [Parameter(ValueFromPipeline)]
        [string[]]$AdsiServer

    )
    process {
        ForEach ($ThisServer in $AdsiServer) {
            $AdsiProvider = $null
            $AdsiPath = "LDAP://$ThisServer"
            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tFind-AdsiProvider`t[System.DirectoryServices.DirectoryEntry]::Exists('$AdsiPath')"
            try {
                $null = [System.DirectoryServices.DirectoryEntry]::Exists($AdsiPath)
                $AdsiProvider = 'LDAP'
            } catch { Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tFind-AdsiProvider`t# $ThisServer did not respond to LDAP" }
            if (!$AdsiProvider) {
                $AdsiPath = "WinNT://$ThisServer"
                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tFind-AdsiProvider`t[System.DirectoryServices.DirectoryEntry]::Exists('$AdsiPath')"
                try {
                    $null = [System.DirectoryServices.DirectoryEntry]::Exists($AdsiPath)
                    $AdsiProvider = 'WinNT'
                } catch {
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tFind-AdsiProvider`t# $ThisServer did not respond to WinNT"
                }
            }
            if (!$AdsiProvider) {
                $AdsiProvider = 'none'
            }
        }
        $AdsiProvider
    }
}
function Find-LocalAdsiServerSid {
    param (
        [string]$ComputerName,
        [string]$ThisHostname = (HOSTNAME.EXE),
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName)
    )
    Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tFind-LocalAdsiServerSid`tGet-Win32UserAccount -ComputerName '$ComputerName'"
    $Win32UserAccounts = Get-Win32UserAccount -ComputerName $ComputerName -ThisHostname $ThisHostname -ThisFqdn $ThisFqdn
    if (-not $Win32UserAccounts) {
        return
    }
    [string]$LocalAccountSID = @($Win32UserAccounts.SID)[0]
    return $LocalAccountSID.Substring(0, $LocalAccountSID.LastIndexOf("-"))
}
function Get-AdsiGroup {
    <#
        .SYNOPSIS
        Get the directory entries for a group and its members using ADSI
        .DESCRIPTION
        Uses the ADSI components to search a directory for a group, then get its members
        Both the WinNT and LDAP providers are supported
        .INPUTS
        None. Pipeline input is not accepted.
        .OUTPUTS
        [System.DirectoryServices.DirectoryEntry] for each group memeber
        .EXAMPLE
        Get-AdsiGroup -DirectoryPath 'WinNT://WORKGROUP/localhost' -GroupName Administrators

        Get members of the local Administrators group
        .EXAMPLE
        Get-AdsiGroup -GroupName Administrators

        On a domain-joined computer, this will get members of the domain's Administrators group
        On a workgroup computer, this will get members of the local Administrators group
    #>
    [OutputType([System.DirectoryServices.DirectoryEntry])]

    param (

        <#
        Path to the directory object to retrieve
        Defaults to the root of the current domain
        #>
        [string]$DirectoryPath = (([System.DirectoryServices.DirectorySearcher]::new()).SearchRoot.Path),

        # Name (CN or Common Name) of the group to retrieve
        [string]$GroupName,

        # Properties of the group and its members to find in the directory
        <#
        [string[]]$PropertiesToLoad = @(
            'department',
            'description',
            'distinguishedName',
            'grouptype',
            'managedby',
            'member',
            'name',
            'objectClass',
            'objectSid',
            'operatingSystem',
            'samAccountName',
            'title'
        ),
        #>
        [string[]]$PropertiesToLoad,

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{}))

    )

    $GroupParams = @{
        DirectoryPath       = $DirectoryPath
        PropertiesToLoad    = $PropertiesToLoad
        DirectoryEntryCache = $DirectoryEntryCache
        DomainsByFqdn       = $DomainsByFqdn
        DomainsByNetbios    = $DomainsByNetbios
        DomainsBySid        = $DomainsBySid
    }
    $GroupMemberParams = @{
        PropertiesToLoad    = $PropertiesToLoad
        DirectoryEntryCache = $DirectoryEntryCache
        DomainsByFqdn       = $DomainsByFqdn
        DomainsByNetbios    = $DomainsByNetbios
        DomainsBySid        = $DomainsBySid
    }

    switch -Regex ($DirectoryPath) {
        '^WinNT' {
            $GroupParams['DirectoryPath'] = "$DirectoryPath/$GroupName"
            $GroupMemberParams['DirectoryEntry'] = Get-DirectoryEntry @GroupParams
            $FullMembers = Get-WinNTGroupMember @GroupMemberParams
        }
        '^$' {
            # This is expected for a workgroup computer
            $GroupParams['DirectoryPath'] = "WinNT://localhost/$GroupName"
            $GroupMemberParams['DirectoryEntry'] = Get-DirectoryEntry @GroupParams
            $FullMembers = Get-WinNTGroupMember @GroupMemberParams
        }
        default {
            if ($GroupName) {
                $GroupParams['Filter'] = "(&(objectClass=group)(cn=$GroupName))"
            } else {
                $GroupParams['Filter'] = "(objectClass=group)"
            }
            $GroupMemberParams['Group'] = Search-Directory @GroupParams
            $FullMembers = Get-AdsiGroupMember @GroupMemberParams
        }
    }

    $FullMembers

}
function Get-AdsiGroupMember {
    <#
        .SYNOPSIS
        Get members of a group from the LDAP provider
        .DESCRIPTION
        Use ADSI to get members of a group from the LDAP provider
        Return the group's DirectoryEntry plus a FullMembers property containing the member DirectoryEntries
        .INPUTS
        [System.DirectoryServices.DirectoryEntry]$DirectoryEntry
        .OUTPUTS
        [System.DirectoryServices.DirectoryEntry] plus a FullMembers property
        .EXAMPLE
        [System.DirectoryServices.DirectoryEntry]::new('LDAP://ad.contoso.com/CN=Administrators,CN=BuiltIn,DC=ad,DC=contoso,DC=com') | Get-AdsiGroupMember

        Get members of the domain Administrators group
    #>
    [OutputType([System.DirectoryServices.DirectoryEntry])]
    param (

        # Directory entry of the LDAP group whose members to get
        [Parameter(ValueFromPipeline)]
        $Group,

        # Properties of the group members to find in the directory
        [string[]]$PropertiesToLoad,

        <#
        Hashtable containing cached directory entries so they don't have to be retrieved from the directory again
        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{}))

    )
    begin {

        $PathRegEx = '(?<Path>LDAP:\/\/[^\/]*)'
        $DomainRegEx = '(?i)DC=\w{1,}?\b'

        $SearchParameters = @{
            PropertiesToLoad    = $PropertiesToLoad
            DirectoryEntryCache = $DirectoryEntryCache
            DomainsByNetbios    = $DomainsByNetbios
        }

    }
    process {

        foreach ($ThisGroup in $Group) {

            # Recursive search
            $SearchParameters['Filter'] = "(memberof:1.2.840.113556.1.4.1941:=$($ThisGroup.Properties['distinguishedname']))"

            # Non-recursive search
            #$SearchParameters['Filter'] = "(memberof=$($ThisGroup.Properties['distinguishedname']))"

            if ($ThisGroup.Path -match $PathRegEx) {

                $SearchParameters['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath $Matches.Path

                if ($ThisGroup.Path -match $DomainRegEx) {
                    $Domain = ([regex]::Matches($ThisGroup.Path, $DomainRegEx) | ForEach-Object { $_.Value }) -join ','
                    $SearchParameters['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath "LDAP://$Domain"
                } else {
                    $SearchParameters['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath $ThisGroup.Path
                }

            } else {
                $SearchParameters['DirectoryPath'] = Add-DomainFqdnToLdapPath -DirectoryPath $ThisGroup.Path
            }

            #Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-AdsiGroupMember`t$($SearchParameters['Filter'])"

            $GroupMemberSearch = Search-Directory @SearchParameters

            if ($GroupMemberSearch.Count -gt 0) {

                $CurrentADGroupMembers = $GroupMemberSearch | ForEach-Object {
                    $FQDNPath = Add-DomainFqdnToLdapPath -DirectoryPath $_.Path
                    Get-DirectoryEntry -DirectoryPath $FQDNPath -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
                }

            } else {
                $CurrentADGroupMembers = $null
            }

            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-AdsiGroupMember`t$($ThisGroup.Properties.name) has $(($CurrentADGroupMembers | Measure-Object).Count) members"

            $ProcessedGroupMembers = Expand-AdsiGroupMember -DirectoryEntry $CurrentADGroupMembers -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsBySid $DomainsBySid -DomainsByNetbios $DomainsByNetbios

            Add-Member -InputObject $ThisGroup -MemberType NoteProperty -Name FullMembers -Value $ProcessedGroupMembers -Force -PassThru

        }
    }
    end {}
}
function Get-AdsiServer {
    <#
        .SYNOPSIS
        Get information about a directory server including the ADSI provider it hosts and its well-known SIDs
        .DESCRIPTION
        Uses the ADSI provider to query the server using LDAP first, then WinNT upon failure
        Uses WinRM to query the CIM class Win32_SystemAccount for well-known SIDs
        .INPUTS
        [System.String]$Fqdn
        .OUTPUTS
        [PSCustomObject] with AdsiProvider and WellKnownSIDs properties
        .EXAMPLE
        Get-AdsiServer -Fqdn localhost

        Find the ADSI provider of the local computer
        .EXAMPLE
        Get-AdsiServer -Fqdn 'ad.contoso.com'

        Find the ADSI provider of the AD domain 'ad.contoso.com'
    #>
    [OutputType([System.String])]

    param (

        # IP address or hostname of the directory server whose ADSI provider type to determine
        [Parameter(ValueFromPipeline)]
        [string[]]$Fqdn,

        # NetBIOS name of the ADSI server whose information to determine
        [string[]]$Netbios,

        # Cache of known Win32_Account instances keyed by domain and SID
        [hashtable]$Win32AccountsBySID = ([hashtable]::Synchronized(@{})),

        # Cache of known Win32_Account instances keyed by domain (e.g. CONTOSO) and Caption (NTAccount name e.g. CONTOSO\User1)
        [hashtable]$Win32AccountsByCaption = ([hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName,AdsiProvider,Win32Accounts properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{}))

    )
    process {
        ForEach ($DomainFqdn in $Fqdn) {
            $OutputObject = $DomainsByFqdn[$DomainFqdn]
            if ($OutputObject) {
                Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`t # Domain FQDN cache hit for '$DomainFqdn'"
                $OutputObject
                continue
            }
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`t # Domain FQDN cache miss for '$DomainFqdn'"
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`tFind-AdsiProvider -AdsiServer '$DomainFqdn'"
            $AdsiProvider = Find-AdsiProvider -AdsiServer $DomainFqdn
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`tConvertTo-DistinguishedName -DomainFQDN '$DomainFqdn' -AdsiProvider '$AdsiProvider'"
            $DomainDn = ConvertTo-DistinguishedName -DomainFQDN $DomainFqdn -AdsiProvider $AdsiProvider
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`tConvertTo-DomainSidString -DomainDnsName '$DomainFqdn'"
            $DomainSid = ConvertTo-DomainSidString -DomainDnsName $DomainFqdn -AdsiProvider $AdsiProvider -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`tConvertTo-DomainNetBIOS -DomainFQDN '$DomainFqdn'"
            $DomainNetBIOS = ConvertTo-DomainNetBIOS -DomainFQDN $DomainFqdn -AdsiProvider $AdsiProvider  -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`tGet-Win32Account -ComputerName '$DomainFqdn'"
            $Win32Accounts = Get-Win32Account -ComputerName $DomainFqdn -Win32AccountsBySID $Win32AccountsBySID -ErrorAction SilentlyContinue

            $Win32Accounts |
            ForEach-Object {
                $Win32AccountsBySID["$($_.Domain)\$($_.SID)"] = $_
                $Win32AccountsByCaption["$($_.Domain)\$($_.Caption)"] = $_
            }

            $OutputObject = [PSCustomObject]@{
                DistinguishedName = $DomainDn
                Dns               = $DomainFqdn
                Sid               = $DomainSid
                Netbios           = $DomainNetBIOS
                AdsiProvider      = $AdsiProvider
                Win32Accounts     = $Win32Accounts
            }
            $DomainsBySid[$OutputObject.Sid] = $OutputObject
            $DomainsByNetbios[$OutputObject.Netbios] = $OutputObject
            $DomainsByFqdn[$DomainFqdn] = $OutputObject
            $OutputObject
        }

        ForEach ($DomainNetbios in $Netbios) {
            $OutputObject = $DomainsByNetbios[$DomainNetbios]
            if ($OutputObject) {
                Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`t # Domain NetBIOS cache hit for '$DomainNetbios'"
                $OutputObject
                continue
            }
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`t # Domain NetBIOS cache hit for '$DomainNetbios'"

            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`tFind-AdsiProvider -AdsiServer '$DomainDnsName'"
            $AdsiProvider = Find-AdsiProvider -AdsiServer $DomainDnsName

            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`tConvertTo-DistinguishedName -Domain '$DomainNetBIOS'"
            $DomainDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -DomainsByNetbios $DomainsByNetbios

            if ($DomainDn) {
                Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`tConvertTo-Fqdn -DistinguishedName '$DomainDn'"
                $DomainDnsName = ConvertTo-Fqdn -DistinguishedName $DomainDn
            } else {
                $CimSession = New-CimSession -ComputerName $DomainNetbios
                $ParentDomainDnsName = (Get-CimInstance -CimSession $CimSession -ClassName CIM_ComputerSystem).domain
                if ($ParentDomainDnsName -eq 'WORKGROUP' -or $null -eq $ParentDomainDnsName) {
                    $ParentDomainDnsName = (Get-DnsClientGlobalSetting -CimSession $CimSession).SuffixSearchList[0]
                }
                $DomainDnsName = "$DomainNetBIOS.$ParentDomainDnsName"
            }

            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`tConvertTo-DomainSidString -DomainDnsName '$DomainFqdn'"
            $DomainSid = ConvertTo-DomainSidString -DomainDnsName $DomainDnsName -AdsiProvider $AdsiProvider -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid

            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-AdsiServer`tGet-Win32Account -ComputerName '$DomainDnsName'"
            $Win32Accounts = Get-Win32Account -ComputerName $DomainDnsName -Win32AccountsBySID $Win32AccountsBySID -ErrorAction SilentlyContinue

            $Win32Accounts |
            ForEach-Object {
                $Win32AccountsBySID["$($_.Domain)\$($_.SID)"] = $_
                $Win32AccountsByCaption["$($_.Domain)\$($_.Caption)"] = $_
            }

            $OutputObject = [PSCustomObject]@{
                DistinguishedName = $DomainDn
                Dns               = $DomainDnsName
                Sid               = $DomainSid
                Netbios           = $DomainNetBIOS
                AdsiProvider      = $AdsiProvider
                Win32Accounts     = $Win32Accounts
            }
            $DomainsBySid[$OutputObject.Sid] = $OutputObject
            $DomainsByNetbios[$OutputObject.Netbios] = $OutputObject
            $DomainsByFqdn[$OutputObject.Dns] = $OutputObject
            $OutputObject
        }
    }
}
function Get-CurrentDomain {
    <#
        .SYNOPSIS
        Use ADSI to get the current domain
        .DESCRIPTION
        Works only on domain-joined systems, otherwise returns nothing
        .INPUTS
        None. Pipeline input is not accepted.
        .OUTPUTS
        [System.DirectoryServices.DirectoryEntry] The current domain

        .EXAMPLE
        Get-CurrentDomain

        Get the domain of the current computer
    #>
    [OutputType([System.DirectoryServices.DirectoryEntry])]
    $Obj = [adsi]::new()
    try { $null = $Obj.RefreshCache('objectSid') } catch { return }
    return $Obj
}
function Get-DirectoryEntry {
    <#
        .SYNOPSIS
        Use Active Directory Service Interfaces to retrieve an object from a directory
        .DESCRIPTION
        Retrieve a directory entry using either the WinNT or LDAP provider for ADSI
        .INPUTS
        None. Pipeline input is not accepted.
        .OUTPUTS
        [System.DirectoryServices.DirectoryEntry] where possible
        [PSCustomObject] for security principals with no directory entry
        .EXAMPLE
        Get-DirectoryEntry
        distinguishedName : {DC=ad,DC=contoso,DC=com}
        Path              : LDAP://DC=ad,DC=contoso,DC=com

        As the current user on a domain-joined computer, bind to the current domain and retrieve the DirectoryEntry for the root of the domain
        .EXAMPLE
        Get-DirectoryEntry
        distinguishedName :
        Path              : WinNT://ComputerName

        As the current user on a workgroup computer, bind to the local system and retrieve the DirectoryEntry for the root of the directory
    #>
    [OutputType([System.DirectoryServices.DirectoryEntry], [PSCustomObject])]
    [CmdletBinding()]
    param (

        <#
        Path to the directory object to retrieve
        Defaults to the root of the current domain
        #>
        [string]$DirectoryPath = (([System.DirectoryServices.DirectorySearcher]::new()).SearchRoot.Path),

        <#
        Credentials to use to bind to the directory
        Defaults to the credentials of the current user
        #>
        [pscredential]$Credential,

        # Properties of the target object to retrieve
        [string[]]$PropertiesToLoad,

        <#
        Hashtable containing cached directory entries so they don't have to be retrieved from the directory again
        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{}))

    )

    $DirectoryEntry = $null
    if ($null -eq $DirectoryEntryCache[$DirectoryPath]) {
        switch -regex ($DirectoryPath) {
            <#
            The WinNT provider only throws an error if you try to retrieve certain accounts/identities
            We will create own dummy objects instead of performing the query
            #>
            '^WinNT:\/\/.*\/CREATOR OWNER$' {
                $DirectoryEntry = New-FakeDirectoryEntry -DirectoryPath $DirectoryPath
            }
            '^WinNT:\/\/.*\/SYSTEM$' {
                $DirectoryEntry = New-FakeDirectoryEntry -DirectoryPath $DirectoryPath
            }
            '^WinNT:\/\/.*\/INTERACTIVE$' {
                $DirectoryEntry = New-FakeDirectoryEntry -DirectoryPath $DirectoryPath
            }
            '^WinNT:\/\/.*\/Authenticated Users$' {
                $DirectoryEntry = New-FakeDirectoryEntry -DirectoryPath $DirectoryPath
            }
            '^WinNT:\/\/.*\/TrustedInstaller$' {
                $DirectoryEntry = New-FakeDirectoryEntry -DirectoryPath $DirectoryPath
            }
            # Workgroup computers do not return a DirectoryEntry with a SearchRoot Path so this ends up being an empty string
            # This is also invoked when DirectoryPath is null for any reason
            # We will return a WinNT object representing the local computer's WinNT directory
            '^$' {
                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-DirectoryEntry`t$(hostname) does not appear to be domain-joined since the SearchRoot Path is empty. Defaulting to WinNT provider for localhost instead."
                $Workgroup = (Get-CimInstance -ClassName Win32_ComputerSystem).Workgroup
                $DirectoryPath = "WinNT://$Workgroup/$(hostname)"
                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-DirectoryEntry`t[System.DirectoryServices.DirectoryEntry]::new('$DirectoryPath')"
                if ($Credential) {
                    $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath, $($Credential.UserName), $($Credential.GetNetworkCredential().password))
                } else {
                    $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath)
                }

                $SampleUser = $DirectoryEntry.PSBase.Children |
                Where-Object -FilterScript { $_.schemaclassname -eq 'user' } |
                Select-Object -First 1 |
                Add-SidInfo -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid

                $DirectoryEntry |
                Add-Member -MemberType NoteProperty -Name 'Domain' -Value $SampleUser.Domain -Force

            }
            # Otherwise the DirectoryPath is an LDAP path or a WinNT path (treated the same at this stage)
            default {

                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-DirectoryEntry`t[System.DirectoryServices.DirectoryEntry]::new('$DirectoryPath')"
                if ($Credential) {
                    $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath, $($Credential.UserName), $($Credential.GetNetworkCredential().password))
                } else {
                    $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath)
                }

            }

        }

        $DirectoryEntryCache[$DirectoryPath] = $DirectoryEntry
    } else {
        #Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-DirectoryEntry`tDirectoryEntryCache hit for '$DirectoryPath'"
        $DirectoryEntry = $DirectoryEntryCache[$DirectoryPath]
    }

    if ($PropertiesToLoad) {
        try {
            # If the $DirectoryPath was invalid, this line will return an error
            $null = $DirectoryEntry.RefreshCache($PropertiesToLoad)

        } catch {
            Write-Warning "$(Get-Date -Format s)`t$(hostname)`tGet-DirectoryEntry`t'$DirectoryPath' could not be retrieved."

            # Ensure that the error message appears on 1 line
            # Use .Trim() to remove leading and trailing whitespace
            # Use -replace to remove an errant line break in the following specific error I encountered: The following exception occurred while retrieving member "RefreshCache": "The group name could not be found.`r`n"
            Write-Warning "$(Get-Date -Format s)`t$(hostname)`tGet-DirectoryEntry`t'$($_.Exception.Message.Trim() -replace '\s"',' "')"
            return
        }
    }
    return $DirectoryEntry

}
function Get-DomainInfo {
    param (
        [string]$DomainDn,
        [string]$DomainDnsName,
        [string]$DomainNetBIOS,
        [string]$DomainSID,

        # Cache of known directory servers to reduce duplicate queries
        [hashtable]$AdsiServersByDns = [hashtable]::Synchronized(@{}),

        <#
        Hashtable containing cached directory entries so they don't have to be retrieved from the directory again

        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{}))
    )

    if ($PSBoundParameters.ContainsKey('DomainNetBIOS')) {
        $OutputObject = $DomainsByNetbios[$DomainNetbios]
        if ($OutputObject) {
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-DomainInfo`t # Domain NetBIOS cache hit for '$DomainNetbios'"
            return $OutputObject
        }
        Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-DomainInfo`t # Domain NetBIOS cache hit for '$DomainNetbios'"
        $DomainDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -DomainsByNetbios $DomainsByNetbios
        if ($DomainDn) {
            $DomainDnsName = ConvertTo-Fqdn -DistinguishedName $DomainDn
        } else {
            $CimSession = New-CimSession -ComputerName $DomainNetBIOS
            $ParentDomainDnsName = (Get-CimInstance -CimSession $CimSession -ClassName CIM_ComputerSystem).domain
            if ($ParentDomainDnsName -eq 'WORKGROUP' -or $null -eq $ParentDomainDnsName) {
                $ParentDomainDnsName = (Get-DnsClientGlobalSetting -CimSession $CimSession).SuffixSearchList[0]
            }
            $DomainDnsName = "$DomainNetBIOS.$ParentDomainDnsName"
        }
        $DomainSid = ConvertTo-DomainSidString -DomainDnsName $DomainDnsName -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
    }

    if ($PSBoundParameters.ContainsKey('DomainDnsName')) {
        $OutputObject = $DomainsByFqdn[$DomainDnsName]
        if ($OutputObject) {
            Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-DomainInfo`t # Domain FQDN cache hit for '$DomainDnsName'"
            return $OutputObject
        }
        Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-DomainInfo`t # Domain FQDN cache miss for '$DomainDnsName'"
        Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-DomainInfo`tConvertTo-DistinguishedName -DomainFQDN '$DomainDnsName'"
        $DomainDn = ConvertTo-DistinguishedName -DomainFQDN $DomainDnsName
        Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-DomainInfo`tConvertTo-DomainSidString -DomainDnsName '$DomainDnsName'"
        $DomainSid = ConvertTo-DomainSidString -DomainDnsName $DomainDnsName -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
        Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-DomainInfo`tConvertTo-DomainNetBIOS -DomainFQDN '$DomainDnsName'"
        $DomainNetBIOS = ConvertTo-DomainNetBIOS -DomainFQDN $DomainDnsName -AdsiServersByDns $AdsiServersByDns -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
    }

    $OutputObject = [PSCustomObject]@{
        Dns               = $DomainDnsName
        NetBIOS           = $DomainNetBIOS
        SID               = $DomainSid
        DistinguishedName = $DomainDn
    }

    $DomainsBySID[$OutputObject.SID] = $OutputObject
    $DomainsByNetbios[$DomainNetbios] = $OutputObject
    $DomainsByFqdn[$DomainDnsName] = $OutputObject

    return $OutputObject
}
function Get-TrustedDomain {
    <#
        .SYNOPSIS
        Returns a dictionary of trusted domains by the current computer
        .DESCRIPTION
        Works only on domain-joined systems
        Use nltest to get the domain trust relationships for the domain of the current computer
        Use ADSI's LDAP provider to get each trusted domain's DNS name, NETBIOS name, and SID
        For each trusted domain the key is the domain's SID, or its NETBIOS name if the -KeyByNetbios switch parameter was used
        For each trusted domain the value contains the details retrieved with ADSI
        .INPUTS
        None. Pipeline input is not accepted.
        .OUTPUTS
        [PSCustomObject] One object per trusted domain, each with a DomainFqdn property and a DomainNetbios property

        .EXAMPLE
        Get-TrustedDomain

        Get the trusted domains of the current computer
        .NOTES
    #>
    [OutputType([PSCustomObject])]
    param (
        $ThisHostname = (HOSTNAME.EXE)
    )
    # Redirect the error stream to null, errors are expected on non-domain-joined systems
    Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-TrustedDomain`t$('& nltest /domain_trusts 2> $null')"
    $nltestresults = & nltest /domain_trusts 2> $null
    $NlTestRegEx = '[\d]*: .*'
    $TrustRelationships = $nltestresults -match $NlTestRegEx

    $RegExForEachTrust = '(?<index>[\d]*): (?<netbios>\S*) (?<dns>\S*).*'
    foreach ($TrustRelationship in $TrustRelationships) {
        if ($TrustRelationship -match $RegExForEachTrust) {
            [PSCustomObject]@{
                DomainFqdn    = $Matches.dns
                DomainNetbios = $Matches.netbios
            }
        } else {
            continue
        }
    }
}
function Get-Win32Account {
    <#
        .SYNOPSIS
        Use CIM to get well-known SIDs
        .DESCRIPTION
        Use WinRM to query the CIM namespace root/cimv2 for instances of the Win32_Account class
        .INPUTS
        [System.String]$ComputerName
        .OUTPUTS
        [Microsoft.Management.Infrastructure.CimInstance] for each instance of the Win32_Account class in the root/cimv2 namespace
        .EXAMPLE
        Get-Win32Account

        Get the well-known SIDs on the current computer
        .EXAMPLE
        Get-Win32Account -CimServerName 'server123'

        Get the well-known SIDs on the remote computer 'server123'
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param (

        # Name or address of the computer whose Win32_Account instances to return
        [Parameter(ValueFromPipeline)]
        [string[]]$ComputerName,

        # Cache of known Win32_Account instances keyed by domain and SID
        [hashtable]$Win32AccountsBySID = ([hashtable]::Synchronized(@{})),

        # Cache of known Win32_Account instances keyed by domain (e.g. CONTOSO) and Caption (NTAccount name e.g. CONTOSO\User1)
        [hashtable]$Win32AccountsByCaption = ([hashtable]::Synchronized(@{})),

        # Cache of known directory servers to reduce duplicate queries
        [hashtable]$AdsiServersByDns = [hashtable]::Synchronized(@{}),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{}))

    )
    begin {
        $AdsiServersWhoseWin32AccountsExistInCache = $Win32AccountsBySID.Keys |
        ForEach-Object { ($_ -split '\\')[0] } |
        Sort-Object -Unique
    }
    process {
        ForEach ($ThisServer in $ComputerName) {
            if (
                $ThisServer -eq 'localhost' -or
                $ThisServer -eq '127.0.0.1' -or
                [string]::IsNullOrEmpty($ThisServer)
            ) {
                $ThisServer = hostname
            }
            # Return matching objects from the cache if possible rather than performing a CIM query
            # The cache is based on the Caption of the Win32 accounts which conatins only NetBios names
            $AdsiProvider = Find-AdsiProvider -AdsiServer $ThisServer
            $ThisServerNetbios = ConvertTo-DomainNetBIOS -DomainFQDN $ThisServer -AdsiProvider $AdsiProvider -AdsiServersByDns $AdsiServersByDns -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
            if ($AdsiServersWhoseWin32AccountsExistInCache -contains $ThisServer) {
                $Win32AccountsBySID.Keys |
                ForEach-Object {
                    if ($_ -like "$ThisServer\*") {
                        $Win32AccountsBySID[$_]
                    }
                }
            } else {

                if ($ThisServer -eq (hostname)) {
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-Win32Account`t`$CimSession = New-CimSession # For '$ThisServer'"
                    $CimSession = New-CimSession
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-Win32Account`tGet-CimInstance -ClassName Win32_Account -CimSession `$CimSession # For '$ThisServer'"
                } else {
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-Win32Account`t`$CimSession = New-CimSession -ComputerName '$ThisServer' # For '$ThisServer'"
                    $CimSession = New-CimSession -ComputerName $ThisServer
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-Win32Account`tGet-CimInstance -ClassName Win32_Account -CimSession `$CimSession # For '$ThisServer'"
                }

                $Win32_Accounts = Get-CimInstance -ClassName Win32_Account -CimSession $CimSession
                $Win32_Accounts

                Remove-CimSession -CimSession $CimSession

            }
        }
    }
}
function Get-Win32UserAccount {
    param (
        [string]$ComputerName,
        [string]$ThisHostname = (HOSTNAME.EXE),
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName(($ThisHostName)).HostName)
    )
    if (
        $ComputerName -eq $ThisHostname -or
        $ComputerName -eq "$ThisHostname." -or
        $ComputerName -eq $ThisFqdn
    ) {
        Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-Win32UserAccount`tGet-CimInstance -Query `"SELECT SID FROM Win32_UserAccount WHERE LocalAccount = 'True'`""
        Get-CimInstance -Query "SELECT SID FROM Win32_UserAccount WHERE LocalAccount = 'True'"
    } else {
        Write-Debug -Message "  $(Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff')`t$(hostname)`t$(whoami)`tGet-Win32UserAccount`tGet-CimInstance -ComputerName $ComputerName -Query `"SELECT SID FROM Win32_UserAccount WHERE LocalAccount = 'True'`""
        # If an Active Directory domain is targeted there are no local accounts and CIM connectivity is not expected
        # Suppress errors and return nothing in that case
        Get-CimInstance -ComputerName $ComputerName -Query "SELECT SID FROM Win32_UserAccount WHERE LocalAccount = 'True'" -ErrorAction SilentlyContinue
    }
}
function Get-WinNTGroupMember {
    <#
        .SYNOPSIS
        Get members of a group from the WinNT provider
        .DESCRIPTION
        Get members of a group from the WinNT provider
        Convert them from COM objects into usable DirectoryEntry objects
        .INPUTS
        [System.DirectoryServices.DirectoryEntry]$DirectoryEntry
        .OUTPUTS
        [System.DirectoryServices.DirectoryEntry] for each group member
        .EXAMPLE
        [System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrators') | Get-WinNTGroupMember

        Get members of the local Administrators group
    #>
    [OutputType([System.DirectoryServices.DirectoryEntry])]
    param (

        # DirectoryEntry [System.DirectoryServices.DirectoryEntry] of the WinNT group whose members to get
        [Parameter(ValueFromPipeline)]
        $DirectoryEntry,

        # Properties of the group members to find in the directory
        [string[]]$PropertiesToLoad,

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{}))

    )
    process {
        ForEach ($ThisDirEntry in $DirectoryEntry) {
            $SourceDomain = $ThisDirEntry.Path | Split-Path -Parent | Split-Path -Leaf
            # Retrieve the members of local groups
            if ($null -ne $ThisDirEntry.Properties['groupType'] -or $ThisDirEntry.schemaclassname -eq 'group') {
                # Assembly: System.DirectoryServices.dll
                # Namespace: System.DirectoryServices
                # DirectoryEntry.Invoke(String, Object[]) Method
                # Calls a method on the native Active Directory Domain Services object
                # https://docs.microsoft.com/en-us/dotnet/api/system.directoryservices.directoryentry.invoke?view=dotnet-plat-ext-6.0

                # I am using it to call the IADsGroup::Members method
                # The IADsGroup programming interface is part of the iads.h header
                # The iads.h header is part of the ADSI component of the Win32 API
                # The IADsGroup::Members method retrieves a collection of the immediate members of the group.
                # The collection does not include the members of other groups that are nested within the group.
                # The default implementation of this method uses LsaLookupSids to query name information for the group members.
                # LsaLookupSids has a maximum limitation of 20480 SIDs it can convert, therefore that limitation also applies to this method.
                # Returns a pointer to an IADsMembers interface pointer that receives the collection of group members. The caller must release this interface when it is no longer required.
                # https://docs.microsoft.com/en-us/windows/win32/api/iads/nf-iads-iadsgroup-members
                # The IADsMembers::Members method would use the same provider but I have chosen not to implement that here
                # Recursion through nested groups can be handled outside of Get-WinNTGroupMember for now
                # Maybe that could be a feature in the future
                # https://docs.microsoft.com/en-us/windows/win32/adsi/adsi-object-model-for-winnt-providers?redirectedfrom=MSDN
                $DirectoryMembers = & { $ThisDirEntry.Invoke('Members') } 2>$null

                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-WinNTGroupMember`t # '$($ThisDirEntry.Path)' has $(($DirectoryMembers | Measure-Object).Count) members # For $($ThisDirEntry.Path)"
                ForEach ($DirectoryMember in $DirectoryMembers) {
                    # The IADsGroup::Members method returns ComObjects
                    # But proper .Net objects are much easier to work with
                    # So we will convert the ComObjects into DirectoryEntry objects
                    $DirectoryPath = Invoke-ComObject -ComObject $DirectoryMember -Property 'ADsPath'
                    $MemberDomainDn = $null
                    if ($DirectoryPath -match 'WinNT:\/\/(?<Domain>[^\/]*)\/(?<Acct>.*$)') {
                        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-WinNTGroupMember`t # '$DirectoryPath' has a domain of '$($Matches.Domain)' and an account name of '$($Matches.Acct)'"
                        $MemberName = $Matches.Acct
                        $MemberDomainNetbios = $Matches.Domain

                        $DomainCacheResult = $DomainsByNetbios[$MemberDomainNetbios]
                        if ($DomainCacheResult) {
                            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-WinNTGroupMember`t' # Domain NetBIOS cache hit for '$MemberDomainNetBios'"
                            if ( "WinNT:\\$MemberDomainNetbios" -ne $SourceDomain ) {
                                $MemberDomainDn = $DomainCacheResult.DistinguishedName
                            }
                        } else {
                            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-WinNTGroupMember`t' # Domain NetBIOS cache miss for '$MemberDomainNetBios'. Available keys: $($DomainsByNetBios.Keys -join ',')"
                        }
                        if ($DirectoryPath -match 'WinNT:\/\/(?<Domain>[^\/]*)\/(?<Middle>[^\/]*)\/(?<Acct>.*$)') {
                            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-WinNTGroupMember`t # '$DirectoryPath' came from an ADSI server joined to the domain of '$($Matches.Domain)' but its domain is '$($Matches.Middle)' and its name is '$($Matches.Acct)'"
                            if ($Matches.Middle -eq ($ThisDirEntry.Path | Split-Path -Parent | Split-Path -Leaf)) {
                                $MemberDomainDn = $null
                            }
                        }
                    } else {
                        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-WinNTGroupMember`t # '$DirectoryPath' does not match 'WinNT:\/\/(?<Domain>[^\/]*)\/(?<Acct>.*$)'"
                    }

                    $MemberParams = @{
                        DirectoryEntryCache = $DirectoryEntryCache
                        DirectoryPath       = $DirectoryPath
                        PropertiesToLoad    = $PropertiesToLoad
                        DomainsByNetbios    = $DomainsByNetbios
                    }
                    if ($MemberDomainDn) {
                        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-WinNTGroupMember`t # '$MemberName' is a domain security principal"
                        $MemberParams['DirectoryPath'] = "LDAP://$MemberDomainDn"
                        $MemberParams['Filter'] = "(samaccountname=$MemberName)"
                        $MemberDirectoryEntry = Search-Directory @MemberParams
                    } else {
                        Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-WinNTGroupMember`t # '$DirectoryPath' is a local security principal"
                        $MemberDirectoryEntry = Get-DirectoryEntry @MemberParams
                    }

                    Expand-WinNTGroupMember -DirectoryEntry $MemberDirectoryEntry -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid

                }
            } else {
                Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tGet-WinNTGroupMember`t # '$($ThisDirEntry.Path)' is not a group"
            }
        }
    }

}
function Invoke-ComObject {
    <#
        .SYNOPSIS
        Invoke a member method of a ComObject [__ComObject]
        .DESCRIPTION
        Use the InvokeMember method to invoke the InvokeMethod or GetProperty or SetProperty methods
        By default, invokes the GetProperty method for the specified Property
        If the Value parameter is specified, invokes the SetProperty method for the specified Property
        If the Method switch is specified, invokes the InvokeMethod method
        .INPUTS
        None. Pipeline input is not accepted.
        .OUTPUTS
        The output of the invoked method is returned directly
        .EXAMPLE
        $ComObject = [System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrators').Invoke('Members') | Select -First 1
        Invoke-ComObject -ComObject $ComObject -Property AdsPath

        Get the first member of the local Administrators group on the current computer
        Then use Invoke-ComObject to invoke the GetProperty method and return the value of the AdsPath property
    #>
    param (

        # The ComObject whose member method to invoke
        [Parameter(Mandatory)]
        $ComObject,

        # The property to use with the invoked method
        [Parameter(Mandatory)]
        [String]$Property,

        # The value to set with the SetProperty method, or the name of the method to run with the InvokeMethod method
        $Value,

        # Use the InvokeMethod method of the ComObject
        [Switch]$Method

    )
    <#
    # Don't remember what this is for
    If ($ComObject -IsNot "__ComObject") {
        If (!$ComInvoke) {
            $Global:ComInvoke = @{}
        }
        If (!$ComInvoke.$ComObject) {
            $ComInvoke.$ComObject = New-Object -ComObject $ComObject
        }
        $ComObject = $ComInvoke.$ComObject
    }
    #>
    If ($Method) {
        $Invoke = "InvokeMethod"
    } ElseIf ($MyInvocation.BoundParameters.ContainsKey("Value")) {
        $Invoke = "SetProperty"
    } Else {
        $Invoke = "GetProperty"
    }
    [__ComObject].InvokeMember($Property, $Invoke, $Null, $ComObject, $Value)
}
function New-FakeDirectoryEntry {
    <#
        .SYNOPSIS
        Returns a PSCustomObject in place of a DirectoryEntry for certain WinNT security principals that do not have objects in the directory
        .DESCRIPTION
        The WinNT provider only throws an error if you try to retrieve certain accounts/identities
        We will create dummy objects instead of performing the query
        .INPUTS
        None. Pipeline input is not accepted.
        .OUTPUTS
        [System.Management.Automation.PSCustomObject]
        .EXAMPLE
        ----------  EXAMPLE 1  ----------
        New-FakeDirectoryEntry -DirectoryPath 'WinNT://WORKGROUP/Computer/CREATOR OWNER'

        Create a fake DirectoryEntry to represent the CREATOR OWNER special security principal
    #>
    [OutputType([System.Management.Automation.PSCustomObject])]
    param (

        <#
        Path to the directory object to retrieve
        Defaults to the root of the current domain (but don't use it for that, just do this instead: [System.DirectoryServices.DirectorySearcher]::new())
        #>
        [string]$DirectoryPath

    )

    $DirectoryEntry = $null
    $Properties = @{
        Name        = ($DirectoryPath -split '\/') | Select-Object -Last 1
        Parent      = $DirectoryPath | Split-Path -Parent
        Path        = $DirectoryPath
        SchemaEntry = [System.DirectoryServices.DirectoryEntry]
    }

    switch -regex ($DirectoryPath) {

        'CREATOR OWNER$' {
            $Properties['objectSid'] = 'S-1-3-0' | ConvertTo-SidByteArray
            $Properties['Description'] = 'A SID to be replaced by the SID of the user who creates a new object. This SID is used in inheritable ACEs.'
            $Properties['Properties'] = @{
                Name        = $Properties['Name']
                Description = $Description
                objectSid   = $SidByteAray
            }
            $Properties['SchemaClassName'] = 'user'
        }
        'SYSTEM$' {
            $Properties['objectSid'] = 'S-1-5-18' | ConvertTo-SidByteArray
            $Properties['Description'] = 'By default, the SYSTEM account is granted Full Control permissions to all files on an NTFS volume'
            $Properties['Properties'] = @{
                Name        = $Properties['Name']
                Description = $Description
                objectSid   = $SidByteAray
            }
            $Properties['SchemaClassName'] = 'user'
        }
        'INTERACTIVE$' {
            $Properties['objectSid'] = 'S-1-5-4' | ConvertTo-SidByteArray
            $Properties['Description'] = 'Users who log on for interactive operation. This is a group identifier added to the token of a process when it was logged on interactively.'
            $Properties['Properties'] = @{
                Name        = $Properties['Name']
                Description = $Description
                objectSid   = $SidByteAray
            }
            $Properties['SchemaClassName'] = 'group'
        }
        'Authenticated Users$' {
            $Properties['objectSid'] = 'S-1-5-11' | ConvertTo-SidByteArray
            $Properties['Description'] = 'Any user who accesses the system through a sign-in process has the Authenticated Users identity.'
            $Properties['Properties'] = @{
                Name        = $Properties['Name']
                Description = $Description
                objectSid   = $SidByteAray
            }
            $Properties['SchemaClassName'] = 'group'
        }
        'TrustedInstaller$' {
            $Properties['objectSid'] = 'S-1-5-11' | ConvertTo-SidByteArray
            $Properties['Description'] = 'Most of the operating system files are owned by the TrustedInstaller security identifier (SID)'
            $Properties['Properties'] = @{
                Name        = $Properties['Name']
                Description = $Description
                objectSid   = $SidByteAray
            }
            $Properties['SchemaClassName'] = 'user'
        }
    }

    $DirectoryEntry = [pscustomobject]::new($Properties)

    $DirectoryEntry |
    Add-Member -MemberType ScriptMethod -Name RefreshCache -Force -Value {}

    return $DirectoryEntry

}
function Resolve-Ace {
    <#
        .SYNOPSIS
        Use ADSI to lookup info about IdentityReferences from Authorization Rule Collections that came from Discretionary Access Control Lists
        .DESCRIPTION
        Based on the IdentityReference proprety of each Access Control Entry:
        Resolve SID to NT account name and vise-versa
        Resolve well-known SIDs
        Resolve generic defaults like 'NT AUTHORITY' and 'BUILTIN' to the applicable computer or domain name
        Add these properties (IdentityReferenceSID,IdentityReferenceName,IdentityReferenceResolved) to the object and return it
        .INPUTS
        [System.Security.AccessControl.AuthorizationRuleCollection]$InputObject
        .OUTPUTS
        [PSCustomObject] Original object plus IdentityReferenceSID,IdentityReferenceName,IdentityReferenceResolved, and AdsiProvider properties
        .EXAMPLE
        Get-Acl |
        Expand-Acl |
        Resolve-Ace

        Use Get-Acl from the Microsoft.PowerShell.Security module as the source of the access list
        This works in either Windows Powershell or in Powershell
        Get-Acl does not support long paths (>256 characters)
        That was why I originally used the .Net Framework method
        .EXAMPLE
        Get-FolderAce -LiteralPath C:\Test -IncludeInherited |
        Resolve-Ace
        .EXAMPLE
        [System.String]$FolderPath = 'C:\Test'
        [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
        $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor [System.Security.AccessControl.AccessControlSections]::Owner
        $FileSecurity = [System.Security.AccessControl.FileSecurity]::new($DirectoryInfo,$Sections)
        $IncludeExplicitRules = $true
        $IncludeInheritedRules = $true
        $AccountType = [System.Security.Principal.SecurityIdentifier]
        $FileSecurity.GetAccessRules($IncludeExplicitRules,$IncludeInheritedRules,$AccountType) |
        Resolve-Ace

        This uses .Net Core as the source of the access list
        It uses the GetAccessRules method on the [System.Security.AccessControl.FileSecurity] class
        The targetType parameter of the method is used to specify that the accounts in the ACL are returned as SIDs
        .EXAMPLE
        [System.String]$FolderPath = 'C:\Test'
        [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
        $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor
        [System.Security.AccessControl.AccessControlSections]::Owner -bor
        [System.Security.AccessControl.AccessControlSections]::Group
        $DirectorySecurity = [System.Security.AccessControl.DirectorySecurity]::new($DirectoryInfo,$Sections)
        $IncludeExplicitRules = $true
        $IncludeInheritedRules = $true
        $AccountType = [System.Security.Principal.NTAccount]
        $FileSecurity.GetAccessRules($IncludeExplicitRules,$IncludeInheritedRules,$AccountType) |
        Resolve-Ace

        This uses .Net Core as the source of the access list
        It uses the GetAccessRules method on the [System.Security.AccessControl.FileSecurity] class
        The targetType parameter of the method is used to specify that the accounts in the ACL are returned as NT account names (DOMAIN\User)
        .EXAMPLE
        [System.String]$FolderPath = 'C:\Test'
        [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
        [System.Security.AccessControl.DirectorySecurity]$DirectorySecurity = $DirectoryInfo.GetAccessControl('Access')
        [System.Security.AccessControl.AuthorizationRuleCollection]$AuthRules = $DirectorySecurity.Access
        $AuthRules | Resolve-Ace

        Use the .Net Framework (or legacy .Net Core up to 2.2) as the source of the access list
        Only works in Windows PowerShell
        Those versions of .Net had a GetAccessControl method on the [System.IO.DirectoryInfo] class
        This method is removed in modern versions of .Net Core

        .EXAMPLE
        [System.String]$FolderPath = 'C:\Test'
        [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
        $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor [System.Security.AccessControl.AccessControlSections]::Owner
        $FileSecurity = [System.IO.FileSystemAclExtensions]::GetAccessControl($DirectoryInfo,$Sections)

        The [System.IO.FileSystemAclExtensions] class is a Windows-specific implementation
        It provides no known benefit over the cross-platform equivalent [System.Security.AccessControl.FileSecurity]

        .NOTES
        Dependencies:
            Get-DirectoryEntry
            Add-SidInfo
            Get-TrustedDomain
            Find-AdsiProvider

        if ($FolderPath.Length -gt 255) {
            $FolderPath = "\\?\$FolderPath"
        }
    #>
    [OutputType([PSCustomObject])]
    param (

        # Authorization Rule Collection of Access Control Entries from Discretionary Access Control Lists
        [Parameter(
            ValueFromPipeline
        )]
        [PSObject[]]$InputObject,

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        [hashtable]$Win32AccountsBySID = ([hashtable]::Synchronized(@{})),

        [hashtable]$Win32AccountsByCaption = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{}))

    )

    process {

        $ACEPropertyNames = (Get-Member -InputObject $InputObject[0] -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name
        ForEach ($ThisACE in $InputObject) {

            $IdentityReference = $ThisACE.IdentityReference.ToString()

            if ([string]::IsNullOrEmpty($IdentityReference)) {
                continue
            }

            $ThisServerDns = $null
            $DomainNetBios = $null

            # Remove the PsProvider prefix from the path string
            if (-not [string]::IsNullOrEmpty($ThisACE.SourceAccessList.Path)) {
                $LiteralPath = $ThisACE.SourceAccessList.Path -replace [regex]::escape("$($ThisACE.SourceAccessList.PsProvider)::"), ''
            } else {
                $LiteralPath = $LiteralPath -replace [regex]::escape("$($ThisACE.SourceAccessList.PsProvider)::"), ''
            }

            switch -Wildcard ($IdentityReference) {
                "S-1-*" {
                    # IdentityReference is a SID (Revision 1)
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tResolve-Ace`t'$IdentityReference'.LastIndexOf('-')"
                    $IndexOfLastHyphen = $IdentityReference.LastIndexOf("-")
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tResolve-Ace`t'$IdentityReference'.Substring(0, $IndexOfLastHyphen)"
                    $DomainSid = $IdentityReference.Substring(0, $IndexOfLastHyphen)
                    if ($DomainSid) {
                        $DomainCacheResult = $DomainsBySID[$DomainSid]
                        if ($DomainCacheResult) {
                            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tResolve-Ace`t# Domain SID cache hit for '$DomainSid'"
                            $ThisServerDns = $DomainCacheResult.Dns
                            $DomainNetBios = $DomainCacheResult.Netbios
                        } else {
                            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tResolve-Ace`t# Domain SID cache miss for '$DomainSid'"
                        }
                    }
                }
                "NT SERVICE\*" {
                    $ThisServerDns = Find-ServerNameInPath -LiteralPath $LiteralPath
                }
                "BUILTIN\*" {
                    $ThisServerDns = Find-ServerNameInPath -LiteralPath $LiteralPath
                }
                "NT AUTHORITY\*" {
                    $ThisServerDns = Find-ServerNameInPath -LiteralPath $LiteralPath
                }
                default {
                    $DomainNetBios = ($IdentityReference -split '\\')[0]
                    if ($DomainNetBios) {
                        $ThisServerDns = $DomainsByNetbios[$DomainNetBios].Dns #Doesn't work for BUILTIN, etc.
                    }
                    if (-not $ThisServerDns) {
                        $ThisServerDn = ConvertTo-DistinguishedName -Domain $DomainNetBios -DomainsByNetbios $DomainsByNetbios
                        $ThisServerDns = ConvertTo-Fqdn -DistinguishedName $ThisServerDn
                    }
                }
            }

            if (-not $ThisServerDns) {
                # Bug: I think this will report incorrectly for a remote domain not in the cache (trust broken or something)
                $ThisServerDns = Find-ServerNameInPath -LiteralPath $LiteralPath
            }
            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tResolve-Ace`t# '$IdentityReference' has a domain DNS name of '$ThisServerDns'"

            if (-not $DomainNetBios) {
                $DomainCacheResult = $DomainsByFqdn[$ThisServerDns]
                if ($DomainCacheResult) {
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tResolve-Ace`t# Domain FQDN cache hit for '$ThisServerDns'"
                    $DomainNetBios = $DomainCacheResult.Netbios
                } else {
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tResolve-Ace`t# Domain FQDN cache miss for '$ThisServerDns'"
                }
            }

            if (-not $DomainNetBios) {
                $AdsiProvider = Find-AdsiProvider -AdsiServer $ThisServerDns
                $DomainNetBios = ConvertTo-DomainNetBIOS -DomainFQDN $ThisServerDns -AdsiProvider $AdsiProvider  -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
            }
            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tResolve-Ace`t# '$IdentityReference' has a domain NetBIOS name of '$DomainNetBios'"

            $GetAdsiServerParams = @{
                Fqdn                   = $ThisServerDns
                Win32AccountsBySID     = $Win32AccountsBySID
                Win32AccountsByCaption = $Win32AccountsByCaption
                DirectoryEntryCache    = $DirectoryEntryCache
                DomainsByFqdn          = $DomainsByFqdn
                DomainsByNetbios       = $DomainsByNetbios
                DomainsBySid           = $DomainsBySid
            }
            $AdsiServer = Get-AdsiServer @GetAdsiServerParams
            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tResolve-Ace`t# '$IdentityReference' has an ADSI server of '$($AdsiServer.AdsiProvider)://$($AdsiServer.Dns)'"

            $ResolveIdentityReferenceParams = @{
                IdentityReference      = $IdentityReference
                AdsiServer             = $AdsiServer
                Win32AccountsBySID     = $Win32AccountsBySID
                Win32AccountsByCaption = $Win32AccountsByCaption
                DirectoryEntryCache    = $DirectoryEntryCache
                DomainsBySID           = $DomainsBySID
                DomainsByNetbios       = $DomainsByNetbios
                DomainsByFqdn          = $DomainsByFqdn
            }
            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tResolve-Ace`tResolve-IdentityReference -IdentityReference '$IdentityReference'..."
            $ResolvedIdentityReference = Resolve-IdentityReference @ResolveIdentityReferenceParams

            # not sure if I should add a param to offer DNS instead of NetBIOS

            $ObjectProperties = @{
                AdsiProvider              = $AdsiServer.AdsiProvider
                AdsiServer                = $AdsiServer.Dns
                IdentityReferenceSID      = $ResolvedIdentityReference.SIDString
                IdentityReferenceName     = $ResolvedIdentityReference.IdentityReferenceUnresolved
                IdentityReferenceResolved = $ResolvedIdentityReference.IdentityReferenceNetBios
            }
            ForEach ($ThisProperty in $ACEPropertyNames) {
                $ObjectProperties[$ThisProperty] = $ThisACE.$ThisProperty
            }
            [PSCustomObject]$ObjectProperties

        }

    }

}
function Resolve-Ace3 {
    <#
        .SYNOPSIS
        Use ADSI to lookup info about IdentityReferences from Authorization Rule Collections that came from Discretionary Access Control Lists
        .DESCRIPTION
        Based on the IdentityReference proprety of each Access Control Entry:
        Resolve SID to NT account name and vise-versa
        Resolve well-known SIDs
        Resolve generic defaults like 'NT AUTHORITY' and 'BUILTIN' to the applicable computer or domain name
        Add these properties (IdentityReferenceSID,IdentityReferenceName,IdentityReferenceResolved) to the object and return it
        .INPUTS
        [System.Security.AccessControl.AuthorizationRuleCollection]$InputObject
        .OUTPUTS
        [PSCustomObject] Original object plus IdentityReferenceSID,IdentityReferenceName,IdentityReferenceResolved, and AdsiProvider properties
        .EXAMPLE
        Get-Acl |
        Expand-Acl |
        Resolve-Ace

        Use Get-Acl from the Microsoft.PowerShell.Security module as the source of the access list
        This works in either Windows Powershell or in Powershell
        Get-Acl does not support long paths (>256 characters)
        That was why I originally used the .Net Framework method
        .EXAMPLE
        Get-FolderAce -LiteralPath C:\Test -IncludeInherited |
        Resolve-Ace
        .EXAMPLE
        [System.String]$FolderPath = 'C:\Test'
        [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
        $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor [System.Security.AccessControl.AccessControlSections]::Owner
        $FileSecurity = [System.Security.AccessControl.FileSecurity]::new($DirectoryInfo,$Sections)
        $IncludeExplicitRules = $true
        $IncludeInheritedRules = $true
        $AccountType = [System.Security.Principal.SecurityIdentifier]
        $FileSecurity.GetAccessRules($IncludeExplicitRules,$IncludeInheritedRules,$AccountType) |
        Resolve-Ace

        This uses .Net Core as the source of the access list
        It uses the GetAccessRules method on the [System.Security.AccessControl.FileSecurity] class
        The targetType parameter of the method is used to specify that the accounts in the ACL are returned as SIDs
        .EXAMPLE
        [System.String]$FolderPath = 'C:\Test'
        [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
        $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor
        [System.Security.AccessControl.AccessControlSections]::Owner -bor
        [System.Security.AccessControl.AccessControlSections]::Group
        $DirectorySecurity = [System.Security.AccessControl.DirectorySecurity]::new($DirectoryInfo,$Sections)
        $IncludeExplicitRules = $true
        $IncludeInheritedRules = $true
        $AccountType = [System.Security.Principal.NTAccount]
        $FileSecurity.GetAccessRules($IncludeExplicitRules,$IncludeInheritedRules,$AccountType) |
        Resolve-Ace

        This uses .Net Core as the source of the access list
        It uses the GetAccessRules method on the [System.Security.AccessControl.FileSecurity] class
        The targetType parameter of the method is used to specify that the accounts in the ACL are returned as NT account names (DOMAIN\User)
        .EXAMPLE
        [System.String]$FolderPath = 'C:\Test'
        [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
        [System.Security.AccessControl.DirectorySecurity]$DirectorySecurity = $DirectoryInfo.GetAccessControl('Access')
        [System.Security.AccessControl.AuthorizationRuleCollection]$AuthRules = $DirectorySecurity.Access
        $AuthRules | Resolve-Ace

        Use the .Net Framework (or legacy .Net Core up to 2.2) as the source of the access list
        Only works in Windows PowerShell
        Those versions of .Net had a GetAccessControl method on the [System.IO.DirectoryInfo] class
        This method is removed in modern versions of .Net Core

        .EXAMPLE
        [System.String]$FolderPath = 'C:\Test'
        [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
        $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor [System.Security.AccessControl.AccessControlSections]::Owner
        $FileSecurity = [System.IO.FileSystemAclExtensions]::GetAccessControl($DirectoryInfo,$Sections)

        The [System.IO.FileSystemAclExtensions] class is a Windows-specific implementation
        It provides no known benefit over the cross-platform equivalent [System.Security.AccessControl.FileSecurity]

        .NOTES
        Dependencies:
            Get-DirectoryEntry
            Add-SidInfo
            Get-TrustedDomain
            Find-AdsiProvider

        if ($FolderPath.Length -gt 255) {
            $FolderPath = "\\?\$FolderPath"
        }
    #>
    [OutputType([PSCustomObject])]
    param (

        # Authorization Rule Collection of Access Control Entries from Discretionary Access Control Lists
        [Parameter(
            ValueFromPipeline
        )]
        [PSObject[]]$InputObject,

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        [hashtable]$Win32AccountsBySID = ([hashtable]::Synchronized(@{})),

        [hashtable]$Win32AccountsByCaption = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{}))

    )

    process {

        $ACEPropertyNames = (Get-Member -InputObject $InputObject[0] -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name
        ForEach ($ThisACE in $InputObject) {

            $IdentityReference = $ThisACE.IdentityReference.ToString()

            if ([string]::IsNullOrEmpty($IdentityReference)) {
                continue
            }

            $ThisServerDns = $null
            $DomainNetBios = $null

            # Remove the PsProvider prefix from the path string
            if (-not [string]::IsNullOrEmpty($ThisACE.SourceAccessList.Path)) {
                $LiteralPath = $ThisACE.SourceAccessList.Path -replace [regex]::escape("$($ThisACE.SourceAccessList.PsProvider)::"), ''
            } else {
                $LiteralPath = $LiteralPath -replace [regex]::escape("$($ThisACE.SourceAccessList.PsProvider)::"), ''
            }

            switch -Wildcard ($IdentityReference) {
                "S-1-*" {
                    # IdentityReference is a SID (Revision 1)
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tResolve-Ace`t'$IdentityReference'.LastIndexOf('-')"
                    $IndexOfLastHyphen = $IdentityReference.LastIndexOf("-")
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tResolve-Ace`t'$IdentityReference'.Substring(0, $IndexOfLastHyphen)"
                    $DomainSid = $IdentityReference.Substring(0, $IndexOfLastHyphen)
                    if ($DomainSid) {
                        $DomainCacheResult = $DomainsBySID[$DomainSid]
                        if ($DomainCacheResult) {
                            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tResolve-Ace`t# Domain SID cache hit for '$DomainSid'"
                            $ThisServerDns = $DomainCacheResult.Dns
                            $DomainNetBios = $DomainCacheResult.Netbios
                        } else {
                            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tResolve-Ace`t# Domain SID cache miss for '$DomainSid'"
                        }
                    }
                }
                "NT SERVICE\*" {
                    $ThisServerDns = Find-ServerNameInPath -LiteralPath $LiteralPath
                }
                "BUILTIN\*" {
                    $ThisServerDns = Find-ServerNameInPath -LiteralPath $LiteralPath
                }
                "NT AUTHORITY\*" {
                    $ThisServerDns = Find-ServerNameInPath -LiteralPath $LiteralPath
                }
                default {
                    $DomainNetBios = ($IdentityReference -split '\\')[0]
                    if ($DomainNetBios) {
                        $ThisServerDns = $DomainsByNetbios[$DomainNetBios].Dns #Doesn't work for BUILTIN, etc.
                    }
                    if (-not $ThisServerDns) {
                        $ThisServerDn = ConvertTo-DistinguishedName -Domain $DomainNetBios -DomainsByNetbios $DomainsByNetbios
                        $ThisServerDns = ConvertTo-Fqdn -DistinguishedName $ThisServerDn
                    }
                }
            }

            if (-not $ThisServerDns) {
                # Bug: I think this will report incorrectly for a remote domain not in the cache (trust broken or something)
                $ThisServerDns = Find-ServerNameInPath -LiteralPath $LiteralPath
            }
            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tResolve-Ace`t# '$IdentityReference' has a domain DNS name of '$ThisServerDns'"

            if (-not $DomainNetBios) {
                $DomainCacheResult = $DomainsByFqdn[$ThisServerDns]
                if ($DomainCacheResult) {
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tResolve-Ace`t# Domain FQDN cache hit for '$ThisServerDns'"
                    $DomainNetBios = $DomainCacheResult.Netbios
                } else {
                    Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tResolve-Ace`t# Domain FQDN cache miss for '$ThisServerDns'"
                }
            }

            if (-not $DomainNetBios) {
                $AdsiProvider = Find-AdsiProvider -AdsiServer $ThisServerDns
                $DomainNetBios = ConvertTo-DomainNetBIOS -DomainFQDN $ThisServerDns -AdsiProvider $AdsiProvider  -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
            }
            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tResolve-Ace`t# '$IdentityReference' has a domain NetBIOS name of '$DomainNetBios'"

            $GetAdsiServerParams = @{
                Fqdn                   = $ThisServerDns
                Win32AccountsBySID     = $Win32AccountsBySID
                Win32AccountsByCaption = $Win32AccountsByCaption
                DirectoryEntryCache    = $DirectoryEntryCache
                DomainsByFqdn          = $DomainsByFqdn
                DomainsByNetbios       = $DomainsByNetbios
                DomainsBySid           = $DomainsBySid
            }
            $AdsiServer = Get-AdsiServer @GetAdsiServerParams
            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tResolve-Ace`t# '$IdentityReference' has an ADSI server of '$($AdsiServer.AdsiProvider)://$($AdsiServer.Dns)'"

            $ResolveIdentityReferenceParams = @{
                IdentityReference      = $IdentityReference
                AdsiServer             = $AdsiServer
                Win32AccountsBySID     = $Win32AccountsBySID
                Win32AccountsByCaption = $Win32AccountsByCaption
                DirectoryEntryCache    = $DirectoryEntryCache
                DomainsBySID           = $DomainsBySID
                DomainsByNetbios       = $DomainsByNetbios
                DomainsByFqdn          = $DomainsByFqdn
            }
            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tResolve-Ace`tResolve-IdentityReference -IdentityReference '$IdentityReference'..."
            $ResolvedIdentityReference = Resolve-IdentityReference @ResolveIdentityReferenceParams

            # not sure if I should add a param to offer DNS instead of NetBIOS

            $ObjectProperties = @{
                AdsiProvider              = $AdsiServer.AdsiProvider
                AdsiServer                = $AdsiServer.Dns
                IdentityReferenceSID      = $ResolvedIdentityReference.SIDString
                IdentityReferenceName     = $ResolvedIdentityReference.IdentityReferenceUnresolved
                IdentityReferenceResolved = $ResolvedIdentityReference.IdentityReferenceNetBios
            }
            ForEach ($ThisProperty in $ACEPropertyNames) {
                $ObjectProperties[$ThisProperty] = $ThisACE.$ThisProperty
            }
            [PSCustomObject]$ObjectProperties

        }

    }

}

function Resolve-Ace4 {
    <#
        .SYNOPSIS
        Use ADSI to lookup info about IdentityReferences from Authorization Rule Collections that came from Discretionary Access Control Lists
        .DESCRIPTION
        Based on the IdentityReference proprety of each Access Control Entry:
        Resolve SID to NT account name and vise-versa
        Resolve well-known SIDs
        Resolve generic defaults like 'NT AUTHORITY' and 'BUILTIN' to the applicable computer or domain name
        Add these properties (IdentityReferenceSID,IdentityReferenceName,IdentityReferenceResolved) to the object and return it
        .INPUTS
        [System.Security.AccessControl.AuthorizationRuleCollection]$InputObject
        .OUTPUTS
        [PSCustomObject] Original object plus IdentityReferenceSID,IdentityReferenceName,IdentityReferenceResolved, and AdsiProvider properties
        .EXAMPLE
        Get-Acl |
        Expand-Acl |
        Resolve-Ace

        Use Get-Acl from the Microsoft.PowerShell.Security module as the source of the access list
        This works in either Windows Powershell or in Powershell
        Get-Acl does not support long paths (>256 characters)
        That was why I originally used the .Net Framework method
        .EXAMPLE
        Get-FolderAce -LiteralPath C:\Test -IncludeInherited |
        Resolve-Ace
        .EXAMPLE
        [System.String]$FolderPath = 'C:\Test'
        [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
        $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor [System.Security.AccessControl.AccessControlSections]::Owner
        $FileSecurity = [System.Security.AccessControl.FileSecurity]::new($DirectoryInfo,$Sections)
        $IncludeExplicitRules = $true
        $IncludeInheritedRules = $true
        $AccountType = [System.Security.Principal.SecurityIdentifier]
        $FileSecurity.GetAccessRules($IncludeExplicitRules,$IncludeInheritedRules,$AccountType) |
        Resolve-Ace

        This uses .Net Core as the source of the access list
        It uses the GetAccessRules method on the [System.Security.AccessControl.FileSecurity] class
        The targetType parameter of the method is used to specify that the accounts in the ACL are returned as SIDs
        .EXAMPLE
        [System.String]$FolderPath = 'C:\Test'
        [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
        $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor
        [System.Security.AccessControl.AccessControlSections]::Owner -bor
        [System.Security.AccessControl.AccessControlSections]::Group
        $DirectorySecurity = [System.Security.AccessControl.DirectorySecurity]::new($DirectoryInfo,$Sections)
        $IncludeExplicitRules = $true
        $IncludeInheritedRules = $true
        $AccountType = [System.Security.Principal.NTAccount]
        $FileSecurity.GetAccessRules($IncludeExplicitRules,$IncludeInheritedRules,$AccountType) |
        Resolve-Ace

        This uses .Net Core as the source of the access list
        It uses the GetAccessRules method on the [System.Security.AccessControl.FileSecurity] class
        The targetType parameter of the method is used to specify that the accounts in the ACL are returned as NT account names (DOMAIN\User)
        .EXAMPLE
        [System.String]$FolderPath = 'C:\Test'
        [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
        [System.Security.AccessControl.DirectorySecurity]$DirectorySecurity = $DirectoryInfo.GetAccessControl('Access')
        [System.Security.AccessControl.AuthorizationRuleCollection]$AuthRules = $DirectorySecurity.Access
        $AuthRules | Resolve-Ace

        Use the .Net Framework (or legacy .Net Core up to 2.2) as the source of the access list
        Only works in Windows PowerShell
        Those versions of .Net had a GetAccessControl method on the [System.IO.DirectoryInfo] class
        This method is removed in modern versions of .Net Core

        .EXAMPLE
        [System.String]$FolderPath = 'C:\Test'
        [System.IO.DirectoryInfo]$DirectoryInfo = Get-Item -LiteralPath $FolderPath
        $Sections = [System.Security.AccessControl.AccessControlSections]::Access -bor [System.Security.AccessControl.AccessControlSections]::Owner
        $FileSecurity = [System.IO.FileSystemAclExtensions]::GetAccessControl($DirectoryInfo,$Sections)

        The [System.IO.FileSystemAclExtensions] class is a Windows-specific implementation
        It provides no known benefit over the cross-platform equivalent [System.Security.AccessControl.FileSecurity]

        .NOTES
        Dependencies:
            Get-DirectoryEntry
            Add-SidInfo
            Get-TrustedDomain
            Find-AdsiProvider

        if ($FolderPath.Length -gt 255) {
            $FolderPath = "\\?\$FolderPath"
        }
    #>
    [OutputType([PSCustomObject])]
    param (

        # Authorization Rule Collection of Access Control Entries from Discretionary Access Control Lists
        [Parameter(
            ValueFromPipeline
        )]
        [PSObject[]]$InputObject,

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        [hashtable]$Win32AccountsBySID = ([hashtable]::Synchronized(@{})),

        [hashtable]$Win32AccountsByCaption = ([hashtable]::Synchronized(@{})),

        [hashtable]$DomainsBySID = ([hashtable]::Synchronized(@{})),

        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{}))

    )
    return $InputObject
}

function Resolve-IdentityReference {
    <#
        .SYNOPSIS
        Use ADSI to lookup info about IdentityReferences from Access Control Entries that came from Discretionary Access Control Lists
        .DESCRIPTION
        Based on the IdentityReference proprety of each Access Control Entry:
        Resolve SID to NT account name and vise-versa
        Resolve well-known SIDs
        Resolve generic defaults like 'NT AUTHORITY' and 'BUILTIN' to the applicable computer or domain name
        .INPUTS
        None. Pipeline input is not accepted.
        .OUTPUTS
        [PSCustomObject] with UnresolvedIdentityReference and SIDString properties (each strings)
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

        [hashtable]$Win32AccountsBySID = ([hashtable]::Synchronized(@{})),

        [hashtable]$Win32AccountsByCaption = ([hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache known servers to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$AdsiServersByDns = [hashtable]::Synchronized(@{}),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{}))
    )

    # Populate the caches of known domains if they are currently empty (not sure if this is required so commenting it out for now)
    #if (($DomainsByFqdn.Keys.Count + $DomainsByNetBios.Keys.Count + $DomainsBySid.Keys.Count) -lt 1) {
    #    $null = Get-TrustedDomainInfo -DirectoryEntryCache $DirectoryEntryCache -DomainsBySID $DomainsBySid -DomainsByNetbios $DomainsByNetbios -DomainsByFqdn $DomainsByFqdn
    #}

    # Populate the caches of known domains if they are currently empty (not sure if this is required so commenting it out for now)
    #if (($DomainsByFqdn.Keys.Count + $DomainsByNetBios.Keys.Count + $DomainsBySid.Keys.Count) -lt 1) {
    #    $null = Get-TrustedDomainInfo -DirectoryEntryCache $DirectoryEntryCache -DomainsBySID $DomainsBySid -DomainsByNetbios $DomainsByNetbios -DomainsByFqdn $DomainsByFqdn
    #}

    $ThisHostName = hostname
    $ServerNetBIOS = $AdsiServer.Netbios
    $split = $IdentityReference.Split('\')
    $DomainNetBIOS = $split[0]
    $DomainNetBIOS = $ServerNetBIOS
    $Name = $split[1]

    # Many Well-Known SIDs cannot be translated with the Translate method
    # Instead we have used CIM to collect information on instances of the Win32_Account class from the AdsiServer
    # This has been done by Get-AdsiServer and it updated the Win32AccountsBySID and Win32AccountsByCaption caches
    # Search the caches now
    $CacheResult = $Win32AccountsBySID["$ServerNetBIOS\$IdentityReference"]
    if ($CacheResult) {
        #IdentityReference is a SID, and has been cached from this server
        Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t# Win32_Account SID cache hit for '$ServerNetBIOS\$IdentityReference'"
        return [PSCustomObject]@{
            IdentityReferenceOriginal   = $IdentityReference
            # IdentityReferenceNameUnresolved below is not available, the Win32_Account instances in the cache are already resolved to the NetBios domain names
            IdentityReferenceUnresolved = $null # Could parse SID to get this?
            SIDString                   = $CacheResult.SID
            IdentityReferenceNetBios    = $CacheResult.Caption
            IdentityReferenceDns        = "$($AdsiServer.Dns)\$($CacheResult.Name)"
        }
    } else {
        Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t# Win32_Account SID cache miss for '$ServerNetBIOS\$IdentityReference'"
    }
    if ($Name) {
        # Win32_Account provides a NetBIOS-resolved IdentityReference
        # NT Authority\SYSTEM on would be SERVER123\SYSTEM as a Win32_Account on a server with hostname server123
        # This could also match on a domain account since those can be returned as Win32_Account, not sure if that will be a bug or what
        $CacheResult = $Win32AccountsByCaption["$ServerNetBIOS\$ServerNetBIOS\$Name"]
        if ($CacheResult) {
            # IdentityReference is an NT Account Name, and has been cached from this server
            Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t# Win32_Account caption cache hit for '$ServerNetBIOS\$ServerNetBIOS\$Name'"
            if ($ServerNetBIOS -eq $CacheResult.Domain) {
                $DomainDns = $AdsiServer.Dns
            }
            if (-not $DomainDns) {
                $DomainCacheResult = $DomainsByNetbios[$CacheResult.Domain]
                if ($DomainCacheResult) {
                    $DomainDns = $DomainCacheResult.Dns
                }
            }
            if (-not $DomainDns) {
                $DomainDns = ConvertTo-Fqdn -NetBIOS $DomainNetBIOS  -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
                $DomainDn = $DomainsByNetbios[$DomainNetBIOS].DistinguishedName
            }

            return [PSCustomObject]@{
                IdentityReferenceOriginal   = $IdentityReference
                # IdentityReferenceNameUnresolved below is not available, the Win32_Account instances in the cache are already resolved to the NetBios domain names
                IdentityReferenceUnresolved = $IdentityReference
                SIDString                   = $CacheResult.SID
                IdentityReferenceNetBios    = $CacheResult.Caption
                IdentityReferenceDns        = "$DomainDns\$($CacheResult.Name)"
            }
        } else {
            Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t# Win32_Account caption cache miss for '$ServerNetBIOS\$ServerNetBIOS\$Name'"
        }
    }
    $CacheResult = $Win32AccountsByCaption["$ServerNetBIOS\$IdentityReference"]
    if ($CacheResult) {
        # IdentityReference is an NT Account Name, and has been cached from this server
        Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t# Win32_Account caption cache hit for '$ServerNetBIOS\$IdentityReference'"
        return [PSCustomObject]@{
            IdentityReferenceOriginal   = $IdentityReference
            # IdentityReferenceNameUnresolved below is not available, the Win32_Account instances in the cache are already resolved to the NetBios domain names
            IdentityReferenceUnresolved = $null
            SIDString                   = $CacheResult.SID
            IdentityReferenceNetBios    = $CacheResult.Caption
            IdentityReferenceDns        = "$($AdsiServer.Dns)\$($CacheResult.Name)"
        }
    } else {
        Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t# Win32_Account caption cache miss for '$ServerNetBIOS\$IdentityReference'"
    }

    switch -Wildcard ($IdentityReference) {
        "S-1-*" {
            # IdentityReference is a Revision 1 SID
            <#
            Use the SecurityIdentifier.Translate() method to translate the SID to an NT Account name
                This .Net method makes it impossible to redirect the error stream directly
                Wrapping it in a scriptblock (which is then executed with &) fixes the problem
                I don't understand exactly why
                The scriptblock will evaluate null if the SID cannot be translated, and the error stream redirection supresses the error
            #>
            Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t[System.Security.Principal.SecurityIdentifier]::new('$IdentityReference').Translate([System.Security.Principal.NTAccount])"
            $SecurityIdentifier = [System.Security.Principal.SecurityIdentifier]::new($IdentityReference)
            $UnresolvedIdentityReference = & { $SecurityIdentifier.Translate([System.Security.Principal.NTAccount]).Value } 2>$null

            # The SID of the domain is everything up to (but not including) the last hyphen
            $DomainSid = $IdentityReference.Substring(0, $IdentityReference.LastIndexOf("-"))

            # Search the cache of domains, first by SID, then by NetBIOS name
            $DomainCacheResult = $DomainsBySID[$DomainSid]
            if (-not $DomainCacheResult) {
                $split = $UnresolvedIdentityReference -split '\\'
                $DomainCacheResult = $DomainsByNetbios[$split[0]]
                Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t# Domain SID cache miss for '$DomainSid'"
            } else {
                Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t# Domain SID cache hit for '$DomainSid'"
            }
            if ($DomainCacheResult) {
                $DomainNetBIOS = $DomainCacheResult.Netbios
                $DomainDns = $DomainCacheResult.Dns
            } else {
                Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t# Domain SID '$DomainSid' is unknown."
                $DomainNetBIOS = $split[0]
                Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t# Translated NTAccount name for '$IdentityReference' is '$UnresolvedIdentityReference'"
                $DomainDns = ConvertTo-Fqdn -NetBIOS $DomainNetBIOS  -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
            }
            $AdsiServer = Get-AdsiServer -Fqdn $DomainDns  -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid

            if ( -not $UnresolvedIdentityReference ) {
                $Resolved = [PSCustomObject]@{
                    IdentityReferenceOriginal   = $IdentityReference
                    IdentityReferenceUnresolved = $IdentityReference
                    SIDString                   = $IdentityReference
                    IdentityReferenceNetBios    = "$DomainNetBIOS\$IdentityReference"
                    IdentityReferenceDns        = "$DomainDns\$IdentityReference"
                }
            } else {
                # Recursively call this function to resolve the new IdentityReference we have
                $ResolveIdentityReferenceParams = @{
                    IdentityReference      = $UnresolvedIdentityReference
                    AdsiServer             = $AdsiServer
                    Win32AccountsBySID     = $Win32AccountsBySID
                    Win32AccountsByCaption = $Win32AccountsByCaption
                    AdsiServersByDns       = $AdsiServersByDns
                    DirectoryEntryCache    = $DirectoryEntryCache
                    DomainsBySID           = $DomainsBySID
                    DomainsByNetbios       = $DomainsByNetbios
                    DomainsByFqdn          = $DomainsByFqdn
                }
                $Resolved = Resolve-IdentityReference @ResolveIdentityReferenceParams
            }

            return $Resolved

        }
        "NT SERVICE\*" {
            # Some of them are services (yes services can have SIDs, notably this includes TrustedInstaller but it is also common with SQL)
            if ($ServerNetBIOS -eq $ThisHostName) {
                Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`tsc.exe showsid $Name"
                [string[]]$ScResult = & sc.exe showsid $Name
            } else {
                Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`tInvoke-Command -ComputerName $ServerNetBIOS -ScriptBlock { & sc.exe showsid `$args[0] } -ArgumentList $Name"
                [string[]]$ScResult = Invoke-Command -ComputerName $ServerNetBIOS -ScriptBlock { & sc.exe showsid $args[0] } -ArgumentList $Name
            }
            $ScResultProps = @{}

            $ScResult |
            ForEach-Object {
                $Prop, $Value = ($_ -split ':').Trim()
                $ScResultProps[$Prop] = $Value
            }

            $SIDString = $ScResultProps['SERVICE SID']
            $Caption = $IdentityReference -replace 'NT SERVICE', $ServerNetBIOS

            $DomainCacheResult = $DomainsByNetbios[$ServerNetBIOS]
            if ($DomainCacheResult) {
                $DomainDns = $DomainCacheResult.Dns
            }
            if (-not $DomainDns) {
                $DomainDns = ConvertTo-Fqdn -NetBIOS $ServerNetBIOS  -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
            }

            # Update the caches
            $Win32Acct = [PSCustomObject]@{
                SID     = $SIDString
                Caption = $Caption
                Domain  = $ServerNetBIOS
                Name    = $Name
            }
            $Win32AccountsByCaption["$ServerNetBIOS\$Caption"] = $Win32Acct
            $Win32AccountsBySID["$ServerNetBIOS\$SIDString"] = $Win32Acct

            return [PSCustomObject]@{
                IdentityReferenceOriginal   = $IdentityReference
                IdentityReferenceUnresolved = $IdentityReference
                SIDString                   = $SIDString
                IdentityReferenceNetBios    = $Caption
                IdentityReferenceDns        = "$DomainDns\$Name"
            }
        }
        "BUILTIN\*" {
            # Some built-in groups such as BUILTIN\Users and BUILTIN\Administrators are not in the CIM class or translatable with the NTAccount.Translate() method
            # But they may have real DirectoryEntry objects
            # Try to find the DirectoryEntry object locally on the server
            $DirectoryPath = "$($AdsiServer.AdsiProvider)`://$ServerNetBIOS/$Name"
            $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -DomainsBySid $DomainsBySid
            $SIDString = (Add-SidInfo -InputObject $DirectoryEntry -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -DomainsBySid $DomainsBySid).SidString
            $Caption = $IdentityReference -replace 'BUILTIN', $ServerNetBIOS
            $DomainDns = $AdsiServer.Dns

            # Update the caches
            $Win32Acct = [PSCustomObject]@{
                SID     = $SIDString
                Caption = $Caption
                Domain  = $ServerNetBIOS
                Name    = $Name
            }
            $Win32AccountsByCaption["$ServerNetBIOS\$Caption"] = $Win32Acct
            $Win32AccountsBySID["$ServerNetBIOS\$SIDString"] = $Win32Acct

            return [PSCustomObject]@{
                IdentityReferenceOriginal   = $IdentityReference
                IdentityReferenceUnresolved = $IdentityReference
                SIDString                   = $SIDString
                IdentityReferenceNetBios    = $Caption
                IdentityReferenceDns        = "$DomainDns\$Name"
            }
        }
    }

    # The IdentityReference is an NTAccount
    # Resolve NTAccount to SID
    # Start by determining the domain

    if (-not [string]::IsNullOrEmpty($DomainNetBIOS)) {
        $DomainNetBIOSCacheResult = $DomainsByNetbios[$DomainNetBIOS]
        if (-not $DomainNetBIOSCacheResult) {
            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tResolve-IdentityReference`t# Domain NetBIOS cache miss for '$($DomainNetBIOS)'."
            $DomainNetBIOSCacheResult = Get-AdsiServer -Netbios $DomainNetBIOS  -DirectoryEntryCache $DirectoryEntryCache -DomainsByFqdn $DomainsByFqdn -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid
            $DomainsByNetbios[$DomainNetBIOS] = $DomainNetBIOSCacheResult

        } else {
            Write-Debug -Message "  $(Get-Date -Format s)`t$(hostname)`tResolve-IdentityReference`t# Domain NetBIOS cache hit for '$($DomainNetBIOS)'."
        }

        $DomainDn = $DomainNetBIOSCacheResult.DistinguishedName
        $DomainDns = $DomainNetBIOSCacheResult.Dns

        # Try to resolve the account against the server the Access Control Entry came from (which may or may not be the directory server for the account)
        Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t[System.Security.Principal.NTAccount]::new('$ServerNetBIOS', '$Name').Translate([System.Security.Principal.SecurityIdentifier])"
        $NTAccount = [System.Security.Principal.NTAccount]::new($ServerNetBIOS, $Name)
        $SIDString = & { $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]) } 2>$null

        if (-not $SIDString) {
            # Try to resolve the account against the domain indicated in its NT Account Name (which may or may not be the correct ADSI server for the account, it won't be if it's NT AUTHORITY\SYSTEM for example)
            Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t[System.Security.Principal.NTAccount]::new('$DomainNetBIOS', '$Name')"
            $NTAccount = [System.Security.Principal.NTAccount]::new($DomainNetBIOS, $Name)
            Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t[System.Security.Principal.NTAccount]::new('$DomainNetBIOS', '$Name').Translate([System.Security.Principal.SecurityIdentifier])"
            $SIDString = & { $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]) } 2>$null
        } else {
            $DomainNetBIOS = $ServerNetBIOS
        }

        if (-not $SIDString) {
            # Try to resolve the account against the domain indicated in its NT Account Name
            # Add this domain to our list of known domains
            try {
                $SearchPath = Add-DomainFqdnToLdapPath -DirectoryPath "LDAP://$DomainDn"
                $DirectoryEntry = Search-Directory -DirectoryEntryCache $DirectoryEntryCache -DirectoryPath $SearchPath -Filter "(samaccountname=$Name)" -PropertiesToLoad @('objectClass', 'distinguishedName', 'name', 'grouptype', 'description', 'managedby', 'member', 'objectClass', 'Department', 'Title') -DomainsByNetbios $DomainsByNetbios
                $SIDString = (Add-SidInfo -InputObject $DirectoryEntry -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid).SidString
            } catch {
                Write-Warning "$(Get-Date -Format s)`t$(hostname)`tResolve-IdentityReference`t$($StartingIdentityName) could not be resolved against its directory"
                Write-Warning "$(Get-Date -Format s)`t$(hostname)`tResolve-IdentityReference`t$($_.Exception.Message)"
            }
        }

        if (-not $SIDString) {

            # Try to find the DirectoryEntry object directly on the server
            $DirectoryPath = "$($AdsiServer.AdsiProvider)`://$ServerNetBIOS/$Name"
            $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -DomainsBySid $DomainsBySid
            $SIDString = (Add-SidInfo -InputObject $DirectoryEntry -DirectoryEntryCache $DirectoryEntryCache -DomainsByNetbios $DomainsByNetbios -DomainsBySid $DomainsBySid -DomainsBySid $DomainsBySid).SidString

        }

        if ($SIDString) {
            $DomainNetBIOS = $ServerNetBIOS
        }

        # This covers unresolved SIDs for deleted accounts, broken domain trusts, etc.
        if ( '' -eq "$Name" ) {
            $Name = $IdentityReference
            Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t# An identity reference girl has no name ($Name)"
        } else {
            Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t# '$IdentityReference' is named '$Name'"
        }

        return [PSCustomObject]@{
            IdentityReferenceOriginal   = $IdentityReference
            IdentityReferenceUnresolved = $IdentityReference
            SIDString                   = $SIDString
            IdentityReferenceNetBios    = "$DomainNetBios\$Name"
            IdentityReferenceDns        = "$DomainDns\$Name"
        }

    }
}
function Search-Directory {
    <#
        .SYNOPSIS
        Use Active Directory Service Interfaces to search an LDAP directory
        .DESCRIPTION
        Find directory entries using the LDAP provider for ADSI (the WinNT provider does not support searching)
        Provides a wrapper around the [System.DirectoryServices.DirectorySearcher] class
        .INPUTS
        None. Pipeline input is not accepted.
        .OUTPUTS
        [System.DirectoryServices.DirectoryEntry]
        .EXAMPLE
        Search-Directory -Filter ''

        As the current user on a domain-joined computer, bind to the current domain and search for all directory entries matching the LDAP filter
    #>
    param (

        <#
        Path to the directory object to retrieve
        Defaults to the root of the current domain
        #>
        [string]$DirectoryPath = (([adsisearcher]'').SearchRoot.Path),

        # Filter for the LDAP search
        [string]$Filter,

        # Number of records per page of results
        [int]$PageSize = 1000,

        # Additional properties to return
        [string[]]$PropertiesToLoad,

        # Credentials to use
        [pscredential]$Credential,

        # Scope of the search
        [string]$SearchScope = 'subtree',

        <#
        Hashtable containing cached directory entries so they don't have to be retrieved from the directory again
        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{}))

    )

    $ThisHostName = HOSTNAME.EXE

    $DirectoryEntryParameters = @{
        DirectoryEntryCache = $DirectoryEntryCache
        DomainsByNetbios    = $DomainsByNetbios
    }

    if ($Credential) {
        $DirectoryEntryParameters['Credential'] = $Credential
    }

    if (($null -eq $DirectoryPath -or '' -eq $DirectoryPath)) {
        $Workgroup = (Get-CimInstance -ClassName Win32_ComputerSystem).Workgroup
        $DirectoryPath = "WinNT://$Workgroup/$(hostname)"
    }
    $DirectoryEntryParameters['DirectoryPath'] = $DirectoryPath

    $DirectoryEntry = Get-DirectoryEntry @DirectoryEntryParameters

    Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tSearch-Directory`t`$DirectorySearcher = [System.DirectoryServices.DirectorySearcher]::new(([System.DirectoryServices.DirectoryEntry]::new('$DirectoryPath')))"
    $DirectorySearcher = [System.DirectoryServices.DirectorySearcher]::new($DirectoryEntry)

    if ($Filter) {
        Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tSearch-Directory`t`$DirectorySearcher.Filter = '$Filter'"
        $DirectorySearcher.Filter = $Filter
    }

    Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tSearch-Directory`t`$DirectorySearcher.PageSize = '$PageSize'"
    $DirectorySearcher.PageSize = $PageSize
    Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tSearch-Directory`t`$DirectorySearcher.SearchScope = '$SearchScope'"
    $DirectorySearcher.SearchScope = $SearchScope

    ForEach ($Property in $PropertiesToLoad) {
        Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tSearch-Directory`t`$DirectorySearcher.PropertiesToLoad.Add('$Property')"
        $null = $DirectorySearcher.PropertiesToLoad.Add($Property)
    }

    Write-Debug -Message "  $(Get-Date -Format s)`t$ThisHostName`tSearch-Directory`t`$DirectorySearcher.FindAll()"
    $SearchResultCollection = $DirectorySearcher.FindAll()
    # TODO: Fix this.  Problems in integration testing trying to use the objects later if I dispose them here now.
    # Error: Cannot access a disposed object.
    #$null = $DirectorySearcher.Dispose()
    #$null = $DirectoryEntry.Dispose()
    $Output = [System.DirectoryServices.SearchResult[]]::new($SearchResultCollection.Count)
    $SearchResultCollection.CopyTo($Output, 0)
    #$null = $SearchResultCollection.Dispose()
    return $Output

}
<#
# Add any custom C# classes as usable (exported) types
$CSharpFiles = Get-ChildItem -Path "$PSScriptRoot\*.cs"
ForEach ($ThisFile in $CSharpFiles) {
    Add-Type -Path $ThisFile.FullName -ErrorAction Stop
}
#>
Export-ModuleMember -Function @('Add-DomainFqdnToLdapPath','Add-SidInfo','ConvertFrom-DirectoryEntry','ConvertFrom-PropertyValueCollectionToString','ConvertTo-DecStringRepresentation','ConvertTo-DistinguishedName','ConvertTo-DomainNetBIOS','ConvertTo-DomainSidString','ConvertTo-Fqdn','ConvertTo-HexStringRepresentation','ConvertTo-HexStringRepresentationForLDAPFilterString','ConvertTo-SidByteArray','Expand-AdsiGroupMember','Expand-IdentityReference','Expand-WinNTGroupMember','Find-AdsiProvider','Find-LocalAdsiServerSid','Get-ADSIGroup','Get-ADSIGroupMember','Get-AdsiServer','Get-CurrentDomain','Get-DirectoryEntry','Get-DomainInfo','Get-TrustedDomain','Get-Win32Account','Get-Win32UserAccount','Get-WinNTGroupMember','Invoke-ComObject','New-FakeDirectoryEntry','Resolve-Ace','Resolve-Ace3','Resolve-Ace4','Resolve-IdentityReference','Search-Directory')































