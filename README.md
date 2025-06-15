---
Module Name: Adsi
Module Guid: 282a2aed-9567-49a1-901c-122b7831a805
Download Help Link: https://IMJLA.github.io/Adsi/UpdatableHelp/
Help Version: 5.0.548
Locale: en-US
---

# Adsi Module
## Description
Use Active Directory Service Interfaces to query LDAP and WinNT directories

## Adsi Cmdlets
### [Add-DomainFqdnToLdapPath](docs\en-US/Add-DomainFqdnToLdapPath.md)
Add a domain FQDN to an LDAP directory path as the server address so the new path can be used for remote queries


### [Add-SidInfo](docs\en-US/Add-SidInfo.md)
Add some useful properties to a DirectoryEntry object for easier access


### [ConvertFrom-DirectoryEntry](docs\en-US/ConvertFrom-DirectoryEntry.md)
Convert a DirectoryEntry to a PSCustomObject


### [ConvertFrom-PropertyValueCollectionToString](docs\en-US/ConvertFrom-PropertyValueCollectionToString.md)
Convert a PropertyValueCollection to a string


### [ConvertFrom-ResolvedID](docs\en-US/ConvertFrom-ResolvedID.md)
Use ADSI to collect more information about the IdentityReference in NTFS Access Control Entries


### [ConvertFrom-ResultPropertyValueCollectionToString](docs\en-US/ConvertFrom-ResultPropertyValueCollectionToString.md)
Convert a ResultPropertyValueCollection to a string


### [ConvertFrom-SearchResult](docs\en-US/ConvertFrom-SearchResult.md)
Convert a SearchResult to a PSCustomObject


### [ConvertFrom-SidString](docs\en-US/ConvertFrom-SidString.md)
Converts a SID string to a DirectoryEntry object.



### [ConvertTo-DecStringRepresentation](docs\en-US/ConvertTo-DecStringRepresentation.md)
Convert a byte array to a string representation of its decimal format


### [ConvertTo-DistinguishedName](docs\en-US/ConvertTo-DistinguishedName.md)
Convert a domain NetBIOS name to its distinguishedName


### [ConvertTo-DomainNetBIOS](docs\en-US/ConvertTo-DomainNetBIOS.md)
Converts a domain FQDN to its NetBIOS name.



### [ConvertTo-DomainSidString](docs\en-US/ConvertTo-DomainSidString.md)
Converts a domain DNS name to its corresponding SID string.



### [ConvertTo-FakeDirectoryEntry](docs\en-US/ConvertTo-FakeDirectoryEntry.md)
Creates a fake DirectoryEntry object for security principals that don't have objects in the directory.



### [ConvertTo-Fqdn](docs\en-US/ConvertTo-Fqdn.md)
Convert a domain distinguishedName name or NetBIOS name to its FQDN


### [ConvertTo-HexStringRepresentation](docs\en-US/ConvertTo-HexStringRepresentation.md)
Convert a SID from byte array format to a string representation of its hexadecimal format


### [ConvertTo-HexStringRepresentationForLDAPFilterString](docs\en-US/ConvertTo-HexStringRepresentationForLDAPFilterString.md)
Convert a SID from byte array format to a string representation of its hexadecimal format, properly formatted for an LDAP filter string


### [ConvertTo-SidByteArray](docs\en-US/ConvertTo-SidByteArray.md)
Convert a SID from a string to binary format (byte array)


### [Expand-AdsiGroupMember](docs\en-US/Expand-AdsiGroupMember.md)
Use the LDAP provider to add information about group members to a DirectoryEntry of a group for easier access


### [Expand-WinNTGroupMember](docs\en-US/Expand-WinNTGroupMember.md)
Use the LDAP provider to add information about group members to a DirectoryEntry of a group for easier access


### [Find-LocalAdsiServerSid](docs\en-US/Find-LocalAdsiServerSid.md)
Finds the SID prefix of the local server by querying the built-in administrator account.


### [Get-AdsiGroup](docs\en-US/Get-AdsiGroup.md)
Get the directory entries for a group and its members using ADSI


### [Get-AdsiGroupMember](docs\en-US/Get-AdsiGroupMember.md)
Get members of a group from the LDAP provider


### [Get-AdsiServer](docs\en-US/Get-AdsiServer.md)
Get information about a directory server including the ADSI provider it hosts and its well-known SIDs


### [Get-CurrentDomain](docs\en-US/Get-CurrentDomain.md)
Use ADSI to get the current domain


### [Get-DirectoryEntry](docs\en-US/Get-DirectoryEntry.md)
Use Active Directory Service Interfaces to retrieve an object from a directory


### [Get-KnownCaptionHashTable](docs\en-US/Get-KnownCaptionHashTable.md)
Creates a hashtable of well-known SIDs indexed by their NT Account names (captions).


### [Get-KnownSid](docs\en-US/Get-KnownSid.md)
Retrieves information about well-known security identifiers (SIDs).



### [Get-KnownSidByName](docs\en-US/Get-KnownSidByName.md)
Creates a hashtable of well-known SIDs indexed by their friendly names.


### [Get-KnownSidHashTable](docs\en-US/Get-KnownSidHashTable.md)
Returns a hashtable of known security identifiers (SIDs) with detailed information.



### [Get-ParentDomainDnsName](docs\en-US/Get-ParentDomainDnsName.md)
Gets the DNS name of the parent domain for a given computer or domain.


### [Get-TrustedDomain](docs\en-US/Get-TrustedDomain.md)
Returns a dictionary of trusted domains by the current computer


### [Get-WinNTGroupMember](docs\en-US/Get-WinNTGroupMember.md)
Get members of a group from the WinNT provider


### [Invoke-ComObject](docs\en-US/Invoke-ComObject.md)
Invoke a member method of a ComObject [__ComObject]


### [Resolve-IdentityReference](docs\en-US/Resolve-IdentityReference.md)
Use CIM and ADSI to lookup info about IdentityReferences from Access Control Entries that came from Discretionary Access Control Lists


### [Resolve-ServiceNameToSID](docs\en-US/Resolve-ServiceNameToSID.md)
Resolves Windows service names to their corresponding security identifiers (SIDs).


### [Search-Directory](docs\en-US/Search-Directory.md)
Use Active Directory Service Interfaces to search an LDAP directory



