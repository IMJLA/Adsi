﻿function Add-SidInfo {

    <#
    .SYNOPSIS

    Add some useful properties to a DirectoryEntry object for easier access
    .DESCRIPTION
    Add SidString, Domain, and SamAccountName NoteProperties to a DirectoryEntry
    .INPUTS
    [System.DirectoryServices.DirectoryEntry] or a [PSCustomObject] imitation. InputObject parameter.  Must contain the objectSid property.
    .OUTPUTS
    [System.DirectoryServices.DirectoryEntry] or a [PSCustomObject] imitation. Whatever was input, but with three extra properties added now.
    .EXAMPLE
    [System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrator') | Add-SidInfo
    distinguishedName :
    Path              : WinNT://localhost/Administrator

    The output object's default format is not modified so with default formatting it appears identical to the original.
    Upon closer inspection it now has SidString, Domain, and SamAccountName properties.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Add-SidInfo')]
    [OutputType([System.DirectoryServices.DirectoryEntry[]], [PSCustomObject[]])]

    param (

        # Expecting a [System.DirectoryServices.DirectoryEntry] from the LDAP or WinNT providers, or a [PSCustomObject] imitation from Get-DirectoryEntry.
        # Must contain the objectSid property
        [Parameter(ValueFromPipeline)]
        $InputObject,

        # In-process cache to reduce calls to other processes or to disk
        [ref]$DomainsBySid

    )

    process {

        ForEach ($Object in $InputObject) {

            $SID = $null
            [string]$SamAccountName = $Object.SamAccountName
            $DomainObject = $null

            if ($null -eq $Object) {
                continue
            }

            if ($Object.objectSid.Value) {

                # With WinNT directory entries for the root (WinNT://localhost), objectSid is a method rather than a property
                # So we need to filter out those instances here to avoid this error:
                # The following exception occurred while retrieving the string representation for method "objectSid":
                # "Object reference not set to an instance of an object."
                if ( $Object.objectSid.Value.GetType().FullName -ne 'System.Management.Automation.PSMethod' ) {
                    [string]$SID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]$Object.objectSid.Value, 0)
                }

            } elseif ($Object.objectSid) {

                # With WinNT directory entries for the root (WinNT://localhost), objectSid is a method rather than a property
                # So we need to filter out those instances here to avoid this error:
                # The following exception occurred while retrieving the string representation for method "objectSid":
                # "Object reference not set to an instance of an object."
                if ($Object.objectSid.GetType().FullName -ne 'System.Management.Automation.PSMethod') {
                    [string]$SID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]$Object.objectSid, 0)
                }

            } elseif ($Object.Properties) {

                if ($Object.Properties['objectSid'].Value) {
                    [string]$SID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]$Object.Properties['objectSid'].Value, 0)
                } elseif ($Object.Properties['objectSid']) {
                    [string]$SID = [System.Security.Principal.SecurityIdentifier]::new([byte[]]($Object.Properties['objectSid'] | ForEach-Object { $_ }), 0)
                }

                if ($Object.Properties['samaccountname']) {
                    $SamAccountName = $Object.Properties['samaccountname']
                } else {

                    #DirectoryEntries from the WinNT provider for local accounts do not have a samaccountname attribute so we use name instead
                    $SamAccountName = $Object.Properties['name']

                }

            } elseif ($Object.Domain.Sid) {

                if ($null -eq $SID) {
                    [string]$SID = $Object.Domain.Sid
                }

                $DomainObject = $Object.Domain

            }

            if (-not $DomainObject) {

                # The SID of the domain is the SID of the user minus the last block of numbers
                $DomainSid = $SID.Substring(0, $Sid.LastIndexOf('-'))

                # Lookup other information about the domain using its SID as the key
                $DomainObject = $null
                $null = $DomainsBySid.Value.TryGetValue($DomainSid, [ref]$DomainObject)

            }

            Add-Member -InputObject $Object -PassThru -Force @{
                SidString      = $SID
                Domain         = $DomainObject
                SamAccountName = $SamAccountName
            }

        }

    }

}
