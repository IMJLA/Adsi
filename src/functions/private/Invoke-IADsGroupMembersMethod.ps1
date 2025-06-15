function Invoke-IADsGroupMembersMethod {
    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Invoke-IADsGroupMembersMethod')]

    <#
        .SYNOPSIS
        Get members of a group from the WinNT provider
        .DESCRIPTION
        Get members of a group from the WinNT provider
        Convert them from COM objects into usable DirectoryEntry objects

        Assembly: System.DirectoryServices.dll
        Namespace: System.DirectoryServices
        DirectoryEntry.Invoke(String, Object[]) Method
        Calls a method on the native Active Directory Domain Services object
        https://docs.microsoft.com/en-us/dotnet/api/system.directoryservices.directoryentry.invoke?view=dotnet-plat-ext-6.0

        I am using it to call the IADsGroup::Members method
        The IADsGroup programming interface is part of the iads.h header
        The iads.h header is part of the ADSI component of the Win32 API
        The IADsGroup::Members method retrieves a collection of the immediate members of the group.
        The collection does not include the members of other groups that are nested within the group.
        The default implementation of this method uses LsaLookupSids to query name information for the group members.
        LsaLookupSids has a maximum limitation of 20480 SIDs it can convert, therefore that limitation also applies to this method.
        Returns a pointer to an IADsMembers interface pointer that receives the collection of group members. The caller must release this interface when it is no longer required.
        https://docs.microsoft.com/en-us/windows/win32/api/iads/nf-iads-iadsgroup-members
        The IADsMembers::Members method would use the same provider but I have chosen not to implement that here
        Recursion through nested groups can be handled outside of Get-WinNTGroupMember for now
        Maybe that could be a feature in the future
        https://docs.microsoft.com/en-us/windows/win32/adsi/adsi-object-model-for-winnt-providers?redirectedfrom=MSDN
        .INPUTS
        [System.DirectoryServices.DirectoryEntry]$DirectoryEntry
        .OUTPUTS
        [System.DirectoryServices.DirectoryEntry] for each group member
        .EXAMPLE
        [System.DirectoryServices.DirectoryEntry]::new('WinNT://localhost/Administrators') | Get-WinNTGroupMember

        Get members of the local Administrators group
    #>

    [OutputType([System.DirectoryServices.DirectoryEntry])]


    param (

        # DirectoryEntry [System.DirectoryServices.DirectoryEntry] of the WinNT group whose members to get
        [Parameter(ValueFromPipeline)]
        $DirectoryEntry


    )

    process {

        ForEach ($ThisDirectoryEntry in $DirectoryEntry) {
            # Invoke the Members method to get the group members
            & { $ThisDirectoryEntry.Invoke('Members') 2>$null }
        }

    }

}
