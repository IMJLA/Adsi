function Get-KnownSidHashTable {

    <# Returns a hashtable of known SIDs which can be used to avoid errors and delays due to unnecessary directory queries.
    Some SIDs cannot be translated using the [SecurityIdentifier]::Translate or [NTAccount]::Translate methods.
    Some SIDs cannot be retrieved using CIM or ADSI.
    Hardcoding them here allows avoiding queries that we know will fail.
    Hardcoding them also improves performance by avoiding unnecessary directory queries with predictable results.
    https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/11e1608c-6169-4fbc-9c33-373fc9b224f4#Appendix_A_34
    https://learn.microsoft.com/en-us/windows/win32/secauthz/well-known-sids
    #>

    return @{

        #https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-identifiers
        'S-1-0-0'                                                                                              = [PSCustomObject]@{
            'Description'     = "A group with no members. This is often used when a SID value isn't known (WellKnownSidType NullSid)"
            'DisplayName'     = 'Null SID'
            'Name'            = 'Null SID'
            'NTAccount'       = 'NULL SID AUTHORITY\NULL'
            'SamAccountName'  = 'NULL'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-0-0'
        }

        'S-1-1-0'                                                                                              = [PSCustomObject]@{
            'Description'     = "A group that includes all users; aka 'World' (WellKnownSidType WorldSid)"
            'DisplayName'     = 'Everyone'
            'Name'            = 'Everyone'
            'NTAccount'       = 'WORLD SID AUTHORITY\Everyone'
            'SamAccountName'  = 'Everyone'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-1-0'
        }

        'S-1-2-1'                                                                                              = [PSCustomObject]@{
            'Description'     = 'A group that includes users who are signed in to the physical console (WellKnownSidType WinConsoleLogonSid)'
            'DisplayName'     = 'Console Logon'
            'Name'            = 'Console Logon'
            'NTAccount'       = 'LOCAL SID AUTHORITY\CONSOLE_LOGON'
            'SamAccountName'  = 'CONSOLE_LOGON'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-2-1'
        }

        'S-1-3-0'                                                                                              = [PSCustomObject]@{
            'Description'     = 'A security identifier to be replaced by the SID of the user who creates a new object. This SID is used in inheritable access control entries (WellKnownSidType CreatorOwnerSid)'
            'DisplayName'     = 'Creator Owner ID'
            'Name'            = 'Creator Owner'
            'NTAccount'       = 'CREATOR SID AUTHORITY\CREATOR OWNER'
            'SamAccountName'  = 'CREATOR OWNER'
            'SchemaClassName' = 'user'
            'SID'             = 'S-1-3-0'
        }

        'S-1-4'                                                                                                = [PSCustomObject]@{
            'Description'     = 'A SID that represents an identifier authority which is not unique'
            'DisplayName'     = 'Non-unique Authority'
            'Name'            = 'Non-unique Authority'
            'NTAccount'       = 'Non-unique Authority'
            'SamAccountName'  = 'Non-unique Authority'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-4'
        }

        'S-1-5'                                                                                                = [PSCustomObject]@{
            'Description'     = "Identifier authority which produces SIDs that aren't universal and are meaningful only in installations of the Windows operating systems in the 'Applies to' list at the beginning of this article (WellKnownSidType NTAuthoritySid) (SID constant SECURITY_NT_AUTHORITY)"
            'DisplayName'     = 'NT Authority'
            'Name'            = 'NT AUTHORITY'
            'NTAccount'       = 'NT AUTHORITY'
            'SamAccountName'  = 'NT Authority'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-5'
        }

        'S-1-5-1'                                                                                              = [PSCustomObject]@{
            'Description'     = 'A group that includes all users who are signed in to the system via dial-up connection (WellKnownSidType DialupSid) (SID constant SECURITY_DIALUP_RID)'
            'DisplayName'     = 'Dialup'
            'Name'            = 'DIALUP'
            'NTAccount'       = 'NT AUTHORITY\DIALUP'
            'SamAccountName'  = 'DIALUP'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-5-1'
        }

        'S-1-5-2'                                                                                              = [PSCustomObject]@{
            'Description'     = "A group that includes all users who are signed in via a network connection. Access tokens for interactive users don't contain the Network SID (WellKnownSidType NetworkSid) (SID constant SECURITY_NETWORK_RID)"
            'DisplayName'     = 'Network'
            'Name'            = 'NETWORK'
            'NTAccount'       = 'NT AUTHORITY\NETWORK'
            'SamAccountName'  = 'NETWORK'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-2'
        }

        'S-1-5-3'                                                                                              = [PSCustomObject]@{
            'Description'     = 'A group that includes all users who have signed in via batch queue facility, such as task scheduler jobs (WellKnownSidType BatchSid) (SID constant SECURITY_BATCH_RID)'
            'DisplayName'     = 'Batch'
            'Name'            = 'BATCH'
            'NTAccount'       = 'NT AUTHORITY\BATCH'
            'SamAccountName'  = 'BATCH'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-3'
        }

        'S-1-5-4'                                                                                              = [PSCustomObject]@{
            'Description'     = "Users who log on for interactive operation. This is a group identifier added to the token of a process when it was logged on interactively. A group that includes all users who sign in interactively. A user can start an interactive sign-in session by opening a Remote Desktop Services connection from a remote computer, or by using a remote shell such as Telnet. In each case, the user's access token contains the Interactive SID. If the user signs in by using a Remote Desktop Services connection, the user's access token also contains the Remote Interactive Logon SID (WellKnownSidType InteractiveSid) (SID constant SECURITY_INTERACTIVE_RID)"
            'DisplayName'     = 'Interactive'
            'Name'            = 'INTERACTIVE'
            'NTAccount'       = 'NT AUTHORITY\INTERACTIVE'
            'SamAccountName'  = 'INTERACTIVE'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-4'
        }

        'S-1-5-6'                                                                                              = [PSCustomObject]@{
            'Description'     = 'A group that includes all security principals that have signed in as a service (WellKnownSidType ServiceSid) (SID constant SECURITY_SERVICE_RID)'
            'DisplayName'     = 'Service'
            'Name'            = 'SERVICE'
            'NTAccount'       = 'NT AUTHORITY\SERVICE'
            'SamAccountName'  = 'SERVICE'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-6'
        }

        'S-1-5-7'                                                                                              = [PSCustomObject]@{
            'Description'     = 'A user who has connected to the computer without supplying a user name and password. Not a member of Authenticated Users (WellKnownSidType AnonymousSid) (SID constant SECURITY_ANONYMOUS_LOGON_RID)'
            'DisplayName'     = 'Anonymous Logon'
            'Name'            = 'ANONYMOUS LOGON'
            'NTAccount'       = 'NT AUTHORITY\ANONYMOUS LOGON'
            'SamAccountName'  = 'ANONYMOUS LOGON'
            'SchemaClassName' = 'user'
            'SID'             = 'S-1-5-7'
        }

        'S-1-5-8'                                                                                              = [PSCustomObject]@{
            'Description'     = "Doesn't currently apply: this SID isn't used (WellKnownSidType ProxySid) (SID Constant SECURITY_PROXY_RID)"
            'DisplayName'     = 'Proxy'
            'Name'            = 'PROXY'
            'NTAccount'       = 'NT AUTHORITY\PROXY'
            'SamAccountName'  = 'PROXY'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-8'
        }

        'S-1-5-9'                                                                                              = [PSCustomObject]@{
            'Description'     = 'A group that includes all domain controllers in a forest of domains (WellKnownSidType EnterpriseControllersSid) (SID constant SECURITY_ENTERPRISE_CONTROLLERS_RID)'
            'DisplayName'     = 'Enterprise Domain Controllers'
            'Name'            = 'ENTERPRISE DOMAIN CONTROLLERS'
            'NTAccount'       = 'NT AUTHORITY\ENTERPRISE DOMAIN CONTROLLERS'
            'SamAccountName'  = 'ENTERPRISE DOMAIN CONTROLLERS'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-9'
        }

        'S-1-5-10'                                                                                             = [PSCustomObject]@{
            'Description'     = "A placeholder in an ACE for a user, group, or computer object in Active Directory. When you grant permissions to Self, you grant them to the security principal that's represented by the object. During an access check, the operating system replaces the SID for Self with the SID for the security principal that's represented by the object (WellKnownSidType SelfSid) (SID constant SECURITY_PRINCIPAL_SELF_RID)"
            'DisplayName'     = 'Self'
            'Name'            = 'SELF'
            'NTAccount'       = 'NT AUTHORITY\SELF'
            'SamAccountName'  = 'SELF'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-10'
        }

        'S-1-5-11'                                                                                             = [PSCustomObject]@{
            'Description'     = 'A group that includes all users and computers with identities that have been authenticated. Does not include Guest even if the Guest account has a password. This group includes authenticated security principals from any trusted domain, not only the current domain (WellKnownSidType AuthenticatedUserSid) (SID constant SECURITY_AUTHENTICATED_USER_RID)'
            'DisplayName'     = 'Authenticated Users'
            'Name'            = 'Authenticated Users'
            'NTAccount'       = 'NT AUTHORITY\Authenticated Users'
            'SamAccountName'  = 'Authenticated Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-11'
        }

        'S-1-5-12'                                                                                             = [PSCustomObject]@{
            'Description'     = "An identity that's used by a process that's running in a restricted security context. In Windows and Windows Server operating systems, a software restriction policy can assign one of three security levels to code: Unrestricted/Restricted/Disallowed. When code runs at the restricted security level, the Restricted SID is added to the user's access token (WellKnownSidType RestrictedCodeSid) (SID constant SECURITY_RESTRICTED_CODE_RID)"
            'DisplayName'     = 'Restricted Code'
            'Name'            = 'RESTRICTED'
            'NTAccount'       = 'NT AUTHORITY\RESTRICTED'
            'SamAccountName'  = 'RESTRICTED'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-12'
        }

        'S-1-5-13'                                                                                             = [PSCustomObject]@{
            'Description'     = 'A group that includes all users who sign in to a server with Remote Desktop Services enabled (WellKnownSidType TerminalServerSid) (SID constant SECURITY_TERMINAL_SERVER_RID)'
            'DisplayName'     = 'Terminal Server User'
            'Name'            = 'TERMINAL SERVER USER'
            'NTAccount'       = 'NT AUTHORITY\TERMINAL SERVER USER'
            'SamAccountName'  = 'TERMINAL SERVER USER'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-13'
        }

        'S-1-5-14'                                                                                             = [PSCustomObject]@{
            'Description'     = 'A group that includes all users who sign in to the computer by using a remote desktop connection. This group is a subset of the Interactive group. Access tokens that contain the Remote Interactive Logon SID also contain the Interactive SID (WellKnownSidType RemoteLogonIdSid)'
            'DisplayName'     = 'Remote Interactive Logon'
            'Name'            = 'REMOTE INTERACTIVE LOGON'
            'NTAccount'       = 'NT AUTHORITY\REMOTE INTERACTIVE LOGON'
            'SamAccountName'  = 'REMOTE INTERACTIVE LOGON'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-14'
        }

        'S-1-5-15'                                                                                             = [PSCustomObject]@{
            'Description'     = 'A group that includes all users from the same organization. Included only with Active Directory accounts and added only by a domain controller (WellKnownSidType ThisOrganizationSid)'
            'DisplayName'     = 'This Organization'
            'Name'            = 'THIS ORGANIZATION'
            'NTAccount'       = 'NT AUTHORITY\THIS ORGANIZATION'
            'SamAccountName'  = 'THIS ORGANIZATION'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-15'
        }

        'S-1-5-17'                                                                                             = [PSCustomObject]@{
            'Description'     = 'An account used by the default Internet Information Services user (WellKnownSidType WinIUserSid) (SID constant IIS_USRS)'
            'DisplayName'     = 'IIS_USRS'
            'Name'            = 'IUSR'
            'NTAccount'       = 'NT AUTHORITY\IUSR'
            'SamAccountName'  = 'IUSR'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-17'
        }

        'S-1-5-18'                                                                                             = [PSCustomObject]@{
            'Description'     = "An identity used locally by the operating system and by services that are configured to sign in as LocalSystem. System is a hidden member of Administrators. That is, any process running as System has the SID for the built-in Administrators group in its access token. When a process that's running locally as System accesses network resources, it does so by using the computer's domain identity. Its access token on the remote computer includes the SID for the local computer's domain account plus SIDs for security groups that the computer is a member of, such as Domain Computers and Authenticated Users. By default, the SYSTEM account is granted Full Control permissions to all files on an NTFS volume (WellKnownSidType LocalSystemSid) (SID constant SECURITY_LOCAL_SYSTEM_RID)"
            'DisplayName'     = 'LocalSystem'
            'Name'            = 'SYSTEM'
            'NTAccount'       = 'NT AUTHORITY\SYSTEM'
            'SamAccountName'  = 'SYSTEM'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-5-18'
        }

        'S-1-5-19'                                                                                             = [PSCustomObject]@{
            'Description'     = "An identity used by services that are local to the computer, have no need for extensive local access, and don't need authenticated network access. Services that run as LocalService access local resources as ordinary users, and they access network resources as anonymous users. As a result, a service that runs as LocalService has significantly less authority than a service that runs as LocalSystem locally and on the network (WellKnownSidType LocalServiceSid)"
            'DisplayName'     = 'LocalService'
            'Name'            = 'LOCAL SERVICE'
            'NTAccount'       = 'NT AUTHORITY\LOCAL SERVICE'
            'SamAccountName'  = 'LOCAL SERVICE'
            'SchemaClassName' = 'user'
            'SID'             = 'S-1-5-19'
        }

        'S-1-5-20'                                                                                             = [PSCustomObject]@{
            'Description'     = "An identity used by services that have no need for extensive local access but do need authenticated network access. Services running as NetworkService access local resources as ordinary users and access network resources by using the computer's identity. As a result, a service that runs as NetworkService has the same network access as a service that runs as LocalSystem, but it has significantly reduced local access (WellKnownSidType NetworkServiceSid)"
            'DisplayName'     = 'Network Service'
            'Name'            = 'NETWORK SERVICE'
            'NTAccount'       = 'NT AUTHORITY\NETWORK SERVICE'
            'SamAccountName'  = 'NETWORK SERVICE'
            'SchemaClassName' = 'user'
            'SID'             = 'S-1-5-20'
        }

        'S-1-5-32-544'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group used for administration of the computer/domain. Administrators have complete and unrestricted access to the computer/domain. After the initial installation of the operating system, the only member of the group is the Administrator account. When a computer joins a domain, the Domain Admins group is added to the Administrators group. When a server becomes a domain controller, the Enterprise Admins group also is added to the Administrators group (WellKnownSidType BuiltinAdministratorsSid) (SID constant DOMAIN_ALIAS_RID_ADMINS)'
            'DisplayName'     = 'Administrators'
            'Name'            = 'Administrators'
            'NTAccount'       = 'BUILTIN\Administrators'
            'SamAccountName'  = 'Administrators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-544'
        }

        'S-1-5-32-545'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group that represents all users in the domain. Users are prevented from making accidental or intentional system-wide changes and can run most applications. After the initial installation of the operating system, the only member is the Authenticated Users group (WellKnownSidType BuiltinUsersSid) (SID constant DOMAIN_ALIAS_RID_USERS)'
            'DisplayName'     = 'Users'
            'Name'            = 'Users'
            'NTAccount'       = 'BUILTIN\Users'
            'SamAccountName'  = 'Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-545'
        }

        'S-1-5-32-546'                                                                                         = [PSCustomObject]@{
            'Description'     = "A built-in local group that represents guests of the domain. Guests have the same access as members of the Users group by default, except for the Guest account which is further restricted. By default, the only member is the Guest account. The Guests group allows occasional or one-time users to sign in with limited privileges to a computer's built-in Guest account (WellKnownSidType BuiltinGuestsSid) (SID constant DOMAIN_ALIAS_RID_GUESTS)"
            'DisplayName'     = 'Guests'
            'Name'            = 'Guests'
            'NTAccount'       = 'BUILTIN\Guests'
            'SamAccountName'  = 'Guests'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-546'
        }

        'S-1-5-32-547'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group used to represent a user or set of users who expect to treat a system as if it were their personal computer rather than as a workstation for multiple users. By default, the group has no members. Power users can create local users and groups; modify and delete accounts that they have created; and remove users from the Power Users, Users, and Guests groups. Power users also can install programs; create, manage, and delete local printers; and create and delete file shares. Power Users are included for backwards compatibility and possess limited administrative powers (WellKnownSidType BuiltinPowerUsersSid) (SID constant DOMAIN_ALIAS_RID_POWER_USERS)'
            'DisplayName'     = 'Power Users'
            'Name'            = 'Power Users'
            'NTAccount'       = 'BUILTIN\Power Users'
            'SamAccountName'  = 'Power Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-547'
        }

        'S-1-5-32-548'                                                                                         = [PSCustomObject]@{
            'Description'     = "A built-in local group that exists only on domain controllers. This group permits control over nonadministrator accounts. By default, the group has no members. By default, Account Operators have permission to create, modify, and delete accounts for users, groups, and computers in all containers and organizational units of Active Directory except the Builtin container and the Domain Controllers OU. Account Operators don't have permission to modify the Administrators and Domain Admins groups, nor do they have permission to modify the accounts for members of those groups (WellKnownSidType BuiltinAccountOperatorsSid) (SID constant DOMAIN_ALIAS_RID_ACCOUNT_OPS)"
            'DisplayName'     = 'Account Operators'
            'Name'            = 'Account Operators'
            'NTAccount'       = 'BUILTIN\DOMAIN_ALIAS_RID_ACCOUNT_OPS'
            'SamAccountName'  = 'DOMAIN_ALIAS_RID_ACCOUNT_OPS'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-548'
        }

        'S-1-5-32-549'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group that exists only on domain controllers. This group performs system administrative functions, not including security functions. It establishes network shares, controls printers, unlocks workstations, and performs other operations. By default, the group has no members. Server Operators can sign in to a server interactively; create and delete network shares; start and stop services; back up and restore files; format the hard disk of the computer; and shut down the computer (WellKnownSidType BuiltinSystemOperatorsSid) (SID constant DOMAIN_ALIAS_RID_SYSTEM_OPS)'
            'DisplayName'     = 'Server Operators'
            'Name'            = 'Server Operators'
            'NTAccount'       = 'BUILTIN\Server Operators'
            'SamAccountName'  = 'Server Operators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-549'
        }

        'S-1-5-32-550'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group that exists only on domain controllers. This group controls printers and print queues. By default, the only member is the Domain Users group. Print Operators can manage printers and document queues (WellKnownSidType BuiltinPrintOperatorsSid) (SID constant DOMAIN_ALIAS_RID_PRINT_OPS)'
            'DisplayName'     = 'DOMAIN_ALIAS_RID_PRINT_OPS'
            'Name'            = 'Print Operators'
            'NTAccount'       = 'BUILTIN\Print Operators'
            'SamAccountName'  = 'Print Operators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-550'
        }

        'S-1-5-32-551'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group used for controlling assignment of file backup-and-restore privileges. Backup Operators can override security restrictions for the sole purpose of backing up or restoring files. By default, the group has no members. Backup Operators can back up and restore all files on a computer, regardless of the permissions that protect those files. Backup Operators also can sign in to the computer and shut it down (WellKnownSidType BuiltinBackupOperatorsSid) (SID constant DOMAIN_ALIAS_RID_BACKUP_OPS)'
            'DisplayName'     = 'Backup Operators'
            'Name'            = 'Backup Operators'
            'NTAccount'       = 'BUILTIN\Backup Operators'
            'SamAccountName'  = 'Backup Operators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-551'
        }

        'S-1-5-32-552'                                                                                         = [PSCustomObject]@{
            'Description'     = "A built-in local group responsible for copying security databases from the primary domain controller to the backup domain controllers by the File Replication service. By default, the group has no members. Don't add users to this group. These accounts are used only by the system (WellKnownSidType BuiltinReplicatorSid) (SID constant DOMAIN_ALIAS_RID_REPLICATOR)"
            'DisplayName'     = 'Replicators'
            'Name'            = 'Replicators'
            'NTAccount'       = 'BUILTIN\Replicator'
            'SamAccountName'  = 'Replicator'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-552'
        }

        'S-1-5-32-554'                                                                                         = [PSCustomObject]@{
            'Description'     = 'An alias. A local group added by Windows 2000 server and used for backward compatibility. Allows read access on all users and groups in the domain (WellKnownSidType BuiltinPreWindows2000CompatibleAccessSid) (SID constant DOMAIN_ALIAS_RID_PREW2KCOMPACCESS)'
            'DisplayName'     = 'Pre-Windows 2000 Compatible Access'
            'Name'            = 'Pre-Windows 2000 Compatible Access'
            'NTAccount'       = 'BUILTIN\Pre-Windows 2000 Compatible Access'
            'SamAccountName'  = 'Pre-Windows 2000 Compatible Access'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-554'
        }

        'S-1-5-32-555'                                                                                         = [PSCustomObject]@{
            'Description'     = 'An alias. A local group that represents all remote desktop users. Members are granted the right to logon remotely (WellKnownSid BuiltinRemoteDesktopUsersSid) (SID constant DOMAIN_ALIAS_RID_REMOTE_DESKTOP_USERS)'
            'DisplayName'     = 'Remote Desktop Users'
            'Name'            = 'Remote Desktop Users'
            'NTAccount'       = 'BUILTIN\Remote Desktop Users'
            'SamAccountName'  = 'Remote Desktop Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-555'
        }

        'S-1-5-32-556'                                                                                         = [PSCustomObject]@{
            'Description'     = 'An alias. A local group that represents the network configuration. Members can have some administrative privileges to manage configuration of networking features (WellKnownSidType BuiltinNetworkConfigurationOperatorsSid) (SID constant DOMAIN_ALIAS_RID_NETWORK_CONFIGURATION_OPS)'
            'DisplayName'     = 'Network Configuration Operators'
            'Name'            = 'Network Configuration Operators'
            'NTAccount'       = 'BUILTIN\Network Configuration Operators'
            'SamAccountName'  = 'Network Configuration Operators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-556'
        }

        'S-1-5-32-557'                                                                                         = [PSCustomObject]@{
            'Description'     = 'An alias. A local group that represents any forest trust users. Members can create incoming, one-way trusts to this forest (WellKnownSidType BuiltinIncomingForestTrustBuildersSid) (SID constant DOMAIN_ALIAS_RID_INCOMING_FOREST_TRUST_BUILDERS)'
            'DisplayName'     = 'Incoming Forest Trust Builders'
            'Name'            = 'Incoming Forest Trust Builders'
            'NTAccount'       = 'BUILTIN\Incoming Forest Trust Builders'
            'SchemaClassName' = 'group'
            'SamAccountName'  = 'Incoming Forest Trust Builders'
            'SID'             = 'S-1-5-32-557'
        }

        'S-1-5-32-558'                                                                                         = [PSCustomObject]@{
            'Description'     = 'An alias. A local group. Members can access performance counter data locally and remotely (WellKnownSidType BuiltinPerformanceMonitoringUsersSid) (SID constant DOMAIN_ALIAS_RID_MONITORING_USERS)'
            'DisplayName'     = 'Performance Monitor Users'
            'Name'            = 'Performance Monitor Users'
            'NTAccount'       = 'BUILTIN\Performance Monitor Users'
            'SamAccountName'  = 'Performance Monitor Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-558'
        }

        'S-1-5-32-559'                                                                                         = [PSCustomObject]@{
            'Description'     = 'An alias. A local group responsible for logging users. Members may schedule logging of performance counters, enable trace providers, and collect event traces both locally and via remote access to this computer (WellKnownSidType BuiltinPerformanceLoggingUsersSid) (SID constant DOMAIN_ALIAS_RID_LOGGING_USERS)'
            'DisplayName'     = 'Performance Log Users'
            'Name'            = 'Performance Log Users'
            'NTAccount'       = 'BUILTIN\Performance Log Users'
            'SamAccountName'  = 'Performance Log Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-559'
        }

        'S-1-5-32-560'                                                                                         = [PSCustomObject]@{
            'Description'     = 'An alias. A local group that represents all authorized access. Members have access to the computed tokenGroupsGlobalAndUniversal attribute on User objects (WellKnownSidType BuiltinAuthorizationAccessSid) (SID constant DOMAIN_ALIAS_RID_AUTHORIZATIONACCESS)'
            'DisplayName'     = 'Windows Authorization Access Group'
            'Name'            = 'Windows Authorization Access Group'
            'NTAccount'       = 'BUILTIN\Windows Authorization Access Group'
            'SamAccountName'  = 'Windows Authorization Access Group'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-560'
        }

        'S-1-5-32-561'                                                                                         = [PSCustomObject]@{
            'Description'     = 'An alias. A local group that exists only on systems running server operating systems that allow for terminal services and remote access. When Windows Server 2003 Service Pack 1 is installed, a new local group is created (WellKnownSidType WinBuiltinTerminalServerLicenseServersSid) (SID constant DOMAIN_ALIAS_RID_TS_LICENSE_SERVERS)'
            'DisplayName'     = 'Terminal Server License Servers'
            'Name'            = 'Terminal Server License Servers'
            'NTAccount'       = 'BUILTIN\Terminal Server License Servers'
            'SamAccountName'  = 'Terminal Server License Servers'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-561'
        }

        'S-1-5-32-562'                                                                                         = [PSCustomObject]@{
            'Description'     = 'An alias. A local group that represents users who can use Distributed Component Object Model (DCOM). Used by COM to provide computer-wide access controls that govern access to all call, activation, or launch requests on the computer.Members are allowed to launch, activate and use Distributed COM objects on this machine (WellKnownSidType WinBuiltinDCOMUsersSid) (SID constant DOMAIN_ALIAS_RID_DCOM_USERS)'
            'DisplayName'     = 'Distributed COM Users'
            'Name'            = 'Distributed COM Users'
            'NTAccount'       = 'BUILTIN\Distributed COM Users'
            'SamAccountName'  = 'Distributed COM Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-562'
        }

        'S-1-5-32-568'                                                                                         = [PSCustomObject]@{
            'Description'     = 'An alias. A built-in local group used by Internet Information Services that represents Internet users (WellKnownSidType WinBuiltinIUsersSid) (SID constant DOMAIN_ALIAS_RID_IUSERS)'
            'DisplayName'     = 'IIS_IUSRS'
            'Name'            = 'IIS_IUSRS'
            'NTAccount'       = 'BUILTIN\IIS_IUSRS'
            'SamAccountName'  = 'IIS_IUSRS'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-568'
        }

        'S-1-5-32-569'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group that represents access to cryptography operators. Members are authorized to perform cryptographic operations (WellKnownSidType WinBuiltinCryptoOperatorsSid) (SID constant DOMAIN_ALIAS_RID_CRYPTO_OPERATORS)'
            'DisplayName'     = 'Cryptographic Operators'
            'Name'            = 'Cryptographic Operators'
            'NTAccount'       = 'BUILTIN\Cryptographic Operators'
            'SamAccountName'  = 'Cryptographic Operators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-569'
        }

        'S-1-5-32-573'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group that represents event log readers. Members can read event logs from a local computer (WellKnownSidType WinBuiltinEventLogReadersGroup) (SID constant DOMAIN_ALIAS_RID_EVENT_LOG_READERS_GROUP)'
            'DisplayName'     = 'Event Log Readers'
            'Name'            = 'Event Log Readers'
            'SID'             = 'S-1-5-32-573'
            'NTAccount'       = 'BUILTIN\Event Log Readers'
            'SamAccountName'  = 'Event Log Readers'
            'SchemaClassName' = 'group'
        }

        'S-1-5-32-574'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group. Members are allowed to connect to Certification Authorities in the enterprise using Distributed Component Object Model (DCOM) (WellKnownSidType WinBuiltinCertSvcDComAccessGroup) (SID constant DOMAIN_ALIAS_RID_CERTSVC_DCOM_ACCESS_GROUP)'
            'DisplayName'     = 'Certificate Service DCOM Access'
            'Name'            = 'Certificate Service DCOM Access'
            'NTAccount'       = 'BUILTIN\Certificate Service DCOM Access'
            'SamAccountName'  = 'Certificate Service DCOM Access'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-574'
        }

        'S-1-5-32-575'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group. Servers in this group enable users of RemoteApp programs and personal virtual desktops access to these resources. In internet-facing deployments, these servers are typically deployed in an edge network. This group needs to be populated on servers that are running RD Connection Broker. RD Gateway servers and RD Web Access servers used in the deployment need to be in this group (SID constant DOMAIN_ALIAS_RID_RDS_REMOTE_ACCESS_SERVERS)'
            'DisplayName'     = 'RDS Remote Access Servers'
            'Name'            = 'RDS Remote Access Servers'
            'NTAccount'       = 'BUILTIN\RDS Remote Access Servers'
            'SamAccountName'  = 'RDS Remote Access Servers'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-575'
        }

        'S-1-5-32-576'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group. Servers in this group run virtual machines and host sessions where users RemoteApp programs and personal virtual desktops run. This group needs to be populated on servers running RD Connection Broker. RD Session Host servers and RD Virtualization Host servers used in the deployment need to be in this group (SID constant DOMAIN_ALIAS_RID_RDS_ENDPOINT_SERVERS)'
            'DisplayName'     = 'RDS Endpoint Servers'
            'Name'            = 'RDS Endpoint Servers'
            'NTAccount'       = 'BUILTIN\RDS Endpoint Servers'
            'SamAccountName'  = 'RDS Endpoint Servers'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-576'
        }

        'S-1-5-32-577'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group. Servers in this group can perform routine administrative actions on servers running Remote Desktop Services. This group needs to be populated on all servers in a Remote Desktop Services deployment. The servers running the RDS Central Management service must be included in this group (SID constant DOMAIN_ALIAS_RID_RDS_MANAGEMENT_SERVERS)'
            'DisplayName'     = 'RDS Management Servers'
            'Name'            = 'RDS Management Servers'
            'NTAccount'       = 'BUILTIN\RDS Management Servers'
            'SamAccountName'  = 'RDS Management Servers'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-577'
        }

        'S-1-5-32-578'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group. Members have complete and unrestricted access to all features of Hyper-V (SID constant DOMAIN_ALIAS_RID_HYPER_V_ADMINS)'
            'DisplayName'     = 'Hyper-V Administrators'
            'Name'            = 'Hyper-V Administrators'
            'NTAccount'       = 'BUILTIN\Hyper-V Administrators'
            'SamAccountName'  = 'Hyper-V Administrators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-578'
        }

        'S-1-5-32-579'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group. Members can remotely query authorization attributes and permissions for resources on this computer (SID constant DOMAIN_ALIAS_RID_ACCESS_CONTROL_ASSISTANCE_OPS)'
            'DisplayName'     = 'Access Control Assistance Operators'
            'Name'            = 'Access Control Assistance Operators'
            'NTAccount'       = 'BUILTIN\Access Control Assistance Operators'
            'SamAccountName'  = 'Access Control Assistance Operators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-579'
        }

        'S-1-5-32-580'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A built-in local group. Members can access Windows Management Instrumentation (WMI) resources over management protocols (such as WS-Management via the Windows Remote Management service). This applies only to WMI namespaces that grant access to the user (SID constant DOMAIN_ALIAS_RID_REMOTE_MANAGEMENT_USERS)'
            'DisplayName'     = 'Remote Management Users'
            'Name'            = 'Remote Management Users'
            'NTAccount'       = 'BUILTIN\Remote Management Users'
            'SamAccountName'  = 'Remote Management Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-580'
        }

        'S-1-5-64-10'                                                                                          = [PSCustomObject]@{
            'Description'     = "A SID that's used when the NTLM authentication package authenticates the client (WellKnownSidType NtlmAuthenticationSid)"
            'DisplayName'     = 'NTLM Authentication'
            'Name'            = 'NTLM Authentication'
            'NTAccount'       = 'NT AUTHORITY\NTLM Authentication'
            'SamAccountName'  = 'NTLM Authentication'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-64-10'
        }

        'S-1-5-64-14'                                                                                          = [PSCustomObject]@{
            'Description'     = "A SID that's used when the SChannel authentication package authenticates the client (WellKnownSidType SChannelAuthenticationSid)"
            'DisplayName'     = 'SChannel Authentication'
            'Name'            = 'SChannel Authentication'
            'NTAccount'       = 'NT AUTHORITY\SChannel Authentication'
            'SamAccountName'  = 'SChannel Authentication'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-64-14'
        }

        'S-1-5-64-21'                                                                                          = [PSCustomObject]@{
            'Description'     = "A SID that's used when the Digest authentication package authenticates the client (WellKnownSidType DigestAuthenticationSid)"
            'DisplayName'     = 'Digest Authentication'
            'Name'            = 'Digest Authentication'
            'NTAccount'       = 'NT AUTHORITY\Digest Authentication'
            'SamAccountName'  = 'Digest Authentication'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-64-21'
        }

        'S-1-5-80'                                                                                             = [PSCustomObject]@{
            'Description'     = "A SID that's used as an NT Service account prefix"
            'DisplayName'     = 'NT Service'
            'Name'            = 'NT Service'
            'NTAccount'       = 'NT AUTHORITY\NT Service'
            'SamAccountName'  = 'NT Service'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-5-80'
        }

        'S-1-5-80-0'                                                                                           = [PSCustomObject]@{
            'Description'     = 'A group that includes all service processes that are configured on the system. Membership is controlled by the operating system. This SID was introduced in Windows Server 2008 R2'
            'DisplayName'     = 'All Services'
            'Name'            = 'All Services'
            'NTAccount'       = 'NT SERVICE\ALL SERVICES'
            'SamAccountName'  = 'ALL SERVICES'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-80-0'
        }

        'S-1-5-83-0'                                                                                           = [PSCustomObject]@{
            'Description'     = 'A built-in group. The group is created when the Hyper-V role is installed. Membership in the group is maintained by the Hyper-V Management Service [VMMS]. This group requires the Create Symbolic Links right [SeCreateSymbolicLinkPrivilege] and the Log on as a Service right [SeServiceLogonRight]'
            'DisplayName'     = 'Virtual Machines'
            'Name'            = 'Virtual Machines'
            'NTAccount'       = 'NT VIRTUAL MACHINE\Virtual Machines'
            'SamAccountName'  = 'Virtual Machines'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-83-0'
        }

        'S-1-5-113'                                                                                            = [PSCustomObject]@{
            'Description'     = "You can use this SID when you're restricting network sign-in to local accounts instead of 'administrator' or equivalent. This SID can be effective in blocking network sign-in for local users and groups by account type regardless of what they're named (SID constant LOCAL_ACCOUNT)"
            'DisplayName'     = 'Local account'
            'Name'            = 'Local account'
            'NTAccount'       = 'NT AUTHORITY\Local account'
            'SamAccountName'  = 'Local account'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-113'
        }

        'S-1-5-114'                                                                                            = [PSCustomObject]@{
            'Description'     = "You can use this SID when you're restricting network sign-in to local accounts instead of 'administrator' or equivalent. This SID can be effective in blocking network sign-in for local users and groups by account type regardless of what they're named (SID constant LOCAL_ACCOUNT_AND_MEMBER_OF_ADMINISTRATORS_GROUP)"
            'DisplayName'     = 'Local account and member of Administrators group'
            'Name'            = 'Local account and member of Administrators group'
            'NTAccount'       = 'NT AUTHORITY\Local account and member of Administrators group'
            'SamAccountName'  = 'Local account and member of Administrators group'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-114'
        }

        <#
        https://devblogs.microsoft.com/oldnewthing/20220502-00/?p=106550
        SIDs of the form S-1-15-2-xxx are app container SIDs.
        These SIDs are present in the token of apps running in an app container, and they encode the app container identity.
        According to the rules for Mandatory Integrity Control, objects default to allowing write access only to medium integrity level (IL) or higher.
        App containers run at low IL, so they by default don’t have write access to such objects.
            An object can add access control entries (ACEs) to its access control list (Get-Acl) to grant access to low IL.
            There are a few security identifiers (SIDs) you may see when an object extends access to low IL.
            #>
        'S-1-15-2-1'                                                                                           = [PSCustomObject]@{
            'Description'     = 'All applications running in an app package context have this app container SID (WellKnownSidType WinBuiltinAnyPackageSid) (SID constant SECURITY_BUILTIN_PACKAGE_ANY_PACKAGE)'
            'DisplayName'     = 'All Application Packages'
            'Name'            = 'ALL APPLICATION PACKAGES'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\ALL APPLICATION PACKAGES'
            'SamAccountName'  = 'ALL APPLICATION PACKAGES'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-2-1'
        }

        'S-1-15-2-2'                                                                                           = [PSCustomObject]@{
            'Description'     = 'Some applications running in an app package context may have this app container SID (SID constant SECURITY_BUILTIN_PACKAGE_ANY_RESTRICTED_PACKAGE)'
            'DisplayName'     = 'All Restricted Application Packages'
            'Name'            = 'ALL RESTRICTED APPLICATION PACKAGES'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\ALL RESTRICTED APPLICATION PACKAGES'
            'SamAccountName'  = 'ALL RESTRICTED APPLICATION PACKAGES'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-2-2'
        }

        <#
        # https://devblogs.microsoft.com/oldnewthing/20220503-00/?p=106557
        SIDs of the form S-1-15-3-xxx are app capability SIDs.
        These SIDs are present in the token of apps running in an app container, and they encode the app capabilities possessed by the app.
        The rules for Mandatory Integrity Control say that objects default to allowing write access only to medium integrity level (IL) or higher.
        Granting access to these app capability SIDs permit access from apps running at low IL, provided they possess the matching capability.
    
        Autogenerated
        S-1-15-3-x1-x2-x3-x4    device capability
        S-1-15-3-1024-x1-x2-x3-x4-x5-x6-x7-x8    app capability
    
        You can sort of see how these assignments evolved.
        At first, the capability RIDs were assigned by an assigned numbers authority, so anybody who wanted a capability had to apply for a number.
        After about a dozen of these, the assigned numbers team (probably just one person) realized that this had the potential to become a real bottleneck, so they switched to an autogeneration mechanism, so that people who needed a capability SID could just generate their own.
        For device capabilities, the four 32-bit decimal digits represent the 16 bytes of the device interface GUID.
        Let’s decode this one: S-1-15-3-787448254-1207972858-3558633622-1059886964.
    
        787448254    1207972858    3558633622    1059886964
        0x2eef81be    0x480033fa    0xd41c7096    0x3f2c9774
        be    81    ef    2e    fa    33    00    48    96    70    1c    d4    74    97    2c    3f
        2eef81be    33fa    4800    96    70    1c    d4    74    97    2c    3f
        {2eef81be-    33fa-    4800-    96    70-    1c    d4    74    97    2c    3f}
    
        And we recognize {2eef81be-33fa-4800-9670-1cd474972c3f} as DEVINTERFACE_AUDIO_CAPTURE, so this is the microphone device capability.
        For app capabilities, the eight 32-bit decimal numbers represent the 32 bytes of the SHA256 hash of the capability name.
        You can programmatically generate these app capability SIDs by calling Derive­Capability­Sids­From­Name.
        #>
        'S-1-15-3-1'                                                                                           = [PSCustomObject]@{
            'Description'     = 'internetClient containerized app capability SID (WellKnownSidType WinCapabilityInternetClientSid)'
            'DisplayName'     = 'Your Internet connection'
            'Name'            = 'Your Internet connection'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your Internet connection'
            'SamAccountName'  = 'Your Internet connection'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-1'
        }

        'S-1-15-3-2'                                                                                           = [PSCustomObject]@{
            'Description'     = 'internetClientServer containerized app capability SID (WellKnownSidType WinCapabilityInternetClientServerSid)'
            'DisplayName'     = 'Your Internet connection, including incoming connections from the Internet'
            'Name'            = 'Your Internet connection, including incoming connections from the Internet'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your Internet connection, including incoming connections from the Internet'
            'SamAccountName'  = 'Your Internet connection, including incoming connections from the Internet'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-2'
        }

        'S-1-15-3-3'                                                                                           = [PSCustomObject]@{
            'Description'     = 'privateNetworkClientServer containerized app capability SID (WellKnownSidType WinCapabilityPrivateNetworkClientServerSid)'
            'DisplayName'     = 'Your home or work networks'
            'Name'            = 'Your home or work networks'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your home or work networks'
            'SamAccountName'  = 'Your home or work networks'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-3'
        }

        'S-1-15-3-4'                                                                                           = [PSCustomObject]@{
            'Description'     = 'picturesLibrary containerized app capability SID (WellKnownSidType WinCapabilityPicturesLibrarySid)'
            'DisplayName'     = 'Your pictures library'
            'Name'            = 'Your pictures library'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your pictures library'
            'SamAccountName'  = 'Your pictures library'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-4'
        }

        'S-1-15-3-5'                                                                                           = [PSCustomObject]@{
            'Description'     = 'videosLibrary containerized app capability SID (WellKnownSidType WinCapabilityVideosLibrarySid)'
            'DisplayName'     = 'Your videos library'
            'Name'            = 'Your videos library'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your videos library'
            'SamAccountName'  = 'Your videos library'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-5'
        }

        'S-1-15-3-6'                                                                                           = [PSCustomObject]@{
            'Description'     = 'musicLibrary containerized app capability SID (WellKnownSidType WinCapabilityMusicLibrarySid)'
            'DisplayName'     = 'Your music library'
            'Name'            = 'Your music library'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your music library'
            'SamAccountName'  = 'Your music library'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-6'
        }

        'S-1-15-3-7'                                                                                           = [PSCustomObject]@{
            'Description'     = 'documentsLibrary containerized app capability SID (WellKnownSidType WinCapabilityDocumentsLibrarySid)'
            'DisplayName'     = 'Your documents library'
            'Name'            = 'Your documents library'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your documents library'
            'SamAccountName'  = 'Your documents library'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-7'
        }

        'S-1-15-3-8'                                                                                           = [PSCustomObject]@{
            'Description'     = 'enterpriseAuthentication containerized app capability SID (WellKnownSidType WinCapabilityEnterpriseAuthenticationSid)'
            'DisplayName'     = 'Your Windows credentials'
            'Name'            = 'Your Windows credentials'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your Windows credentials'
            'SamAccountName'  = 'Your Windows credentials'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-8'
        }

        'S-1-15-3-9'                                                                                           = [PSCustomObject]@{
            'Description'     = 'sharedUserCertificates containerized app capability SID (WellKnownSidType WinCapabilitySharedUserCertificatesSid)'
            'DisplayName'     = 'Software and hardware certificates or a smart card'
            'Name'            = 'Software and hardware certificates or a smart card'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Software and hardware certificates or a smart card'
            'SamAccountName'  = 'Software and hardware certificates or a smart card'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-9'
        }

        'S-1-15-3-10'                                                                                          = [PSCustomObject]@{
            'Description'     = 'removableStorage containerized app capability SID'
            'DisplayName'     = 'Removable storage'
            'Name'            = 'Removable storage'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Removable storage'
            'SamAccountName'  = 'Removable storage'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-10'
        }

        'S-1-15-3-11'                                                                                          = [PSCustomObject]@{
            'Description'     = 'appointments containerized app capability SID'
            'DisplayName'     = 'Your Appointments'
            'Name'            = 'Your Appointments'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your Appointments'
            'SamAccountName'  = 'Your Appointments'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-11'
        }

        'S-1-15-3-12'                                                                                          = [PSCustomObject]@{
            'Description'     = 'contacts containerized app capability SID'
            'DisplayName'     = 'Your Contacts'
            'Name'            = 'Your Contacts'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your Contacts'
            'SamAccountName'  = 'Your Contacts'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-12'
        }

        'S-1-15-3-4096'                                                                                        = [PSCustomObject]@{
            'Description'     = 'internetExplorer containerized app capability SID'
            'DisplayName'     = 'Internet Explorer'
            'Name'            = 'internetExplorer'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\internetExplorer'
            'SamAccountName'  = 'internetExplorer'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-4096'
        }

        <#Other known SIDs#>
        'S-1-5-80-242729624-280608522-2219052887-3187409060-2225943459'                                        = [PSCustomObject]@{
            'Description'     = 'Windows Cryptographic service account'
            'DisplayName'     = 'CryptSvc'
            'Name'            = 'CryptSvc'
            'NTAccount'       = 'NT SERVICE\CryptSvc'
            'SamAccountName'  = 'CryptSvc'
            'SchemaClassName' = 'service'
            'SID'             = 'S-1-5-80-242729624-280608522-2219052887-3187409060-2225943459'
        }

        'S-1-5-80-3139157870-2983391045-3678747466-658725712-1809340420'                                       = [PSCustomObject]@{
            'Description'     = 'Windows Diagnostics service account'
            'DisplayName'     = 'WdiServiceHost'
            'Name'            = 'WdiServiceHost'
            'NTAccount'       = 'NT SERVICE\WdiServiceHost'
            'SamAccountName'  = 'WdiServiceHost'
            'SchemaClassName' = 'service'
            'SID'             = 'S-1-5-80-3139157870-2983391045-3678747466-658725712-1809340420'
        }

        'S-1-5-80-880578595-1860270145-482643319-2788375705-1540778122'                                        = [PSCustomObject]@{
            'Description'     = 'Windows Event Log service account'
            'DisplayName'     = 'EventLog'
            'Name'            = 'EventLog'
            'NTAccount'       = 'NT SERVICE\EventLog'
            'SamAccountName'  = 'EventLog'
            'SchemaClassName' = 'service'
            'SID'             = 'S-1-5-80-880578595-1860270145-482643319-2788375705-1540778122'
        }

        'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'                                       = [PSCustomObject]@{
            'Description'     = 'Windows Modules Installer service account used to install, modify, and remove Windows updates and optional components. Most operating system files are owned by TrustedInstaller'
            'DisplayName'     = 'TrustedInstaller'
            'Name'            = 'TrustedInstaller'
            'NTAccount'       = 'NT SERVICE\TrustedInstaller'
            'SamAccountName'  = 'TrustedInstaller'
            'SchemaClassName' = 'service'
            'SID'             = 'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'
        }

        'S-1-5-32-553'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A local group that represents RAS and IAS servers. This group permits access to various attributes of user objects (SID constant DOMAIN_ALIAS_RID_RAS_SERVERS)'
            'DisplayName'     = 'RAS and IAS Servers'
            'Name'            = 'RAS and IAS Servers'
            'NTAccount'       = 'BUILTIN\RAS and IAS Servers'
            'SamAccountName'  = 'RAS and IAS Servers'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-553'
        }

        'S-1-5-32-571'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A local group that represents principals that can be cached (SID constant DOMAIN_ALIAS_RID_CACHEABLE_PRINCIPALS_GROUP)'
            'DisplayName'     = 'Allowed RODC Password Replication Group'
            'Name'            = 'Allowed RODC Password Replication Group'
            'NTAccount'       = 'BUILTIN\Allowed RODC Password Replication Group'
            'SamAccountName'  = 'Allowed RODC Password Replication Group'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-571'
        }

        'S-1-5-32-572'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A local group that represents principals that cannot be cached (SID constant DOMAIN_ALIAS_RID_NON_CACHEABLE_PRINCIPALS_GROUP)'
            'DisplayName'     = 'Denied RODC Password Replication Group'
            'Name'            = 'Denied RODC Password Replication Group'
            'NTAccount'       = 'BUILTIN\Denied RODC Password Replication Group'
            'SamAccountName'  = 'Denied RODC Password Replication Group'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-572'
        }

        'S-1-5-32-581'                                                                                         = [PSCustomObject]@{
            'Description'     = 'Members are managed by the system. A local group that represents the default account (SID constant DOMAIN_ALIAS_RID_DEFAULT_ACCOUNT)'
            'DisplayName'     = 'System Managed Accounts'
            'Name'            = 'System Managed Accounts'
            'NTAccount'       = 'BUILTIN\System Managed Accounts'
            'SamAccountName'  = 'System Managed Accounts'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-581'
        }

        'S-1-5-32-582'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A local group that represents storage replica admins (SID constant DOMAIN_ALIAS_RID_STORAGE_REPLICA_ADMINS)'
            'DisplayName'     = 'Domain Alias RID Storage Replica Admins'
            'Name'            = 'Domain Alias RID Storage Replica Admins'
            'NTAccount'       = 'BUILTIN\Domain Alias RID Storage Replica Admins'
            'SamAccountName'  = 'Domain Alias RID Storage Replica Admins'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-582'
        }

        'S-1-5-32-583'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A local group that represents can make settings expected for Device Owners (SID constant DOMAIN_ALIAS_RID_DEVICE_OWNERS)'
            'DisplayName'     = 'Device Owners'
            'Name'            = 'Device Owners'
            'NTAccount'       = 'BUILTIN\Device Owners'
            'SamAccountName'  = 'Device Owners'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-583'
        }

        # Additional SIDs found on local machine via discovery
        'S-1-5-32'                                                                                             = [PSCustomObject]@{
            'Description'     = 'The built-in system domain (WellKnownSidType BuiltinDomainSid) (SID constant SECURITY_BUILTIN_DOMAIN_RID)'
            'DisplayName'     = 'Built-in'
            'Name'            = 'BUILTIN'
            'NTAccount'       = 'NT AUTHORITY\BUILTIN'
            'SamAccountName'  = 'BUILTIN'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-5-32'
        }

        'S-1-5-80-1594061079-2000966165-462148798-751814865-2644087104'                                        = [PSCustomObject]@{
            'Description'     = 'Used by the Language Experience Service to provide support for deploying and configuring localized Windows resources'
            'DisplayName'     = 'LxpSvc'
            'Name'            = 'LxpSvc'
            'NTAccount'       = 'NT SERVICE\LxpSvc'
            'SamAccountName'  = 'LxpSvc'
            'SchemaClassName' = 'service'
            'SID'             = 'S-1-5-80-1594061079-2000966165-462148798-751814865-2644087104'
        }

        'S-1-5-80-4230913304-2206818457-801678004-120036174-1892434133'                                        = [PSCustomObject]@{
            'Description'     = 'Used by the TAPI server to provide the central repository of telephony on data on a computer'
            'DisplayName'     = 'TapiSrv'
            'Name'            = 'TapiSrv'
            'NTAccount'       = 'NT SERVICE\TapiSrv'
            'SamAccountName'  = 'TapiSrv'
            'SchemaClassName' = 'service'
            'SID'             = 'S-1-5-80-4230913304-2206818457-801678004-120036174-1892434133'
        }

        'S-1-5-84-0-0-0-0-0'                                                                                   = [PSCustomObject]@{
            #https://learn.microsoft.com/en-us/windows-hardware/drivers/wdf/controlling-device-access
            'Description'     = 'A security identifier that identifies UMDF drivers'
            'DisplayName'     = 'User-Mode Driver Framework (UMDF) drivers'
            'Name'            = 'SDDL_USER_MODE_DRIVERS'
            'NTAccount'       = 'NT SERVICE\SDDL_USER_MODE_DRIVERS'
            'SamAccountName'  = 'SDDL_USER_MODE_DRIVERS'
            'SchemaClassName' = 'service'
            'SID'             = $SID
        }

        <# Get WellKnownSidTypes
        # https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/81d92bba-d22b-4a8c-908a-554ab29148ab
        # PS 5.1 returns fewer results than PS 7
        $logonDomainSid = 'S-1-5-21-1340649458-2707494813-4121304102'
        ForEach ($SidType in [System.Security.Principal.WellKnownSidType].GetEnumNames()) {$var = [System.Security.Principal.WellKnownSidType]::$SidType; [System.Security.Principal.SecurityIdentifier]::new($var,$LogonDomainSid) |Add-Member -PassThru -NotePropertyMembers @{'WellKnownSidType' = $SidType}}
        #>

        'S-1-2-0'                                                                                              = [PSCustomObject]@{
            'Description'     = 'Users who sign in to terminals that are locally (physically) connected to the system (WellKnownSidType LocalSid)'
            'DisplayName'     = 'Local'
            'Name'            = 'Local'
            'NTAccount'       = 'LOCAL SID AUTHORITY\LOCAL'
            'SamAccountName'  = 'LOCAL'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-2-0'
        }

        'S-1-3-1'                                                                                              = [PSCustomObject]@{
            'Description'     = 'A security identifier to be replaced by the primary-group SID of the user who created a new object. Use this SID in inheritable ACEs (WellKnownSidType CreatorGroupSid)'
            'DisplayName'     = 'Creator Group ID'
            'Name'            = 'CREATOR GROUP'
            'NTAccount'       = 'CREATOR SID AUTHORITY\CREATOR GROUP'
            'SamAccountName'  = 'CREATOR GROUP'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-3-1'
        }

        'S-1-3-2'                                                                                              = [PSCustomObject]@{
            'Description'     = "A placeholder in an inheritable ACE. When the ACE is inherited, the system replaces this SID with the SID for the object's owner server and stores information about who created a given object or file (WellKnownSidType CreatorOwnerServerSid)"
            'DisplayName'     = 'Creator Owner Server'
            'Name'            = 'CREATOR OWNER SERVER'
            'NTAccount'       = 'CREATOR SID AUTHORITY\CREATOR OWNER SERVER'
            'SamAccountName'  = 'CREATOR OWNER SERVER'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-3-2'
        }

        'S-1-3-3'                                                                                              = [PSCustomObject]@{
            'Description'     = "A placeholder in an inheritable ACE. When the ACE is inherited, the system replaces this SID with the SID for the object's group server and stores information about the groups that are allowed to work with the object (WellKnownSidType CreatorGroupServerSid)"
            'DisplayName'     = 'Creator Group Server'
            'Name'            = 'CREATOR GROUP SERVER'
            'NTAccount'       = 'CREATOR SID AUTHORITY\CREATOR GROUP SERVER'
            'SamAccountName'  = 'CREATOR GROUP SERVER'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-3-3'
        }

        'S-1-3-4'                                                                                              = [PSCustomObject]@{
            'Description'     = 'A group that represents the current owner of the object. When an ACE that carries this SID is applied to an object, the system ignores the implicit READ_CONTROL and WRITE_DAC permissions for the object owner (WellKnownSidType WinCreatorOwnerRightsSid)'
            'DisplayName'     = 'Owner Rights'
            'Name'            = 'OWNER RIGHTS'
            'NTAccount'       = 'CREATOR SID AUTHORITY\OWNER RIGHTS'
            'SamAccountName'  = 'OWNER RIGHTS'
            'SchemaClassName' = 'user'
            'SID'             = 'S-1-3-4'
        }

        'S-1-5-22'                                                                                             = [PSCustomObject]@{
            'Description'     = 'Domain controllers that are configured as read-only, meaning they cannot make changes to the directory (WellKnownSidType WinEnterpriseReadonlyControllersSid) (SID constant DOMAIN_GROUP_RID_ENTERPRISE_READONLY_DOMAIN_CONTROLLERS)'
            'DisplayName'     = 'Enterprise Read-Only Domain Controllers'
            'Name'            = 'Enterprise Read-Only Domain Controllers'
            'NTAccount'       = 'NT AUTHORITY\Enterprise Read-Only Domain Controllers'
            'SamAccountName'  = 'Enterprise Read-Only Domain Controllers'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-22'
        }

        'S-1-5-1000'                                                                                           = [PSCustomObject]@{
            'Description'     = 'A group that includes all users and computers from another organization. If this SID is present, the THIS_ORGANIZATION SID must NOT be present (WellKnownSidType OtherOrganizationSid) (SID constant OTHER_ORGANIZATION)'
            'DisplayName'     = 'Other Organization'
            'Name'            = 'Other Organization'
            'NTAccount'       = 'NT AUTHORITY\Other Organization'
            'SamAccountName'  = 'Other Organization'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-1000'
        }

        'S-1-16-0'                                                                                             = [PSCustomObject]@{
            'Description'     = 'An untrusted integrity level (WellKnownSidType WinUntrustedLabelSid) (SID constant ML_UNTRUSTED)'
            'DisplayName'     = 'Untrusted Mandatory Level'
            'Name'            = 'Untrusted Mandatory Level'
            'NTAccount'       = 'MANDATORY LABEL AUTHORITY\Untrusted Mandatory Level'
            'SamAccountName'  = 'Untrusted Mandatory Level'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-16-0'
        }

        'S-1-16-4096'                                                                                          = [PSCustomObject]@{
            'Description'     = 'A low integrity level (WellKnownSidType WinLowLabelSid) (SID constant ML_LOW)'
            'DisplayName'     = 'Low Mandatory Level'
            'Name'            = 'Low Mandatory Level'
            'NTAccount'       = 'MANDATORY LABEL AUTHORITY\Low Mandatory Level'
            'SamAccountName'  = 'Low Mandatory Level'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-16-4096'
        }

        'S-1-16-8192'                                                                                          = [PSCustomObject]@{
            'Description'     = 'A medium integrity level (WellKnownSidType WinMediumLabelSid) (SID constant ML_MEDIUM)'
            'DisplayName'     = 'Medium Mandatory Level'
            'Name'            = 'Medium Mandatory Level'
            'NTAccount'       = 'MANDATORY LABEL AUTHORITY\Medium Mandatory Level'
            'SamAccountName'  = 'Medium Mandatory Level'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-16-8192'
        }

        'S-1-16-8448'                                                                                          = [PSCustomObject]@{
            'Description'     = 'A medium-plus integrity level (WellKnownSidType WinMediumPlusLabelSid) (SID constant ML_MEDIUM_PLUS)'
            'DisplayName'     = 'Medium Plus Mandatory Level'
            'Name'            = 'Medium Plus Mandatory Level'
            'NTAccount'       = 'MANDATORY LABEL AUTHORITY\Medium Plus Mandatory Level'
            'SamAccountName'  = 'Medium Plus Mandatory Level'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-16-8448'
        }

        'S-1-16-12288'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A high integrity level (WellKnownSidType WinHighLabelSid) (SID constant ML_HIGH)'
            'DisplayName'     = 'High Mandatory Level'
            'Name'            = 'High Mandatory Level'
            'NTAccount'       = 'MANDATORY LABEL AUTHORITY\High Mandatory Level'
            'SamAccountName'  = 'High Mandatory Level'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-16-12288'
        }

        'S-1-16-16384'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A system integrity level (WellKnownSidType WinSystemLabelSid) (SID constant ML_SYSTEM)'
            'DisplayName'     = 'System Mandatory Level'
            'Name'            = 'System Mandatory Level'
            'NTAccount'       = 'MANDATORY LABEL AUTHORITY\System Mandatory Level'
            'SamAccountName'  = 'System Mandatory Level'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-16-16384'
        }

        'S-1-5-65-1'                                                                                           = [PSCustomObject]@{
            # https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/11e1608c-6169-4fbc-9c33-373fc9b224f4#Appendix_A_32
            'Description'     = "A SID that indicates that the client's Kerberos service ticket's PAC contained a NTLM_SUPPLEMENTAL_CREDENTIAL structure as specified in [MS-PAC] section 2.6.4. If the OTHER_ORGANIZATION SID is present, then this SID MUST NOT be present (WellKnownSidType WinThisOrganizationCertificateSid) (SID constant THIS_ORGANIZATION_CERTIFICATE)"
            'DisplayName'     = 'This Organization Certificate'
            'Name'            = 'This Organization Certificate'
            'NTAccount'       = 'NT AUTHORITY\This Organization Certificate'
            'SamAccountName'  = 'This Organization Certificate'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-65-1'
        }

        # https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/81d92bba-d22b-4a8c-908a-554ab29148ab
        'S-1-5-33'                                                                                             = [PSCustomObject]@{
            'Description'     = 'Any process with a write-restricted token (WellKnownSidType WinWriteRestrictedCodeSid) (SID constant SECURITY_WRITE_RESTRICTED_CODE_RID)'
            'DisplayName'     = 'Write Restricted Code'
            'Name'            = 'Write Restricted Code'
            'NTAccount'       = 'NT AUTHORITY\Write Restricted Code'
            'SamAccountName'  = 'Write Restricted Code'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-33'
        }

        'S-1-5-80-2970612574-78537857-698502321-558674196-1451644582'                                          = [PSCustomObject]@{
            'Description'     = 'The SID gives the Diagnostic Policy Service (which runs as NT AUTHORITY\LocalService in a shared process of svchost.exe) access to coordinate execution of diagnostics/troubleshooting/resolution'
            'DisplayName'     = 'Diagnostic Policy Service'
            'Name'            = 'DPS'
            'NTAccount'       = 'NT SERVICE\DPS'
            'SamAccountName'  = 'DPS'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-33'
        }

        'S-1-16-20480'                                                                                         = [PSCustomObject]@{
            'Description'     = 'A protected-process integrity level (WellKnownSidType WinProtectedProcessLabelSid) (SID constant ML_PROTECTED_PROCESS)'
            'DisplayName'     = 'Protected Process Mandatory Level'
            'Name'            = 'Protected Process Mandatory Level'
            'NTAccount'       = 'MANDATORY LABEL AUTHORITY\Protected Process Mandatory Level'
            'SamAccountName'  = 'Protected Process Mandatory Level'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-16-20480'
        }

        'S-1-16-28672'                                                                                         = [PSCustomObject]@{
            # https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/11e1608c-6169-4fbc-9c33-373fc9b224f4#Appendix_A_36
            'Description'     = 'A secure process integrity level (WellKnownSidType WinSecureProcessLabelSid) (SID constant ML_SECURE_PROCESS)'
            'DisplayName'     = 'Secure Process Mandatory Level'
            'Name'            = 'Secure Process Mandatory Level'
            'NTAccount'       = 'MANDATORY LABEL AUTHORITY\Secure Process Mandatory Level'
            'SamAccountName'  = 'Secure Process Mandatory Level'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-16-28672'
        }

        # https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/dn743661(v=ws.11)
        'S-1-0'                                                                                                = [PSCustomObject]@{
            'Description'     = 'This authority is used to define the Null SID (SID constant SECURITY_NULL_SID_AUTHORITY)'
            'DisplayName'     = 'NULL SID AUTHORITY'
            'Name'            = 'NULL SID AUTHORITY'
            'NTAccount'       = 'NULL SID AUTHORITY'
            'SamAccountName'  = 'NULL SID AUTHORITY'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-0'
        }

        'S-1-1'                                                                                                = [PSCustomObject]@{
            'Description'     = 'This authority is used to define the World SID (SID constant SECURITY_WORLD_SID_AUTHORITY)'
            'DisplayName'     = 'WORLD SID AUTHORITY'
            'Name'            = 'WORLD SID AUTHORITY'
            'NTAccount'       = 'WORLD SID AUTHORITY'
            'SamAccountName'  = 'WORLD SID AUTHORITY'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-1'
        }

        'S-1-2'                                                                                                = [PSCustomObject]@{
            'Description'     = 'This authority manages local users and groups on a computer (SID constant SECURITY_LOCAL_SID_AUTHORITY)'
            'DisplayName'     = 'LOCAL SID AUTHORITY'
            'Name'            = 'LOCAL SID AUTHORITY'
            'NTAccount'       = 'LOCAL SID AUTHORITY'
            'SamAccountName'  = 'LOCAL SID AUTHORITY'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-2'
        }

        'S-1-15-3-1024-1365790099-2797813016-1714917928-519942599-2377126242-1094757716-3949770552-3596009590' = [PSCustomObject]@{
            'Description'     = 'runFullTrust containerized app capability SID (WellKnownSidType WinCapabilityRemovableStorageSid)'
            'DisplayName'     = 'runFullTrust'
            'Name'            = 'runFullTrust'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\runFullTrust'
            'SamAccountName'  = 'runFullTrust'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-1024-1365790099-2797813016-1714917928-519942599-2377126242-1094757716-3949770552-3596009590'
        }

        'S-1-15-3-1024-1195710214-366596411-2746218756-3015581611-3786706469-3006247016-1014575659-1338484819' = [PSCustomObject]@{
            'Description'     = 'userNotificationListener containerized app capability SID'
            'DisplayName'     = 'userNotificationListener'
            'Name'            = 'userNotificationListener'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\userNotificationListener'
            'SamAccountName'  = 'userNotificationListener'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-1024-1195710214-366596411-2746218756-3015581611-3786706469-3006247016-1014575659-1338484819'
        }

    }

}
