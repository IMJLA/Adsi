function Copy-BuildMAMLHelp {

    <#
    .SYNOPSIS
    Copy MAML help files to the build output directory.

    .DESCRIPTION
    This function copies the generated MAML help files from the documentation directory to the module build output directory and validates the copy operation.

    .EXAMPLE
    Copy-BuildMAMLHelp -DocsMamlDir './docs/maml' -BuildOutputDir './dist'
    #>

    [CmdletBinding()]
    param(
        # Path to the MAML help directory (source)
        [Parameter(Mandatory)]
        [string]$DocsMamlDir,

        # Path to the build output directory (destination)
        [Parameter(Mandatory)]
        [string]$BuildOutputDir
    )

    Write-Information "`tCopy-Item -Path '$DocsMamlDir\*' -Destination '$BuildOutputDir' -Recurse"
    Copy-Item -Path "$DocsMamlDir\*" -Destination $BuildOutputDir -Recurse -ErrorAction SilentlyContinue

    # Test if MAML help files were copied successfully
    $copiedFiles = Get-ChildItem -Path $BuildOutputDir -Filter '*.xml' -Recurse -ErrorAction SilentlyContinue
    if ($copiedFiles) {
        Write-InfoColor "`t# Successfully copied MAML help files to the build output directory." -ForegroundColor Green
    } else {
        Write-Error 'Failed to copy MAML help files to the build output directory.'
    }
}
