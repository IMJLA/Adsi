function New-BuildArt {

    <#
    .SYNOPSIS
    Builds dynamic SVG art files using PSSVG scripts.

    .DESCRIPTION
    This function executes PowerShell scripts found in the source art directory to generate
    dynamic SVG art files for the online help website.

    .EXAMPLE
    New-BuildArt -In 'C:\MyProject\src\img' -Out 'C:\MyProject\docs\online\MyModule\static\img'
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(

        # The source directory containing PowerShell scripts for generating art
        [Parameter(Mandatory)]
        [string]$In,

        # The destination directory for the generated art files

        [Parameter(Mandatory)]
        [string]$Out,

        # The newline character(s) to use in output messages

        [string]$NewLine = [System.Environment]::NewLine

    )

    if ($PSCmdlet.ShouldProcess($Out, 'Build dynamic art files')) {

        $null = New-Item -ItemType Directory -Path $Out -ErrorAction SilentlyContinue
        $SourceArtFiles = Get-ChildItem -Path $In -Filter '*.ps1'

        if ($SourceArtFiles.Count -eq 0) {
            Write-InfoColor "`t# No source art files found in '$In' (this may be expected if no art scripts exist).$NewLine" -ForegroundColor Green
            return
        }

        ForEach ($ScriptToRun in $SourceArtFiles) {
            $ThisPath = [IO.Path]::Combine($In, $ScriptToRun.Name)
            Write-Information "`t. $ThisPath -OutputDir '$Out'"
            . $ThisPath -OutputDir $Out
        }

        # Test if art files were created
        $artFiles = Get-ChildItem -Path $Out -ErrorAction SilentlyContinue

        if ($artFiles.Count -eq $SourceArtFiles.Count) {
            Write-InfoColor "`t# Successfully built all dynamic art files." -ForegroundColor Green
            return $artFiles
        } else {
            Write-InfoColor "`t# Warning: Not all dynamic art files were built successfully." -ForegroundColor Yellow
            return
        }

    }

}
