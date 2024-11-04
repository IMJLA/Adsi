function Find-WinNTGroupMember {

    # Find LDAP and WinNT group members to retrieve from their directories.
    # Convert COM objects from the IADsGroup::Members method into strings.
    # Use contextual information to determine whether each string represents an LDAP or a WinNT group member.

    param (

        # DirectoryEntry [System.DirectoryServices.DirectoryEntry] of the WinNT group whose members to get
        $DirectoryEntry,

        $ComObject,

        [hashtable]$Out,

        [string]$LogSuffix,

        [hashtable]$Log,

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [ref]$DomainsByNetbios = ([System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()),

        [string]$SourceDomain

    )

    ForEach ($DirectoryMember in $ComObject) {

        # Convert the ComObjects into DirectoryEntry objects.
        $DirectoryPath = Invoke-ComObject -ComObject $DirectoryMember -Property 'ADsPath'

        $MemberLogSuffix = "# For '$DirectoryPath'"
        $MemberDomainDn = $null

        # Split the DirectoryPath into its constituent components.
        $DirectorySplit = Split-DirectoryPath -DirectoryPath $DirectoryPath
        $MemberName = $DirectorySplit['Account']

        # Resolve well-known SID authorities to the name of the computer the DirectoryEntry came from.
        Resolve-SidAuthority -DirectorySplit $DirectorySplit -DirectoryEntry $DirectoryEntry
        $ResolvedDirectoryPath = $DirectorySplit['ResolvedDirectoryPath']
        $MemberDomainNetbios = $DirectorySplit['ResolvedDomain']

        if ($DirectorySplit['ParentDomain'] -eq 'WORKGROUP') {

            Write-LogMsg @Log -Text " # '$MemberDomainNetbios' is a workgroup computer $MemberLogSuffix $LogSuffix"
            $DomainCacheResult = $DomainsByNetbios[$MemberDomainNetbios]

            if ($DomainCacheResult) {

                #Write-LogMsg @Log -Text " # Domain NetBIOS cache hit for '$MemberDomainNetBios' $MemberLogSuffix $LogSuffix"

                if ( $MemberDomainNetbios -ne $SourceDomain ) {

                    Write-LogMsg @Log -Text " # $MemberDomainNetbios -ne $SourceDomain but why does my logic think this means LDAP group member rather than WinNT? $MemberLogSuffix $LogSuffix"
                    $MemberDomainDn = $DomainCacheResult.DistinguishedName

                } else {
                    Write-LogMsg @Log -Text " # $MemberDomainNetbios -eq $SourceDomain but why does my logic think this means WinNT group member rather than LDAP? $MemberLogSuffix $LogSuffix"
                }

            } else {
                #Write-LogMsg @Log -Text " # Domain NetBIOS cache miss for '$MemberDomainNetBios'. Available keys: $($DomainsByNetBios.Keys -join ',') $MemberLogSuffix $LogSuffix"
            }

            if ($DirectorySplit['Domain'] -eq $SourceDomain) {

                Write-LogMsg @Log -Text " # Member's parsed domain $($DirectorySplit['Domain']) equals the group's parsed domain '$SourceDomain' but why does my logic think this means WinNT group member rather than LDAP? $MemberLogSuffix $LogSuffix"
                $MemberDomainDn = $null

            } else {
                Write-LogMsg @Log -Text " # Member's parsed domain $($DirectorySplit['Domain']) does not equal the group's parsed domain '$SourceDomain' but why does my logic think this means LDAP or unconfirmed WinNT group member? $MemberLogSuffix $LogSuffix"
            }

        } else {
            Write-LogMsg @Log -Text " # '$MemberDomainNetbios' may or may not be a workgroup computer (inconclusive) $MemberLogSuffix $LogSuffix"
        }

        # LDAP directories have a distinguishedName
        if ($MemberDomainDn) {

            # LDAP directories support searching
            # Combine all members' samAccountNames into a single search per directory distinguishedName
            # Use a hashtable with the directory path as the key and a string as the definition
            # The string is a partial LDAP filter, just the segments of the LDAP filter for each samAccountName
            Write-LogMsg @Log -Text " # '$MemberName' is a domain security principal $MemberLogSuffix $LogSuffix"
            $Out["LDAP://$MemberDomainDn"] += "(samaccountname=$MemberName)"

        } else {

            # WinNT directories do not support searching so we will retrieve each member individually
            # Use a hashtable with 'WinNTMembers' as the key and an array of WinNT directory paths as the value
            Write-LogMsg @Log -Text " # Is a local security principal $MemberLogSuffix $LogSuffix"
            $Out['WinNTMembers'] += $ResolvedDirectoryPath

        }

    }

}
