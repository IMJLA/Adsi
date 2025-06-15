function Get-DirectoryEntryParentName {

    <#
    .SYNOPSIS
        Extracts the parent name from a DirectoryEntry object.

    .DESCRIPTION
        The Get-DirectoryEntryParentName function retrieves the name of the parent container
        from a DirectoryEntry object. This function handles different scenarios where the
        DirectoryEntry.Parent property might be presented as either a DirectoryEntry object
        with properties or as a string path.

        The function first attempts to access the Parent.Name property directly. If that
        fails or returns null, it falls back to parsing the parent path string by finding
        the last forward slash and extracting the substring that follows it.

        This dual approach ensures compatibility with different representations of the
        DirectoryEntry.Parent property that may occur in different execution contexts
        (such as debugging in VS Code versus console execution).

    .EXAMPLE
        $directoryEntry = [ADSI]"LDAP://CN=Users,DC=contoso,DC=com"
        $parentName = Get-DirectoryEntryParentName -DirectoryEntry $directoryEntry

        This example gets the parent name of a specific LDAP directory entry.

    .EXAMPLE
        $user = Get-ADUser -Identity "jdoe"
        $userEntry = [ADSI]"LDAP://$($user.DistinguishedName)"
        $parentName = Get-DirectoryEntryParentName -DirectoryEntry $userEntry

        This example demonstrates getting the parent container name for a user object.

    .EXAMPLE
        $entries = Get-ChildItem "LDAP://CN=Users,DC=contoso,DC=com"
        $entries | ForEach-Object { Get-DirectoryEntryParentName -DirectoryEntry $_ }

        This example shows processing multiple directory entries to get their parent names.

    .INPUTS
        System.DirectoryServices.DirectoryEntry
        A DirectoryEntry object from which to extract the parent name.

    .OUTPUTS
        System.String
        The name of the parent container or organizational unit.

    .NOTES
        Author: Your Name
        Version: 1.0.0

        This function addresses a specific issue where DirectoryEntry.Parent behavior
        can vary between execution contexts:
        - In VS Code debugger: Shows as DirectoryEntry with accessible properties
        - In console execution: May appear as a string representation

        The function includes error handling for both scenarios to ensure reliable
        operation regardless of the execution environment.

        Performance considerations:
        - Primary method (Parent.Name) is fastest when available
        - Fallback string parsing adds minimal overhead
        - No external dependencies or network calls

    .LINK
        https://IMJLA.github.io/Adsi/docs/en-US/Get-DirectoryEntryParentName

    .LINK
        System.DirectoryServices.DirectoryEntry
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Get-DirectoryEntryParentName')]

    param (

        # The DirectoryEntry object from which to extract the parent name. This can be any valid DirectoryEntry object that has a Parent property, such as LDAP directory entries, Active Directory objects, or other directory service entries.
        $DirectoryEntry

    )

    if ($DirectoryEntry.Parent.Name) {

        return $DirectoryEntry.Parent.Name

    } else {

        $LastIndexOf = $DirectoryEntry.Parent.LastIndexOf('/')
        return $DirectoryEntry.Parent.Substring($LastIndexOf + 1, $DirectoryEntry.Parent.Length - $LastIndexOf - 1)

    }

}
