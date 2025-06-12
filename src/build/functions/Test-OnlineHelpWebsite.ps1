function Test-OnlineHelpWebsite {

    <#
    .SYNOPSIS
    Test if online help website exists.

    .DESCRIPTION
    Checks if the online help website directory already exists for the module.

    .EXAMPLE
    Test-OnlineHelpWebsite -ModuleName 'MyModule' -DocsOnlineHelpRoot 'C:\docs\online' -Root 'C:\ProjectRoot' -NewLine "`r`n"
    #>

    [CmdletBinding()]
    [OutputType([bool])]
    param(
        # The name of the module
        [Parameter(Mandatory)]
        [string]$ModuleName,

        # The root directory for online help
        [Parameter(Mandatory)]
        [string]$DocsOnlineHelpRoot,

        # The root directory to set as the working location
        [Parameter(Mandatory)]
        [string]$Root,

        # Character sequence for line separation in output
        [Parameter(Mandatory)]
        [string]$NewLine
    )

    # Find prerequisites for creating online help website.
    Write-InfoColor "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-InfoColor "FindOnlineHelpWebsitePrerequisites$NewLine" -ForegroundColor Blue

    # Set location to the project root
    Write-Verbose "`tSet-Location -Path '$ModuleName'"
    Set-Location -Path $Root
    [string]$ProjectRoot = [IO.Path]::Combine('..', '..')
    Set-Location -Path $ProjectRoot

    # Determine whether the Online Help website already exists.
    Write-Verbose "`tGet-ChildItem -Path '$DocsOnlineHelpRoot' -Directory -ErrorAction SilentlyContinue | Where-Object { `$_.Name -eq '$ModuleName' }"
    $joinedPath = [IO.Path]::Combine($DocsOnlineHelpRoot, $ModuleName)

    if (Get-ChildItem -Path $DocsOnlineHelpRoot -Directory -ErrorAction Stop | Where-Object { $_.Name -eq $ModuleName }) {
        Write-InfoColor "`t# Online Help website already exists. ('$joinedPath') It will be updated.$NewLine" -ForegroundColor Green
        return $true
    } else {
        Write-InfoColor "`t# Online Help website does not exist. It will be created. ('$joinedPath')" -ForegroundColor Green
        return $false
    }
}
