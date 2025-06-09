function Update-BuildMarkdownHelp {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$DocsMarkdownDir,

        [hashtable]$IO = @{}
    )

    Write-Information "`tGet-ChildItem -LiteralPath '$DocsMarkdownDir' -Filter *.md -Recurse" @IO

    if (Get-ChildItem -LiteralPath $DocsMarkdownDir -Filter *.md -Recurse) {

        Write-Information "`tGet-ChildItem -LiteralPath '$DocsMarkdownDir' -Directory" @IO
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
