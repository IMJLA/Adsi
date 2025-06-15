function Remove-BuildMAMLHelp {

    <#
    .SYNOPSIS
    Delete existing MAML help files to prepare for PlatyPS to build new ones.

    .DESCRIPTION
    This function removes all existing MAML help files from the specified directory to ensure a clean build environment for new MAML help generation.

    .EXAMPLE
    Remove-BuildMAMLHelp -DocsMamlDir 'C:\MyProject\docs\maml'
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(

        # Path to the MAML help directory
        [Parameter(Mandatory)]
        [string]$DocsMamlDir
    )

    Write-Information "`tGet-ChildItem -Path '$DocsMamlDir' -Recurse | Remove-Item -Recurse -Force"

    if ($PSCmdlet.ShouldProcess($DocsMamlDir, 'Remove existing MAML help files')) {
        Get-ChildItem -Path $DocsMamlDir -Recurse -ErrorAction Stop | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue -ProgressAction SilentlyContinue
        Write-InfoColor "`t# Successfully deleted existing MAML help files." -ForegroundColor Green
    }

}
