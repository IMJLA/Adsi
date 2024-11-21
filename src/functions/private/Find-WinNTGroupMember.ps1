function Find-WinNTGroupMember {

    # Find LDAP and WinNT group members to retrieve from their directories.
    # Convert COM objects from the IADsGroup::Members method into strings.
    # Use contextual information to determine whether each string represents an LDAP or a WinNT group member.

    param (

        # DirectoryEntry [System.DirectoryServices.DirectoryEntry] of the WinNT group whose members to get
        $DirectoryEntry,

        # COM Objects representing the DirectoryPaths of the group members
        $ComObject,

        [hashtable]$Out,

        [string]$LogSuffix,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache,

        $GroupDomain,

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug'

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
        } else {

            Write-LogMsg @Log -Text " # '$MemberDomainNetbios' may or may not be a workgroup computer (inconclusive) $MemberLogSuffix $LogSuffix"
            $DomainCacheResult = $null
            $TryGetValueResult = $Cache.Value['DomainByNetbios'].Value.TryGetValue($MemberDomainNetbios, [ref]$DomainCacheResult)

            if ($TryGetValueResult) {

                #Write-LogMsg @Log -Text " # Domain NetBIOS cache hit for '$MemberDomainNetBios' $MemberLogSuffix $LogSuffix"

                if ($DomainCacheResult.AdsiProvider -eq 'LDAP') {

                    Write-LogMsg @Log -Text " # '$MemberDomainNetbios' is an LDAP server $MemberLogSuffix $LogSuffix"
                    $MemberDomainDn = $DomainCacheResult.DistinguishedName

                }

            } else {

                #Write-LogMsg @Log -Text " # Domain NetBIOS cache miss for '$MemberDomainNetBios' $MemberLogSuffix $LogSuffix"

                if ( $MemberDomainNetbios -ne $GroupDomain.Dns -and $MemberDomainNetbios -ne $GroupDomain.NetBIOS ) {

                    Write-LogMsg @Log -Text " # member domain is different from the group domain (LDAP member of WinNT group or LDAP member of LDAP group in a trusted domain) for domain NetBIOS '$MemberDomainNetbios' $MemberLogSuffix $LogSuffix"
                    $MemberDomainDn = ConvertTo-DistinguishedName -Domain $MemberDomainNetbios -AdsiProvider 'LDAP' -Cache $Cache -ThisHostName $ThisHostname -ThisFqdn $ThisFqdn -WhoAmI $WhoAmI -DebugOutputStream $DebugOutputStream

                } else {

                    Write-LogMsg @Log -Text " # member domain is the same as the group domain (either LDAP member of LDAP group or WinNT member of WinNT group) for domain '$MemberDomainNetbios' $MemberLogSuffix $LogSuffix"
                    $AdsiServer = Get-AdsiServer -Netbios $MemberDomainNetbios -Cache $Cache -ThisHostName $ThisHostname -ThisFqdn $ThisFqdn -WhoAmI $WhoAmI -DebugOutputStream $DebugOutputStream

                    if ($AdsiServer) {

                        if ($AdsiServer.AdsiProvider -eq 'LDAP') {

                            Write-LogMsg @Log -Text " # ADSI provider is LDAP for domain NetBIOS '$MemberDomainNetbios' $MemberLogSuffix $LogSuffix"
                            $MemberDomainDn = $AdsiServer.DistinguishedName

                        } elseif ($AdsiServer.AdsiProvider -eq 'WinNT') {
                            Write-LogMsg @Log -Text " # ADSI provider is WinNT for domain NetBIOS '$MemberDomainNetbios' $MemberLogSuffix $LogSuffix"
                        } else {

                            $Log['Type'] = 'Warning'
                            Write-LogMsg @Log -Text " # ADSI provider could not be found # for domain NetBIOS so WinNT will be assumed # for ADSI server '$MemberDomainNetbios' $MemberLogSuffix $LogSuffix"

                        }

                    } else {

                        $Log['Type'] = 'Warning'
                        Write-LogMsg @Log -Text " # ADSI server could not be found # for domain NetBIOS so WinNT will be assumed '$MemberDomainNetbios' $MemberLogSuffix $LogSuffix"

                    }

                }

            }

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
