
function Add-DomainFqdnToLdapPath {
    <#
        .SYNOPSIS
        Add a domain FQDN to an LDAP directory path as the server address so the new path can be used for remote queries
        .DESCRIPTION
        Uses RegEx to:  
            Match the Domain Components from the Distinguished Name in the LDAP directory path  
            Convert the Domain Components to an FQDN  
            Insert them into the directory path as the server address
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
                    $DomainFqdn = $DomainDN | ConvertTo-Fqdn
                    if ($ThisPath -match "LDAP:\/\/$DomainFqdn\/") {
                        #Write-Debug "Domain FQDN already found in the directory path: $($ThisPath)"
                        $FQDNPath = $ThisPath
                    } else {
                        $FQDNPath = $ThisPath -replace 'LDAP:\/\/', "LDAP://$DomainFqdn/"
                    }
                } else {
                    #Write-Debug "Domain DN not found in the directory path: $($ThisPath)"
                    $FQDNPath = $ThisPath
                }
            } else {
                #Write-Debug "Not an expected directory path: $($ThisPath)"
                $FQDNPath = $ThisPath
            }

            $FQDNPath
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

        # Hashtable containing known domain SIDs as the keys and their names as the values
        $TrustedDomainSidNameMap = (Get-TrustedDomainSidNameMap -DirectoryEntryCache $DirectoryEntryCache)

    )

    begin {}

    process {
        ForEach ($Object in $InputObject) {
            $SID = $null
            if ($null -eq $Object) { continue }
            elseif (
                $null -ne $Object.objectSid.Value -and
                # With WinNT directory entries for the root (WinNT://localhost), objectSid is a method rather than a property
                # So we need to filter out those instances here to avoid this error:
                # The following exception occurred while retrieving the string representation for method "objectSid":
                # "Object reference not set to an instance of an object."
                $Object.objectSid.Value.GetType().FullName -ne 'System.Management.Automation.PSMethod'
            ) {
                [string]$SID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]$Object.objectSid.Value, 0)
            } elseif ($Object.Properties['objectSid'].Value) {
                [string]$SID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]$Object.Properties['objectSid'].Value, 0)
            } elseif ($Object.Properties['objectSid']) {
                [string]$SID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]($Object.Properties['objectSid'] | ForEach-Object { $_ }), 0)
            } elseif ($Object.objectSid) {
                [string]$SID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]$Object.objectSid, 0)
            }

            if ($Object.Properties['samaccountname']) {
                $SamAccountName = $Object.Properties['samaccountname']
            } else {
                #DirectoryEntries from the WinNT provider for local accounts do not have a samaccountname attribute so we use name instead
                $SamAccountName = $Object.Properties['name']
            }

            $DomainObject = $null
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
            if (!($DomainObject)) {
                # The SID of the domain is the SID of the user minus the last block of numbers
                $DomainSid = $SID.Substring(0, $Sid.LastIndexOf("-"))

                # Lookup other information about the domain using its SID as the key
                $DomainObject = $TrustedDomainSidNameMap[$DomainSid]
            }

            #Write-Debug "$SamAccountName`t$SID"

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
function Add-Win32AccountToCache {
    param (
        [hashtable]$SidCache,

        [hashtable]$CaptionCache,

        [hashtable]$AdsiServerCache
    )

    ForEach ($ThisKey in $AdsiServerCache.Keys) {
        $AdsiServer = $AdsiServerCache[$ThisKey]
        ForEach ($ThisSubkey in $AdsiServer.WellKnownSIDs.Keys) {
            $ThisValue = $AdsiServer.WellKnownSIDs[$ThisSubkey]
            $Win32AccountsBySID["$($ThisValue.Domain)\$($ThisValue.SID)"] = $ThisValue
            $Win32AccountsByCaption["$($ThisValue.Domain)\$($ThisValue.Caption)"] = $ThisValue
        }
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
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$Domain
    )
    process {
        ForEach ($ThisDomain in $Domain) {
            $IADsNameTranslateComObject = New-Object -comObject "NameTranslate"
            $IADsNameTranslateInterface = $IADsNameTranslateComObject.GetType()
            $null = $IADsNameTranslateInterface.InvokeMember("Init", "InvokeMethod", $Null, $IADsNameTranslateComObject, (3, $Null))
            $null = $IADsNameTranslateInterface.InvokeMember("Set", "InvokeMethod", $Null, $IADsNameTranslateComObject, (3, "$ThisDomain\"))
            $IADsNameTranslateInterface.InvokeMember("Get", "InvokeMethod", $Null, $IADsNameTranslateComObject, 1)
        }
    }
}
function ConvertTo-Fqdn {
    <#
        .SYNOPSIS
        Convert a domain distinguishedName name to its FQDN
        .DESCRIPTION
        Uses PowerShell's -replace operator to perform the conversion
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
        [Parameter(ValueFromPipeline)]
        [string[]]$DistinguishedName
    )
    process {
        ForEach ($DN in $DistinguishedName) {
            $DN -replace ',DC=', '.' -replace 'DC=', ''
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

        # Hashtable containing known domain SIDs as the keys and their names as the values
        $TrustedDomainSidNameMap = (Get-TrustedDomainSidNameMap -DirectoryEntryCache $DirectoryEntryCache)

    )

    begin {
        $i = 0
    }

    process {

        ForEach ($Entry in $DirectoryEntry) {

            $i++

            #$status = ("$(Get-Date -Format s)`t$(hostname)`tExpand-AdsiGroupMember`tStatus: Using ADSI to get info on group member $i`: " + $Entry.Name)
            #Write-Debug "  $status"

            $Principal = $null

            if ($Entry.objectClass -contains 'foreignSecurityPrincipal') {

                if ($Entry.distinguishedName.Value -match '(?>^CN=)(?<SID>[^,]*)') {

                    [string]$SID = $Matches.SID

                    #The SID of the domain is the SID of the user minus the last block of numbers
                    $DomainSid = $SID.Substring(0, $Sid.LastIndexOf("-"))
                    $Domain = $TrustedDomainSidNameMap[$DomainSid]

                    #$Success = $true
                    #try {
                    $Principal = Get-DirectoryEntry -DirectoryPath "LDAP://$($Domain.Dns)/<SID=$SID>" -DirectoryEntryCache $DirectoryEntryCache
                    #} catch {
                    #    $Success = $false
                    #    $Principal = $Entry
                    #    Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-AdsiGroupMember`t$SID could not be retrieved from $Domain"
                    #}

                    #if ($Success -eq $true) {

                    try {
                        $null = $Principal.RefreshCache($PropertiesToLoad)
                    } catch {
                        #$Success = $false
                        $Principal = $Entry
                        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-AdsiGroupMember`t$SID could not be retrieved from $Domain"
                    }

                    # Recursively enumerate group members
                    if ($Principal.properties['objectClass'].Value -contains 'group') {
                        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-AdsiGroupMember`t'$($Principal.properties['name'])' is a group in $Domain"
                        $Principal = ($Principal | Get-AdsiGroupMember -DirectoryEntryCache $DirectoryEntryCache).FullMembers | Expand-AdsiGroupMember -DirectoryEntryCache $DirectoryEntryCache -TrustedDomainSidNameMap $TrustedDomainSidNameMap

                    }

                    #}

                }

            } else {
                $Principal = $Entry
            }

            $Principal | Add-SidInfo -DirectoryEntryCache $DirectoryEntryCache -TrustedDomainSidNameMap $TrustedDomainSidNameMap

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
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Thread-safe hashtable to use for caching directory entries and avoiding duplicate directory queries
        [hashtable]$IdentityReferenceCache = ([hashtable]::Synchronized(@{}))

    )

    begin {

        #Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$(($AccessControlEntry | Measure).Count) unique IdentityReferences found in the $(($AccessControlEntry | Measure).Count) ACEs"

        # Get the SID of the current domain
        $CurrentDomain = (Get-CurrentDomain)

        # Convert the objectSID attribute (byte array) to a security descriptor string formatted according to SDDL syntax (Security Descriptor Definition Language)
        [string]$CurrentDomainSID = & { [System.Security.Principal.SecurityIdentifier]::new([byte[]]$CurrentDomain.objectSid.Value, 0) } 2>$null

        $KnownDomains = @{}
        $i = 0

    }

    process {

        ForEach ($ThisIdentity in $AccessControlEntry) {

            $ThisIdentityGroup = $ThisIdentity.Group

            $i++
            #Calculate the completion percentage, and format it to show 0 decimal places
            $percentage = "{0:N0}" -f (($i / ($AccessControlEntry.Count)) * 100)

            #Display the progress bar
            $status = $percentage + "% - Using ADSI to get info on NTFS IdentityReference $i of " + $AccessControlEntry.Count + ": " + $ThisIdentity.Name
            #Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`tStatus: $status"

            #Write-Progress -Activity ("Unique IdentityReferences: " + $AccessControlEntry.Count) -Status $status -PercentComplete $percentage

            if ($null -eq $IdentityReferenceCache[$ThisIdentity.Name]) {

                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`tIdentityReferenceCache miss for '$($ThisIdentity.Name)'"

                $DomainDN = $null
                $DirectoryEntry = $null
                $Members = $null

                $StartingIdentityName = $ThisIdentity.Name
                $split = $StartingIdentityName.Split('\')
                $domainNetbiosString = $split[0]
                $name = $split[1]

                if (
                    $null -ne $name -and
                    ($ThisIdentity.Group.AdsiProvider | Select-Object -First 1) -eq 'LDAP'
                ) {
                    Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) is a domain security principal"

                    # Add this domain to our list of known domains
                    if (
                        -not $KnownDomains[$domainNetbiosString] -and
                        -not [string]::IsNullOrEmpty($domainNetbiosString)
                    ) {
                        $KnownDomains[$domainNetbiosString] = ConvertTo-DistinguishedName -Domain $domainNetbiosString
                        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`tCache miss for domain $($domainNetbiosString).  Adding its Distinguished Name to dictionary of known domains for future lookup"
                    }

                    # Search the domain for the principal
                    $DomainDn = $KnownDomains[$domainNetbiosString]
                    try {
                        $SearchPath = "LDAP://$DomainDn" | Add-DomainFqdnToLdapPath
                        $DirectoryEntry = Search-Directory -DirectoryEntryCache $DirectoryEntryCache -DirectoryPath $SearchPath -Filter "(samaccountname=$Name)" -PropertiesToLoad @('objectClass', 'distinguishedName', 'name', 'grouptype', 'description', 'managedby', 'member', 'objectClass', 'Department', 'Title')
                    } catch {
                        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) could not be resolved against its directory"
                        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($_.Exception.Message)"
                    }

                } elseif (((($StartingIdentityName -split '-') | Select-Object -SkipLast 1) -join '-') -eq $CurrentDomainSID) {
                    Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) is an unresolved SID from the current domain"

                    # Get the distinguishedName and netBIOSName of the current domain.  This also determines whether the domain is online.
                    $DomainDN = $CurrentDomain.distinguishedName.Value
                    $DomainFQDN = $DomainDN | ConvertTo-Fqdn
                    $PartitionsPath = "LDAP://cn=partitions,cn=configuration,$DomainDn" | Add-DomainFqdnToLdapPath
                    $DomainCrossReference = Search-Directory -DirectoryEntryCache $DirectoryEntryCache -DirectoryPath $PartitionsPath -Filter "(&(objectcategory=crossref)(dnsroot=$DomainFQDN)(netbiosname=*))" -PropertiesToLoad netbiosname
                    if ($DomainCrossReference.Properties ) {
                        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`tThe domain '$DomainFQDN' is online"
                        $domainNetbiosString = $DomainCrossReference.Properties['netbiosname']
                        # TODO: The domain is online, so let's see if any domain trusts have issues?  Determine if SID is foreign security principal?
                        # TODO: What if the foreign security principal exists but the corresponding domain trust is down?  Don't want to recommend deletion of the ACE in that case.
                    }
                    $SidObject = [System.Security.Principal.SecurityIdentifier]::new($StartingIdentityName)
                    $SidBytes = [byte[]]::new($SidObject.BinaryLength)
                    $null = $SidObject.GetBinaryForm($SidBytes, 0)
                    $ObjectSid = ConvertTo-HexStringRepresentationForLDAPFilterString -SIDByteArray $SidBytes
                    try {
                        $DirectoryEntry = Search-Directory -DirectoryEntryCache $DirectoryEntryCache -DirectoryPath "LDAP://$DomainDn" -Filter "(objectsid=$ObjectSid)" -PropertiesToLoad @('objectClass', 'distinguishedName', 'name', 'grouptype', 'description', 'managedby', 'member', 'objectClass', 'Department', 'Title')
                    } catch {
                        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) could not be resolved against its directory"
                        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($_.Exception.Message)"
                    }


                } else {

                    Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) is a local security principal or unresolved SID"

                    # Determine if SID belongs to current domain
                    $IdentityDomainSID = (($StartingIdentityName -split '-') | Select-Object -SkipLast 1) -join '-'
                    if ($IdentityDomainSID -eq $CurrentDomainSID) {
                        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) belongs to the current domain.  Could be a deleted user.  ?possibly a foreign security principal corresponding to an offline trusted domain or deleted user in the trusted domain?"
                    } else {
                        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) does not belong to the current domain. Could be a local security principal or belong to an unresolvable domain."
                    }

                    if ($null -eq $name) { $name = $StartingIdentityName }

                    if ($name -match 'S-\d+-\d+-\d+-\d+-\d+\-\d+\-\d+') {
                        if ($Domains.Count -gt 1) {
                            $DirectoryEntry = ForEach ($domainNetbiosString in $Domains) {

                                try {
                                    $UsersGroup = Get-DirectoryEntry -DirectoryPath "WinNT://$domainNetbiosString/Users,group" -DirectoryEntryCache $DirectoryEntryCache
                                } catch {
                                    Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`tCould not connect to $domainNetbiosString using PSRemoting"
                                    Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$_"
                                }
                                $MembersOfUsersGroup = Get-WinNTGroupMember -DirectoryEntry $UsersGroup -DirectoryEntryCache $DirectoryEntryCache
                                $MembersOfUsersGroup | Where-Object -FilterScript { ($name -eq [System.Security.Principal.SecurityIdentifier]::new([byte[]]$_.Properties['objectSid'].Value, 0)) }
                                $ThisIdentity = [pscustomobject]@{
                                    Count = $(($ThisIdentityGroup | Measure-Object).Count)
                                    Name  = "$domainNetbiosString\" + $DirectoryEntry.Name
                                    Group = $ThisIdentityGroup | Where-Object -FilterScript { ($_.SourceAccessList.Path -split '\\')[2] -eq $domainNetbiosString }
                                    #####Group = $ThisIdentityGroup | Where-Object -FilterScript { ($_.Path -split '\\')[2] -eq $domainNetbiosString }
                                }

                            }

                        }

                        else {

                            try {
                                $UsersGroup = Get-DirectoryEntry -DirectoryPath "WinNT://$domainNetbiosString/Users,group" -DirectoryEntryCache $DirectoryEntryCache
                            } catch {
                                Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`tCould not connect to $domainNetbiosString using PSRemoting"
                                Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$_"
                            }
                            $MembersOfUsersGroup = Get-WinNTGroupMember -DirectoryEntry $UsersGroup -DirectoryEntryCache $DirectoryEntryCache
                            $DirectoryEntry = $MembersOfUsersGroup | Where-Object -FilterScript { ($name -eq [System.Security.Principal.SecurityIdentifier]::new([byte[]]$_.Properties['objectSid'].Value, 0)) }
                            $ThisIdentity = [pscustomobject]@{
                                Count = $(($ThisIdentityGroup | Measure-Object).Count)
                                Name  = "$domainNetbiosString\" + $DirectoryEntry.Name
                                Group = $ThisIdentityGroup
                            }

                        }

                    }

                    else {
                        if ($Domains.Count -gt 1) {
                            $DirectoryEntry = ForEach ($domainNetbiosString in $Domains) {
                                $DirectoryPath = "WinNT://$domainNetbiosString/$name"
                                try {
                                    Get-DirectoryEntry -DirectoryPath $DirectoryPath -PropertiesToLoad members -DirectoryEntryCache $DirectoryEntryCache
                                } catch {
                                    Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($DirectoryPath) could not be resolved"
                                }
                            }
                        } else {
                            $DirectoryPath = "WinNT://$domainNetbiosString/$name"
                            try {
                                $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath -PropertiesToLoad members -DirectoryEntryCache $DirectoryEntryCache
                            } catch {
                                Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($DirectoryPath) could not be resolved"
                            }

                        }
                    }

                }

                $ObjectType = $null
                if ($null -ne $DirectoryEntry) {
                    $ThisIdentity | Add-Member -Name 'DirectoryEntry' -Value $DirectoryEntry -MemberType NoteProperty -Force

                    if (
                        $DirectoryEntry.Properties['objectClass'] -contains 'group' -or
                        $DirectoryEntry.SchemaClassName -contains 'Group'
                    ) {
                        $ObjectType = 'Group'
                    } else {
                        $ObjectType = 'User'
                    }

                    if ($NoGroupMembers -eq $false) {

                        if ($DirectoryEntry.Properties['objectClass'] -contains 'group') {

                            # Retrieve the members of groups from the LDAP provider
                            #$Members = (Get-AdsiGroup -DirectoryEntryCache $DirectoryEntryCache -DirectoryPath $DirectoryEntry.Path).FullMembers
                            $Members = Get-AdsiGroupMember -Group $DirectoryEntry -DirectoryEntryCache $DirectoryEntryCache

                        } else {

                            # Retrieve the members of groups from the WinNT provider
                            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($DirectoryEntry.Path) must be a WinNT user or group"
                            $Members = Get-WinNTGroupMember -DirectoryEntryCache $DirectoryEntryCache -DirectoryEntry $DirectoryEntry -KnownDomains $KnownDomains

                        }

                        if ($Members) {

                            $Members |
                            ForEach-Object {

                                if ($_.Domain) {

                                    $_ | Add-Member -Force -NotePropertyMembers @{
                                        Group = $ThisIdentityGroup
                                    }

                                } else {

                                    $_ | Add-Member -Force -NotePropertyMembers @{
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

                        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($DirectoryEntry.Path) has $(($Members | Measure-Object).Count) members"

                        $ThisIdentity |
                        Add-Member -Name 'Members' -Value $Members -MemberType NoteProperty -Force
                    }
                } else {
                    Write-Warning "$(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`t$($StartingIdentityName) could not be matched to a DirectoryEntry"
                }
                $ThisIdentity | Add-Member -Force -NotePropertyMembers @{
                    DomainDn      = $DomainDn
                    DomainNetbios = $DomainNetBiosString
                    ObjectType    = $ObjectType
                }
                $IdentityReferenceCache[$StartingIdentityName] = $ThisIdentity

            }

            else {
                #Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-IdentityReference`tIdentityReferenceCache hit for '$($ThisIdentity.Name)'"
                $null = $IdentityReferenceCache[$ThisIdentity.Name].Group.Add($ThisIdentityGroup)
                $ThisIdentity = $IdentityReferenceCache[$ThisIdentity.Name]
            }

            $ThisIdentity

        }

    }

    end {
        #Write-Progress -Activity Completed -Completed
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
        Hashtable containing cached directory entries so they don't need to be retrieved from the directory again
        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{}))

    )
    begin {}
    process {
        ForEach ($ThisEntry in $DirectoryEntry) {

            if (!($ThisEntry.Properties)) {
                Write-Warning "'$ThisEntry' has no properties"
            } elseif ($ThisEntry.Properties['objectClass'] -contains 'group') {

                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-WinNTGroupMember`t'$($ThisEntry.Path)' is an ADSI group"
                (Get-AdsiGroup -DirectoryEntryCache $DirectoryEntryCache -DirectoryPath $ThisEntry.Path).FullMembers |
                Add-SidInfo -DirectoryEntryCache $DirectoryEntryCache

            } else {

                if ($ThisEntry.SchemaClassName -contains 'group') {
                    Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-WinNTGroupMember`t'$($ThisEntry.Path)' is a WinNT group"

                    if ($ThisEntry.GetType().FullName -eq 'System.Collections.Hashtable') {
                        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-WinNTGroupMember`t'$($ThisEntry.Path)' is a special group with no direct memberships"
                        $ThisEntry | Add-SidInfo -DirectoryEntryCache $DirectoryEntryCache
                    } else {
                        Get-WinNTGroupMember -DirectoryEntry $ThisEntry -DirectoryEntryCache $DirectoryEntryCache
                    }

                } else {
                    Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tExpand-WinNTGroupMember`t'$($ThisEntry.Path)' is a user account"
                    $ThisEntry | Add-SidInfo -DirectoryEntryCache $DirectoryEntryCache
                }

            }

        }
    }
    end {}
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
            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tFind-AdsiProvider`t[System.DirectoryServices.DirectoryEntry]::Exists('$AdsiPath')"
            try {
                $null = [System.DirectoryServices.DirectoryEntry]::Exists($AdsiPath)
                $AdsiProvider = 'LDAP'
            } catch { Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tFind-AdsiProvider`t$ThisServer is not an LDAP server" }
            if (!$AdsiProvider) {
                $AdsiPath = "WinNT://$ThisServer"
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tFind-AdsiProvider`t[System.DirectoryServices.DirectoryEntry]::Exists('$AdsiPath')"
                try {
                    $null = [System.DirectoryServices.DirectoryEntry]::Exists($AdsiPath)
                    $AdsiProvider = 'WinNT'
                } catch {
                    Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tFind-AdsiProvider`t$ThisServer is not a WinNT server"
                }
            }
            if (!$AdsiProvider) {
                $AdsiProvider = 'none'
            }
        }
        $AdsiProvider
    }
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
        Hashtable containing cached directory entries so they don't have to be retrieved from the directory again
        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{}))

    )

    $GroupParams = @{
        DirectoryEntryCache = $DirectoryEntryCache
        DirectoryPath       = $DirectoryPath
        PropertiesToLoad    = $PropertiesToLoad
    }
    $GroupMemberParams = @{
        DirectoryEntryCache = $DirectoryEntryCache
        PropertiesToLoad    = $PropertiesToLoad
    }

    switch -Regex ($DirectoryPath) {
        '^WinNT' {
            $GroupParams['DirectoryPath'] = "$DirectoryPath/$GroupName"
            Get-DirectoryEntry @GroupParams |
            Get-WinNTGroupMember @GroupMemberParams
        }
        '^$' {
            # This is expected for a workgroup computer
            $GroupParams['DirectoryPath'] = "WinNT://localhost/$GroupName"
            Get-DirectoryEntry @GroupParams |
            Get-WinNTGroupMember @GroupMemberParams
        }
        default {
            if ($GroupName) {
                $GroupParams['Filter'] = "(&(objectClass=group)(cn=$GroupName))"
            } else {
                $GroupParams['Filter'] = "(objectClass=group)"
            }
            Search-Directory @GroupParams |
            Get-AdsiGroupMember @GroupMemberParams
        }
    }

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
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{}))

    )
    begin {

        $PathRegEx = '(?<Path>LDAP:\/\/[^\/]*)'
        $DomainRegEx = '(?i)DC=\w{1,}?\b'

        $SearchParameters = @{
            PropertiesToLoad    = $PropertiesToLoad
            DirectoryEntryCache = $DirectoryEntryCache
        }

        $TrustedDomainSidNameMap = Get-TrustedDomainSidNameMap -DirectoryEntryCache $DirectoryEntryCache

    }
    process {

        foreach ($ThisGroup in $Group) {

            # Recursive search
            $SearchParameters['Filter'] = "(memberof:1.2.840.113556.1.4.1941:=$($ThisGroup.Properties['distinguishedname']))"

            # Non-recursive search
            #$SearchParameters['Filter'] = "(memberof=$($ThisGroup.Properties['distinguishedname']))"

            if ($ThisGroup.Path -match $PathRegEx) {

                $SearchParameters['DirectoryPath'] = $Matches.Path | Add-DomainFqdnToLdapPath

                if ($ThisGroup.Path -match $DomainRegEx) {
                    $Domain = ([regex]::Matches($ThisGroup.Path, $DomainRegEx) | ForEach-Object { $_.Value }) -join ','
                    $SearchParameters['DirectoryPath'] = "LDAP://$Domain" | Add-DomainFqdnToLdapPath
                } else {
                    $SearchParameters['DirectoryPath'] = $ThisGroup.Path | Add-DomainFqdnToLdapPath
                }

            } else {
                $SearchParameters['DirectoryPath'] = $ThisGroup.Path | Add-DomainFqdnToLdapPath
            }

            #Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-AdsiGroupMember`t$($SearchParameters['Filter'])"

            $GroupMemberSearch = Search-Directory @SearchParameters

            if ($GroupMemberSearch.Count -gt 0) {

                $CurrentADGroupMembers = $GroupMemberSearch | ForEach-Object {
                    $FQDNPath = $_.Path | Add-DomainFqdnToLdapPath
                    Get-DirectoryEntry -DirectoryPath $FQDNPath -DirectoryEntryCache $DirectoryEntryCache
                }

            } else {
                $CurrentADGroupMembers = $null
            }

            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-AdsiGroupMember`t$($ThisGroup.Properties.name) has $(($CurrentADGroupMembers | Measure-Object).Count) members"

            $ProcessedGroupMembers = $CurrentADGroupMembers | Expand-AdsiGroupMember -DirectoryEntryCache $DirectoryEntryCache -TrustedDomainSidNameMap $TrustedDomainSidNameMap
            $ThisGroup |
            Add-Member -MemberType NoteProperty -Name FullMembers -Value $ProcessedGroupMembers -Force -PassThru

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
        [System.String]$AdsiServer
        .OUTPUTS
        [PSCustomObject] with AdsiProvider and WellKnownSIDs properties
        .EXAMPLE
        Get-AdsiServer -AdsiServer localhost

        Find the ADSI provider of the local computer
        .EXAMPLE
        Get-AdsiServer -AdsiServer 'ad.contoso.com'

        Find the ADSI provider of the AD domain 'ad.contoso.com'
    #>
    [OutputType([System.String])]

    param (

        # IP address or hostname of the directory server whose ADSI provider type to determine
        [Parameter(ValueFromPipeline)]
        [string[]]$AdsiServer,

        # Cache of known directory servers to reduce duplicate queries
        [hashtable]$KnownServers = [hashtable]::Synchronized(@{})

    )
    process {
        ForEach ($ThisServer in $AdsiServer) {
            if (!($KnownServers[$ThisServer])) {
                $AdsiProvider = Find-AdsiProvider -AdsiServer $ThisServer
                $WellKnownSIDs = Get-WellKnownSid -CimServerName $ThisServer
                $KnownServers[$ThisServer] = [pscustomobject]@{
                    AdsiProvider  = $AdsiProvider
                    WellKnownSIDs = $WellKnownSIDs
                }
            }
            $KnownServers[$ThisServer]
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
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{}))

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
            '^$' {
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-DirectoryEntry`t$(hostname) does not appear to be domain-joined since the SearchRoot Path is empty. Defaulting to WinNT provider for localhost instead."
                $Workgroup = (Get-CimInstance -ClassName Win32_ComputerSystem).Workgroup
                $DirectoryPath = "WinNT://$Workgroup/$(hostname)"
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-DirectoryEntry`t[System.DirectoryServices.DirectoryEntry]::new('$DirectoryPath')"
                if ($Credential) {
                    $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath, $($Credential.UserName), $($Credential.GetNetworkCredential().password))
                } else {
                    $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath)
                }

                $SampleUser = $DirectoryEntry.PSBase.Children |
                Where-Object -FilterScript { $_.schemaclassname -eq 'user' } |
                Select-Object -First 1 |
                Add-SidInfo

                $DirectoryEntry | Add-Member -MemberType NoteProperty -Name 'Domain' -Value $SampleUser.Domain -Force

            }
            # Otherwise the DirectoryPath is an LDAP path
            default {

                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-DirectoryEntry`t[System.DirectoryServices.DirectoryEntry]::new('$DirectoryPath')"
                if ($Credential) {
                    $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath, $($Credential.UserName), $($Credential.GetNetworkCredential().password))
                } else {
                    $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath)
                }

            }

        }

        $DirectoryEntryCache[$DirectoryPath] = $DirectoryEntry
    } else {
        #Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-DirectoryEntry`tDirectoryEntryCache hit for '$DirectoryPath'"
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
function Get-TrustedDomainSidNameMap {
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
        [System.Collections.Hashtable] The current domain trust relationships

        .EXAMPLE
        Get-TrustedDomainSidNameMap

        Get the trusted domains of the current computer
    #>
    [OutputType([System.Collections.Hashtable])]
    param (

        # Key the dictionary by the domain NetBIOS names instead of SIDs
        [Switch]$KeyByNetbios,

        <#
        Hashtable containing cached directory entries so they don't have to be retrieved from the directory again
        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{}))

    )

    $Map = @{}

    # Redirect the error stream to null
    $nltestresults = & nltest /domain_trusts 2> $null
    $NlTestRegEx = '[\d]*: .*'
    $TrustRelationships = $nltestresults -match $NlTestRegEx

    foreach ($TrustRelationship in $TrustRelationships) {

        $RegEx = '(?<index>[\d]*): (?<netbios>\S*) (?<dns>\S*).*'
        if ($TrustRelationship -match $RegEx) {
            $DomainDnsName = $Matches.dns
            $DomainNetbios = $Matches.netbios
        } else {
            continue
        }

        $DomainDirectoryEntry = Get-DirectoryEntry -DirectoryPath "LDAP://$DomainDnsName" -DirectoryEntryCache $DirectoryEntryCache
        try {
            $null = $DomainDirectoryEntry.RefreshCache('objectSid')
        } catch {
            Write-Warning "$(Get-Date -Format s)`t$(hostname)`tGet-TrustedDomainSidNameMap`tLDAP Domain: '$DomainDnsName' - $($_.Exception.Message)"
            continue
        }

        try {
            $DomainSid = [System.Security.Principal.SecurityIdentifier]::new([byte[]]$DomainDirectoryEntry.Properties["objectSid"].Value, 0).ToString()
        } catch {
            Write-Warning "$(Get-Date -Format s)`t$(hostname)`tGet-TrustedDomainSidNameMap`tLDAP Domain: '$DomainDnsName' has an invalid SID - $($_.Exception.Message)"
            continue
        }

        $DistinguishedName = ConvertTo-DistinguishedName -Domain $DomainNetbios
        if ($KeyByNetbios -eq $true) {
            $Map[$DomainNetbios] = [pscustomobject]@{
                Dns               = $DomainDnsName
                Netbios           = $DomainNetbios
                Sid               = $DomainSid
                DistinguishedName = $DistinguishedName
            }
        } else {
            $Map[$DomainSid] = [pscustomobject]@{
                Dns               = $DomainDnsName
                Netbios           = $DomainNetbios
                Sid               = $DomainSid
                DistinguishedName = $DistinguishedName
            }
        }
    }

    # Add the WinNT domain of the local computer as well
    $LocalAccountSID = Get-CimInstance -Query "SELECT SID FROM Win32_UserAccount WHERE LocalAccount = 'True'" |
    Select-Object -First 1 -ExpandProperty SID
    $DomainSid = $LocalAccountSID.Substring(0, $LocalAccountSID.LastIndexOf("-"))
    $DomainNetBios = hostname
    $DomainDnsName = "$DomainNetbios.$((Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters').'NV Domain')"

    if ($KeyByNetbios -eq $true) {
        $Map[$DomainNetbios] = [pscustomobject]@{
            Dns               = $DomainDnsName
            Netbios           = $DomainNetbios
            Sid               = $DomainSid
            DistinguishedName = $null
        }
    } else {
        $Map[$DomainSid] = [pscustomobject]@{
            Dns               = $DomainDnsName
            Netbios           = $DomainNetbios
            Sid               = $DomainSid
            DistinguishedName = $null
        }
    }

    return $Map

}
function Get-WellKnownSid {
    <#
        .SYNOPSIS
        Use CIM to get well-known SIDs
        .DESCRIPTION
        Use WinRM to query the CIM namespace root/cimv2 for instances of the Win32_Account class
        .INPUTS
        [System.String]$CimServerName
        .OUTPUTS
        [Microsoft.Management.Infrastructure.CimInstance] for each instance of the Win32_Account class in the root/cimv2 namespace
        .EXAMPLE
        Get-WellKnownSid

        Get the well-known SIDs on the current computer
        .EXAMPLE
        Get-WellKnownSid -CimServerName 'server123'

        Get the well-known SIDs on the remote computer 'server123'
    #>
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    param (
        [Parameter(ValueFromPipeline)]
        [string[]]$CimServerName
    )
    process {
        ForEach ($ThisServer in $CimServerName) {
            if ($ThisServer -eq (hostname) -or $ThisServer -eq 'localhost' -or $ThisServer -eq '127.0.0.1' -or [string]::IsNullOrEmpty($ThisServer)) {
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-WellKnownSid`tNew-CimSession"
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-WellKnownSid`tGet-CimInstance -ClassName Win32_Account"
                $CimSession = New-CimSession
            } else {
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-WellKnownSid`tNew-CimSession -ComputerName '$ThisServer'"
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-WellKnownSid`tGet-CimInstance -ClassName Win32_Account -ComputerName '$ThisServer'"
                $CimSession = New-CimSession -ComputerName $ThisServer
            }
            $Results = @{}
            Get-CimInstance -ClassName Win32_Account -CimSession $CimSession |
            ForEach-Object {
                $Results[$_.Name] = $_
            }
            $Results
            Remove-CimSession -CimSession $CimSession
        }
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

        <#
        Hashtable containing cached directory entries so they don't have to be retrieved from the directory again
        Uses a thread-safe hashtable by default
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Properties of the group members to find in the directory
        [string[]]$PropertiesToLoad,

        # Hashtable of domain DNs
        $KnownDomains = (Get-TrustedDomainSidNameMap -DirectoryEntryCache $DirectoryEntryCache -KeyByNetbios)

    )
    process {
        ForEach ($ThisDirEntry in $DirectoryEntry) {
            $SourceDomain = $ThisDirEntry.Path | Split-Path -Parent | Split-Path -Leaf
            # Retrieve the members of local groups
            if ($null -ne $ThisDirEntry.Properties['groupType'] -or $ThisDirEntry.schemaclassname -contains 'Group') {
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
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-WinNTGroupMember`t'$($ThisDirEntry.Path)' has $(($DirectoryMembers | Measure-Object).Count) members"
                ForEach ($DirectoryMember in $DirectoryMembers) {
                    # The IADsGroup::Members method returns ComObjects
                    # But proper .Net objects are much easier to work with
                    # So we will convert the ComObjects into DirectoryEntry objects
                    $DirectoryPath = Invoke-ComObject -ComObject $DirectoryMember -Property 'ADsPath'
                    $MemberDomainDn = $null
                    if ($DirectoryPath -match 'WinNT:\/\/(?<Domain>[^\/]*)\/(?<Acct>.*$)') {
                        $MemberName = $Matches.Acct
                        $MemberDomainNetbios = $Matches.Domain

                        if ($KnownDomains[$MemberDomainNetbios] -and $MemberDomainNetbios -ne $SourceDomain) {
                            $MemberDomainDn = $KnownDomains[$MemberDomainNetbios].DistinguishedName
                        }
                        if ($DirectoryPath -match 'WinNT:\/\/(?<Domain>[^\/]*)\/(?<Middle>[^\/]*)\/(?<Acct>.*$)') {
                            if ($Matches.Middle -eq ($ThisDirEntry.Path | Split-Path -Parent | Split-Path -Leaf)) {
                                $MemberDomainDn = $null
                            }
                        }
                    }

                    $MemberParams = @{
                        DirectoryEntryCache = $DirectoryEntryCache
                        DirectoryPath       = $DirectoryPath
                        PropertiesToLoad    = $PropertiesToLoad
                    }
                    if ($MemberDomainDn) {
                        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-WinNTGroupMember`t'$MemberName' is a domain security principal"
                        $MemberParams['DirectoryPath'] = "LDAP://$MemberDomainDn"
                        $MemberParams['Filter'] = "(samaccountname=$MemberName)"
                        $MemberDirectoryEntry = Search-Directory @MemberParams
                    } else {
                        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-WinNTGroupMember`t'$DirectoryPath' is a local security principal"
                        $MemberDirectoryEntry = Get-DirectoryEntry @MemberParams
                    }

                    $MemberDirectoryEntry | Expand-WinNTGroupMember -DirectoryEntryCache $DirectoryEntryCache

                }
            } else {
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-WinNTGroupMember`t'$($ThisDirEntry.Path)' is not a group"
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
            $Properties['SchemaClassName'] = 'User'
        }
        'SYSTEM$' {
            $Properties['objectSid'] = 'S-1-5-18' | ConvertTo-SidByteArray
            $Properties['Description'] = 'By default, the SYSTEM account is granted Full Control permissions to all files on an NTFS volume'
            $Properties['Properties'] = @{
                Name        = $Properties['Name']
                Description = $Description
                objectSid   = $SidByteAray
            }
            $Properties['SchemaClassName'] = 'User'
        }
        'INTERACTIVE$' {
            $Properties['objectSid'] = 'S-1-5-4' | ConvertTo-SidByteArray
            $Properties['Description'] = 'Users who log on for interactive operation. This is a group identifier added to the token of a process when it was logged on interactively.'
            $Properties['Properties'] = @{
                Name        = $Properties['Name']
                Description = $Description
                objectSid   = $SidByteAray
            }
            $Properties['SchemaClassName'] = 'Group'
        }
        'Authenticated Users$' {
            $Properties['objectSid'] = 'S-1-5-11' | ConvertTo-SidByteArray
            $Properties['Description'] = 'Any user who accesses the system through a sign-in process has the Authenticated Users identity.'
            $Properties['Properties'] = @{
                Name        = $Properties['Name']
                Description = $Description
                objectSid   = $SidByteAray
            }
            $Properties['SchemaClassName'] = 'Group'
        }
        'TrustedInstaller$' {
            $Properties['objectSid'] = 'S-1-5-11' | ConvertTo-SidByteArray
            $Properties['Description'] = 'Most of the operating system files are owned by the TrustedInstaller security identifier (SID)'
            $Properties['Properties'] = @{
                Name        = $Properties['Name']
                Description = $Description
                objectSid   = $SidByteAray
            }
            $Properties['SchemaClassName'] = 'User'
        }
    }

    $DirectoryEntry = [pscustomobject]::new($Properties)
    $DirectoryEntry | Add-Member -MemberType ScriptMethod -Name RefreshCache -Force -Value {}
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
            Get-TrustedDomainSidNameMap
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

        # Dictionary to cache known servers to avoid redundant lookups
        # Defaults to an empty thread-safe hashtable
        [hashtable]$KnownServers = [hashtable]::Synchronized(@{}),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        [hashtable]$Win32AccountsBySID = ([hashtable]::Synchronized(@{})),

        [hashtable]$Win32AccountsByCaption = ([hashtable]::Synchronized(@{}))

    )

    process {

        $ACEPropertyNames = (Get-Member -InputObject $InputObject[0] -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name
        ForEach ($ThisACE in $InputObject) {

            # Remove the PsProvider prefix from the path string
            if (-not [string]::IsNullOrEmpty($ThisACE.SourceAccessList.Path)) {
                $LiteralPath = $ThisACE.SourceAccessList.Path -replace [regex]::escape("$($ThisACE.SourceAccessList.PsProvider)::"), ''
            } else {
                $LiteralPath = $LiteralPath -replace [regex]::escape("$($ThisACE.SourceAccessList.PsProvider)::"), ''
            }

            $ThisServer = Find-ServerNameInPath -LiteralPath $LiteralPath
            $AdsiServer = Get-AdsiServer -AdsiServer $ThisServer -KnownServers $KnownServers
            $ResolvedIdentityReference = Resolve-IdentityReference -IdentityReference $ThisACE.IdentityReference -ServerName $ThisServer -AdsiServer $AdsiServer -Win32AccountsBySID $Win32AccountsBySID -Win32AccountsByCaption $Win32AccountsByCaption -DirectoryEntryCache $DirectoryEntryCache
            $FullyResolved = $ResolvedIdentityReference.UnresolvedIdentityReference -replace
            'NT AUTHORITY', $ThisServer -replace
            'NT SERVICE', $ThisServer -replace
            'BUILTIN', $ThisServer

            $ObjectProperties = @{
                AdsiProvider              = $AdsiServer.AdsiProvider
                AdsiServer                = $ThisServer
                IdentityReferenceSID      = $ResolvedIdentityReference.SIDString
                IdentityReferenceName     = $ResolvedIdentityReference.UnresolvedIdentityReference
                IdentityReferenceResolved = $FullyResolved
            }
            ForEach ($ThisProperty in $ACEPropertyNames) {
                $ObjectProperties[$ThisProperty] = $ThisACE.$ThisProperty
            }
            [PSCustomObject]$ObjectProperties

        }

    }

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
        Resolve-IdentityReference -IdentityReference 'BUILTIN\Administrator' -ServerName 'localhost' -AdsiServer (Get-AdsiServer 'localhost')

        Get information about the local Administrator account
    #>
    [OutputType([PSCustomObject])]
    param (
        # IdentityReference from an Access Control Entry
        # Expecting either a SID (S-1-5-18) or an NT account name (CONTOSO\User)
        [string]$IdentityReference,

        # Name of the directory server to use to resolve the IdentityReference
        [string]$ServerName,

        # Object from Get-AdsiServer representing the directory server and its attributes
        [PSObject]$AdsiServer,

        [hashtable]$KnownDomains = [hashtable]::Synchronized(@{}),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        [hashtable]$Win32AccountsBySID = ([hashtable]::Synchronized(@{})),

        [hashtable]$Win32AccountsByCaption = ([hashtable]::Synchronized(@{}))
    )

    $ThisHostName = hostname

    $CacheResult = $Win32AccountsBySID["$ServerName\$IdentityReference"]
    if ($CacheResult) {
        #IdentityReference is a SID, and has been cached from this server
        return [PSCustomObject]@{
            SIDString                   = $CacheResult.SID
            UnresolvedIdentityReference = $CacheResult.Caption # This is actually resolved but good enough for now maybe? Can parse SID to get the unresolved format
        }
    }
    $CacheResult = $Win32AccountsByCaption["$ServerName\$IdentityReference"]
    if ($CacheResult) {
        # IdentityReference is an NT Account Name, and has been cached from this server
        return [PSCustomObject]@{
            SIDString                   = $CacheResult.SID
            UnresolvedIdentityReference = $IdentityReference
        }
    }

    switch -Wildcard ($IdentityReference) {
        "S-1-*" {
            # IdentityReference is a SID

            # Constricted a SecurityIdentifier object based on the SID
            Write-Debug "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t[System.Security.Principal.SecurityIdentifier]::new('$IdentityReference')"
            $SecurityIdentifier = [System.Security.Principal.SecurityIdentifier]::new($IdentityReference)

            # Use the SecurityIdentifier.Translate() method to translate the SID to an NT Account name
            # This .Net method makes it impossible to redirect the error stream directly
            # Wrapping it in a scriptblock (which is then executed with &) fixes the problem
            # I don't understand exactly why
            # Anyway UnresolvedIdentityReference will be null if the SID cannot be translated
            Write-Debug "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t[System.Security.Principal.SecurityIdentifier]::new('$IdentityReference').Translate([System.Security.Principal.NTAccount])"
            $UnresolvedIdentityReference = & { $SecurityIdentifier.Translate([System.Security.Principal.NTAccount]).Value } 2>$null
            $Win32AccountsBySID["$ServerName\$IdentityReference"] = [PSCustomObject]@{
                SID     = $IdentityReference
                Caption = "$ServerName\$UnresolvedIdentityReference"
                Domain  = $ServerName
            }
            return [PSCustomObject]@{
                SIDString                   = $IdentityReference
                UnresolvedIdentityReference = $UnresolvedIdentityReference
            }

        }
        "NT SERVICE\*" {

            $split = $IdentityReference.Split('\')
            $domainNetbiosString = $split[0]
            $Name = $split[1]

            # Some of them are services (yes services can have SIDs, notably this includes TrustedInstaller but it is also common with SQL)
            if ($ServerName -eq $ThisHostName) {
                Write-Debug "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`tsc.exe showsid $Name"
                [string[]]$ScResult = & sc.exe showsid $Name
            } else {
                Write-Debug "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`tInvoke-Command -ComputerName $ServerName -ScriptBlock { & sc.exe showsid `$args[0] } -ArgumentList $Name"
                [string[]]$ScResult = Invoke-Command -ComputerName $ServerName -ScriptBlock { & sc.exe showsid $args[0] } -ArgumentList $Name
            }
            $ScResultProps = @{}

            $ScResult |
            ForEach-Object {
                $Prop, $Value = ($_ -split ':').Trim()
                $ScResultProps[$Prop] = $Value
            }

            $SIDString = $ScResultProps['SERVICE SID']

            $Win32AccountsByCaption["$ServerName\$IdentityReference"] = [PSCustomObject]@{
                SID     = $SIDString
                Caption = "$ServerName\$IdentityReference"
                Domain  = $ServerName
            }

            return [PSCustomObject]@{
                SIDString                   = $SIDString
                UnresolvedIdentityReference = $IdentityReference
            }
        }
        "BUILTIN\*" {
            # Some built-in groups such as BUILTIN\Users and BUILTIN\Administrators are not in the CIM class or translatable with the NTAccount.Translate() method
            # But they may have real DirectoryEntry objects
            # Try to find the DirectoryEntry object locally on the server
            $DirectoryPath = "$($AdsiServer.AdsiProvider)`://$ServerName/$Name"
            $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath -DirectoryEntryCache $DirectoryEntryCache
            $SIDString = (Add-SidInfo -InputObject $DirectoryEntry).SidString

            $Win32AccountsByCaption["$ServerName\$IdentityReference"] = [PSCustomObject]@{
                SID     = $SIDString
                Caption = "$ServerName\$IdentityReference"
                Domain  = $ServerName
            }

            return [PSCustomObject]@{
                UnresolvedIdentityReference = $IdentityReference
                SIDString                   = $SIDString
            }
        }
    }

    # The IdentityReference is an NTAccount
    # Resolve NTAccount to SID
    # Start by determining the domain
    $split = $IdentityReference.Split('\')
    $domainNetbiosString = $split[0]
    $Name = $split[1]

    # Well-Known SIDs cannot be translated with the Translate method so instead we will have used CIM to collect information on well-known SIDs
    $SIDString = $AdsiServer.WellKnownSIDs[$Name].SID
    if (-not $SIDString) {
        if (
            -not $KnownDomains[$domainNetbiosString] -and
            -not [string]::IsNullOrEmpty($domainNetbiosString)
        ) {
            $KnownDomains[$domainNetbiosString] = ConvertTo-DistinguishedName -Domain $domainNetbiosString
            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tResolve-IdentityReference`tCache miss for domain $($domainNetbiosString).  Adding its Distinguished Name to dictionary of known domains for future lookup"
        }

        $DomainDn = $KnownDomains[$domainNetbiosString]
        $DomainFqdn = ConvertTo-Fqdn -DistinguishedName $DomainDn

        # Try to resolve the account locally against the server it came from (which may or may not be the correct ADSI server for the account)
        Write-Debug "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t[System.Security.Principal.NTAccount]::new('$ServerName','$Name')"
        $NTAccount = [System.Security.Principal.NTAccount]::new($ServerName, $Name)
        Write-Debug "  $(Get-Date -Format s)`t$ThisHostName`tResolve-IdentityReference`t[System.Security.Principal.NTAccount]::new('$ServerName','$Name').Translate([System.Security.Principal.SecurityIdentifier])"
        $SIDString = & { $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]) } 2>$null

        if (-not $SIDString) {
            # Try to resolve the account against the domain indicated in its NT Account Name
            # Add this domain to our list of known domains

            try {
                $SearchPath = "LDAP://$DomainDn" | Add-DomainFqdnToLdapPath
                $DirectoryEntry = Search-Directory -DirectoryEntryCache $DirectoryEntryCache -DirectoryPath $SearchPath -Filter "(samaccountname=$Name)" -PropertiesToLoad @('objectClass', 'distinguishedName', 'name', 'grouptype', 'description', 'managedby', 'member', 'objectClass', 'Department', 'Title')
                $SIDString = (Add-SidInfo -InputObject $DirectoryEntry).SidString
            } catch {
                Write-Warning "$(Get-Date -Format s)`t$(hostname)`tResolve-IdentityReference`t$($StartingIdentityName) could not be resolved against its directory"
                Write-Warning "$(Get-Date -Format s)`t$(hostname)`tResolve-IdentityReference`t$($_.Exception.Message)"
            }

            if (-not $SIDString) {

                # Try to find the DirectoryEntry object directly on the server
                $DirectoryPath = "$($AdsiServer.AdsiProvider)`://$ServerName/$Name"
                $DirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath -DirectoryEntryCache $DirectoryEntryCache
                $SIDString = (Add-SidInfo -InputObject $DirectoryEntry).SidString

            }
        }
    }

    return [PSCustomObject]@{
        UnresolvedIdentityReference = $IdentityReference
        SIDString                   = $SIDString
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
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{}))

    )

    $ThisHostName = HOSTNAME.EXE

    $DirectoryEntryParameters = @{
        DirectoryEntryCache = $DirectoryEntryCache
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

    Write-Debug "  $(Get-Date -Format s)`t$ThisHostName`tSearch-Directory`t[System.DirectoryServices.DirectorySearcher]::new(([System.DirectoryServices.DirectoryEntry]::new('$DirectoryPath)'))"
    $DirectorySearcher = [System.DirectoryServices.DirectorySearcher]::new($DirectoryEntry)

    if ($Filter) {
        $DirectorySearcher.Filter = $Filter
    }

    $DirectorySearcher.PageSize = $PageSize
    $DirectorySearcher.SearchScope = $SearchScope

    ForEach ($Property in $PropertiesToLoad) {
        $null = $DirectorySearcher.PropertiesToLoad.Add($Property)
    }

    Write-Debug "  $(Get-Date -Format s)`t$ThisHostName`tSearch-Directory`t[System.DirectoryServices.DirectorySearcher]::new(([System.DirectoryServices.DirectoryEntry]::new('$DirectoryPath)')).FindAll()"
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
Export-ModuleMember -Function @('Add-DomainFqdnToLdapPath','Add-SidInfo','Add-Win32AccountToCache','ConvertFrom-DirectoryEntry','ConvertFrom-PropertyValueCollectionToString','ConvertTo-DecStringRepresentation','ConvertTo-DistinguishedName','ConvertTo-Fqdn','ConvertTo-HexStringRepresentation','ConvertTo-HexStringRepresentationForLDAPFilterString','ConvertTo-SidByteArray','Expand-AdsiGroupMember','Expand-IdentityReference','Expand-WinNTGroupMember','Find-AdsiProvider','Get-AdsiGroup','Get-AdsiGroupMember','Get-AdsiServer','Get-CurrentDomain','Get-DirectoryEntry','Get-TrustedDomainSidNameMap','Get-WellKnownSid','Get-WinNTGroupMember','Invoke-ComObject','New-FakeDirectoryEntry','Resolve-Ace','Resolve-IdentityReference','Search-Directory')








