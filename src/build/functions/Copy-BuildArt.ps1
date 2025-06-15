function Copy-BuildArt {

    <#
    .SYNOPSIS
    Copies static SVG art files to the online help website.

    .DESCRIPTION
    This function copies existing SVG art files from the source directory to the online help website's
    static image directory.

    .EXAMPLE
    Copy-BuildArt -DocsImageSourceCodeDir 'C:\MyProject\src\img' -DocsOnlineStaticImageDir 'C:\MyProject\docs\online\MyModule\static\img'
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(

        # The source directory containing static SVG art files
        [Parameter(Mandatory)]
        [string]$DocsImageSourceCodeDir,

        # The destination directory for the art files

        [Parameter(Mandatory)]
        [string]$DocsOnlineStaticImageDir
    )

    if ($PSCmdlet.ShouldProcess($DocsOnlineStaticImageDir, 'Copy static SVG art files')) {
        Write-Information "`tGet-ChildItem -Path '$DocsImageSourceCodeDir' -Filter '*.svg' -ErrorAction Stop |"
        Write-Information "`tCopy-Item -Destination '$DocsOnlineStaticImageDir'"
        Get-ChildItem -Path $DocsImageSourceCodeDir -Filter '*.svg' -ErrorAction Stop | Copy-Item -Destination $DocsOnlineStaticImageDir -PassThru

        Write-InfoColor "`t# Successfully copied static SVG art files to the online help directory." -ForegroundColor Green
    }
}
