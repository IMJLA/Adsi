function Find-WinNTGroupMember {
    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Find-WinNTGroupMember')]

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


        [ref]$Cache

    )

    ForEach ($DirectoryMember in $ComObject) {

        # Convert the ComObjects into DirectoryEntry objects.
        $DirectoryPath = Invoke-ComObject -ComObject $DirectoryMember -Property 'ADsPath'

        $Log = @{ 'Cache' = $Cache ; 'Suffix' = " # for member of WinNT group; member path '$DirectoryPath' $LogSuffix" }

        # Split the DirectoryPath into its constituent components.
        $DirectorySplit = Split-DirectoryPath -DirectoryPath $DirectoryPath
        $MemberName = $DirectorySplit['Account']

        # Resolve well-known SID authorities to the name of the computer the DirectoryEntry came from.
        Resolve-SidAuthority -DirectorySplit $DirectorySplit -DirectoryEntry $DirectoryEntry
        $ResolvedDirectoryPath = $DirectorySplit['ResolvedDirectoryPath']
        $MemberDomainNetbios = $DirectorySplit['ResolvedDomain']
        Write-LogMsg @Log -Text "Get-AdsiServer -Netbios '$MemberDomainNetbios' -Cache `$Cache"
        $AdsiServer = Get-AdsiServer -Netbios $MemberDomainNetbios -Cache $Cache

        if ($AdsiServer) {

            if ($AdsiServer.AdsiProvider -eq 'LDAP') {

                #Write-LogMsg @Log -Text " # ADSI provider is LDAP for domain NetBIOS '$MemberDomainNetbios'"
                $Out["LDAP://$($AdsiServer.Dns)"] += "(samaccountname=$MemberName)"

            } elseif ($AdsiServer.AdsiProvider -eq 'WinNT') {

                #Write-LogMsg @Log -Text " # ADSI provider is WinNT for domain NetBIOS '$MemberDomainNetbios'"
                $Out['WinNTMembers'] += $ResolvedDirectoryPath

            } else {

                $StartingLogType = $Cache.Value['LogType'].Value
                $Cache.Value['LogType'].Value = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
                Write-LogMsg @Log -Text " # Could not find ADSI provider. WinNT will be assumed # for domain NetBIOS '$MemberDomainNetbios'"
                $Cache.Value['LogType'].Value = $StartingLogType

            }

        } else {

            $StartingLogType = $Cache.Value['LogType'].Value
            $Cache.Value['LogType'].Value = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
            Write-LogMsg @Log -Text " # Could not find ADSI server to find ADSI provider. WinNT will be assumed # for domain NetBIOS '$MemberDomainNetbios'"
            $Cache.Value['LogType'].Value = $StartingLogType

        }

    }

}
