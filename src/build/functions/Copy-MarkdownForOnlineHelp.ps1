function Copy-MarkdownForOnlineHelp {

    <#
    .SYNOPSIS
    Copies Markdown help files as source for the online help website.

    .DESCRIPTION
    This function copies both the generated Markdown help files and additional documentation
    source files to the online help website's source directory for each locale.

    .EXAMPLE
    Copy-MarkdownForOnlineHelp -DocsMarkdownDir 'C:\MyProject\docs\markdown' -OnlineHelpSourceMarkdown 'C:\MyProject\docs\online\MyModule\docs' -MarkdownSourceCodeDir 'C:\MyProject\src\docs'
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(

        # The directory containing the generated Markdown help files
        [Parameter(Mandatory)]
        [string]$DocsMarkdownDir,

        # The destination directory for the online help source markdown
        [Parameter(Mandatory)]
        [string]$OnlineHelpSourceMarkdown,

        # The source directory containing additional markdown documentation
        [Parameter(Mandatory)]
        [string]$MarkdownSourceCodeDir
    )

    if ($PSCmdlet.ShouldProcess($OnlineHelpSourceMarkdown, 'Copy Markdown files for online help')) {
        $helpLocales = (Get-ChildItem -Path $DocsMarkdownDir -Directory -Exclude 'UpdatableHelp').Name

        ForEach ($Locale in $helpLocales) {
            Write-Information "`tCopy-Item -Path '$DocsMarkdownDir\*' -Destination '$OnlineHelpSourceMarkdown' -Recurse -Force"
            Copy-Item -Path "$DocsMarkdownDir\*" -Destination $OnlineHelpSourceMarkdown -Recurse -Force
            Write-Information "`tCopy-Item -Path '$MarkdownSourceCodeDir\*' -Destination '$OnlineHelpSourceMarkdown\$Locale' -Recurse -Force"
            Copy-Item -Path "$MarkdownSourceCodeDir\*" -Destination "$OnlineHelpSourceMarkdown\$Locale" -Recurse -Force
        }

        # Test if markdown files were copied successfully
        $copiedMarkdown = Get-ChildItem -Path $OnlineHelpSourceMarkdown -Filter '*.md' -Recurse -ErrorAction SilentlyContinue
        if ($copiedMarkdown) {
            Write-InfoColor "`t# Successfully copied Markdown files for online help." -ForegroundColor Green
        } else {
            Write-Error 'Failed to copy Markdown files for online help'
        }
    }
}
