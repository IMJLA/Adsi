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
            Write-Information "`tUpdate-MarkdownHelp -Path '$($_.FullName)'" @IO

            if ($PSCmdlet.ShouldProcess($_.FullName, "Update-MarkdownHelp")) {
                Update-MarkdownHelp -Path $_.FullName -ErrorAction Stop
            }
        }

        Write-InfoColor "`t# Successfully updated existing Markdown help files." -ForegroundColor Green

    } else {
        Write-InfoColor "`t# No existing Markdown help files found to update." -ForegroundColor Green
    }
}
