function Split-DirectoryPath {

    <#
    .EXAMPLE
        Split-DirectoryPath -DirectoryPath 'WinNT://WORKGROUP/COMPUTER/Administrator'
        Split-DirectoryPath -DirectoryPath 'WinNT://COMPUTER/Administrator'
        Split-DirectoryPath -DirectoryPath 'WinNT://WORKGROUP/COMPUTER/Administrator'
        Split-DirectoryPath -DirectoryPath 'WinNT://DOMAIN/COMPUTER/Administrator'
        Split-DirectoryPath -DirectoryPath 'WinNT://DOMAIN/OU1/COMPUTER/Administrator'
        Split-DirectoryPath -DirectoryPath 'WinNT://DOMAIN/OU1/OU2/COMPUTER/Administrator'
    #>

    param (
        [string]$DirectoryPath
    )

    $Split = $DirectoryPath.Split('/')

    # Extra segments an account's Directory Path indicate that the account's domain is a child domain.
    if ($Split.Count -gt 4) {

        $ParentDomain = $Split[2]

        if ($Split.Count -gt 5) {
            $Middle = $Split[3..($Split.Count - 3)]
        } else {
            $Middle = $null
        }

    } else {
        $ParentDomain = $null
    }

    return @{
        DirectoryPath = $DirectoryPath # Not currently in use by dependent functions
        Account       = $Split[ ( $Split.Count - 1 ) ]
        Domain        = $Split[ ( $Split.Count - 2 ) ]
        ParentDomain  = $ParentDomain # Not currently in use by dependent functions
        Middle        = $Middle # Not currently in use by dependent functions
    }

}
