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

    $Log = @{ ThisHostname = $ThisHostname ; Type = $DebugOutputStream ; Buffer = $Cache.Value['LogBuffer'] ; WhoAmI = $WhoAmI }

    ForEach ($DirectoryMember in $ComObject) {

        # Convert the ComObjects into DirectoryEntry objects.
        $DirectoryPath = Invoke-ComObject -ComObject $DirectoryMember -Property 'ADsPath'

        $Log['Suffix'] = " # for '$DirectoryPath' $LogSuffix"

        # Split the DirectoryPath into its constituent components.
        $DirectorySplit = Split-DirectoryPath -DirectoryPath $DirectoryPath
        $MemberName = $DirectorySplit['Account']

        # Resolve well-known SID authorities to the name of the computer the DirectoryEntry came from.
        Resolve-SidAuthority -DirectorySplit $DirectorySplit -DirectoryEntry $DirectoryEntry
        $ResolvedDirectoryPath = $DirectorySplit['ResolvedDirectoryPath']
        $MemberDomainNetbios = $DirectorySplit['ResolvedDomain']
        Write-LogMsg @Log -Text "Get-AdsiServer -Netbios '$MemberDomainNetbios' -ThisFqdn '$ThisFqdn' -Cache `$Cache -ThisHostName '$ThisHostname' -ThisFqdn '$ThisFqdn' -WhoAmI '$WhoAmI' -DebugOutputStream '$DebugOutputStream'"
        $AdsiServer = Get-AdsiServer -Netbios $MemberDomainNetbios -Cache $Cache -ThisHostName $ThisHostname -ThisFqdn $ThisFqdn -WhoAmI $WhoAmI -DebugOutputStream $DebugOutputStream

        if ($AdsiServer) {

            if ($AdsiServer.AdsiProvider -eq 'LDAP') {

                #Write-LogMsg @Log -Text " # ADSI provider is LDAP for domain NetBIOS '$MemberDomainNetbios'"
                $Out["LDAP://$($AdsiServer.Dns)"] += "(samaccountname=$MemberName)"

            } elseif ($AdsiServer.AdsiProvider -eq 'WinNT') {

                #Write-LogMsg @Log -Text " # ADSI provider is WinNT for domain NetBIOS '$MemberDomainNetbios'"
                $Out['WinNTMembers'] += $ResolvedDirectoryPath

            } else {

                $Log['Type'] = 'Warning'
                Write-LogMsg @Log -Text " # Could not find ADSI provider. WinNT will be assumed # for domain NetBIOS '$MemberDomainNetbios'"
                $Log['Type'] = $DebugOutputStream

            }

        } else {

            $Log['Type'] = 'Warning'
            Write-LogMsg @Log -Text " # Could not find ADSI server to find ADSI provider. WinNT will be assumed # for domain NetBIOS '$MemberDomainNetbios'"
            $Log['Type'] = $DebugOutputStream

        }

    }

}
