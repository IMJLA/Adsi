<#
# Add any custom C# classes as usable (exported) types
$CSharpFiles = Get-ChildItem -Path "$PSScriptRoot\*.cs"
ForEach ($ThisFile in $CSharpFiles) {
    Add-Type -Path $ThisFile.FullName -ErrorAction Stop
}
#>
Export-ModuleMember -Function @('Add-DomainFqdnToLdapPath','Add-SidInfo','ConvertFrom-DirectoryEntry','ConvertFrom-IdentityReferenceResolved','ConvertFrom-PropertyValueCollectionToString','ConvertFrom-ResultPropertyValueCollectionToString','ConvertFrom-SearchResult','ConvertFrom-SidString','ConvertTo-DecStringRepresentation','ConvertTo-DistinguishedName','ConvertTo-DomainNetBIOS','ConvertTo-DomainSidString','ConvertTo-Fqdn','ConvertTo-HexStringRepresentation','ConvertTo-HexStringRepresentationForLDAPFilterString','ConvertTo-SidByteArray','Expand-AdsiGroupMember','Expand-WinNTGroupMember','Find-AdsiProvider','Find-LocalAdsiServerSid','Get-ADSIGroup','Get-ADSIGroupMember','Get-AdsiServer','Get-CurrentDomain','Get-DirectoryEntry','Get-ParentDomainDnsName','Get-TrustedDomain','Get-Win32Account','Get-Win32UserAccount','Get-WinNTGroupMember','Invoke-ComObject','New-AdsiServerCimSession','New-FakeDirectoryEntry','Resolve-Ace','Resolve-IdentityReference','Search-Directory')





























































































