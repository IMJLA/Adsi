function Get-NewVersion {
    param (
        [version]$OldVersion,
        [switch]$IncrementMajorVersion,
        [switch]$IncrementMinorVersion
    )

    if ($IncrementMajorVersion) {
        [version]"$([int]$OldVersion.Major + 1).0.0"
    } elseif ($IncrementMinorVersion) {
        [version]"$([int]$OldVersion.Major).$([int]$OldVersion.Minor + 1).0"
    } else {
        [version]"$([int]$OldVersion.Major).$([int]$OldVersion.Minor).$([int]$OldVersion.Build + 1)"
    }
}
