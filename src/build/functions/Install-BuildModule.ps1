function Install-BuildModule {
    <#
    .SYNOPSIS
    Install the latest version of a specified module with retry logic.

    .DESCRIPTION
    This function attempts to install the specified module with retry logic,
    verifying that the expected version was successfully installed.

    .PARAMETER ModuleName
    The name of the module to install.

    .PARAMETER ExpectedVersion
    The expected version that should be installed.

    .PARAMETER MaxAttempts
    Maximum number of installation attempts. Default is 3.

    .EXAMPLE
    Install-BuildModule -ModuleName 'MyModule' -ExpectedVersion '1.0.0'
    #>

    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [Parameter(Mandatory)]
        [version]$ExpectedVersion,

        [int]$MaxAttempts = 3
    )

    [int]$attempts = 0

    do {
        $attempts++
        Write-Information "`tInstall-Module -Name '$ModuleName' -Force"
        Install-Module -Name $ModuleName -Force -ErrorAction Continue
        Start-Sleep -Seconds 1
        $ModuleStatus = Get-Module -Name $ModuleName -ListAvailable | Where-Object { $_.Version -eq $ExpectedVersion }
    } while ((-not $ModuleStatus) -and ($attempts -lt $MaxAttempts))

    # Test if reinstall was successful
    if ($ModuleStatus) {
        Write-InfoColor "`t# Successfully reinstalled module $ModuleName (version: $($ModuleStatus.Version))." -ForegroundColor Green
        return $true
    } else {
        Write-Error "Failed to reinstall module $ModuleName after $attempts attempts"
        return $false
    }
}
