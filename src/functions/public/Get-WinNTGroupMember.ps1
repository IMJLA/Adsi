function Get-WinNTGroupMember {

    param (

        [Parameter(ValueFromPipeline)]
        $DirectoryEntry,

        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Properties of the group members to find in the directory
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
        )

    )
    begin {
        #TODO: Default should know at least any trusted domains
        $KnownDomains = Get-TrustedDomainSidNameMap -DirectoryEntryCache $DirectoryEntryCache -KeyByNetbios

    }
    process {
        ForEach ($ThisDirEntry in $DirectoryEntry) {
            $SourceDomain = $ThisDirEntry.Path | Split-Path -Parent | Split-Path -Leaf
            # Retrieve the members of local groups
            if ($null -ne $ThisDirEntry.Properties['groupType']) {
                $DirectoryMembers = $ThisDirEntry.Invoke('Members')
                ForEach ($DirectoryMember in $DirectoryMembers) {
                    # The WinNT provider returns COM objects
                    # The LDAP provider returns [System.DirectoryServices.DirectoryEntry] objects
                    # The DirectoryEntry objects are much easier to work with
                    # So we will convert the COM objects into DirectoryEntry objects
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
