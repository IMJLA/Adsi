<#
.SYNOPSIS
Build MAML help files from the Markdown files by using PlatyPS invoked by PowerShellBuild.

.DESCRIPTION
This function creates MAML help files from existing Markdown help files using the PowerShellBuild module's PlatyPS integration.
#>
function New-BuildMAMLHelp {
    [CmdletBinding()]
    param(
        # Path to the directory containing Markdown help files
        [Parameter(Mandatory)]
        [string]$DocsMarkdownDir,

        # Destination path for the MAML help files
        [Parameter(Mandatory)]
        [string]$DocsMamlDir
    )

    Write-Information "`tBuild-PSBuildMAMLHelp -Path '$DocsMarkdownDir' -DestinationPath '$DocsMamlDir' -ErrorAction Stop"
    Build-PSBuildMAMLHelp -Path $DocsMarkdownDir -DestinationPath $DocsMamlDir -ErrorAction Stop
    Write-InfoColor "`t# Successfully built MAML help files from the Markdown files." -ForegroundColor Green
}
