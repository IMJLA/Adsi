function Test-OnlineHelpScaffoldingMissing {
    <#
    .SYNOPSIS
    Test if online help scaffolding is missing and needs to be created.

    .DESCRIPTION
    Checks if the online help scaffolding directory already exists for the module.

    .PARAMETER ModuleName
    The name of the module.

    .PARAMETER DocsOnlineHelpRoot
    The root directory for online help.

    .PARAMETER Root
    The root directory to set as the working location.

    .PARAMETER NewLine
    Character sequence for line separation in output.

    .EXAMPLE
    Test-OnlineHelpScaffoldingMissing -ModuleName 'MyModule' -DocsOnlineHelpRoot 'C:\docs\online' -Root 'C:\ProjectRoot' -NewLine "`r`n"
    #>

    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [Parameter(Mandatory)]
        [string]$DocsOnlineHelpRoot,

        [Parameter(Mandatory)]
        [string]$Root,

        [Parameter(Mandatory)]
        [string]$NewLine
    )

    # Find prerequisites for creating online help scaffolding.
    Write-InfoColor "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-InfoColor "FindOnlineHelpScaffoldingPrerequisites$NewLine" -ForegroundColor Blue

    # Set location to the project root
    Write-InfoColor "`tSet-Location -Path '$ModuleName'"
    Set-Location -Path $Root
    [string]$ProjectRoot = [IO.Path]::Combine('..', '..')
    Set-Location -Path $ProjectRoot

    # Determine whether the Online Help scaffolding already exists.
    Write-Information "`tGet-ChildItem -Path '$DocsOnlineHelpRoot' -Directory -ErrorAction SilentlyContinue | Where-Object { `$_.Name -eq '$ModuleName' }"
    if (Get-ChildItem -Path $DocsOnlineHelpRoot -Directory -ErrorAction Stop | Where-Object { $_.Name -eq $ModuleName }) {
        Write-InfoColor "`t# Online Help scaffolding already exists. It will be updated.$NewLine" -ForegroundColor Green
        return $false
    } else {
        Write-InfoColor "`t# Online Help scaffolding does not exist. It will be created." -ForegroundColor Green
        return $true
    }
}
