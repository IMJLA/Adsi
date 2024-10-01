---
Module Name: Adsi
Module Guid: 282a2aed-9567-49a1-901c-122b7831a805
Download Help Link: {{ Update Download Link }}
Help Version: 4.0.232
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

### [ConvertFrom-IdentityReferenceResolved](ConvertFrom-IdentityReferenceResolved.md)
Use ADSI to collect more information about the IdentityReference in NTFS Access Control Entries

### [ConvertFrom-PropertyValueCollectionToString](ConvertFrom-PropertyValueCollectionToString.md)
Convert a PropertyValueCollection to a string

### [ConvertFrom-ResultPropertyValueCollectionToString](ConvertFrom-ResultPropertyValueCollectionToString.md)
Convert a ResultPropertyValueCollection to a string

### [ConvertFrom-SearchResult](ConvertFrom-SearchResult.md)
Convert a SearchResult to a PSCustomObject

### [ConvertFrom-SidString](ConvertFrom-SidString.md)

ConvertFrom-SidString [[-SID] <string>] [[-DebugOutputStream] <string>] [[-CimCache] <hashtable>] [[-DirectoryEntryCache] <hashtable>] [[-DomainsByNetbios] <hashtable>] [[-DomainsBySid] <hashtable>] [[-DomainsByFqdn] <hashtable>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogBuffer] <hashtable>]


### [ConvertTo-DecStringRepresentation](ConvertTo-DecStringRepresentation.md)
Convert a byte array to a string representation of its decimal format

### [ConvertTo-DistinguishedName](ConvertTo-DistinguishedName.md)
Convert a domain NetBIOS name to its distinguishedName

### [ConvertTo-DomainNetBIOS](ConvertTo-DomainNetBIOS.md)

ConvertTo-DomainNetBIOS [[-DomainFQDN] <string>] [[-AdsiProvider] <string>] [[-CimCache] <hashtable>] [[-DirectoryEntryCache] <hashtable>] [[-DomainsByNetbios] <hashtable>] [[-DomainsBySid] <hashtable>] [[-DomainsByFqdn] <hashtable>] [[-ThisFqdn] <string>] [[-ThisHostName] <string>] [[-WhoAmI] <string>] [[-LogBuffer] <hashtable>] [[-DebugOutputStream] <string>]


### [ConvertTo-DomainSidString](ConvertTo-DomainSidString.md)

ConvertTo-DomainSidString [-DomainDnsName] <string> [[-DirectoryEntryCache] <hashtable>] [[-DomainsByNetbios] <hashtable>] [[-DomainsBySid] <hashtable>] [[-DomainsByFqdn] <hashtable>] [[-AdsiProvider] <string>] [[-CimCache] <hashtable>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogBuffer] <hashtable>] [[-DebugOutputStream] <string>] [<CommonParameters>]


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

### [Expand-WinNTGroupMember](Expand-WinNTGroupMember.md)
Use the LDAP provider to add information about group members to a DirectoryEntry of a group for easier access

### [Find-AdsiProvider](Find-AdsiProvider.md)
Determine whether a directory server is an LDAP or a WinNT server

### [Find-LocalAdsiServerSid](Find-LocalAdsiServerSid.md)

Find-LocalAdsiServerSid [[-ComputerName] <string>] [[-CimCache] <hashtable>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogBuffer] <hashtable>] [[-DebugOutputStream] <string>]


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

### [Get-KnownCaptionHashTable](Get-KnownCaptionHashTable.md)

Get-KnownCaptionHashTable [[-WellKnownSidBySid] <hashtable>]


### [Get-KnownSid](Get-KnownSid.md)

Get-KnownSid [[-SID] <string>]


### [Get-KnownSidHashtable](Get-KnownSidHashtable.md)

Get-KnownSidHashTable 


### [Get-ParentDomainDnsName](Get-ParentDomainDnsName.md)

Get-ParentDomainDnsName [[-DomainNetbios] <string>] [[-CimCache] <hashtable>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-LogBuffer] <hashtable>] [[-CimSession] <CimSession>] [[-DebugOutputStream] <string>] [-RemoveCimSession]


### [Get-TrustedDomain](Get-TrustedDomain.md)
Returns a dictionary of trusted domains by the current computer

### [Get-WinNTGroupMember](Get-WinNTGroupMember.md)
Get members of a group from the WinNT provider

### [Invoke-ComObject](Invoke-ComObject.md)
Invoke a member method of a ComObject [__ComObject]

### [New-FakeDirectoryEntry](New-FakeDirectoryEntry.md)

New-FakeDirectoryEntry [[-DirectoryPath] <string>] [[-SID] <string>] [[-Description] <string>] [[-SchemaClassName] <string>] [[-InputObject] <Object>] [[-NameAllowList] <hashtable>] [[-Name] <string>] [[-NTAccount] <string>]


### [Resolve-IdentityReference](Resolve-IdentityReference.md)
Use ADSI to lookup info about IdentityReferences from Access Control Entries that came from Discretionary Access Control Lists

### [Resolve-ServiceNameToSID](Resolve-ServiceNameToSID.md)

Resolve-ServiceNameToSID [[-InputObject] <Object>] [[-ComputerName] <string>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-Log] <hashtable>] [<CommonParameters>]


### [Search-Directory](Search-Directory.md)
Use Active Directory Service Interfaces to search an LDAP directory


