---
Module Name: Adsi
Module Guid: 282a2aed-9567-49a1-901c-122b7831a805 282a2aed-9567-49a1-901c-122b7831a805
Download Help Link: {{ Update Download Link }}
Help Version: 3.0.39
Locale: en-US
---

# Adsi Module
## Description
Use Active Directory Service Interfaces to query LDAP and WinNT directories

## Adsi Cmdlets
### [Add-DomainFqdnToLdapPath](Add-DomainFqdnToLdapPath.md)
Add a domain FQDN to an LDAP directory path as the server address so the new path can be used for remote queries

### [Add-SidInfo](Add-SidInfo.md)
Add some useful properties to a DirectoryEntry object for easier access

### [ConvertFrom-DirectoryEntry](ConvertFrom-DirectoryEntry.md)
Convert a DirectoryEntry to a PSCustomObject

### [ConvertFrom-PropertyValueCollectionToString](ConvertFrom-PropertyValueCollectionToString.md)
Convert a PropertyValueCollection to a string

### [ConvertTo-DecStringRepresentation](ConvertTo-DecStringRepresentation.md)
Convert a byte array to a string representation of its decimal format

### [ConvertTo-DistinguishedName](ConvertTo-DistinguishedName.md)
Convert a domain NetBIOS name to its distinguishedName

### [ConvertTo-DomainNetBIOS](ConvertTo-DomainNetBIOS.md)

ConvertTo-DomainNetBIOS [[-DomainFQDN] <string>] [[-AdsiProvider] <string>] [[-DirectoryEntryCache] <hashtable>] [[-DomainsByNetbios] <hashtable>] [[-DomainsBySid] <hashtable>] [[-DomainsByFqdn] <hashtable>] [[-ThisHostName] <string>]


### [ConvertTo-DomainSidString](ConvertTo-DomainSidString.md)

ConvertTo-DomainSidString [-DomainDnsName] <string> [[-DirectoryEntryCache] <hashtable>] [[-DomainsByNetbios] <hashtable>] [[-DomainsBySid] <hashtable>] [[-DomainsByFqdn] <hashtable>] [[-AdsiProvider] <string>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [<CommonParameters>]


### [ConvertTo-Fqdn](ConvertTo-Fqdn.md)
Convert a domain distinguishedName name or NetBIOS name to its FQDN

### [ConvertTo-HexStringRepresentation](ConvertTo-HexStringRepresentation.md)
Convert a SID from byte array format to a string representation of its hexadecimal format

### [ConvertTo-HexStringRepresentationForLDAPFilterString](ConvertTo-HexStringRepresentationForLDAPFilterString.md)
Convert a SID from byte array format to a string representation of its hexadecimal format, properly formatted for an LDAP filter string

### [ConvertTo-SidByteArray](ConvertTo-SidByteArray.md)
Convert a SID from a string to binary format (byte array)

### [Expand-AdsiGroupMember](Expand-AdsiGroupMember.md)
Use the LDAP provider to add information about group members to a DirectoryEntry of a group for easier access

### [Expand-IdentityReference](Expand-IdentityReference.md)
Use ADSI to collect more information about the IdentityReference in NTFS Access Control Entries

### [Expand-WinNTGroupMember](Expand-WinNTGroupMember.md)
Use the LDAP provider to add information about group members to a DirectoryEntry of a group for easier access

### [Find-AdsiProvider](Find-AdsiProvider.md)
Determine whether a directory server is an LDAP or a WinNT server

### [Find-LocalAdsiServerSid](Find-LocalAdsiServerSid.md)

Find-LocalAdsiServerSid [[-ComputerName] <string>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>]


### [Get-ADSIGroup](Get-ADSIGroup.md)
Get the directory entries for a group and its members using ADSI

### [Get-ADSIGroupMember](Get-ADSIGroupMember.md)
Get members of a group from the LDAP provider

### [Get-AdsiServer](Get-AdsiServer.md)
Get information about a directory server including the ADSI provider it hosts and its well-known SIDs

### [Get-CurrentDomain](Get-CurrentDomain.md)
Use ADSI to get the current domain

### [Get-DirectoryEntry](Get-DirectoryEntry.md)
Use Active Directory Service Interfaces to retrieve an object from a directory

### [Get-TrustedDomain](Get-TrustedDomain.md)
Returns a dictionary of trusted domains by the current computer

### [Get-Win32Account](Get-Win32Account.md)
Use CIM to get well-known SIDs

### [Get-Win32UserAccount](Get-Win32UserAccount.md)

Get-Win32UserAccount [[-ComputerName] <string>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>]


### [Get-WinNTGroupMember](Get-WinNTGroupMember.md)
Get members of a group from the WinNT provider

### [Invoke-ComObject](Invoke-ComObject.md)
Invoke a member method of a ComObject [__ComObject]

### [New-FakeDirectoryEntry](New-FakeDirectoryEntry.md)
Returns a PSCustomObject in place of a DirectoryEntry for certain WinNT security principals that do not have objects in the directory

### [Resolve-Ace](Resolve-Ace.md)
Use ADSI to lookup info about IdentityReferences from Authorization Rule Collections that came from Discretionary Access Control Lists

### [Resolve-Ace3](Resolve-Ace3.md)
Use ADSI to lookup info about IdentityReferences from Authorization Rule Collections that came from Discretionary Access Control Lists

### [Resolve-Ace4](Resolve-Ace4.md)
Use ADSI to lookup info about IdentityReferences from Authorization Rule Collections that came from Discretionary Access Control Lists

### [Resolve-IdentityReference](Resolve-IdentityReference.md)
Use ADSI to lookup info about IdentityReferences from Access Control Entries that came from Discretionary Access Control Lists

### [Search-Directory](Search-Directory.md)
Use Active Directory Service Interfaces to search an LDAP directory


