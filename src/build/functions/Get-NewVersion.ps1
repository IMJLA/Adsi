function Get-NewVersion {
    <#
    .SYNOPSIS
        Determines the new version number for a module build.

    .DESCRIPTION
        Calculates the new version number based on increment parameters and the current version.

    .EXAMPLE
        Get-NewVersion -IncrementMajorVersion:$false -IncrementMinorVersion:$true -OldVersion '1.0.0'
    #>
    [CmdletBinding()]
    [OutputType([System.Version])]
    param(
        # Whether to increment the major version number
        [bool]$IncrementMajorVersion,

        # Whether to increment the minor version number
        [bool]$IncrementMinorVersion,

        # The current version to increment from
        [version]$OldVersion
    )

    Write-Verbose "`tGet-NewVersion -IncrementMajorVersion:`$$IncrementMajorVersion -IncrementMinorVersion:`$$IncrementMinorVersion -OldVersion '$OldVersion'"

    # Version increment logic here
    if ($IncrementMajorVersion) {
        $newVersion = [version]::new($OldVersion.Major + 1, 0, 0)
    } elseif ($IncrementMinorVersion) {
        $newVersion = [version]::new($OldVersion.Major, $OldVersion.Minor + 1, 0)
    } else {
        $newVersion = [version]::new($OldVersion.Major, $OldVersion.Minor, $OldVersion.Build + 1)
    }

    Write-InfoColor "`t# Successfully determined the new version number: $newVersion" -ForegroundColor Green
    return $newVersion
}
