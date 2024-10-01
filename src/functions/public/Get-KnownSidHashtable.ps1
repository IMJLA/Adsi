function Get-KnownSidHashTable {
    # Some of these cannot be translated using the [SecurityIdentifier]::Translate or [NTAccount]::Translate methods.
    # Some of these cannot be retrieved using CIM or ADSI.
    # Hardcoding them here allows avoiding queries that we know will fail.
    return @{
        #https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-identifiers
        'S-1-0-0'                                                        = @{
            'Description'     = "A group with no members. This is often used when a SID value isn't known."
            'Name'            = 'NULL SID'
            'NTAccount'       = 'NULL SID AUTHORITY\NULL SID'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-0-0'
        }
        'S-1-1-0'                                                        = @{
            'Description'     = "A group that includes all users; aka 'World'."
            'Name'            = 'Everyone'
            'NTAccount'       = 'WORLD SID AUTHORITY\Everyone'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-1-0'
        }
        'S-1-2-1'                                                        = @{
            'Description'     = 'A group that includes users who are signed in to the physical console.'
            'Name'            = 'CONSOLE LOGON'
            'NTAccount'       = 'LOCAL SID AUTHORITY\CONSOLE LOGON'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-2-0'
        }
        'S-1-3-0'                                                        = @{
            'Description'     = 'A security identifier to be replaced by the SID of the user who creates a new object. This SID is used in inheritable access control entries.'
            'Name'            = 'CREATOR OWNER'
            'NTAccount'       = 'CREATOR SID AUTHORITY\CREATOR OWNER'
            'SchemaClassName' = 'user'
            'SID'             = 'S-1-3-0'
        }
        'S-1-4'                                                          = @{
            'Description'     = 'A SID that represents an identifier authority which is not unique.'
            'Name'            = 'Non-unique Authority'
            'NTAccount'       = 'Non-unique Authority'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-4'
        }
        'S-1-5'                                                          = @{
            'Description'     = "The SECURITY_NT_AUTHORITY (S-1-5) predefined identifier authority produces SIDs that aren't universal and are meaningful only in installations of the Windows operating systems in the 'Applies to' list at the beginning of this article."
            'Name'            = 'NT Authority'
            'NTAccount'       = 'NT Authority'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-5'
        }
        'S-1-5-1'                                                        = @{
            'Description'     = "A group that includes all users who are signed in to the system via dial-up connection."
            'Name'            = 'Dialup'
            'NTAccount'       = 'NT AUTHORITY\DIALUP'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-5-1'
        }
        'S-1-5-2'                                                        = @{
            'Description'     = "A group that includes all users who are signed in via a network connection. Access tokens for interactive users don't contain the Network SID."
            'Name'            = 'Network'
            'NTAccount'       = 'NT AUTHORITY\NETWORK'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-2'
        }
        'S-1-5-3'                                                        = @{
            'Description'     = "A group that includes all users who have signed in via batch queue facility, such as task scheduler jobs."
            'Name'            = 'Batch'
            'NTAccount'       = 'NT AUTHORITY\BATCH'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-3'
        }
        'S-1-5-4'                                                        = @{
            'Description'     = "Users who log on for interactive operation. This is a group identifier added to the token of a process when it was logged on interactively. A group that includes all users who sign in interactively. A user can start an interactive sign-in session by opening a Remote Desktop Services connection from a remote computer, or by using a remote shell such as Telnet. In each case, the user's access token contains the Interactive SID. If the user signs in by using a Remote Desktop Services connection, the user's access token also contains the Remote Interactive Logon SID."
            'Name'            = 'INTERACTIVE'
            'NTAccount'       = 'NT AUTHORITY\INTERACTIVE'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-4'
        }
        'S-1-5-6'                                                        = @{
            'Description'     = "A group that includes all security principals that have signed in as a service."
            'Name'            = 'Service'
            'NTAccount'       = 'NT AUTHORITY\SERVICE'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-6'
        }
        'S-1-5-7'                                                        = @{
            'Description'     = 'A user who has connected to the computer without supplying a user name and password. Not a member of Authenticated Users.'
            'Name'            = 'ANONYMOUS LOGON'
            'NTAccount'       = 'NT AUTHORITY\ANONYMOUS LOGON'
            'SchemaClassName' = 'user'
            'SID'             = 'S-1-5-7'
        }
        'S-1-5-8'                                                        = @{
            'Description'     = "Doesn't currently apply: this SID isn't used."
            'Name'            = 'Proxy'
            'NTAccount'       = 'NT AUTHORITY\PROXY'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-8'
        }
        'S-1-5-9'                                                        = @{
            'Description'     = "A group that includes all domain controllers in a forest of domains."
            'Name'            = 'Enterprise Domain Controllers'
            'NTAccount'       = 'NT AUTHORITY\ENTERPRISE DOMAIN CONTROLLERS'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-9'
        }
        'S-1-5-10'                                                       = @{
            'Description'     = "A placeholder in an ACE for a user, group, or computer object in Active Directory. When you grant permissions to Self, you grant them to the security principal that's represented by the object. During an access check, the operating system replaces the SID for Self with the SID for the security principal that's represented by the object."
            'Name'            = 'Self'
            'NTAccount'       = 'NT AUTHORITY\SELF'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-10'
        }
        'S-1-5-11'                                                       = @{
            'Description'     = 'A group that includes all users and computers with identities that have been authenticated. Does not include Guest even if the Guest account has a password. This group includes authenticated security principals from any trusted domain, not only the current domain.'
            'Name'            = 'Authenticated Users'
            'NTAccount'       = 'NT AUTHORITY\Authenticated Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-11'
        }
        'S-1-5-12'                                                       = @{
            'Description'     = "An identity that's used by a process that's running in a restricted security context. In Windows and Windows Server operating systems, a software restriction policy can assign one of three security levels to code: Unrestricted/Restricted/Disallowed. When code runs at the restricted security level, the Restricted SID is added to the user's access token."
            'Name'            = 'Restricted Code'
            'NTAccount'       = 'NT AUTHORITY\RESTRICTED'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-12'
        }
        'S-1-5-13'                                                       = @{
            'Description'     = "A group that includes all users who sign in to a server with Remote Desktop Services enabled."
            'Name'            = 'Terminal Server User'
            'NTAccount'       = 'NT AUTHORITY\TERMINAL SERVER USER'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-13'
        }
        'S-1-5-14'                                                       = @{
            'Description'     = "A group that includes all users who sign in to the computer by using a remote desktop connection. This group is a subset of the Interactive group. Access tokens that contain the Remote Interactive Logon SID also contain the Interactive SID."
            'Name'            = 'Remote Interactive Logon'
            'NTAccount'       = 'NT AUTHORITY\REMOTE INTERACTIVE LOGON'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-14'
        }
        'S-1-5-15'                                                       = @{
            'Description'     = "A group that includes all users from the same organization. Included only with Active Directory accounts and added only by a domain controller."
            'Name'            = 'This Organization'
            'NTAccount'       = 'NT AUTHORITY\This Organization'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-15'
        }
        'S-1-5-17'                                                       = @{
            'Description'     = "An account that's used by the default Internet Information Services (IIS) user."
            'Name'            = 'IUSR'
            'NTAccount'       = 'NT AUTHORITY\IUSR'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-17'
        }
        'S-1-5-18'                                                       = @{
            'Description'     = "An identity used locally by the operating system and by services that are configured to sign in as LocalSystem. System is a hidden member of Administrators. That is, any process running as System has the SID for the built-in Administrators group in its access token. When a process that's running locally as System accesses network resources, it does so by using the computer's domain identity. Its access token on the remote computer includes the SID for the local computer's domain account plus SIDs for security groups that the computer is a member of, such as Domain Computers and Authenticated Users. By default, the SYSTEM account is granted Full Control permissions to all files on an NTFS volume (LocalSystem)"
            'Name'            = 'SYSTEM'
            'NTAccount'       = 'NT AUTHORITY\SYSTEM'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-5-18'
        }
        'S-1-5-19'                                                       = @{
            'Description'     = "An identity used by services that are local to the computer, have no need for extensive local access, and don't need authenticated network access. Services that run as LocalService access local resources as ordinary users, and they access network resources as anonymous users. As a result, a service that runs as LocalService has significantly less authority than a service that runs as LocalSystem locally and on the network."
            'Name'            = 'LOCAL SERVICE'
            'NTAccount'       = 'NT AUTHORITY\LOCAL SERVICE'
            'SchemaClassName' = 'user'
            'SID'             = 'S-1-5-19'
        }
        'S-1-5-20'                                                       = @{
            'Description'     = "An identity used by services that have no need for extensive local access but do need authenticated network access. Services running as NetworkService access local resources as ordinary users and access network resources by using the computer's identity. As a result, a service that runs as NetworkService has the same network access as a service that runs as LocalSystem, but it has significantly reduced local access."
            'Name'            = 'NETWORK SERVICE'
            'NTAccount'       = 'NT AUTHORITY\NETWORK SERVICE'
            'SchemaClassName' = 'user'
            'SID'             = 'S-1-5-20'
        }
        'S-1-5-32-544'                                                   = @{
            'Description'     = "A built-in local group used for administration of the computer/domain. Administrators have complete and unrestricted access to the computer/domain. After the initial installation of the operating system, the only member of the group is the Administrator account. When a computer joins a domain, the Domain Admins group is added to the Administrators group. When a server becomes a domain controller, the Enterprise Admins group also is added to the Administrators group. (DOMAIN_ALIAS_RID_ADMINS)"
            'Name'            = 'Administrators'
            'NTAccount'       = 'BUILTIN\Administrators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-544'
        }
        'S-1-5-32-545'                                                   = @{
            'Description'     = "A built-in local group that represents all users in the domain. Users are prevented from making accidental or intentional system-wide changes and can run most applications. After the initial installation of the operating system, the only member is the Authenticated Users group. (DOMAIN_ALIAS_RID_USERS)"
            'Name'            = 'Users'
            'NTAccount'       = 'BUILTIN\Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-545'
        }
        'S-1-5-32-546'                                                   = @{
            'Description'     = "A built-in local group that represents guests of the domain. Guests have the same access as members of the Users group by default, except for the Guest account which is further restricted. By default, the only member is the Guest account. The Guests group allows occasional or one-time users to sign in with limited privileges to a computer's built-in Guest account. (DOMAIN_ALIAS_RID_GUESTS)"
            'Name'            = 'Guests'
            'NTAccount'       = 'BUILTIN\Guests'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-546'
        }
        'S-1-5-32-547'                                                   = @{
            'Description'     = "A built-in local group used to represent a user or set of users who expect to treat a system as if it were their personal computer rather than as a workstation for multiple users. By default, the group has no members. Power users can create local users and groups; modify and delete accounts that they have created; and remove users from the Power Users, Users, and Guests groups. Power users also can install programs; create, manage, and delete local printers; and create and delete file shares. Power Users are included for backwards compatibility and possess limited administrative powers. (DOMAIN_ALIAS_RID_POWER_USERS)"
            'Name'            = 'Power Users'
            'NTAccount'       = 'BUILTIN\Power Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-547'
        }
        'S-1-5-32-548'                                                   = @{
            'Description'     = "A built-in local group that exists only on domain controllers. This group permits control over nonadministrator accounts. By default, the group has no members. By default, Account Operators have permission to create, modify, and delete accounts for users, groups, and computers in all containers and organizational units of Active Directory except the Builtin container and the Domain Controllers OU. Account Operators don't have permission to modify the Administrators and Domain Admins groups, nor do they have permission to modify the accounts for members of those groups. (DOMAIN_ALIAS_RID_ACCOUNT_OPS)"
            'Name'            = 'Account Operators'
            'NTAccount'       = 'BUILTIN\DOMAIN_ALIAS_RID_ACCOUNT_OPS'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-548'
        }
        'S-1-5-32-549'                                                   = @{
            'Description'     = "A built-in local group that exists only on domain controllers. This group performs system administrative functions, not including security functions. It establishes network shares, controls printers, unlocks workstations, and performs other operations. By default, the group has no members. Server Operators can sign in to a server interactively; create and delete network shares; start and stop services; back up and restore files; format the hard disk of the computer; and shut down the computer. (DOMAIN_ALIAS_RID_SYSTEM_OPS)"
            'Name'            = 'Server Operators'
            'NTAccount'       = 'BUILTIN\DOMAIN_ALIAS_RID_SYSTEM_OPS'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-549'
        }
        'S-1-5-32-550'                                                   = @{
            'Description'     = "A built-in local group that exists only on domain controllers. This group controls printers and print queues. By default, the only member is the Domain Users group. Print Operators can manage printers and document queues. (DOMAIN_ALIAS_RID_PRINT_OPS)"
            'Name'            = 'Print Operators'
            'NTAccount'       = 'BUILTIN\DOMAIN_ALIAS_RID_PRINT_OPS'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-550'
        }
        'S-1-5-32-551'                                                   = @{
            'Description'     = "A built-in local group used for controlling assignment of file backup-and-restore privileges. Backup Operators can override security restrictions for the sole purpose of backing up or restoring files. By default, the group has no members. Backup Operators can back up and restore all files on a computer, regardless of the permissions that protect those files. Backup Operators also can sign in to the computer and shut it down. (DOMAIN_ALIAS_RID_BACKUP_OPS)"
            'Name'            = 'Backup Operators'
            'NTAccount'       = 'BUILTIN\Backup Operators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-551'
        }
        'S-1-5-32-552'                                                   = @{
            'Description'     = "A built-in local group responsible for copying security databases from the primary domain controller to the backup domain controllers by the File Replication service. By default, the group has no members. Don't add users to this group. These accounts are used only by the system. (DOMAIN_ALIAS_RID_REPLICATOR)"
            'Name'            = 'Replicators'
            'NTAccount'       = 'BUILTIN\Replicator'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-552'
        }
        'S-1-5-32-554'                                                   = @{
            'Description'     = "An alias. A local group added by Windows 2000 server and used for backward compatibility. Allows read access on all users and groups in the domain. (DOMAIN_ALIAS_RID_PREW2KCOMPACCESS)"
            'Name'            = 'Pre-Windows 2000 Compatible Access'
            'NTAccount'       = 'BUILTIN\Pre-Windows 2000 Compatible Access'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-554'
        }
        'S-1-5-32-555'                                                   = @{
            'Description'     = "An alias. A local group that represents all remote desktop users. Members are granted the right to logon remotely. (DOMAIN_ALIAS_RID_REMOTE_DESKTOP_USERS)"
            'Name'            = 'Remote Desktop Users'
            'NTAccount'       = 'BUILTIN\Remote Desktop Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-555'
        }
        'S-1-5-32-556'                                                   = @{
            'Description'     = "An alias. A local group that represents the network configuration. Members can have some administrative privileges to manage configuration of networking features. (DOMAIN_ALIAS_RID_NETWORK_CONFIGURATION_OPS)"
            'Name'            = 'Network Configuration Operators'
            'NTAccount'       = 'BUILTIN\Network Configuration Operators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-556'
        }
        'S-1-5-32-557'                                                   = @{
            'Description'     = "An alias. A local group that represents any forest trust users. Members can create incoming, one-way trusts to this forest. (DOMAIN_ALIAS_RID_INCOMING_FOREST_TRUST_BUILDERS)"
            'Name'            = 'Incoming Forest Trust Builders'
            'NTAccount'       = 'BUILTIN\Incoming Forest Trust Builders'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-557'
        }
        'S-1-5-32-558'                                                   = @{
            'Description'     = "An alias. A local group. Members can access performance counter data locally and remotely. (DOMAIN_ALIAS_RID_MONITORING_USERS)"
            'Name'            = 'Performance Monitor Users'
            'NTAccount'       = 'BUILTIN\Performance Monitor Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-558'
        }
        'S-1-5-32-559'                                                   = @{
            'Description'     = "An alias. A local group responsible for logging users. Members may schedule logging of performance counters, enable trace providers, and collect event traces both locally and via remote access to this computer. (DOMAIN_ALIAS_RID_LOGGING_USERS)"
            'Name'            = 'Performance Log Users'
            'NTAccount'       = 'BUILTIN\Performance Log Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-559'
        }
        'S-1-5-32-560'                                                   = @{
            'Description'     = "An alias. A local group that represents all authorized access. Members have access to the computed tokenGroupsGlobalAndUniversal attribute on User objects. (DOMAIN_ALIAS_RID_AUTHORIZATIONACCESS)"
            'Name'            = 'Windows Authorization Access Group'
            'NTAccount'       = 'BUILTIN\Windows Authorization Access Group'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-560'
        }
        'S-1-5-32-561'                                                   = @{
            'Description'     = "An alias. A local group that exists only on systems running server operating systems that allow for terminal services and remote access. When Windows Server 2003 Service Pack 1 is installed, a new local group is created. (DOMAIN_ALIAS_RID_TS_LICENSE_SERVERS)"
            'Name'            = 'Terminal Server License Servers'
            'NTAccount'       = 'BUILTIN\Terminal Server License Servers'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-561'
        }
        'S-1-5-32-562'                                                   = @{
            'Description'     = "An alias. A local group that represents users who can use Distributed Component Object Model (DCOM). Used by COM to provide computer-wide access controls that govern access to all call, activation, or launch requests on the computer.Members are allowed to launch, activate and use Distributed COM objects on this machine. (DOMAIN_ALIAS_RID_DCOM_USERS)"
            'Name'            = 'Distributed COM Users'
            'NTAccount'       = 'BUILTIN\Distributed COM Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-562'
        }
        'S-1-5-32-568'                                                   = @{
            'Description'     = "An alias. A built-in local group used by Internet Information Services that represents Internet users. (DOMAIN_ALIAS_RID_IUSERS)"
            'Name'            = 'IIS_IUSRS'
            'NTAccount'       = 'BUILTIN\IIS_IUSRS'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-568'
        }
        'S-1-5-32-569'                                                   = @{
            'Description'     = "A built-in local group that represents access to cryptography operators. Members are authorized to perform cryptographic operations. (DOMAIN_ALIAS_RID_CRYPTO_OPERATORS)"
            'Name'            = 'Cryptographic Operators'
            'NTAccount'       = 'BUILTIN\Cryptographic Operators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-569'
        }
        'S-1-5-32-573'                                                   = @{
            'Description'     = "A built-in local group that represents event log readers. Members can read event logs from a local computer. (DOMAIN_ALIAS_RID_EVENT_LOG_READERS_GROUP)"
            'Name'            = 'Event Log Readers'
            'SID'             = 'S-1-5-32-573'
            'NTAccount'       = 'BUILTIN\Event Log Readers'
            'SchemaClassName' = 'group'
        }
        'S-1-5-32-574'                                                   = @{
            'Description'     = "A built-in local group. Members are allowed to connect to Certification Authorities in the enterprise using Distributed Component Object Model (DCOM). (DOMAIN_ALIAS_RID_CERTSVC_DCOM_ACCESS_GROUP)"
            'Name'            = 'Certificate Service DCOM Access'
            'NTAccount'       = 'BUILTIN\Certificate Service DCOM Access'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-574'
        }
        'S-1-5-32-575'                                                   = @{
            'Description'     = "A built-in local group. Servers in this group enable users of RemoteApp programs and personal virtual desktops access to these resources. In internet-facing deployments, these servers are typically deployed in an edge network. This group needs to be populated on servers that are running RD Connection Broker. RD Gateway servers and RD Web Access servers used in the deployment need to be in this group. (DOMAIN_ALIAS_RID_RDS_REMOTE_ACCESS_SERVERS)"
            'Name'            = 'RDS Remote Access Servers'
            'NTAccount'       = 'BUILTIN\RDS Remote Access Servers'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-575'
        }
        'S-1-5-32-576'                                                   = @{
            'Description'     = "A built-in local group. Servers in this group run virtual machines and host sessions where users RemoteApp programs and personal virtual desktops run. This group needs to be populated on servers running RD Connection Broker. RD Session Host servers and RD Virtualization Host servers used in the deployment need to be in this group. (DOMAIN_ALIAS_RID_RDS_ENDPOINT_SERVERS)"
            'Name'            = 'RDS Endpoint Servers'
            'NTAccount'       = 'BUILTIN\RDS Endpoint Servers'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-576'
        }
        'S-1-5-32-577'                                                   = @{
            'Description'     = "A built-in local group. Servers in this group can perform routine administrative actions on servers running Remote Desktop Services. This group needs to be populated on all servers in a Remote Desktop Services deployment. The servers running the RDS Central Management service must be included in this group. (DOMAIN_ALIAS_RID_RDS_MANAGEMENT_SERVERS)"
            'Name'            = 'RDS Management Servers'
            'NTAccount'       = 'BUILTIN\RDS Management Servers'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-577'
        }
        'S-1-5-32-578'                                                   = @{
            'Description'     = "A built-in local group. Members have complete and unrestricted access to all features of Hyper-V. (DOMAIN_ALIAS_RID_HYPER_V_ADMINS)"
            'Name'            = 'Hyper-V Administrators'
            'NTAccount'       = 'BUILTIN\Hyper-V Administrators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-578'
        }
        'S-1-5-32-579'                                                   = @{
            'Description'     = "A built-in local group. Members can remotely query authorization attributes and permissions for resources on this computer. (DOMAIN_ALIAS_RID_ACCESS_CONTROL_ASSISTANCE_OPS)"
            'Name'            = 'Access Control Assistance Operators'
            'NTAccount'       = 'BUILTIN\Access Control Assistance Operators'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-579'
        }
        'S-1-5-32-580'                                                   = @{
            'Description'     = "A built-in local group. Members can access Windows Management Instrumentation (WMI) resources over management protocols (such as WS-Management via the Windows Remote Management service). This applies only to WMI namespaces that grant access to the user. (DOMAIN_ALIAS_RID_REMOTE_MANAGEMENT_USERS)"
            'Name'            = 'Remote Management Users'
            'NTAccount'       = 'BUILTIN\Remote Management Users'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-580'
        }
        'S-1-5-64-10'                                                    = @{
            'Description'     = "A SID that's used when the NTLM authentication package authenticates the client."
            'Name'            = 'NTLM Authentication'
            'NTAccount'       = 'NT AUTHORITY\NTLM Authentication'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-64-10'
        }
        'S-1-5-64-14'                                                    = @{
            'Description'     = "A SID that's used when the SChannel authentication package authenticates the client."
            'Name'            = 'SChannel Authentication'
            'NTAccount'       = 'NT AUTHORITY\SChannel Authentication'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-64-14'
        }
        'S-1-5-64-21'                                                    = @{
            'Description'     = "A SID that's used when the Digest authentication package authenticates the client."
            'Name'            = 'Digest Authentication'
            'NTAccount'       = 'NT AUTHORITY\Digest Authentication'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-64-21'
        }
        'S-1-5-80'                                                       = @{
            'Description'     = "A SID that's used as an NT Service account prefix."
            'Name'            = 'NT Service'
            'NTAccount'       = 'NT AUTHORITY\NT Service'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-5-80'
        }
        'S-1-5-80-0'                                                     = @{
            'Description'     = "A group that includes all service processes that are configured on the system. Membership is controlled by the operating system. This SID was introduced in Windows Server 2008 R2."
            'Name'            = 'All Services'
            'NTAccount'       = 'NT SERVICE\ALL SERVICES'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-80-0'
        }
        'S-1-5-83-0'                                                     = @{
            'Description'     = "A built-in group. The group is created when the Hyper-V role is installed. Membership in the group is maintained by the Hyper-V Management Service (VMMS). This group requires the Create Symbolic Links right (SeCreateSymbolicLinkPrivilege) and the Log on as a Service right (SeServiceLogonRight)."
            'Name'            = 'Virtual Machines'
            'NTAccount'       = 'NT VIRTUAL MACHINE\Virtual Machines'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-83-0'
        }
        'S-1-5-113'                                                      = @{
            'Description'     = "You can use this SID when you're restricting network sign-in to local accounts instead of 'administrator' or equivalent. This SID can be effective in blocking network sign-in for local users and groups by account type regardless of what they're named."
            'Name'            = 'Local account'
            'NTAccount'       = 'NT AUTHORITY\Local account'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-113'
        }
        'S-1-5-114'                                                      = @{
            'Description'     = "You can use this SID when you're restricting network sign-in to local accounts instead of 'administrator' or equivalent. This SID can be effective in blocking network sign-in for local users and groups by account type regardless of what they're named."
            'Name'            = 'Local account and member of Administrators group'
            'NTAccount'       = 'NT AUTHORITY\Local account and member of Administrators group'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-114'
        }

        <#
        https://devblogs.microsoft.com/oldnewthing/20220502-00/?p=106550
        SIDs of the form S-1-15-2-xxx are app container SIDs.
        These SIDs are present in the token of apps running in an app container, and they encode the app container identity.
        According to the rules for Mandatory Integrity Control, objects default to allowing write access only to medium integrity level (IL) or higher.
        App containers run at low IL, so they by default don’t have write access to such objects.
            An object can add access control entries (ACEs) to its access control list (ACL) to grant access to low IL.
            There are a few security identifiers (SIDs) you may see when an object extends access to low IL.
            #>
        'S-1-15-2-1'                                                     = @{
            'Description'     = 'All applications running in an app package context have this app container SID. SECURITY_BUILTIN_PACKAGE_ANY_PACKAGE'
            'Name'            = 'ALL APPLICATION PACKAGES'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\ALL APPLICATION PACKAGES'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-2-1'
        }
        'S-1-15-2-2'                                                     = @{
            'Description'     = 'Some applications running in an app package context may have this app container SID. SECURITY_BUILTIN_PACKAGE_ANY_RESTRICTED_PACKAGE'
            'Name'            = 'ALL RESTRICTED APPLICATION PACKAGES'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\ALL RESTRICTED APPLICATION PACKAGES'
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
        'S-1-15-3-1'                                                     = @{
            'Description'     = 'internetClient containerized app capability SID'
            'Name'            = 'Your Internet connection'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your Internet connection'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-1'
        }
        'S-1-15-3-2'                                                     = @{
            'Description'     = 'internetClientServer containerized app capability SID'
            'Name'            = 'Your Internet connection, including incoming connections from the Internet'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your Internet connection, including incoming connections from the Internet'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-2'
        }
        'S-1-15-3-3'                                                     = @{
            'Description'     = 'privateNetworkClientServer containerized app capability SID'
            'Name'            = 'Your home or work networks'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your home or work networks'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-3'
        }
        'S-1-15-3-4'                                                     = @{
            'Description'     = 'picturesLibrary containerized app capability SID'
            'Name'            = 'Your pictures library'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your pictures library'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-4'
        }
        'S-1-15-3-5'                                                     = @{
            'Description'     = 'videosLibrary containerized app capability SID'
            'Name'            = 'Your videos library'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your videos library'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-5'
        }
        'S-1-15-3-6'                                                     = @{
            'Description'     = 'musicLibrary containerized app capability SID'
            'Name'            = 'Your music library'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your music library'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-6'
        }
        'S-1-15-3-7'                                                     = @{
            'Description'     = 'documentsLibrary containerized app capability SID'
            'Name'            = 'Your documents library'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your documents library'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-7'
        }
        'S-1-15-3-8'                                                     = @{
            'Description'     = 'enterpriseAuthentication containerized app capability SID'
            'Name'            = 'Your Windows credentials'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your Windows credentials'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-8'
        }
        'S-1-15-3-9'                                                     = @{
            'Description'     = 'sharedUserCertificates containerized app capability SID'
            'Name'            = 'Software and hardware certificates or a smart card'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Software and hardware certificates or a smart card'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-9'
        }
        'S-1-15-3-10'                                                    = @{
            'Description'     = 'removableStorage containerized app capability SID'
            'Name'            = 'Removable storage'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Removable storage'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-10'
        }
        'S-1-15-3-11'                                                    = @{
            'Description'     = 'appointments containerized app capability SID'
            'Name'            = 'Your Appointments'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your Appointments'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-11'
        }
        'S-1-15-3-12'                                                    = @{
            'Description'     = 'contacts containerized app capability SID'
            'Name'            = 'Your Contacts'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\Your Contacts'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-12'
        }
        'S-1-15-3-4096'                                                  = @{
            'Description'     = 'internetExplorer containerized app capability SID'
            'Name'            = 'internetExplorer'
            'NTAccount'       = 'APPLICATION PACKAGE AUTHORITY\internetExplorer'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-15-3-4096'
        }
        <#Other known SIDs#>
        'S-1-5-80-242729624-280608522-2219052887-3187409060-2225943459'  = @{
            'Description'     = 'Windows Cryptographic service account'
            'Name'            = 'CryptSvc'
            'NTAccount'       = 'NT SERVICE\CryptSvc'
            'SchemaClassName' = 'service'
            'SID'             = 'S-1-5-80-242729624-280608522-2219052887-3187409060-2225943459'
        }
        'S-1-5-80-3139157870-2983391045-3678747466-658725712-1809340420' = @{
            'Description'     = 'Windows Diagnostics service account'
            'Name'            = 'WdiServiceHost'
            'NTAccount'       = 'NT SERVICE\WdiServiceHost'
            'SchemaClassName' = 'service'
            'SID'             = 'S-1-5-80-3139157870-2983391045-3678747466-658725712-1809340420'
        }
        'S-1-5-80-880578595-1860270145-482643319-2788375705-1540778122'  = @{
            'Description'     = 'Windows Event Log service account'
            'Name'            = 'EventLog'
            'NTAccount'       = 'NT SERVICE\EventLog'
            'SchemaClassName' = 'user'
            'SID'             = 'service'
        }
        'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464' = @{
            'Description'     = 'Most of the operating system files are owned by the TrustedInstaller security identifier (SID)'
            'Name'            = 'TrustedInstaller'
            'NTAccount'       = 'NT SERVICE\TrustedInstaller'
            'SchemaClassName' = 'service'
            'SID'             = 'S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'
        }
        <#
        The following table has examples of domain-relative RIDs that you can use to form well-known SIDs for local groups (aliases). For more information about local and global groups, see Local Group Functions and Group Functions.
        #>
        'S-1-5-32-553'                                                   = @{
            'Name'            = 'DOMAIN_ALIAS_RID_RAS_SERVERS'
            'NTAccount'       = 'BUILTIN\DOMAIN_ALIAS_RID_RAS_SERVERS'
            'Description'     = 'A local group that represents RAS and IAS servers. This group permits access to various attributes of user objects. (DOMAIN_ALIAS_RID_RAS_SERVERS)'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-553'
        }
        'S-1-5-32-571'                                                   = @{
            'Name'            = 'DOMAIN_ALIAS_RID_CACHEABLE_PRINCIPALS_GROUP'
            'NTAccount'       = 'BUILTIN\DOMAIN_ALIAS_RID_CACHEABLE_PRINCIPALS_GROUP'
            'Description'     = 'A local group that represents principals that can be cached. (DOMAIN_ALIAS_RID_CACHEABLE_PRINCIPALS_GROUP)'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-571'
        }
        'S-1-5-32-572'                                                   = @{
            'Name'            = 'DOMAIN_ALIAS_RID_NON_CACHEABLE_PRINCIPALS_GROUP'
            'NTAccount'       = 'BUILTIN\DOMAIN_ALIAS_RID_NON_CACHEABLE_PRINCIPALS_GROUP'
            'Description'     = 'A local group that represents principals that cannot be cached. (DOMAIN_ALIAS_RID_NON_CACHEABLE_PRINCIPALS_GROUP)'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-572'
        }
        'S-1-5-32-581'                                                   = @{
            'Name'            = 'System Managed Accounts Group'
            'NTAccount'       = 'BUILTIN\System Managed Accounts Group'
            'Description'     = 'Members are managed by the system. A local group that represents the default account. (DOMAIN_ALIAS_RID_DEFAULT_ACCOUNT)'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-581'
        }
        'S-1-5-32-582'                                                   = @{
            'Name'            = 'DOMAIN_ALIAS_RID_STORAGE_REPLICA_ADMINS'
            'NTAccount'       = 'BUILTIN\DOMAIN_ALIAS_RID_STORAGE_REPLICA_ADMINS'
            'Description'     = 'A local group that represents storage replica admins. (DOMAIN_ALIAS_RID_STORAGE_REPLICA_ADMINS)'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-582'
        }
        'S-1-5-32-583'                                                   = @{
            'Name'            = 'DOMAIN_ALIAS_RID_DEVICE_OWNERS'
            'NTAccount'       = 'BUILTIN\Device Owners'
            'Description'     = 'A local group that represents can make settings expected for Device Owners. (DOMAIN_ALIAS_RID_DEVICE_OWNERS)'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-5-32-583'
        }
        # Additional SIDs found on local machine via discovery
        'S-1-2-0'                                                        = @{
            'Name'            = 'LOCAL'
            'Description'     = 'Users who sign in to terminals that are locally (physically) connected to the system.'
            'NTAccount'       = 'LOCAL SID AUTHORITY\LOCAL'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-2-0'
        }
        'S-1-3-1'                                                        = @{
            'Name'            = 'CREATOR GROUP'
            'Description'     = 'A security identifier to be replaced by the primary-group SID of the user who created a new object. Use this SID in inheritable ACEs.'
            'NTAccount'       = 'CREATOR SID AUTHORITY\CREATOR GROUP'
            'SchemaClassName' = 'group'
            'SID'             = 'S-1-3-1'
        }
        'S-1-3-2'                                                        = @{
            'Name'            = 'CREATOR OWNER SERVER'
            'Description'     = "A placeholder in an inheritable ACE. When the ACE is inherited, the system replaces this SID with the SID for the object's owner server and stores information about who created a given object or file."
            'NTAccount'       = 'CREATOR SID AUTHORITY\CREATOR OWNER SERVER'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-3-2'
        }
        'S-1-3-3'                                                        = @{
            'Name'            = 'CREATOR GROUP SERVER'
            'Description'     = "A placeholder in an inheritable ACE. When the ACE is inherited, the system replaces this SID with the SID for the object's group server and stores information about the groups that are allowed to work with the object."
            'NTAccount'       = 'CREATOR SID AUTHORITY\CREATOR GROUP SERVER'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-3-3'
        }
        'S-1-3-4'                                                        = @{
            'Name'            = 'OWNER RIGHTS'
            'Description'     = 'A group that represents the current owner of the object. When an ACE that carries this SID is applied to an object, the system ignores the implicit READ_CONTROL and WRITE_DAC permissions for the object owner.'
            'NTAccount'       = 'CREATOR SID AUTHORITY\OWNER RIGHTS'
            'SchemaClassName' = 'user'
            'SID'             = 'S-1-3-4'
        }
        'S-1-5-32'                                                       = @{
            'Name'            = 'BUILTIN'
            'Description'     = 'NT AUTHORITY\BUILTIN'
            'NTAccount'       = 'NT AUTHORITY\BUILTIN'
            'SchemaClassName' = 'computer'
            'SID'             = 'S-1-5-32'
        }
        'S-1-5-80-1594061079-2000966165-462148798-751814865-2644087104'  = @{
            'Name'            = 'LxpSvc'
            'Description'     = 'Used by the Language Experience Service to provide support for deploying and configuring localized Windows resources.'
            'NTAccount'       = 'NT SERVICE\LxpSvc'
            'SchemaClassName' = 'service'
            'SID'             = 'S-1-5-80-1594061079-2000966165-462148798-751814865-2644087104'
        }
        'S-1-5-80-4230913304-2206818457-801678004-120036174-1892434133'  = @{
            'Name'            = 'TapiSrv'
            'NTAccount'       = 'NT SERVICE\TapiSrv'
            'Description'     = 'Used by the TAPI server to provide the central repository of telephony on data on a computer.'
            'SchemaClassName' = 'service'
            'SID'             = 'S-1-5-80-4230913304-2206818457-801678004-120036174-1892434133'
        }
    }
}


<#
COMPUTER-SPECIFIC SIDs


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
