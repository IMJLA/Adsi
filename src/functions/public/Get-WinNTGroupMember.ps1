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
        [string[]]$PropertiesToLoad

    )
    begin {

        $KnownDomains = Get-TrustedDomainSidNameMap -DirectoryEntryCache $DirectoryEntryCache -KeyByNetbios

    }
    process {
        ForEach ($ThisDirEntry in $DirectoryEntry) {
            $SourceDomain = $ThisDirEntry.Path | Split-Path -Parent | Split-Path -Leaf
            # Retrieve the members of local groups
            if ($null -ne $ThisDirEntry.Properties['groupType'] -or $ThisDirEntry.schemaclassname -eq 'Group') {
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
                $DirectoryMembers = $ThisDirEntry.Invoke('Members')
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
            }
        }
    }

}
