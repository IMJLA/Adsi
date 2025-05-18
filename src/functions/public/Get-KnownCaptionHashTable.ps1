function Get-KnownCaptionHashTable {
    <#
    .SYNOPSIS
        Creates a hashtable of well-known SIDs indexed by their NT Account names (captions).
    .DESCRIPTION
        This function takes a hashtable of well-known SIDs (indexed by SID) and
        transforms it into a new hashtable where the keys are the NT Account names
        (captions) of the SIDs. This makes it easier to look up SID information when
        you have the account name representation rather than the SID itself.
    .INPUTS
        System.Collections.Hashtable

        A hashtable containing SID strings as keys and information objects as values.
    .OUTPUTS
        System.Collections.Hashtable

        Returns a hashtable with NT Account names as keys and SID information objects as values.
    .EXAMPLE
        $sidBySid = Get-KnownSidHashTable
        $sidByCaption = Get-KnownCaptionHashTable -WellKnownSidBySid $sidBySid
        $systemInfo = $sidByCaption['NT AUTHORITY\SYSTEM']

        Creates a hashtable of well-known SIDs indexed by their NT Account names and retrieves
        information about the SYSTEM account. This is useful when you need to look up SID
        information by NT Account name rather than by SID string.
    #>

    param (
        # Hashtable of well-known Security Identifiers (SIDs) with their properties
        [hashtable]$WellKnownSidBySid = (Get-KnownSidHashTable)
    )

    $WellKnownSidByCaption = @{}

    ForEach ($KnownSID in $WellKnownSidBySid.Keys) {

        $Known = $WellKnownSidBySid[$KnownSID]
        $WellKnownSidByCaption[$Known.NTAccount] = $Known

    }

    return $WellKnownSidByCaption

}
