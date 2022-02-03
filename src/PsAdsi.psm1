<#$ScriptFiles = Get-ChildItem -Path "$PSScriptRoot\*.ps1" -Recurse

# Dot source any functions
ForEach ($ThisScript in $ScriptFiles) {
    # Dot source the function
    . $($ThisScript.FullName)
}

# Add any custom C# classes as usable (exported) types
$CSharpFiles = Get-ChildItem -Path "$PSScriptRoot\*.cs"
ForEach ($ThisFile in $CSharpFiles) {
    Add-Type -Path $ThisFile.FullName -ErrorAction Stop
}

# Export any public functions
$PublicScriptFiles = $ScriptFiles | Where-Object -FilterScript {
    ($_.PSParentPath | Split-Path -Leaf) -eq 'public'
}
$publicFunctions = $PublicScriptFiles.BaseName
Export-ModuleMember -Function @('ConvertTo-DistinguishedName','ConvertTo-Fqdn','ConvertTo-HexStringRepresentation','ConvertTo-HexStringRepresentationForLDAPFilterString','ConvertTo-SidByteArray','Expand-IdentityReference','Find-AdsiProvider','Get-ADSIGroup','Get-CurrentDomain','Get-DirectoryEntry','Get-TrustedDomainSidNameMap','Invoke-ComObject','Resolve-IdentityReference','Search-Directory','Test-PublicFunction_511f9c72-4f82-4b90-be93-ad7576481d5b')
#>
Export-ModuleMember -Function @('ConvertTo-DistinguishedName','ConvertTo-Fqdn','ConvertTo-HexStringRepresentation','ConvertTo-HexStringRepresentationForLDAPFilterString','ConvertTo-SidByteArray','Expand-IdentityReference','Find-AdsiProvider','Get-ADSIGroup','Get-CurrentDomain','Get-DirectoryEntry','Get-TrustedDomainSidNameMap','Invoke-ComObject','Resolve-IdentityReference','Search-Directory','Test-PublicFunction_511f9c72-4f82-4b90-be93-ad7576481d5b')








