function Get-WinNTGroupMember {

    param (

        [Parameter(ValueFromPipeline)]
        $DirectoryEntry,

        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{}))

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
                    # Convert the COM Objects from the WinNT provider to proper [System.DirectoryServices.DirectoryEntry] objects from the LDAP provider
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

                    if ($MemberDomainDn) {
                        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-WinNTGroupMember`t'$MemberName' is a domain security principal"
                        $MemberDirectoryEntry = Search-Directory -DirectoryEntryCache $DirectoryEntryCache -DirectoryPath "LDAP://$MemberDomainDn" -Filter "(samaccountname=$MemberName)" -PropertiesToLoad @('objectClass', 'distinguishedName', 'name', 'grouptype', 'description', 'managedby', 'member', 'objectClass', 'Department', 'Title', 'samAccountName', 'objectSid')
                    } else {
                        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-WinNTGroupMember`t'$DirectoryPath' is a local security principal"
                        $MemberDirectoryEntry = Get-DirectoryEntry -DirectoryPath $DirectoryPath -PropertiesToLoad @('objectClass', 'distinguishedName', 'name', 'grouptype', 'description', 'managedby', 'member', 'objectClass', 'Department', 'Title', 'samAccountName', 'objectSid') -DirectoryEntryCache $DirectoryEntryCache
                    }

                    $MemberDirectoryEntry | Expand-WinNTGroupMember -DirectoryEntryCache $DirectoryEntryCache

                }
            }
        }
    }

}
