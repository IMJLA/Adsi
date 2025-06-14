﻿<#
# Add any custom C# classes as usable (exported) types
$CSharpFiles = Get-ChildItem -Path "$PSScriptRoot\*.cs"
ForEach ($ThisFile in $CSharpFiles) {
    Add-Type -Path $ThisFile.FullName -ErrorAction Stop
}
#>

Export-ModuleMember -Function @('Add-DomainFqdnToLdapPath', 'Add-SidInfo', 'ConvertFrom-DirectoryEntry', 'ConvertFrom-PropertyValueCollectionToString', 'ConvertFrom-ResolvedID', 'ConvertFrom-ResultPropertyValueCollectionToString', 'ConvertFrom-SearchResult', 'ConvertFrom-SidString', 'ConvertTo-DecStringRepresentation', 'ConvertTo-DistinguishedName', 'ConvertTo-DomainNetBIOS', 'ConvertTo-DomainSidString', 'ConvertTo-FakeDirectoryEntry', 'ConvertTo-Fqdn', 'ConvertTo-HexStringRepresentation', 'ConvertTo-HexStringRepresentationForLDAPFilterString', 'ConvertTo-SidByteArray', 'Expand-AdsiGroupMember', 'Expand-WinNTGroupMember', 'Find-LocalAdsiServerSid', 'Get-AdsiGroup', 'Get-AdsiGroupMember', 'Get-AdsiServer', 'Get-CurrentDomain', 'Get-DirectoryEntry', 'Get-KnownCaptionHashTable', 'Get-KnownSid', 'Get-KnownSidByName', 'Get-KnownSidHashTable', 'Get-ParentDomainDnsName', 'Get-TrustedDomain', 'Get-WinNTGroupMember', 'Invoke-ComObject', 'Resolve-IdentityReference', 'Resolve-ServiceNameToSID', 'Search-Directory')
