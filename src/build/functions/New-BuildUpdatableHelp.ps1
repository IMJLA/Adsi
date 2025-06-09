function New-BuildUpdatableHelp {
    <#
    .SYNOPSIS
    Creates updatable help .cab files based on PlatyPS markdown help.

    .DESCRIPTION
    Generates updatable help files by processing markdown help files in different locales
    and creating .cab files for each locale using PlatyPS.

    .PARAMETER DocsMarkdownDir
    Directory containing the markdown help files organized by locale.

    .PARAMETER DocsMarkdownDefaultLocaleDir
    Directory containing the default locale markdown files.

    .PARAMETER BuildOutputDir
    Directory where the built module files are located.

    .PARAMETER DocsUpdateableDir
    Output directory where the .cab files will be created.

    .PARAMETER ModuleName
    Name of the module for which help is being generated.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$DocsMarkdownDir,

        [Parameter(Mandatory)]
        [string]$DocsMarkdownDefaultLocaleDir,

        [Parameter(Mandatory)]
        [string]$BuildOutputDir,

        [Parameter(Mandatory)]
        [string]$DocsUpdateableDir,

        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    if ($PSCmdlet.ShouldProcess('Updatable help .cab files', "Create for module '$ModuleName' in '$DocsUpdateableDir'")) {
        $helpLocales = (Get-ChildItem -Path $DocsMarkdownDir -Directory).Name

        # Generate updatable help files.  Note: this will currently update the version number in the module's MD
        # file in the metadata.

        foreach ($locale in $helpLocales) {

            $cabParams = @{
                'CabFilesFolder'  = [IO.Path]::Combine($BuildOutputDir, $locale)
                'LandingPagePath' = [IO.Path]::Combine($DocsMarkdownDefaultLocaleDir, "$ModuleName.md")
                'OutputFolder'    = $DocsUpdateableDir
                'ErrorAction'     = 'Stop'
            }

            Write-Information "`tNew-ExternalHelpCab -CabFilesFolder '$($cabParams.CabFilesFolder)' -LandingPagePath '$($cabParams.LandingPagePath)' -OutputFolder '$($cabParams.OutputFolder)'"
            $null = New-ExternalHelpCab @cabParams

        }
        # Copy HelpInfo.xml to module root
        $HelpInfoXml = Get-Item -Path $DocsUpdateableDir -Filter '*_HelpInfo.xml' -ErrorAction 'Stop'
        $XmlPath = [IO.Path]::Combine($DocsUpdateableDir, $HelpInfoXml.Name)
        $ModuleRootHelpInfoPath = [IO.Path]::Combine($BuildOutputDir, 'HelpInfo.xml')
        Write-Information "`tCopy-Item -Path '$XmlPath' -Destination '$ModuleRootHelpInfoPath' -Force"
        Copy-Item -Path $HelpInfoXml.FullName -Destination $ModuleRootHelpInfoPath -Force -ErrorAction 'Stop'
        Write-InfoColor "`t# Successfully created updatable help .cab files for each locale." -ForegroundColor Green

    }

}
