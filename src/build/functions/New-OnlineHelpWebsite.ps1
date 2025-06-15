function New-OnlineHelpWebsite {

    <#
    .SYNOPSIS
    Creates a new Docusaurus-based online help website for a PowerShell module.

    .DESCRIPTION
    This function creates a new online help website using Docusaurus by running the create command
    and setting up the initial structure for PowerShell module documentation.

    .EXAMPLE
    New-OnlineHelpWebsite -DocsOnlineHelpDir 'C:\docs\online\MyModule' -ModuleName 'MyModule'
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(

        # The directory where the online help website should be created
        [Parameter(Mandatory)]
        [string]$DocsOnlineHelpDir,

        # The name of the module for which the help website is being created
        [Parameter(Mandatory)]
        [string]$ModuleName

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
