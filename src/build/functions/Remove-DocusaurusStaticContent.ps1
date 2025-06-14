function Remove-DocusaurusStaticContent {

    <#
    .SYNOPSIS
    Removes all content from the Docusaurus static directory.

    .DESCRIPTION
    This function empties the contents of the Docusaurus static directory to ensure a clean
    state before copying new static assets like images and updatable help files.

    .EXAMPLE
    Remove-DocusaurusStaticContent -DocsOnlineStaticDir 'C:\MyProject\docs\online\MyModule\static'
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The path to the Docusaurus static directory
        [Parameter(Mandatory)]
        [string]$DocsOnlineStaticDir
    )

    if (-not (Test-Path $DocsOnlineStaticDir)) {
        Write-InfoColor "`t# Static directory does not exist: $DocsOnlineStaticDir" -ForegroundColor Yellow
        return
    }

    if ($PSCmdlet.ShouldProcess($DocsOnlineStaticDir, 'Remove all static content')) {
        Write-Verbose "`tGet-ChildItem -Path '$DocsOnlineStaticDir' -Recurse"
        $staticContent = Get-ChildItem -Path $DocsOnlineStaticDir -Recurse

        if ($staticContent.Count -eq 0) {
            Write-InfoColor "`t# Static directory is already empty." -ForegroundColor Green
            return
        }

        foreach ($item in $staticContent) {
            if ($item.PSIsContainer) {
                Write-Information "`tRemove-Item -Path '$($item.FullName)' -Recurse -Force"
                Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction Stop
            } else {
                Write-Information "`tRemove-Item -Path '$($item.FullName)' -Force"
                Remove-Item -Path $item.FullName -Force -ErrorAction Stop
            }
        }

        Write-InfoColor "`t# Successfully removed all static content from Docusaurus directory." -ForegroundColor Green
    }
}
