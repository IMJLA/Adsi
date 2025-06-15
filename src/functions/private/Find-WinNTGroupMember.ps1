function Find-WinNTGroupMember {

    <#
    .SYNOPSIS
        Finds and categorizes LDAP and WinNT group members from a WinNT group's COM objects.

    .DESCRIPTION
        The Find-WinNTGroupMember function processes COM objects from the IADsGroup::Members method
        to identify and categorize group members. It converts COM objects into directory paths and
        uses contextual information to determine whether each member represents an LDAP or WinNT
        group member.

        The function analyzes the ADSI provider for each member's domain and categorizes them
        accordingly:
        - LDAP members are added to domain-specific LDAP queries for efficient batch processing
        - WinNT members are collected for individual WinNT provider access
        - Unknown providers default to WinNT for compatibility

        This categorization allows the calling code to optimize directory queries by grouping
        LDAP members into batch queries while handling WinNT members individually.

    .EXAMPLE
        $out = @{ 'LDAP://domain.com' = @(); 'WinNTMembers' = @() }
        Find-WinNTGroupMember -DirectoryEntry $groupEntry -ComObject $members -Out $out -Cache ([ref]$cache)

        This example processes group members and categorizes them into the output hashtable.

    .EXAMPLE
        $members = $group.Invoke('Members')
        $results = @{}
        Find-WinNTGroupMember -DirectoryEntry $group -ComObject $members -Out $results -LogSuffix 'from local group' -Cache ([ref]$cache)

        This example shows processing members with a custom log suffix for tracking.

    .INPUTS
        System.DirectoryServices.DirectoryEntry
        System.Object (COM Objects)
        System.Collections.Hashtable
        System.String

    .OUTPUTS
        None. The function modifies the passed hashtable reference to categorize members.

    .NOTES
        Author: IMJLA
        This function is part of the ADSI module for Active Directory and WinNT group processing.

        The function handles several scenarios:
        - LDAP domain members are collected into SAM account name queries
        - WinNT local members are stored as resolved directory paths
        - Unknown providers are logged as warnings and treated as WinNT
        - Well-known SID authorities are resolved to computer names

        Performance considerations:
        - Uses caching to reduce repeated ADSI server lookups
        - Groups LDAP queries for batch processing efficiency
        - Resolves SID authorities once per member

    .LINK
        https://IMJLA.github.io/Adsi/docs/en-US/Find-WinNTGroupMember

    .LINK
        Get-AdsiServer

    .LINK
        Split-DirectoryPath
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Find-WinNTGroupMember')]

    param (

        # DirectoryEntry [System.DirectoryServices.DirectoryEntry] of the WinNT group whose members to get
        $DirectoryEntry,

        # COM Objects representing the DirectoryPaths of the group members
        $ComObject,

        # Hashtable to store categorized results with keys for LDAP queries and WinNT members
        [hashtable]$Out,

        # String to append to log messages for context and debugging
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
