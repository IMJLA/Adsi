function New-OnlineHelpScaffolding {
    <#
    .SYNOPSIS
    Create Docusaurus scaffolding for the online help website.

    .DESCRIPTION
    Scaffolds the skeleton of the Online Help website with Docusaurus which is written
    in TypeScript and uses React.js.

    .PARAMETER ModuleName
    The name of the module for which to create the scaffolding.

    .PARAMETER DocsOnlineHelpRoot
    The root directory where the online help will be created.

    .PARAMETER DocsOnlineHelpDir
    The directory where the online help website will be created.

    .EXAMPLE
    New-OnlineHelpScaffolding -ModuleName 'MyModule' -DocsOnlineHelpRoot 'C:\docs\online' -DocsOnlineHelpDir 'C:\docs\online\MyModule'
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [Parameter(Mandatory)]
        [string]$DocsOnlineHelpRoot,

        [Parameter(Mandatory)]
        [string]$DocsOnlineHelpDir
    )

    $Location = Get-Location
    Write-Information "`tSet-Location -Path '$DocsOnlineHelpRoot'"

    if ($PSCmdlet.ShouldProcess($DocsOnlineHelpRoot, 'Change location')) {
        Set-Location $DocsOnlineHelpRoot
    }

    # Check if package.json exists (indicating Docusaurus is already initialized)
    $PackageJsonPath = Join-Path $DocsOnlineHelpDir 'package.json'

    if (Test-Path $PackageJsonPath) {
        Write-Information "`tDocusaurus website already exists, skipping initialization"
        Write-InfoColor "`t# Docusaurus scaffolding already exists." -ForegroundColor Green
    } else {

        Write-InfoColor "`t> npx create-docusaurus@latest $ModuleName classic --typescript" -ForegroundColor Cyan

        if ($PSCmdlet.ShouldProcess("npx create-docusaurus@latest $ModuleName classic --typescript", 'Create Docusaurus scaffolding')) {
            try {

                # Use Start-Process for better control over npx output
                $processArgs = @{
                    FilePath         = 'npx'
                    ArgumentList     = @('create-docusaurus@latest', $ModuleName, 'classic', '--typescript')
                    WorkingDirectory = $DocsOnlineHelpRoot
                    Wait             = $true
                    NoNewWindow      = $true
                    PassThru         = $true
                }

                $process = Start-Process @processArgs

            } catch {
                Write-Error "Failed to create Docusaurus scaffolding: $_"
            }

            if ($process.ExitCode -eq 0) {
                # Test if scaffolding was created successfully
                if (Test-Path $PackageJsonPath) {
                    Write-InfoColor "`t# Successfully created the scaffolding for the Online Help website using Docusaurus." -ForegroundColor Green
                } else {
                    Write-Error 'Failed to create Docusaurus scaffolding - package.json not found'
                }
            } else {
                Write-Error "Failed to create Docusaurus scaffolding - npx exited with code $($process.ExitCode)"
            }
        }

    }

    if ($PSCmdlet.ShouldProcess($Location, 'Restore location')) {
        Set-Location $Location
    }
}
