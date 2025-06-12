function Update-BuildMarkdownHelp {

    <#
    .SYNOPSIS
    Updates existing markdown help files using PlatyPS.

    .DESCRIPTION
    This function updates existing markdown help files by scanning the markdown directory
    for .md files and running Update-MarkdownHelp on each directory containing them.

    .EXAMPLE
    Update-BuildMarkdownHelp -DocsMarkdownDir 'C:\MyProject\docs\markdown'
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The directory containing markdown help files
        [Parameter(Mandatory)]
        [string]$DocsMarkdownDir,

        # Hashtable for output parameters
        [hashtable]$IO = @{}
    )

    Write-Verbose "`tGet-ChildItem -LiteralPath '$DocsMarkdownDir' -Filter *.md -Recurse" @IO

    if (Get-ChildItem -LiteralPath $DocsMarkdownDir -Filter *.md -Recurse) {

        Write-Verbose "`tGet-ChildItem -LiteralPath '$DocsMarkdownDir' -Directory" @IO
        Get-ChildItem -LiteralPath $DocsMarkdownDir -Directory | ForEach-Object {

            $DirName = $_.FullName
            Write-Information "`tUpdate-MarkdownHelp -Path '$DirName'" @IO

            if ($PSCmdlet.ShouldProcess($DirName, 'Update-MarkdownHelp')) {
                Update-MarkdownHelp -Path $DirName -ErrorAction Stop
            }
        }

        Write-InfoColor "`t# Successfully updated existing Markdown help files." -ForegroundColor Green

    } else {
        Write-InfoColor "`t# No existing Markdown help files found to update." -ForegroundColor Green
    }
}
