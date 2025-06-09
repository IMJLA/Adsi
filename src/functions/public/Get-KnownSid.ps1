function Get-KnownSid {

    <#
    .SYNOPSIS
    Retrieves information about well-known security identifiers (SIDs).

    .DESCRIPTION
    Gets information about well-known security identifiers (SIDs) based on patterns and common formats.
    Uses Microsoft documentation references for SID information:
    - https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/81d92bba-d22b-4a8c-908a-554ab29148ab
    - https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-identifiers

    .INPUTS
    System.String

    A SID string that identifies a well-known security principal.

    .OUTPUTS
    PSCustomObject with properties such as Description, DisplayName, Name, NTAccount, SamAccountName, SchemaClassName, and SID.

    .EXAMPLE
    Get-KnownSid -SID 'S-1-5-32-544'

    Returns information about the built-in Administrators group.

    .EXAMPLE
    Get-KnownSid -SID 'S-1-5-18'

    Returns information about the Local System account.
    #>

    param (

        # Security Identifier (SID) string to retrieve information for
        [string]$SID

    )

    $StartingPatterns = @{

        'S-1-5-80-' = {
            [PSCustomObject]@{
                'Description'     = "Service $SID"
                'DisplayName'     = $SID
                'SamAccountName'  = $SID
                'Name'            = $SID
                'NTAccount'       = "NT SERVICE\$SID"
                'SchemaClassName' = 'service'
                'SID'             = $SID
            }
        }

        'S-1-15-2-' = {
            [PSCustomObject]@{
                'Description'     = "App Container $SID"
                'DisplayName'     = $SID
                'SamAccountName'  = $SID
                'Name'            = $SID
                'NTAccount'       = "APPLICATION PACKAGE AUTHORITY\$SID"
                'SchemaClassName' = 'user'
                'SID'             = $SID
            }
        }

        'S-1-15-3-' = {
            ConvertFrom-AppCapabilitySid -SID $SID
        }

        'S-1-5-32-' = {
            [PSCustomObject]@{
                'Description'     = "BuiltIn $SID"
                'DisplayName'     = $SID
                'SamAccountName'  = $SID
                'Name'            = $SID
                'NTAccount'       = "BUILTIN\$SID"
                'SchemaClassName' = 'user'
                'SID'             = $SID
            }
        }

    }

    #if ($SID.Length -lt 9) { Pause } # This should not happen; any such SIDs should have ben found first by Find-CachedWellKnownSid. Pausing for now for debug. ToDo: make this more robust based on dynamic string length detection after it stops highlighting my issues with Find-CachedWellKnownSid.
    $TheNine = $SID.Substring(0, 9)
    $Match = $StartingPatterns[$TheNine]

    if ($Match) {
        $result = Invoke-Command -ScriptBlock $Match
        return $result
    }

    switch -Wildcard ($SID) {

        'S-1-5-*-500' {
            return [PSCustomObject]@{
                'Description'     = "A built-in user account for the system administrator to administer the computer/domain. Every computer has a local Administrator account and every domain has a domain Administrator account. The Administrator account is the first account created during operating system installation. The account can't be deleted, disabled, or locked out, but it can be renamed. By default, the Administrator account is a member of the Administrators group, and it can't be removed from that group."
                'DisplayName'     = 'Administrator'
                'SamAccountName'  = 'Administrator'
                'Name'            = 'Administrator'
                'NTAccount'       = 'BUILTIN\Administrator'
                'SchemaClassName' = 'user'
                'SID'             = $SID
            }
        }

        'S-1-5-*-501' {
            return [PSCustomObject]@{
                'Description'     = "A user account for people who don't have individual accounts. Every computer has a local Guest account, and every domain has a domain Guest account. By default, Guest is a member of the Everyone and the Guests groups. The domain Guest account is also a member of the Domain Guests and Domain Users groups. Unlike Anonymous Logon, Guest is a real account, and it can be used to sign in interactively. The Guest account doesn't require a password, but it can have one."
                'DisplayName'     = 'Guest'
                'SamAccountName'  = 'Guest'
                'Name'            = 'Guest'
                'NTAccount'       = 'BUILTIN\Guest'
                'SchemaClassName' = 'user'
                'SID'             = $SID
            }
        }

        'S-1-5-*-502' {
            return [PSCustomObject]@{
                'Description'     = "Kerberos Ticket-Generating Ticket account: a user account that's used by the Key Distribution Center (KDC) service. The account exists only on domain controllers."
                'DisplayName'     = 'KRBTGT'
                'SamAccountName'  = 'KRBTGT'
                'Name'            = 'KRBTGT'
                'NTAccount'       = 'BUILTIN\KRBTGT'
                'SchemaClassName' = 'user'
                'SID'             = $SID
            }
        }

        'S-1-5-*-512' {
            return [PSCustomObject]@{
                'Description'     = "A global group with members that are authorized to administer the domain. By default, the Domain Admins group is a member of the Administrators group on all computers that have joined the domain, including domain controllers. Domain Admins is the default owner of any object that's created in the domain's Active Directory by any member of the group. If members of the group create other objects, such as files, the default owner is the Administrators group."
                'DisplayName'     = 'Domain Admins'
                'SamAccountName'  = 'Domain Admins'
                'Name'            = 'Domain Admins'
                'NTAccount'       = 'BUILTIN\Domain Admins'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-513' {
            return [PSCustomObject]@{
                'Description'     = 'A global group that includes all users in a domain. When you create a new User object in Active Directory, the user is automatically added to this group.'
                'DisplayName'     = 'Domain Users'
                'SamAccountName'  = 'Domain Users'
                'Name'            = 'Domain Users'
                'NTAccount'       = 'BUILTIN\Domain Users'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-514' {
            return [PSCustomObject]@{
                'Description'     = "A global group that, by default, has only one member: the domain's built-in Guest account."
                'DisplayName'     = 'Domain Guests'
                'SamAccountName'  = 'Domain Guests'
                'Name'            = 'Domain Guests'
                'NTAccount'       = 'BUILTIN\Domain Guests'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-515' {
            return [PSCustomObject]@{
                'Description'     = 'A global group that includes all computers that have joined the domain, excluding domain controllers.'
                'DisplayName'     = 'Domain Computers'
                'SamAccountName'  = 'Domain Computers'
                'Name'            = 'Domain Computers'
                'NTAccount'       = 'BUILTIN\Domain Computers'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-516' {
            return [PSCustomObject]@{
                'Description'     = 'A global group that includes all domain controllers in the domain. New domain controllers are added to this group automatically.'
                'DisplayName'     = 'Domain Controllers'
                'SamAccountName'  = 'Domain Controllers'
                'Name'            = 'Domain Controllers'
                'NTAccount'       = 'BUILTIN\Domain Controllers'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-517' {
            return [PSCustomObject]@{
                'Description'     = 'A global group that includes all computers that host an enterprise certification authority. Cert Publishers are authorized to publish certificates for User objects in Active Directory.'
                'DisplayName'     = 'Cert Publishers'
                'SamAccountName'  = 'Cert Publishers'
                'Name'            = 'Cert Publishers'
                'NTAccount'       = 'BUILTIN\Cert Publishers'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-518' {
            return [PSCustomObject]@{
                'Description'     = "A group that exists only in the forest root domain. It's a universal group if the domain is in native mode, and it's a global group if the domain is in mixed mode. The Schema Admins group is authorized to make schema changes in Active Directory. By default, the only member of the group is the Administrator account for the forest root domain."
                'DisplayName'     = 'Schema Admins'
                'SamAccountName'  = 'Schema Admins'
                'Name'            = 'Schema Admins'
                'NTAccount'       = 'BUILTIN\Schema Admins'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-519' {
            return [PSCustomObject]@{
                'Description'     = "A group that exists only in the forest root domain. It's a universal group if the domain is in native mode, and it's a global group if the domain is in mixed mode. The Enterprise Admins group is authorized to make changes to the forest infrastructure, such as adding child domains, configuring sites, authorizing DHCP servers, and installing enterprise certification authorities. By default, the only member of Enterprise Admins is the Administrator account for the forest root domain. The group is a default member of every Domain Admins group in the forest."
                'DisplayName'     = 'Enterprise Admins'
                'SamAccountName'  = 'Enterprise Admins'
                'Name'            = 'Enterprise Admins'
                'NTAccount'       = 'BUILTIN\Enterprise Admins'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-520' {
            return [PSCustomObject]@{
                'Description'     = "A global group that's authorized to create new Group Policy Objects in Active Directory. By default, the only member of the group is Administrator. Objects that are created by members of Group Policy Creator Owners are owned by the individual user who creates them. In this way, the Group Policy Creator Owners group is unlike other administrative groups (such as Administrators and Domain Admins). Objects that are created by members of these groups are owned by the group rather than by the individual."
                'DisplayName'     = 'Group Policy Creator Owners'
                'SamAccountName'  = 'Group Policy Creator Owners'
                'Name'            = 'Group Policy Creator Owners'
                'NTAccount'       = 'BUILTIN\Group Policy Creator Owners'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-521' {
            return [PSCustomObject]@{
                'Description'     = 'A global group that includes all read-only domain controllers.'
                'DisplayName'     = 'Read-only Domain Controllers'
                'SamAccountName'  = 'Read-only Domain Controllers'
                'Name'            = 'Read-only Domain Controllers'
                'NTAccount'       = 'BUILTIN\Read-only Domain Controllers'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-522' {
            return [PSCustomObject]@{
                'Description'     = 'A global group that includes all domain controllers in the domain that can be cloned.'
                'DisplayName'     = 'Clonable Controllers'
                'SamAccountName'  = 'Clonable Controllers'
                'Name'            = 'Clonable Controllers'
                'NTAccount'       = 'BUILTIN\Clonable Controllers'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-525' {
            return [PSCustomObject]@{
                'Description'     = 'A global group that is afforded additional protections against authentication security threats.'
                'DisplayName'     = 'Protected Users'
                'SamAccountName'  = 'Protected Users'
                'Name'            = 'Protected Users'
                'NTAccount'       = 'BUILTIN\Protected Users'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-526' {
            return [PSCustomObject]@{
                'Description'     = 'This group is intended for use in scenarios where trusted external authorities are responsible for modifying this attribute. Only trusted administrators should be made a member of this group.'
                'DisplayName'     = 'Key Admins'
                'SamAccountName'  = 'Key Admins'
                'Name'            = 'Key Admins'
                'NTAccount'       = 'BUILTIN\Key Admins'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-527' {
            return [PSCustomObject]@{
                'Description'     = 'This group is intended for use in scenarios where trusted external authorities are responsible for modifying this attribute. Only trusted enterprise administrators should be made a member of this group.'
                'DisplayName'     = 'Enterprise Key Admins'
                'SamAccountName'  = 'Enterprise Key Admins'
                'Name'            = 'Enterprise Key Admins'
                'NTAccount'       = 'BUILTIN\Enterprise Key Admins'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-553' {
            return [PSCustomObject]@{
                'Description'     = 'A local domain group. By default, this group has no members. Computers that are running the Routing and Remote Access service are added to the group automatically. Members have access to certain properties of User objects, such as Read Account Restrictions, Read Logon Information, and Read Remote Access Information.'
                'DisplayName'     = 'RAS and IAS Servers'
                'SamAccountName'  = 'RAS and IAS Servers'
                'Name'            = 'RAS and IAS Servers'
                'NTAccount'       = 'BUILTIN\RAS and IAS Servers'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-571' {
            return [PSCustomObject]@{
                'Description'     = 'Members in this group can have their passwords replicated to all read-only domain controllers in the domain.'
                'DisplayName'     = 'Allowed RODC Password Replication Group'
                'SamAccountName'  = 'Allowed RODC Password Replication Group'
                'Name'            = 'Allowed RODC Password Replication Group'
                'NTAccount'       = 'BUILTIN\Allowed RODC Password Replication Group'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        'S-1-5-*-572' {
            return [PSCustomObject]@{
                'Description'     = "Members in this group can't have their passwords replicated to all read-only domain controllers in the domain."
                'DisplayName'     = 'Denied RODC Password Replication Group'
                'SamAccountName'  = 'Denied RODC Password Replication Group'
                'Name'            = 'Denied RODC Password Replication Group'
                'NTAccount'       = 'BUILTIN\Denied RODC Password Replication Group'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }

        default { break }

    }

    if ($SID -match 'S-1-5-5-(?<Session>[^-]-[^-])') {

        return [PSCustomObject]@{
            'Description'     = "Sign-in session $($Matches.Session) (SECURITY_LOGON_IDS_RID)"
            'DisplayName'     = 'Logon Session'
            'Name'            = 'Logon Session'
            'NTAccount'       = 'BUILTIN\Logon Session'
            'SamAccountName'  = 'Logon Session'
            'SchemaClassName' = 'user'
            'SID'             = $SID
        }

    }

}


<#
COMPUTER-SPECIFIC SIDs

            AccountAdministratorSid                             28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-500
            AccountGuestSid                                     28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-501
            AccountKrbtgtSid                                    28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-502
            AccountDomainAdminsSid                              28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-512
            AccountDomainUsersSid                               28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-513
            AccountDomainGuestsSid                              28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-514
            AccountComputersSid                                 28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-515
            AccountControllersSid                               28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-516
            AccountCertAdminsSid                                28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-517
            AccountSchemaAdminsSid                              28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-518
            AccountEnterpriseAdminsSid                          28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-519
            AccountPolicyAdminsSid                              28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-520
            AccountRasAndIasServersSid                          28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-553
            WinCacheablePrincipalsGroupSid                       28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-571
            WinNonCacheablePrincipalsGroupSid                    28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-572
            WinAccountReadonlyControllersSid                     28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-521
            WinNewEnterpriseReadonlyControllersSid               28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-498

        'S-1-5-21-1340649458-2707494813-4121304102-1000'                 = @{
            'Name'        = 'WinRMRemoteWMIUsers__'
            'Description' = 'Members can access WMI resources over management protocols (such as WS-Management via the Windows Remote Management service). This applies only to WMI namespaces
            that grant access to the user.'
            'SID'         = 'S-1-5-21-1340649458-2707494813-4121304102-1000'
        }

        'S-1-5-21-1340649458-2707494813-4121304102-1001'                 = @{
            'Name'        = 'FirstAccountCreatedEndsIn1001'
            'Description' = ''
            'SID'         = 'S-1-5-21-1340649458-2707494813-4121304102-1001'
        }

        'S-1-5-21-1340649458-2707494813-4121304102-1003'                 = @{
            'Name'        = 'GuestAccount'
            'Description' = ''
            'SID'         = 'S-1-5-21-1340649458-2707494813-4121304102-1003'
        }

        'S-1-5-21-1340649458-2707494813-4121304102-500'                  = @{
            'Name'        = 'Administrator'
            'Description' = 'Built-in account for administering the computer/domain'
            'SID'         = 'S-1-5-21-1340649458-2707494813-4121304102-500'
        }

        'S-1-5-21-1340649458-2707494813-4121304102-501'                  = @{
            'Name'        = 'Guest'
            'Description' = 'Built-in account for guest access to the computer/domain'
            'SID'         = 'S-1-5-21-1340649458-2707494813-4121304102-501'
        }

        'S-1-5-21-1340649458-2707494813-4121304102-503'                  = @{
            'Name'        = 'DefaultAccount'
            'Description' = 'A user account managed by the system.'
            'SID'         = 'S-1-5-21-1340649458-2707494813-4121304102-503'
        }

        'S-1-5-21-1340649458-2707494813-4121304102-504'                  = @{
            'Name'        = 'WDAGUtilityAccount'
            'Description' = 'A user account managed and used by the system for Windows Defender Application Guard scenarios.'
            'SID'         = 'S-1-5-21-1340649458-2707494813-4121304102-504'
        }
#>


<#
            # Additional ways to find accounts
            PS C:\Users\Owner> wmic SYSACCOUNT get name,sid
                Name                           SID
                Everyone                       S-1-1-0
                LOCAL                          S-1-2-0
                CREATOR OWNER                  S-1-3-0
                CREATOR GROUP                  S-1-3-1
                CREATOR OWNER SERVER           S-1-3-2
                CREATOR GROUP SERVER           S-1-3-3
                OWNER RIGHTS                   S-1-3-4
                DIALUP                         S-1-5-1
                NETWORK                        S-1-5-2
                BATCH                          S-1-5-3
                INTERACTIVE                    S-1-5-4
                SERVICE                        S-1-5-6
                ANONYMOUS LOGON                S-1-5-7
                PROXY                          S-1-5-8
                SYSTEM                         S-1-5-18
                ENTERPRISE DOMAIN CONTROLLERS  S-1-5-9
                SELF                           S-1-5-10
                Authenticated Users            S-1-5-11
                RESTRICTED                     S-1-5-12
                TERMINAL SERVER USER           S-1-5-13
                REMOTE INTERACTIVE LOGON       S-1-5-14
                IUSR                           S-1-5-17
                LOCAL SERVICE                  S-1-5-19
                NETWORK SERVICE                S-1-5-20
                BUILTIN                        S-1-5-32

            PS C:\Users\Owner> $logonDomainSid = 'S-1-5-21-1340649458-2707494813-4121304102'
            PS C:\Users\Owner> ForEach ($SidType in [System.Security.Principal.WellKnownSidType].GetEnumNames()) {$var = [System.Security.Principal.WellKnownSidType]::$SidType; [System.Security.Principal.SecurityIdentifier]::new($var,$LogonDomainSid) |Add-Member -PassThru -NotePropertyMembers @{'WellKnownSidType' = $SidType}}

            #>