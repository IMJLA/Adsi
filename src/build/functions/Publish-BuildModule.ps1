function Publish-BuildModule {

    <#
    .SYNOPSIS
    Publishes a PowerShell module to a specified repository.

    .DESCRIPTION
    Publishes a built PowerShell module to a PowerShell repository using an API key for authentication.

    .PARAMETER Path
    The path to the built module directory to publish.

    .PARAMETER Repository
    The name of the PowerShell repository to publish to.

    .PARAMETER ApiKey
    The API key to authenticate with the repository.

    .PARAMETER NoPublish
    Skip publishing if true.

    .PARAMETER RequiredBranch
    Only publish if on this git branch. Defaults to 'main'.

    .EXAMPLE
    Publish-BuildModule -Path "C:\Build\MyModule\1.0.0\MyModule" -Repository "PSGallery" -ApiKey $apiKey
    #>

    [CmdletBinding()]

    param(

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Repository,

        [string]$ApiKey,

        [bool]$NoPublish = $false,

        [string]$RequiredBranch = 'main'

    )

    $publishParams = @{
        Path       = $Path
        Repository = $Repository
        Verbose    = $VerbosePreference
    }

    if ($ApiKey) {
        $publishParams.NuGetApiKey = $ApiKey
    }

    # Only publish a release if we are working on the required branch
    $CurrentBranch = git branch --show-current
    if ($NoPublish -ne $true -and $CurrentBranch -eq $RequiredBranch) {
        Write-Information "`tPublish-Module -Path '$Path' -Repository '$Repository'"
        # Publish to repository
        Publish-Module @publishParams
        Write-InfoColor "`t# Successfully published module to $Repository." -ForegroundColor Green
    } else {
        Write-Verbose "Skipping publishing. NoPublish is $NoPublish and current git branch is $CurrentBranch"
        Write-InfoColor "`t# Skipped publishing (NoPublish: $NoPublish, Branch: $CurrentBranch)." -ForegroundColor Green
    }
}
