---
Module Name: Adsi
Module Guid: 282a2aed-9567-49a1-901c-122b7831a805
Download Help Link: {{ Update Download Link }}
Help Version: 4.0.447
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

ConvertFrom-SidString [[-SID] <string>] [[-DebugOutputStream] <string>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [-Cache] <ref> [<CommonParameters>]


### [ConvertTo-DecStringRepresentation](ConvertTo-DecStringRepresentation.md)
Convert a byte array to a string representation of its decimal format

### [ConvertTo-DistinguishedName](ConvertTo-DistinguishedName.md)
Convert a domain NetBIOS name to its distinguishedName

### [ConvertTo-DomainNetBIOS](ConvertTo-DomainNetBIOS.md)

ConvertTo-DomainNetBIOS [[-DomainFQDN] <string>] [[-AdsiProvider] <string>] [[-ThisFqdn] <string>] [[-ThisHostName] <string>] [[-WhoAmI] <string>] [[-DebugOutputStream] <string>] [-Cache] <ref> [<CommonParameters>]


### [ConvertTo-DomainSidString](ConvertTo-DomainSidString.md)

ConvertTo-DomainSidString [-DomainDnsName] <string> [[-AdsiProvider] <string>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-DebugOutputStream] <string>] [-Cache] <ref> [<CommonParameters>]


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

### [Find-LocalAdsiServerSid](Find-LocalAdsiServerSid.md)

Find-LocalAdsiServerSid [[-ThisHostName] <string>] [[-ComputerName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-DebugOutputStream] <string>] [-Cache] <ref> [<CommonParameters>]


### [Get-AdsiGroup](Get-AdsiGroup.md)
Get the directory entries for a group and its members using ADSI

### [Get-AdsiGroupMember](Get-AdsiGroupMember.md)
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


### [Get-KnownSidByName](Get-KnownSidByName.md)

Get-KnownSidByName [[-WellKnownSIDBySID] <hashtable>]


### [Get-KnownSidHashtable](Get-KnownSidHashtable.md)

Get-KnownSidHashTable 


### [Get-ParentDomainDnsName](Get-ParentDomainDnsName.md)

Get-ParentDomainDnsName [[-DomainNetbios] <string>] [[-ThisHostName] <string>] [[-ThisFqdn] <string>] [[-WhoAmI] <string>] [[-CimSession] <CimSession>] [[-DebugOutputStream] <string>] [-Cache] <ref> [-RemoveCimSession] [<CommonParameters>]


### [Get-TrustedDomain](Get-TrustedDomain.md)
Returns a dictionary of trusted domains by the current computer

### [Get-WinNTGroupMember](Get-WinNTGroupMember.md)
Get members of a group from the WinNT provider

### [Invoke-ComObject](Invoke-ComObject.md)
Invoke a member method of a ComObject [__ComObject]

### [New-FakeDirectoryEntry](New-FakeDirectoryEntry.md)

New-FakeDirectoryEntry [[-DirectoryPath] <string>] [[-SID] <string>] [[-Description] <string>] [[-SchemaClassName] <string>] [[-InputObject] <Object>] [[-NameAllowList] <hashtable>] [[-NameBlockList] <hashtable>] [[-Name] <string>] [[-NTAccount] <string>]


### [Resolve-IdentityReference](Resolve-IdentityReference.md)
Use CIM and ADSI to lookup info about IdentityReferences from Access Control Entries that came from Discretionary Access Control Lists

### [Resolve-ServiceNameToSID](Resolve-ServiceNameToSID.md)

Resolve-ServiceNameToSID [[-InputObject] <Object>] [<CommonParameters>]


### [Search-Directory](Search-Directory.md)
Use Active Directory Service Interfaces to search an LDAP directory


