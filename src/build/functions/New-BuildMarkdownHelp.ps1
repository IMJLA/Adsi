function New-BuildMarkdownHelp {

    <#
    .SYNOPSIS
    Generate markdown help files from module help using PlatyPS.

    .DESCRIPTION
    This function creates new markdown help files for a PowerShell module using PlatyPS.
    It generates comprehensive documentation including parameter details and module pages.

    .EXAMPLE
    New-BuildMarkdownHelp -ModuleName 'MyModule' -HelpVersion '1.0.0' -DocsDefaultLocale 'en-US' -DocsMarkdownDefaultLocaleDir 'C:\docs\markdown\en-US'

    .NOTES
    Requires PlatyPS module to be available.
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(

        # Name of the module to generate help for
        [Parameter(Mandatory)]
        [string]$ModuleName,

        # Version number for the help files
        [Parameter(Mandatory)]
        [string]$HelpVersion,

        # Default locale for help generation
        [Parameter(Mandatory)]
        [string]$DocsDefaultLocale,

        # Output directory for markdown help files
        [Parameter(Mandatory)]
        [string]$DocsMarkdownDefaultLocaleDir,

        # Help info URI for the module
        [Parameter(Mandatory)]
        [string]$HelpInfoUri,

        # Metadata for the help files
        [hashtable]$Metadata = @{}

    )

    $markdownHelpParams = @{
        'AlphabeticParamsOrder' = $true
        'ErrorAction'           = 'Stop' # SilentlyContinue will not overwrite an existing MD file.
        'FwLink'                = $HelpInfoUri
        'HelpVersion'           = $HelpVersion
        'Locale'                = $DocsDefaultLocale
        'Metadata'              = $Metadata
        'Module'                = $ModuleName
        'OutputFolder'          = $DocsMarkdownDefaultLocaleDir
        'UseFullTypeName'       = $true
        'WithModulePage'        = $true
    }

    if ($PSCmdlet.ShouldProcess("Module '$ModuleName'", 'Generate markdown help files')) {

        Write-Information "`tNew-MarkdownHelp -AlphabeticParamsOrder `$true -HelpVersion '$HelpVersion' -Locale '$DocsDefaultLocale' -Module '$ModuleName' -OutputFolder '$DocsMarkdownDefaultLocaleDir' -UseFullTypeName `$true -WithModulePage `$true"
        $null = New-MarkdownHelp @markdownHelpParams
        Write-InfoColor "`t# Successfully generated Markdown help files." -ForegroundColor Green
    }

}
