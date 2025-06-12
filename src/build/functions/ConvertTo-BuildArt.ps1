function ConvertTo-BuildArt {
    <#
    .SYNOPSIS
    Convert SVG art files to PNG using Inkscape.

    .DESCRIPTION
    This function converts SVG files to PNG format using Inkscape.

    .EXAMPLE
    ConvertTo-BuildArt -Path "C:\MyProject\static\img"
    #>

    [CmdletBinding()]
    param(
        # The directory containing the SVG files to convert
        [Parameter(Mandatory)]
        [string]$Path
    )

    Write-Information "`tConvertTo-BuildArt -Path '$Path'"

    # Convert SVGs to PNG using Inkscape
    $SvgFiles = Get-ChildItem -Path $Path -Filter '*.svg' -ErrorAction SilentlyContinue

    foreach ($SvgFile in $SvgFiles) {
        $PngPath = $SvgFile.FullName -replace '\.svg$', '.png'
        Write-Information "`t`tConverting '$($SvgFile.Name)' to PNG"

        # Use Inkscape to convert SVG to PNG
        & inkscape --export-type=png --export-filename="$PngPath" "$($SvgFile.FullName)" 2>$null
    }

    Write-InfoColor "`t# Successfully converted $($SvgFiles.Count) SVG files to PNG." -ForegroundColor Green
}
