function Wait-RepoUpdate {

    <#
    .SYNOPSIS
    Wait for a module version to appear in a PowerShell repository.

    .DESCRIPTION
    This function polls a PowerShell repository until the specified module version becomes available,
    or until a timeout is reached.

    .EXAMPLE
    Wait-RepoUpdate -ModuleName 'MyModule' -Repository 'PSGallery' -ExpectedVersion '1.0.0'
    #>

    [CmdletBinding()]
    [OutputType([bool])]

    param(

        # The name of the module to wait for
        [Parameter(Mandatory)]
        [string]$ModuleName,

        # The PowerShell repository to check
        [Parameter(Mandatory)]
        [string]$Repository,

        # The version of the module to wait for
        [Parameter(Mandatory)]
        [version]$ExpectedVersion,

        # Maximum time to wait in seconds. Default is 60
        [int]$TimeoutSeconds = 60,

        # Interval between checks in seconds. Default is 1
        [int]$IntervalSeconds = 1

    )

    $timer = 0
    do {
        Start-Sleep -Seconds $IntervalSeconds
        $timer += $IntervalSeconds
        Write-Information "`tFind-Module -Name '$ModuleName' -Repository '$Repository'"
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
        Write-InfoColor "`t# Successfully confirmed module version $ExpectedVersion is available in $Repository." -ForegroundColor Green
        return $true
    }
}
