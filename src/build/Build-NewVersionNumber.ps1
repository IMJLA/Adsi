param (
    [switch]$IncrementMajorVersion,
    [switch]$IncrementMinorVersion,
    $ManifestTest
)

$CurrentVersion = $ManifestTest.Version
Write-Host "`t# Old Version: $CurrentVersion"

if ($IncrementMajorVersion) {

    Write-Host "`t# This is a new major version"
    "$($CurrentVersion.Major + 1).0.0"

}
elseif ($IncrementMinorVersion) {

    Write-Host "`t# This is a new minor version"
    "$($CurrentVersion.Major).$($CurrentVersion.Minor + 1).0"

}
else {

    Write-Host "`t# This is a new build"
    "$($CurrentVersion.Major).$($CurrentVersion.Minor).$($CurrentVersion.Build + 1)"

}