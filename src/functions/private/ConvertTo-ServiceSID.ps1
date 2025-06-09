function ConvertTo-ServiceSID {
    <#
    .SYNOPSIS
    This script calculates the SID of a Virtual Service Account.
    .DESCRIPTION
    Virtual service accounts are used by Windows Server 2008 and later to isolate services without the
    complexity of password management and local accounts.  However, the SID for these accounts is not
    stored in the SAM database.  Instead, it is calculated based on the service name.  This script
    performs that calculation to arrive at the SID for a service account.  This same calculation
    can be preformed by the sc.exe ustility using "sc.exe showsid <service_name>".
    .LINK
    https://pcsxcetrasupport3.wordpress.com/2013/09/08/how-do-you-get-a-service-sid-from-a-service-name/
    .NOTES
        File Name  :
        Get-ServiceAccountSid.ps1
        Authors    :
            LandOfTheLostPass (www.reddit.com/u/LandOfTheLostPass)
        Version History:
            2016-10-06 - Inital Script Creation
    .EXAMPLE
    Get-ServiceAccountSid -ServiceName "MSSQLSERVER"
    .PARAMETER ServiceName
    The name of the service to calculate the sid for (case insensitive)
    #>

    Param (
        [Parameter(position = 0, mandatory = $true)]
        [string]$ServiceName
    )

    #2: Convert service name to upper case.
    $UppercaseName = $ServiceName.ToUpper()

    #3: Get the Unicode bytes()  from the upper case service name.
    $nameBytes = [System.Text.Encoding]::Unicode.GetBytes($UppercaseName)

    #4: Run bytes() thru the sha1 hash function.
    $hashBytes = ([System.Security.Cryptography.SHA1]::Create()).ComputeHash($nameBytes, 0, $nameBytes.Length)

    #5: Reverse the byte() string returned from the SHA1 hash function (on Little Endian systems Not tested on Big Endian systems)
    [Array]::Reverse($hashBytes)
    [string[]]$hashString = $hashBytes | ForEach-Object { $_.ToString('X2') }

    #6: Split the reversed string into 5 blocks of 4 bytes each.
    $blocks = @()
    for ($i = 0; $i -lt 5; $i++) {

        #7: Convert each block of hex bytes() to Decimal
        $blocks += [Convert]::ToInt64("0x$([String]::Join([String]::Empty, $hashString, ($i * 4), 4))", 16)

    }

    #8: Reverse the Position of the blocks
    [Array]::Reverse($blocks)

    #9: Create the first part of the SID “S-1-5-80“
    #10: Tack on each block of Decimal strings with a “-“ in between each block that was converted and reversed.
    #11: Finally out put the complete SID for the service.
    return "S-1-5-80-$([String]::Join('-', $blocks))"

}
