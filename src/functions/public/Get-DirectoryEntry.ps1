function Get-DirectoryEntry {

    <#
    .SYNOPSIS
    Use Active Directory Service Interfaces to retrieve an object from a directory
    .DESCRIPTION
    Retrieve a directory entry using either the WinNT or LDAP provider for ADSI
    .INPUTS
    None. Pipeline input is not accepted.
    .OUTPUTS
    [System.DirectoryServices.DirectoryEntry] where possible
    [PSCustomObject] for security principals with no directory entry
    .EXAMPLE
    Get-DirectoryEntry
    distinguishedName : {DC=ad,DC=contoso,DC=com}
    Path              : LDAP://DC=ad,DC=contoso,DC=com

    As the current user on a domain-joined computer, bind to the current domain and retrieve the DirectoryEntry for the root of the domain
    .EXAMPLE
    Get-DirectoryEntry
    distinguishedName :
    Path              : WinNT://ComputerName

    As the current user on a workgroup computer, bind to the local system and retrieve the DirectoryEntry for the root of the directory
    #>

    [OutputType([System.DirectoryServices.DirectoryEntry], [PSCustomObject])]
    [CmdletBinding()]

    param (

        <#
        Path to the directory object to retrieve
        Defaults to the root of the current domain
        #>
        [string]$DirectoryPath = (([System.DirectoryServices.DirectorySearcher]::new()).SearchRoot.Path),

        <#
        Credentials to use to bind to the directory
        Defaults to the credentials of the current user
        #>
        [pscredential]$Credential,

        # Properties of the target object to retrieve
        [string[]]$PropertiesToLoad,

        # Mapping of SID types to descriptions used for converting security identifiers
        [hashtable]$SidTypeMap = (Get-SidTypeMap),

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    $Log = @{ Cache = $Cache }
    $CacheResult = $null
    $DirectoryEntryByPath = $Cache.Value['DirectoryEntryByPath']
    $TryGetValueResult = $DirectoryEntryByPath.Value.TryGetValue($DirectoryPath, [ref]$CacheResult)

    if ($TryGetValueResult) {

        #Write-LogMsg @Log -Text " # DirectoryEntryByPath hit # for '$DirectoryPath'"
        return $CacheResult

    }

    #Write-LogMsg @Log -Text " # DirectoryEntryByPath miss # for '$DirectoryPath'"
    $SplitDirectoryPath = Split-DirectoryPath -DirectoryPath $DirectoryPath
    $Server = $SplitDirectoryPath['Domain']

    $CacheSearch = @{
        AccountName   = $SplitDirectoryPath['Account']
        Cache         = $Cache
        DirectoryPath = $DirectoryPath
        Server        = $Server
        SidTypeMap    = $SidTypeMap
    }

    $DirectoryEntry = Get-CachedDirectoryEntry @CacheSearch

    if ($null -eq $DirectoryEntry) {

        if ([string]::IsNullOrEmpty($DirectoryPath)) {

            # Workgroup computers do not return a DirectoryEntry with a SearchRoot Path so this ends up being an empty string
            # This is also invoked when DirectoryPath is null for any reason
            # We will return a WinNT object representing the local computer's WinNT directory
            $ThisHostName = $Cache.Value['ThisHostName'].Value
            Write-LogMsg @Log -Text " # The SearchRoot Path is empty, indicating '$ThisHostName' is not domain-joined. Defaulting to WinNT provider for localhost instead. # for DirectoryPath '$DirectoryPath'"

            $CimParams = @{
                Cache        = $Cache
                ComputerName = $Cache.Value['ThisFqdn'].Value
            }

            $Workgroup = (Get-CachedCimInstance -ClassName 'Win32_ComputerSystem' -KeyProperty 'Name' @CimParams).Workgroup
            $DirectoryPath = "WinNT://$Workgroup/$ThisHostname"
            Write-LogMsg @Log -Text "[System.DirectoryServices.DirectoryEntry]::new('$DirectoryPath')"

            if ($Credential) {

                $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new(
                    $DirectoryPath,
                    $($Credential.UserName),
                    $($Credential.GetNetworkCredential().password)
                )

            }
            else {
                $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath)
            }

            $SampleUser = @(
                $DirectoryEntry.PSBase.Children |
                Where-Object -FilterScript { $_.schemaclassname -eq 'user' }
            )[0] |
            Add-SidInfo -DomainsBySid [ref]$Cache.Value['DomainBySid']

            $DirectoryEntry |
            Add-Member -MemberType NoteProperty -Name 'Domain' -Value $SampleUser.Domain -Force

        }
        else {

            # Otherwise the DirectoryPath is an LDAP path or a WinNT path (treated the same at this stage)
            Write-LogMsg @Log -Text "[System.DirectoryServices.DirectoryEntry]::new('$DirectoryPath')"

            if ($Credential) {
                $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new(
                    $DirectoryPath,
                    $($Credential.UserName),
                    $($Credential.GetNetworkCredential().password)
                )
            }
            else {
                $DirectoryEntry = [System.DirectoryServices.DirectoryEntry]::new($DirectoryPath)
            }

        }

    }

    if ($PropertiesToLoad) {

        try {

            # If the $DirectoryPath was invalid, this line will return an error
            $null = $DirectoryEntry.RefreshCache($PropertiesToLoad)

        }
        catch {

            $Log['Type'] = 'Warning' # PS 5.1 can't override the Splat by calling the param, so we must update the splat manually

            # Ensure that the error message appears on 1 line
            # Use .Trim() to remove leading and trailing whitespace
            # Removed because I think .Trim() does it:
            # -replace '\s"',' "')" to remove an errant line break in the following specific error I encountered:
            # The following exception occurred while retrieving member "RefreshCache": "The group name could not be found.`r`n"
            $UpdatedMsg = $_.Exception.Message.Trim().Replace('The following exception occurred while retrieving member "RefreshCache": ', '').Replace('"', '')
            Write-LogMsg @Log -Text " # '$DirectoryPath' could not be retrieved. Error: $UpdatedMsg"
            return

        }

    }

    $DirectoryEntryByPath.Value[$DirectoryPath] = $DirectoryEntry
    return $DirectoryEntry

}
