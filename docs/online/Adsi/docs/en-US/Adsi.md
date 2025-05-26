---
Module Name: Adsi
Module Guid: 282a2aed-9567-49a1-901c-122b7831a805
Download Help Link: {{ Update Download Link }}
Help Version: 5.0.102
Locale: en-US
---

# Adsi Module
## Description
Use Active Directory Service Interfaces to query LDAP and WinNT directories

## Adsi Cmdlets
### [Add-DomainFqdnToLdapPath]Add-DomainFqdnToLdapPath
Add a domain FQDN to an LDAP directory path as the server address so the new path can be used for remote queries

### [Add-SidInfo]Add-SidInfo
Add some useful properties to a DirectoryEntry object for easier access

### [ConvertFrom-DirectoryEntry]ConvertFrom-DirectoryEntry
Convert a DirectoryEntry to a PSCustomObject

### [ConvertFrom-PropertyValueCollectionToString]ConvertFrom-PropertyValueCollectionToString
Convert a PropertyValueCollection to a string

### [ConvertFrom-ResolvedID]ConvertFrom-ResolvedID
Use ADSI to collect more information about the IdentityReference in NTFS Access Control Entries

### [ConvertFrom-ResultPropertyValueCollectionToString]ConvertFrom-ResultPropertyValueCollectionToString
Convert a ResultPropertyValueCollection to a string

### [ConvertFrom-SearchResult]ConvertFrom-SearchResult
Convert a SearchResult to a PSCustomObject

### [ConvertFrom-SidString]ConvertFrom-SidString
Converts a SID string to a DirectoryEntry object.

### [ConvertTo-DecStringRepresentation]ConvertTo-DecStringRepresentation
Convert a byte array to a string representation of its decimal format

### [ConvertTo-DistinguishedName]ConvertTo-DistinguishedName
Convert a domain NetBIOS name to its distinguishedName

### [ConvertTo-DomainNetBIOS]ConvertTo-DomainNetBIOS
Converts a domain FQDN to its NetBIOS name.

### [ConvertTo-DomainSidString]ConvertTo-DomainSidString
Converts a domain DNS name to its corresponding SID string.

### [ConvertTo-Fqdn]ConvertTo-Fqdn
Convert a domain distinguishedName name or NetBIOS name to its FQDN

### [ConvertTo-HexStringRepresentation]ConvertTo-HexStringRepresentation
Convert a SID from byte array format to a string representation of its hexadecimal format

### [ConvertTo-HexStringRepresentationForLDAPFilterString]ConvertTo-HexStringRepresentationForLDAPFilterString
Convert a SID from byte array format to a string representation of its hexadecimal format, properly formatted for an LDAP filter string

### [ConvertTo-SidByteArray]ConvertTo-SidByteArray
Convert a SID from a string to binary format byte array)

### [Expand-AdsiGroupMember](Expand-AdsiGroupMember
Use the LDAP provider to add information about group members to a DirectoryEntry of a group for easier access

### [Expand-WinNTGroupMember]Expand-WinNTGroupMember
Use the LDAP provider to add information about group members to a DirectoryEntry of a group for easier access

### [Find-LocalAdsiServerSid]Find-LocalAdsiServerSid
Finds the SID prefix of the local server by querying the built-in administrator account.

### [Get-AdsiGroup]Get-AdsiGroup
Get the directory entries for a group and its members using ADSI

### [Get-AdsiGroupMember]Get-AdsiGroupMember
Get members of a group from the LDAP provider

### [Get-AdsiServer]Get-AdsiServer
Get information about a directory server including the ADSI provider it hosts and its well-known SIDs

### [Get-CurrentDomain]Get-CurrentDomain
Use ADSI to get the current domain

### [Get-DirectoryEntry]Get-DirectoryEntry
Use Active Directory Service Interfaces to retrieve an object from a directory

### [Get-KnownCaptionHashTable]Get-KnownCaptionHashTable
Creates a hashtable of well-known SIDs indexed by their NT Account names (captions).

### [Get-KnownSid]Get-KnownSid
Retrieves information about well-known security identifiers (SIDs).

### [Get-KnownSidByName]Get-KnownSidByName
Creates a hashtable of well-known SIDs indexed by their friendly names.

### [Get-KnownSidHashtable]Get-KnownSidHashtable
Returns a hashtable of known security identifiers (SIDs) with detailed information.

### [Get-ParentDomainDnsName]Get-ParentDomainDnsName
Gets the DNS name of the parent domain for a given computer or domain.

### [Get-TrustedDomain]Get-TrustedDomain
Returns a dictionary of trusted domains by the current computer

### [Get-WinNTGroupMember]Get-WinNTGroupMember
Get members of a group from the WinNT provider

### [Invoke-ComObject]Invoke-ComObject
Invoke a member method of a ComObject [__ComObject]

### [New-FakeDirectoryEntry]New-FakeDirectoryEntry
Creates a fake DirectoryEntry object for security principals that don't have objects in the directory.

### [Resolve-IdentityReference]Resolve-IdentityReference
Use CIM and ADSI to lookup info about IdentityReferences from Access Control Entries that came from Discretionary Access Control Lists

### [Resolve-ServiceNameToSID]Resolve-ServiceNameToSID
Resolves Windows service names to their corresponding security identifiers (SIDs).

### [Search-Directory]Search-Directory
Use Active Directory Service Interfaces to search an LDAP directory



