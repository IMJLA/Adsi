function ConvertTo-PermissionPrincipal {

    <#
.SYNOPSIS

Converts directory entry information into a permission principal object.

.DESCRIPTION
Takes directory entry information along with domain and identity details to create a standardized
permission principal object that can be used throughout the permission analysis process.
This function populates a cache of permission principals that can be referenced by identity.
It handles both LDAP and WinNT directory providers and processes group membership information.

.EXAMPLE
ConvertTo-PermissionPrincipal -IdentityReference "DOMAIN\User" -DirectoryEntry $dirEntry -Cache $cacheRef

.INPUTS
System.DirectoryServices.DirectoryEntry

.OUTPUTS
None. This function populates the PrincipalById cache with permission principal objects.
#>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertTo-PermissionPrincipal')]

    param (

        $DomainDn,

        $DomainNetBIOS,

        $IdentityReference,

        $DirectoryEntry,

        $NoGroupMembers,

        $LogSuffixComment,

        $SamAccountNameOrSid,

        $AceGuid,

        # Properties of each Account to display on the report
        [string[]]$AccountProperty = @('DisplayName', 'Company', 'Department', 'Title', 'Description'),

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )



    $Log = @{
        'Cache'  = $Cache
        'Suffix' = $LogSuffixComment
    }

    $PropertiesToAdd = @{
        'DomainDn'            = $DomainDn
        'DomainNetbios'       = $DomainNetBIOS
        'ResolvedAccountName' = $IdentityReference
    }

    # Add the bare minimum required properties
    $PropertiesToLoad = $AccountProperty + @(
        'distinguishedName',
        'grouptype',
        'member',
        'name',
        'objectClass',
        'objectSid',
        'primaryGroupToken',
        'samAccountName'
    )

    $PropertiesToLoad = $PropertiesToLoad |
        Sort-Object -Unique

    $PrincipalById = $Cache.Value['PrincipalById']

    if ($null -ne $DirectoryEntry) {

        ForEach ($Prop in $DirectoryEntry.PSObject.Properties.GetEnumerator().Name) {
            $null = ConvertTo-SimpleProperty -InputObject $DirectoryEntry -Property $Prop -PropertyDictionary $PropertiesToAdd
        }

        if ($DirectoryEntry.Name) {
            $AccountName = $DirectoryEntry.Name
        } else {

            if ($DirectoryEntry.Properties) {

                if ($DirectoryEntry.Properties['name'].Value) {
                    $AccountName = $DirectoryEntry.Properties['name'].Value
                } else {
                    $AccountName = $DirectoryEntry.Properties['name']
                }

            }

        }

        $PropertiesToAdd['ResolvedAccountName'] = "$DomainNetBIOS\$AccountName"

        # WinNT objects have a SchemaClassName property which is a string
        # LDAP objects have an objectClass property which is an ordered list of strings, the last being the class name of the object instance
        # ToDo: LDAP objects may have SchemaClassName too.  When/why?  Should I just request it always in the list of properties?
        # ToDo: Actually I should create an AdsiObjectType property of my own or something...don't expose the dependency
        if (-not $DirectoryEntry.SchemaClassName) {
            $PropertiesToAdd['SchemaClassName'] = @($DirectoryEntry.Properties['objectClass'])[-1] #untested but should work, last value should be the correct one https://learn.microsoft.com/en-us/windows/win32/ad/retrieving-the-objectclass-property
        }

        if ($NoGroupMembers -eq $false) {

            if (

                # WinNT DirectoryEntries do not contain an objectClass property
                # If this property exists it is an LDAP DirectoryEntry rather than WinNT
                $PropertiesToAdd.ContainsKey('objectClass')

            ) {

                # Retrieve the members of groups from the LDAP provider
                Write-LogMsg @Log -Text "Get-AdsiGroupMember -Group `$DirectoryEntry -Cache `$Cache # is an LDAP security principal $LogSuffix"
                $Members = (Get-AdsiGroupMember -Group $DirectoryEntry -PropertiesToLoad $PropertiesToLoad -Cache $Cache).FullMembers

            } else {

                #Write-LogMsg @Log -Text " # '$($DirectoryEntry.Path)' is a WinNT security principal $LogSuffix"

                if ( $DirectoryEntry.SchemaClassName -in @('group', 'SidTypeWellKnownGroup', 'SidTypeAlias')) {

                    Write-LogMsg @Log -Text "Get-WinNTGroupMember -DirectoryEntry `$DirectoryEntry -Cache `$Cache # is a WinNT group $LogSuffix"
                    $Members = Get-WinNTGroupMember -DirectoryEntry $DirectoryEntry -PropertiesToLoad $PropertiesToLoad -Cache $Cache

                }

            }

            # (Get-AdsiGroupMember).FullMembers or Get-WinNTGroupMember could return an array with null members so we must verify that is not true
            if ($Members) {

                $GroupMembers = ForEach ($ThisMember in $Members) {

                    if ($ThisMember.Domain) {

                        # Include specific desired properties
                        $OutputProperties = @{}

                    } else {

                        # Include specific desired properties
                        $OutputProperties = @{

                            Domain = [pscustomobject]@{
                                'Dns'     = $DomainNetBIOS
                                'Netbios' = $DomainNetBIOS
                                'Sid'     = @($SamAccountNameOrSid -split '-')[-1]
                            }

                        }

                    }

                    # Get any existing properties for inclusion later
                    $InputProperties = $ThisMember.PSObject.Properties.GetEnumerator().Name

                    # Include any existing properties found earlier
                    ForEach ($ThisProperty in $InputProperties) {
                        $null = ConvertTo-SimpleProperty -InputObject $ThisMember -Property $ThisProperty -PropertyDictionary $OutputProperties
                    }

                    if ($ThisMember.sAmAccountName) {
                        $ResolvedAccountName = "$($OutputProperties['Domain'].Netbios)\$($ThisMember.sAmAccountName)"
                    } else {
                        $ResolvedAccountName = "$($OutputProperties['Domain'].Netbios)\$($ThisMember.Name)"
                    }

                    $OutputProperties['ResolvedAccountName'] = $ResolvedAccountName
                    $PrincipalById.Value[$ResolvedAccountName] = [PSCustomObject]$OutputProperties

                    ForEach ($ACE in $AceGuid) {
                        Add-PermissionCacheItem -Cache $AceGuidByID -Key $ResolvedAccountName -Value $ACE -Type ([System.Guid])
                    }

                    $ResolvedAccountName

                }

            }

            #Write-LogMsg @Log -Text " # '$($DirectoryEntry.Path)' has $(($Members | Measure-Object).Count) members $LogSuffix"

        }

        $PropertiesToAdd['Members'] = $GroupMembers

    } else {

        $StartingLogType = $Cache.Value['LogType'].Value
        $Cache.Value['LogType'].Value = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually
        Write-LogMsg @Log -Text " # No matching DirectoryEntry $LogSuffix"
        $Cache.Value['LogType'].Value = $StartingLogType

    }

    $PrincipalById.Value[$IdentityReference] = [PSCustomObject]$PropertiesToAdd

}
