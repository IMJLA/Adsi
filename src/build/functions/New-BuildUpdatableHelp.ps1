function New-BuildUpdatableHelp {

    <#
    .SYNOPSIS
    Creates updatable help .cab files based on PlatyPS markdown help.

    .DESCRIPTION
    Generates updatable help files by processing markdown help files in different locales
    and creating .cab files for each locale using PlatyPS.

    .EXAMPLE
    New-BuildUpdatableHelp -DocsMarkdownDir './docs/markdown' -DocsMarkdownDefaultLocaleDir './docs/markdown/en-US' -BuildOutputDir './dist' -DocsUpdateableDir './docs/updateable' -ModuleName 'MyModule'
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
        [string]$DocsUpdateableDir,

        # Name of the module for which help is being generated
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [string]$ModuleGuid
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
        $HelpInfoXml = Get-ChildItem -Path $DocsUpdateableDir -Filter '*_HelpInfo.xml' -File -ErrorAction 'Stop'
        $XmlPath = [IO.Path]::Combine($DocsUpdateableDir, $HelpInfoXml.Name)
        #$ModuleRootHelpInfoPath = [IO.Path]::Combine($BuildOutputDir, 'HelpInfo.xml')
        Write-Information "`tCopy-Item -Path '$XmlPath' -Destination '$BuildOutputDir' -Force"
        Copy-Item -Path $HelpInfoXml.FullName -Destination $BuildOutputDir -Force -ErrorAction 'Stop'

        <#
        PowerShell’s Update-Help does exactly two lookups for your HelpInfo.xml:

        A “lower-case” trial: It takes your module’s Name (Adsi) and does a ToLowerInvariant(), so it first GETs …/UpdateableHelp/adsi_<GUID>_HelpInfo.xml (hence your 404).

        The “correct-case” retry: It then GETs …/UpdateableHelp/Adsi_<GUID>_HelpInfo.xml which succeeds and lets it parse the <HelpContentUri> element properly.

        Because GitHub Pages is case-sensitive, that first lowercase attempt will always 404 if you only checked in the PascalCase file. There’s no built-in way to suppress it—it’s simply Update-Help’s fallback logic at work, logged because you ran -Verbose.

        You have three options:

        • Ignore it It’s only a verbose log line, and Update-Help proceeds normally once the correct file is found.

        • Mirror the lowercase filename Add a second copy (or redirect) named adsi_282a2aed-9567-49a1-901c-122b7831a805_HelpInfo.xml in the same folder. Then both requests return 200.

        • Host locally via -SourcePath If you don’t want any HTTP lookups at all, build cab + xml locally and call: powershell Update-Help -Module Adsi -SourcePath 'C:\MyHelpRepo' -Force -Verbose (bypasses the web lookup entirely).

        In practice most folks just ignore the first 404—once the correct-case URI succeeds, your updatable help installs without any further errors.
        #>
        $Lowercase = [IO.Path]::Combine($BuildOutputDir, "$($ModuleName.ToLowerInvariant())`_$ModuleGuid`_HelpInfo.xml")
        Write-Information "`tCopy-Item -Path '$XmlPath' -Destination '$Lowercase' -Force"
        Copy-Item -Path $HelpInfoXml.FullName -Destination $Lowercase -Force -ErrorAction 'Stop'

        $html = @"
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="refresh" content="0; url=$ModuleName`_$ModuleGuid`_HelpInfo.xml">
    </head>
    <body>
        Redirecting to helpInfo.xml…
    </body>
</html>

"@
        Write-InfoColor "`t# Successfully created updatable help HelpInfo.xml with HelpContent.cab files for each locale." -ForegroundColor Green

    }

}
