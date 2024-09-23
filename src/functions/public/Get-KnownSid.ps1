

function Get-KnownSid {
    #https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/81d92bba-d22b-4a8c-908a-554ab29148ab
    #https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-identifiers
    param ([string]$SID)
    switch -regex ($SID) {
        'S-1-15-2-' {
            return @{
                'Name'            = "App Container $SID"
                'Description'     = "App Container $SID"
                'NTAccount'       = "APPLICATION PACKAGE AUTHORITY\App Container $SID"
                'SchemaClassName' = 'user'
                'SID'             = $SID
            }
        }
        'S-1-15-3-' {
            return ConvertFrom-AppCapabilitySid -SID $IdentityReference
        }
        'S-1-5-5-(?<Session>[^-]-[^-])' {
            return @{
                'Name'            = 'Logon Session'
                'Description'     = "Sign-in session $($Matches.Session)"
                'NTAccount'       = 'BUILTIN\Logon Session'
                'SchemaClassName' = 'user'
                'SID'             = $SID
            }
        }
        'S-1-5-(?<Domain>.*)-500' {
            return @{
                'Name'            = 'Administrator'
                'Description'     = "A built-in user account for the system administrator to administer the computer/domain. Every computer has a local Administrator account and every domain has a domain Administrator account. The Administrator account is the first account created during operating system installation. The account can't be deleted, disabled, or locked out, but it can be renamed. By default, the Administrator account is a member of the Administrators group, and it can't be removed from that group."
                'NTAccount'       = 'BUILTIN\Administrator'
                'SchemaClassName' = 'user'
                'SID'             = $SID
            }
        }
        'S-1-5-(?<Domain>.*)-501' {
            return @{
                'Name'            = 'Guest'
                'Description'     = "A user account for people who don't have individual accounts. Every computer has a local Guest account, and every domain has a domain Guest account. By default, Guest is a member of the Everyone and the Guests groups. The domain Guest account is also a member of the Domain Guests and Domain Users groups. Unlike Anonymous Logon, Guest is a real account, and it can be used to sign in interactively. The Guest account doesn't require a password, but it can have one."
                'NTAccount'       = 'BUILTIN\Guest'
                'SchemaClassName' = 'user'
                'SID'             = $SID
            }
        }
        'S-1-5-(?<Domain>.*)-502' {
            return @{
                'Name'            = 'KRBTGT'
                'Description'     = "Kerberos Ticket-Generating Ticket account: a user account that's used by the Key Distribution Center (KDC) service. The account exists only on domain controllers."
                'NTAccount'       = 'BUILTIN\KRBTGT'
                'SchemaClassName' = 'user'
                'SID'             = $SID
            }
        }
        'S-1-5-(?<Domain>.*)-512' {
            return @{
                'Name'            = 'Domain Admins'
                'Description'     = "A global group with members that are authorized to administer the domain. By default, the Domain Admins group is a member of the Administrators group on all computers that have joined the domain, including domain controllers. Domain Admins is the default owner of any object that's created in the domain's Active Directory by any member of the group. If members of the group create other objects, such as files, the default owner is the Administrators group."
                'NTAccount'       = 'BUILTIN\Domain Admins'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-(?<Domain>.*)-513' {
            return @{
                'Name'            = 'Domain Users'
                'Description'     = "A global group that includes all users in a domain. When you create a new User object in Active Directory, the user is automatically added to this group."
                'NTAccount'       = 'BUILTIN\Domain Users'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-(?<Domain>.*)-514' {
            return @{
                'Name'            = 'Domain Guests'
                'Description'     = "A global group that, by default, has only one member: the domain's built-in Guest account."
                'NTAccount'       = 'BUILTIN\Domain Guests'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-(?<Domain>.*)-515' {
            return @{
                'Name'            = 'Domain Computers'
                'Description'     = "A global group that includes all computers that have joined the domain, excluding domain controllers."
                'NTAccount'       = 'BUILTIN\Domain Computers'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-(?<Domain>.*)-516' {
            return @{
                'Name'            = 'Domain Controllers'
                'Description'     = "A global group that includes all domain controllers in the domain. New domain controllers are added to this group automatically."
                'NTAccount'       = 'BUILTIN\Domain Controllers'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-(?<Domain>.*)-517' {
            return @{
                'Name'            = 'Cert Publishers'
                'Description'     = "A global group that includes all computers that host an enterprise certification authority. Cert Publishers are authorized to publish certificates for User objects in Active Directory."
                'NTAccount'       = 'BUILTIN\Cert Publishers'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-root domain-518' {
            return @{
                'Name'            = 'Schema Admins'
                'Description'     = "A group that exists only in the forest root domain. It's a universal group if the domain is in native mode, and it's a global group if the domain is in mixed mode. The Schema Admins group is authorized to make schema changes in Active Directory. By default, the only member of the group is the Administrator account for the forest root domain."
                'NTAccount'       = 'BUILTIN\Schema Admins'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-root domain-519' {
            return @{
                'Name'            = 'Enterprise Admins'
                'Description'     = "A group that exists only in the forest root domain. It's a universal group if the domain is in native mode, and it's a global group if the domain is in mixed mode. The Enterprise Admins group is authorized to make changes to the forest infrastructure, such as adding child domains, configuring sites, authorizing DHCP servers, and installing enterprise certification authorities. By default, the only member of Enterprise Admins is the Administrator account for the forest root domain. The group is a default member of every Domain Admins group in the forest."
                'NTAccount'       = 'BUILTIN\Enterprise Admins'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-(?<Domain>.*)-520' {
            return @{
                'Name'            = 'Group Policy Creator Owners'
                'Description'     = "A global group that's authorized to create new Group Policy Objects in Active Directory. By default, the only member of the group is Administrator. Objects that are created by members of Group Policy Creator Owners are owned by the individual user who creates them. In this way, the Group Policy Creator Owners group is unlike other administrative groups (such as Administrators and Domain Admins). Objects that are created by members of these groups are owned by the group rather than by the individual."
                'NTAccount'       = 'BUILTIN\Group Policy Creator Owners'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-(?<Domain>.*)-521' {
            return @{
                'Name'            = 'Read-only Domain Controllers'
                'Description'     = "A global group that includes all read-only domain controllers."
                'NTAccount'       = 'BUILTIN\Read-only Domain Controllers'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-(?<Domain>.*)-522' {
            return @{
                'Name'            = 'Clonable Controllers'
                'Description'     = "A global group that includes all domain controllers in the domain that can be cloned."
                'NTAccount'       = 'BUILTIN\Clonable Controllers'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-(?<Domain>.*)-525' {
            return @{
                'Name'            = 'Protected Users'
                'Description'     = "A global group that is afforded additional protections against authentication security threats."
                'NTAccount'       = 'BUILTIN\Protected Users'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-root domain-526' {
            return @{
                'Name'            = 'Key Admins'
                'Description'     = "This group is intended for use in scenarios where trusted external authorities are responsible for modifying this attribute. Only trusted administrators should be made a member of this group."
                'NTAccount'       = 'BUILTIN\Key Admins'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-(?<Domain>.*)-527' {
            return @{
                'Name'            = 'Enterprise Key Admins'
                'Description'     = "This group is intended for use in scenarios where trusted external authorities are responsible for modifying this attribute. Only trusted enterprise administrators should be made a member of this group."
                'NTAccount'       = 'BUILTIN\Enterprise Key Admins'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-(?<Domain>.*)-553' {
            return @{
                'Name'            = 'RAS and IAS Servers'
                'Description'     = "A local domain group. By default, this group has no members. Computers that are running the Routing and Remote Access service are added to the group automatically. Members have access to certain properties of User objects, such as Read Account Restrictions, Read Logon Information, and Read Remote Access Information."
                'NTAccount'       = 'BUILTIN\RAS and IAS Servers'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-(?<Domain>.*)-571' {
            return @{
                'Name'            = 'Allowed RODC Password Replication Group'
                'Description'     = "Members in this group can have their passwords replicated to all read-only domain controllers in the domain."
                'NTAccount'       = 'BUILTIN\Allowed RODC Password Replication Group'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        'S-1-5-(?<Domain>.*)-572' {
            return @{
                'Name'            = 'Denied RODC Password Replication Group'
                'Description'     = "Members in this group can't have their passwords replicated to all read-only domain controllers in the domain."
                'NTAccount'       = 'BUILTIN\Denied RODC Password Replication Group'
                'SchemaClassName' = 'group'
                'SID'             = $SID
            }
        }
        default {
            return @{
                'Name'            = $SID
                'Description'     = $SID
                'NTAccount'       = $SID
                'SchemaClassName' = 'unknown'
                'SID'             = $SID
            }
        }
    }
}
