<#
# Add any custom C# classes as usable (exported) types
$CSharpFiles = Get-ChildItem -Path "$PSScriptRoot\*.cs"
ForEach ($ThisFile in $CSharpFiles) {
    Add-Type -Path $ThisFile.FullName -ErrorAction Stop
}
#>

Export-ModuleMember -Function @('Add-DomainFqdnToLdapPath','Add-SidInfo','ConvertFrom-DirectoryEntry','ConvertFrom-PropertyValueCollectionToString','ConvertFrom-ResolvedID','ConvertFrom-ResultPropertyValueCollectionToString','ConvertFrom-SearchResult','ConvertFrom-SidString','ConvertTo-DecStringRepresentation','ConvertTo-DistinguishedName','ConvertTo-DomainNetBIOS','ConvertTo-DomainSidString','ConvertTo-Fqdn','ConvertTo-HexStringRepresentation','ConvertTo-HexStringRepresentationForLDAPFilterString','ConvertTo-SidByteArray','Expand-AdsiGroupMember','Expand-WinNTGroupMember','Find-LocalAdsiServerSid','Get-AdsiGroup','Get-AdsiGroupMember','Get-AdsiServer','Get-CurrentDomain','Get-DirectoryEntry','Get-KnownCaptionHashTable','Get-KnownSid','Get-KnownSidByName','Get-KnownSidHashtable','Get-ParentDomainDnsName','Get-TrustedDomain','Get-WinNTGroupMember','Invoke-ComObject','New-FakeDirectoryEntry','Resolve-IdentityReference','Resolve-ServiceNameToSID','Search-Directory')





































































