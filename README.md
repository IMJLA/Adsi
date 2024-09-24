---
Module Name: Adsi
Module Guid: 282a2aed-9567-49a1-901c-122b7831a805 282a2aed-9567-49a1-901c-122b7831a805
Download Help Link: {{ Update Download Link }}
Help Version: 4.0.153
Locale: en-US
---

# Adsi Module
## Description
Use Active Directory Service Interfaces to query LDAP and WinNT directories

## Adsi Cmdlets
### [Add-DomainFqdnToLdapPath](docs/en-US/Add-DomainFqdnToLdapPath.md)
Add a domain FQDN to an LDAP directory path as the server address so the new path can be used for remote queries

### [Add-SidInfo](docs/en-US/Add-SidInfo.md)
Add some useful properties to a DirectoryEntry object for easier access

### [ConvertFrom-DirectoryEntry](docs/en-US/ConvertFrom-DirectoryEntry.md)
Convert a DirectoryEntry to a PSCustomObject

### [ConvertFrom-IdentityReferenceResolved](docs/en-US/ConvertFrom-IdentityReferenceResolved.md)
Use ADSI to collect more information about the IdentityReference in NTFS Access Control Entries

### [ConvertFrom-PropertyValueCollectionToString](docs/en-US/ConvertFrom-PropertyValueCollectionToString.md)
Convert a PropertyValueCollection to a string

### [ConvertFrom-ResultPropertyValueCollectionToString](docs/en-US/ConvertFrom-ResultPropertyValueCollectionToString.md)
Convert a ResultPropertyValueCollection to a string

### [ConvertFrom-SearchResult](docs/en-US/ConvertFrom-SearchResult.md)
Convert a SearchResult to a PSCustomObject

### [ConvertFrom-SidString](docs/en-US/ConvertFrom-SidString.md)

ConvertFrom-SidString [[-SID] <string>] [[-DebugOutputStream] <string>] [[-CimCache] <hashtable>] [[-DirectoryEntryCache] <hashtable>] [[-DomainsByNetbios] <hashtable>] [[-DomainsBySid] <hashtable>] [[-DomainsByFqdn] <hashtable>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogBuffer] <hashtable>]


### [ConvertTo-DecStringRepresentation](docs/en-US/ConvertTo-DecStringRepresentation.md)
Convert a byte array to a string representation of its decimal format

### [ConvertTo-DistinguishedName](docs/en-US/ConvertTo-DistinguishedName.md)
Convert a domain NetBIOS name to its distinguishedName

### [ConvertTo-DomainNetBIOS](docs/en-US/ConvertTo-DomainNetBIOS.md)

ConvertTo-DomainNetBIOS [[-DomainFQDN] <string>] [[-AdsiProvider] <string>] [[-CimCache] <hashtable>] [[-DirectoryEntryCache] <hashtable>] [[-DomainsByNetbios] <hashtable>] [[-DomainsBySid] <hashtable>] [[-DomainsByFqdn] <hashtable>] [[-ThisFqdn] <string>] [[-ThisHostName] <string>] [[-WhoAmI] <string>] [[-LogBuffer] <hashtable>] [[-DebugOutputStream] <string>]


### [ConvertTo-DomainSidString](docs/en-US/ConvertTo-DomainSidString.md)

ConvertTo-DomainSidString [-DomainDnsName] <string> [[-DirectoryEntryCache] <hashtable>] [[-DomainsByNetbios] <hashtable>] [[-DomainsBySid] <hashtable>] [[-DomainsByFqdn] <hashtable>] [[-AdsiProvider] <string>] [[-CimCache] <hashtable>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogBuffer] <hashtable>] [[-DebugOutputStream] <string>] [<CommonParameters>]


### [ConvertTo-Fqdn](docs/en-US/ConvertTo-Fqdn.md)
Convert a domain distinguishedName name or NetBIOS name to its FQDN

### [ConvertTo-HexStringRepresentation](docs/en-US/ConvertTo-HexStringRepresentation.md)
Convert a SID from byte array format to a string representation of its hexadecimal format

### [ConvertTo-HexStringRepresentationForLDAPFilterString](docs/en-US/ConvertTo-HexStringRepresentationForLDAPFilterString.md)
Convert a SID from byte array format to a string representation of its hexadecimal format, properly formatted for an LDAP filter string

### [ConvertTo-SidByteArray](docs/en-US/ConvertTo-SidByteArray.md)
Convert a SID from a string to binary format (byte array)

### [Expand-AdsiGroupMember](docs/en-US/Expand-AdsiGroupMember.md)
Use the LDAP provider to add information about group members to a DirectoryEntry of a group for easier access

### [Expand-WinNTGroupMember](docs/en-US/Expand-WinNTGroupMember.md)
Use the LDAP provider to add information about group members to a DirectoryEntry of a group for easier access

### [Find-AdsiProvider](docs/en-US/Find-AdsiProvider.md)
Determine whether a directory server is an LDAP or a WinNT server

### [Find-LocalAdsiServerSid](docs/en-US/Find-LocalAdsiServerSid.md)

Find-LocalAdsiServerSid [[-ComputerName] <string>] [[-CimCache] <hashtable>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogBuffer] <hashtable>] [[-DebugOutputStream] <string>]


### [Get-ADSIGroup](docs/en-US/Get-ADSIGroup.md)
Get the directory entries for a group and its members using ADSI

### [Get-ADSIGroupMember](docs/en-US/Get-ADSIGroupMember.md)
Get members of a group from the LDAP provider

### [Get-AdsiServer](docs/en-US/Get-AdsiServer.md)
Get information about a directory server including the ADSI provider it hosts and its well-known SIDs

### [Get-CurrentDomain](docs/en-US/Get-CurrentDomain.md)
Use ADSI to get the current domain

### [Get-DirectoryEntry](docs/en-US/Get-DirectoryEntry.md)
Use Active Directory Service Interfaces to retrieve an object from a directory

### [Get-KnownSid](docs/en-US/Get-KnownSid.md)

Get-KnownSid [[-SID] <string>]


### [Get-KnownSidHashtable](docs/en-US/Get-KnownSidHashtable.md)

Get-KnownSidHashTable 


### [Get-ParentDomainDnsName](docs/en-US/Get-ParentDomainDnsName.md)

Get-ParentDomainDnsName [[-DomainNetbios] <string>] [[-CimCache] <hashtable>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogBuffer] <hashtable>] [[-CimSession] <CimSession>] [[-DebugOutputStream] <string>] [-RemoveCimSession]


### [Get-TrustedDomain](docs/en-US/Get-TrustedDomain.md)
Returns a dictionary of trusted domains by the current computer

### [Get-WinNTGroupMember](docs/en-US/Get-WinNTGroupMember.md)
Get members of a group from the WinNT provider

### [Invoke-ComObject](docs/en-US/Invoke-ComObject.md)
Invoke a member method of a ComObject [__ComObject]

### [New-FakeDirectoryEntry](docs/en-US/New-FakeDirectoryEntry.md)

New-FakeDirectoryEntry [[-DirectoryPath] <string>] [[-SID] <string>] [[-Description] <string>] [[-SchemaClassName] <string>]


### [Resolve-IdentityReference](docs/en-US/Resolve-IdentityReference.md)
Use ADSI to lookup info about IdentityReferences from Access Control Entries that came from Discretionary Access Control Lists

### [Search-Directory](docs/en-US/Search-Directory.md)
Use Active Directory Service Interfaces to search an LDAP directory


