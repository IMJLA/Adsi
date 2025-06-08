function Wait-RepoUpdate {
    <#
    .SYNOPSIS
    Wait for a module version to appear in a PowerShell repository.

    .DESCRIPTION
    This function polls a PowerShell repository until the specified module version becomes available,
    or until a timeout is reached.

    .PARAMETER ModuleName
    The name of the module to wait for.

    .PARAMETER Repository
    The PowerShell repository to check.

    .PARAMETER ExpectedVersion
    The version of the module to wait for.

    .PARAMETER TimeoutSeconds
    Maximum time to wait in seconds. Default is 60.

    .PARAMETER IntervalSeconds
    Interval between checks in seconds. Default is 1.

    .EXAMPLE
    Wait-RepoUpdate -ModuleName 'MyModule' -Repository 'PSGallery' -ExpectedVersion '1.0.0'
    #>

    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [Parameter(Mandatory)]
        [string]$Repository,

        [Parameter(Mandatory)]
        [version]$ExpectedVersion,

        [int]$TimeoutSeconds = 60,

        [int]$IntervalSeconds = 1
    )

    $timer = 0
    do {
        Start-Sleep -Seconds $IntervalSeconds
        $timer += $IntervalSeconds
        Write-Information "Find-Module -Name '$ModuleName' -Repository '$Repository'"
        $VersionInGallery = Find-Module -Name $ModuleName -Repository $Repository -ErrorAction SilentlyContinue
    } while (
        ($null -eq $VersionInGallery -or $VersionInGallery.Version -lt $ExpectedVersion) -and
        $timer -lt $TimeoutSeconds
    )

    if ($timer -ge $TimeoutSeconds) {
        Write-Warning "Cannot retrieve version '$ExpectedVersion' of module '$ModuleName' from repo '$Repository'"
        Write-Error "Timeout waiting for module version $ExpectedVersion to appear in $Repository"
        return $false
    } else {
        Write-InfoColor "# Successfully confirmed module version $ExpectedVersion is available in $Repository." -ForegroundColor Green
        return $true
    }
}
