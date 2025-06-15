function Remove-BuildMarkdownHelp {

    <#
    .SYNOPSIS
    Remove existing Markdown help files to prepare for PlatyPS to build new ones.

    .DESCRIPTION
    This function removes all existing Markdown help files from the specified directory to ensure a clean state before generating new help documentation.

    .EXAMPLE
    Remove-BuildMarkdownHelp -DocsMarkdownDir './docs/markdown' -DocsDefaultLocale 'en-US'
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(

        # Path to the Markdown help directory containing locale subdirectories
        [Parameter(Mandatory)]
        [string]$DocsMarkdownDir,

        # Default locale for the documentation

        [Parameter(Mandatory)]
        [string]$DocsDefaultLocale
    )

    $MarkdownDir = [IO.Path]::Combine($DocsMarkdownDir, $DocsDefaultLocale)

    if ($PSCmdlet.ShouldProcess($MarkdownDir, 'Remove existing Markdown help files')) {
        Write-Information "`tGet-ChildItem -Path '$MarkdownDir' -Recurse | Remove-Item -Recurse -Force"
        Get-ChildItem -Path $MarkdownDir -Recurse -ErrorAction Stop | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue -ProgressAction SilentlyContinue

        if (Get-ChildItem -Path $MarkdownDir -Recurse -ErrorAction SilentlyContinue) {
            Write-Error 'Failed to delete existing Markdown help files.'
        } else {
            Write-InfoColor "`t# Successfully deleted existing Markdown help files." -ForegroundColor Green
        }
    }
}
