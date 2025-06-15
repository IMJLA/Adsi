function New-BuildUpdatableHelp {

    <#
    .SYNOPSIS
    Creates updatable help .cab files based on PlatyPS markdown help.

    .DESCRIPTION
    Generates updatable help files by processing markdown help files in different locales
    and creating .cab files for each locale using PlatyPS.

    .EXAMPLE
    New-BuildUpdatableHelp -DocsMarkdownDir './docs/markdown' -DocsMarkdownDefaultLocaleDir './docs/markdown/en-US' -BuildOutputDir './dist' -DocsUpdatableDir './docs/updatable' -ModuleName 'MyModule'
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(

        # Directory containing the markdown help files organized by locale
        [Parameter(Mandatory)]
        [string]$DocsMarkdownDir,

        # Directory containing the default locale markdown files
        [Parameter(Mandatory)]
        [string]$DocsMarkdownDefaultLocaleDir,

        # Directory where the built module files are located
        [Parameter(Mandatory)]
        [string]$BuildOutputDir,

        # Output directory where the .cab files will be created
        [Parameter(Mandatory)]
        [string]$DocsUpdatableDir,

        # Name of the module for which help is being generated
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    if ($PSCmdlet.ShouldProcess('Updatable help .cab files', "Create for module '$ModuleName' in '$DocsUpdatableDir'")) {
        $helpLocales = (Get-ChildItem -Path $DocsMarkdownDir -Directory).Name

        # Generate updatable help files.  Note: this will currently update the version number in the module's MD
        # file in the metadata.

        foreach ($locale in $helpLocales) {

            $cabParams = @{
                'CabFilesFolder'  = [IO.Path]::Combine($BuildOutputDir, $locale)
                'LandingPagePath' = [IO.Path]::Combine($DocsMarkdownDefaultLocaleDir, "$ModuleName.md")
                'OutputFolder'    = $DocsUpdatableDir
                'ErrorAction'     = 'Stop'
            }

            Write-Information "`tNew-ExternalHelpCab -CabFilesFolder '$($cabParams.CabFilesFolder)' -LandingPagePath '$($cabParams.LandingPagePath)' -OutputFolder '$($cabParams.OutputFolder)'"
            $null = New-ExternalHelpCab @cabParams

        }

        # Copy HelpInfo.xml to module root
        $HelpInfoXml = Get-ChildItem -Path $DocsUpdatableDir -Filter '*_HelpInfo.xml' -File -ErrorAction 'Stop'
        $XmlPath = [IO.Path]::Combine($DocsUpdatableDir, $HelpInfoXml.Name)
        #$ModuleRootHelpInfoPath = [IO.Path]::Combine($BuildOutputDir, 'HelpInfo.xml')
        Write-Information "`tCopy-Item -Path '$XmlPath' -Destination '$BuildOutputDir' -Force"
        Copy-Item -Path $HelpInfoXml.FullName -Destination $BuildOutputDir -Force -ErrorAction 'Stop'
        Write-InfoColor "`t# Successfully created updatable help HelpInfo.xml with HelpContent.cab files for each locale." -ForegroundColor Green

    }

}
