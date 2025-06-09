using namespace System.Management.Automation

#TODO : Use Fixer 'Get-TextFilesList $pwd | ConvertTo-SpaceIndentation'.

Properties {

    # GitHub (Source Control, Releases, and the Online Help and Documentation Website hosted on GitHub Pages)
    $GitHubOrgName = 'IMJLA'

    # Whether or not this build is a new Major version
    [boolean]$IncrementMajorVersion = $false

    # Whether or not this build is a new Minor version
    [boolean]$IncrementMinorVersion = $false

    # Folder containing the source code
    [string]$SourceCodeDir = [IO.Path]::Combine('.', 'src')

    # This character sequence will be used to separate lines in the console output
    [string]$NewLine = [System.Environment]::NewLine

    # The current working directory
    $StartingLocation = Get-Location

    # Most of the tasks will use these parameters to control how they handle output
    $IO = @{
        'ErrorAction'       = [System.Management.Automation.ActionPreference]::Stop
        'InformationAction' = [System.Management.Automation.ActionPreference]::Continue
    }



    # PlatyPS (Markdown and Updateable help)

    # Whether or not to generate markdown documentation using PlatyPS
    [boolean]$DocumentationEnabled = $true

    # Directory containing the source code for the markdown documentation
    [string]$MarkdownSourceCode = [IO.Path]::Combine($SourceCodeDir, 'docs')

    # Directory PlatyPS markdown documentation will be saved to
    [string]$DocsRootDir = [IO.Path]::Combine('.', 'docs')

    # Culture of the current UI thread
    [cultureinfo]$DocsUICulture = Get-UICulture

    # Default Locale used for help generation
    # Get-UICulture doesn't return a name on Linux so default to en-US
    [string]$DocsDefaultLocale = if (-not $DocsUICulture.Name) { 'en-US' } else { $DocsUICulture.Name }

    # Convert project readme into the module 'about file'
    [boolean]$DocsConvertReadMeToAboutFile = $true

    # Markdown-formatted Help will be created in this folder
    [string]$DocsMamlDir = [IO.Path]::Combine($DocsRootDir, 'maml')

    # Markdown-formatted Help will be created in this folder
    [string]$DocsMarkdownDir = [IO.Path]::Combine($DocsRootDir, 'markdown')

    # .CAB-formatted Updatable Help will be created in this folder
    [string]$DocsUpdateableDir = [IO.Path]::Combine($DocsRootDir, 'updateable')

    # Directory where the markdown help files will be copied to
    [string]$DocsMarkdownDefaultLocaleDir = [IO.Path]::Combine($DocsMarkdownDir, $DocsDefaultLocale)



    # Pester (Unit Testing)

    # Whether or not to perform unit tests using Pester.
    [boolean]$TestEnabled = $true

    # Unit tests found here will be performed using Pester.
    [string]$TestRootDir = [IO.Path]::Combine('.', 'tests')

    # Unit test results will be saved to this directory by Pester.
    [string]$UnitTestOutputDir = [IO.Path]::Combine('.', 'out', 'tests')

    # Unit test results will be saved to this file by Pester.
    [string]$TestResultsFile = [IO.Path]::Combine($UnitTestOutputDir, 'testResults.xml')

    <#
    Test results will be output in this format.
    This is the Pester ConfigurationProperty TestResult.OutputFormat.
    As of Pester v5, valid values are:
        NUnitXml
        JUnitXml
    #>
    enum TestOutputFormat {
        NUnitXml # NUnit-compatible XML
        JUnitXml # JUnit-compatible XML
    }
    [TestOutputFormat]$TestOutputFormat = 'NUnitXml'

    # Enable/disable Pester code coverage reporting.
    [boolean]$TestCodeCoverageEnabled = $false

    # Minimum threshold required to pass Pester code coverage testing
    [single]$TestCodeCoverageThreshold = .75

    # CodeCoverageFiles specifies the files to perform code coverage analysis on. This property
    # acts as a direct input to the Pester -CodeCoverage parameter, so will support constructions
    # like the ones found here: https://pester.dev/docs/usage/code-coverage.
    [System.IO.FileInfo[]]$TestCodeCoverageFiles = @()

    # Path to write code coverage report to
    [System.IO.FileInfo]$TestCodeCoverageOutputFile = [IO.Path]::Combine($TestRootDir, 'out', 'codeCoverage.xml')

    # Format to use for code coverage report
    enum TestCodeCoverageOutputFormat {
        JaCoCo
        CoverageGutters
    }
    [TestCodeCoverageOutputFormat]$TestCodeCoverageOutputFormat = 'JaCoCo'



    # PSScriptAnalyzer (Linting)

    # Enable/disable use of PSScriptAnalyzer to perform script analysis
    [boolean]$LintEnabled = $true

    # When PSScriptAnalyzer is enabled, control which severity level will generate a build failure.
    # Valid values are Error, Warning, Information and None.
    enum LintSeverity {
        None # Report errors but do not fail the build.
        ParseError # This diagnostic is caused by an actual parsing error, and is generated only by the engine.  The build will fail.
        Error # Fail the build only on Error diagnostic records.
        Warning # Fail the build on Warning and Error diagnostic records.
        Information # Fail the build on any diagnostic record, regardless of severity.
    }
    [LintSeverity]$LintSeverityThreshold = 'None' # Default to None so that the build does not fail by default.

    # Path to the PSScriptAnalyzer settings file.
    [string]$LintSettingsFile = [IO.Path]::Combine($SourceCodeDir, 'build', 'config', 'psscriptanalyzerSettings.psd1')



    # PowerShellBuild (Compilation, Build Processes, and MAML help)

    # The PowerShell module will be created in this folder
    [string]$BuildOutDir = [IO.Path]::Combine('.', 'dist')

    # Controls whether to "compile" module into single PSM1 or not
    [boolean]$BuildCompileModule = $true

    # List of directories that if BuildCompileModule is $true, will be concatenated into the PSM1
    [string[]]$BuildCompileDirectories = @(
        'classes',
        'enums',
        'filters',
        [IO.Path]::Combine('functions', 'private'),
        [IO.Path]::Combine('functions', 'public')
    )

    # List of directories that will always be copied "as is" to output directory
    [string[]]$BuildCopyDirectories = @(
        [IO.Path]::Combine('..', 'bin'),
        [IO.Path]::Combine('..', 'config'),
        [IO.Path]::Combine('..', 'data'),
        [IO.Path]::Combine('..', 'lib')
    )

    # List of files (regular expressions) to exclude from output directory
    [string[]]$BuildExclude = @( [IO.Path]::Combine('build', '*'), 'psdependRequirements', 'psscriptanalyzerSettings', 'gitkeep')



    # PowerShell Repository (Publication and Distribution)

    # Whether or not to publish the resultant scripts to any PowerShell repositories
    [boolean]$Publish = $true

    # PowerShell repository name to publish modules to
    [string]$PublishPSRepository = 'PSGallery'

    # API key to authenticate to PowerShell repository with
    [string]$PublishPSRepositoryApiKey = $env:PSGALLERY_API_KEY




    # Calculated Properties


    # Discover public function files so their help files can be fixed (multi-line default parameter values)
    $publicFunctionPath = [IO.Path]::Combine($SourceCodeDir, 'functions', 'public', '*.ps1')

    # Name of the module being built
    $ModuleName = $PSScriptRoot | Split-Path -Parent | Split-Path -Parent | Split-Path -Leaf

    # Path to the module script file
    $ModuleFilePath = [IO.Path]::Combine($SourceCodeDir, "$ModuleName.psm1")

    # Path to the module manifest file
    $ModuleManifestPath = [IO.Path]::Combine($SourceCodeDir, "$ModuleName.psd1")

    # Path to the ReadMe file
    $DocsMarkdownReadMePath = [IO.Path]::Combine('.', 'README.md')

    $DocsImageSourceCodeDir = [IO.Path]::Combine($SourceCodeDir, 'img')

    # Online help website will be created in this folder.
    [string]$DocsOnlineHelpRoot = [IO.Path]::Combine($DocsRootDir, 'online')

    # Online help website will be created in this folder.
    [string]$DocsOnlineHelpDir = [IO.Path]::Combine($DocsOnlineHelpRoot, $ModuleName)

    $OnlineHelpSourceMarkdown = [IO.Path]::Combine($DocsOnlineHelpDir, 'docs')

    $DocsOnlineStaticImageDir = [IO.Path]::Combine($DocsOnlineHelpDir, 'static', 'img')

    $ChangeLog = [IO.Path]::Combine('.', 'CHANGELOG.md')



    # Splatting Parameters

    [hashtable]$ModuleNameSplat = @{ 'ModuleName' = $ModuleName } # Splat for functions that need the module name
    [hashtable]$lineSplat = @{ 'NewLine' = $NewLine } # Splat for functions to handle line breaks in output
    [hashtable]$buildLocationSplat = $ModuleNameSplat + $IO + @{ 'BuildScriptRoot' = $PSScriptRoot } # Splat for Set-BuildLocation
    [hashtable]$testManifestSplat = $IO + @{ 'Path' = $ModuleManifestPath } # Splat for Test-BuildManifest
    [hashtable]$buildOutDirSplat = $ModuleNameSplat + $IO + @{ 'BuildOutDir' = $BuildOutDir } # Splat for Update-BuildOutputDir
    [hashtable]$metadataSplat = $IO + @{ 'ModuleManifestPath' = $ModuleManifestPath } # Splat for Test-BuildModuleMetadata
    [hashtable]$findPublicFunctionsSplat = $IO + @{ 'PublicFunctionPath' = $publicFunctionPath } # Splat for Find-PublicFunction
    [hashtable]$sourceControlSplat = $IO + $lineSplat + @{ 'CommitMessage' = $CommitMessage } # Splat for Invoke-SourceControl
    [hashtable]$lintAnalysisSplat = $IO + @{ 'SeverityThreshold' = $LintSeverityThreshold } # Splat for Select-LintResult
    [hashtable]$removeOldBuildSplat = $IO + @{ 'BuildOutDir' = $BuildOutDir } # Splat for Remove-OldBuild
    [hashtable]$findCopyDirSplat = $IO + @{ 'BuildCopyDirectoryPath' = $BuildCopyDirectories } # Splat for Find-BuildCopyDirectory
    [hashtable]$removeExtraBuildFileSplat = $IO # Splat for Remove-ExtraBuildFile
    [hashtable]$changeLogSplat = $IO + @{ 'ChangeLog' = $ChangeLog } # Splat for Update-BuildChangeLog
    [hashtable]$installTempModuleSplat = $ModuleNameSplat + $IO + @{ 'ModulePath' = $BuildOutDir }# Splat for Install-TempModule
    [hashtable]$importModuleSplat = $ModuleNameSplat + $IO # Splat for Import-BuildModule
    [hashtable]$updateMarkdownHelpSplat = $IO + @{ 'DocsMarkdownDir' = $DocsMarkdownDir } # Splat for Update-BuildMarkdownHelp
    [hashtable]$removeModuleSplat = $ModuleNameSplat + $IO # Splat for Remove-BuildModule
    [hashtable]$removeMAMLHelpSplat = $IO + @{ 'DocsMamlDir' = $DocsMamlDir } # Splat for Remove-BuildMAMLHelp
    [hashtable]$copyMAMLHelpSplat = $IO + @{ 'DocsMamlDir' = $DocsMamlDir } # Splat for Copy-BuildMAMLHelp
    [hashtable]$npmCacheSplat = @{ 'WorkingDirectory' = $DocsOnlineHelpDir } # Splat for Test-NpmCache
    [hashtable]$addDependenciesSplat = @{ 'WorkingDirectory' = $DocsOnlineHelpDir } # Splat for Add-OnlineHelpDependencies
    [hashtable]$installDependencySplat = @{ 'WorkingDirectory' = $DocsOnlineHelpDir } # Splat for Install-OnlineHelpDependency
    [hashtable]$convertArtSplat = @{ 'Path' = $DocsOnlineStaticImageDir } # Splat for ConvertTo-BuildArt
    [hashtable]$buildWebsiteSplat = @{ 'DocsOnlineHelpDir' = $DocsOnlineHelpDir } # Splat for Update-OnlineHelpWebsite
    [hashtable]$uninstallBuildModuleSplat = $ModuleNameSplat + $IO # Splat for Uninstall-BuildModule
    [hashtable]$installBuildModuleSplat = $ModuleNameSplat + $IO + @{ 'MaxAttempts' = 3 } # Splat for Install-BuildModule
    [hashtable]$removeUpdateableHelpSplat = $IO + @{ 'DocsUpdateableDir' = $DocsUpdateableDir } # Splat for Remove-BuildUpdatableHelp

    # Splat for Get-NewVersion
    [hashtable]$versionSplat = $IO + @{
        'IncrementMajorVersion' = $IncrementMajorVersion
        'IncrementMinorVersion' = $IncrementMinorVersion
    }

    # Splat for Export-PublicBuildFunction
    [hashtable]$exportPublicFunctionsSplat = $IO + @{
        'ModuleFilePath'     = $ModuleFilePath
        'ModuleManifestPath' = $ModuleManifestPath
    }

    # Splat for New-BuildModule
    [hashtable]$buildModuleSplat = $IO + $ModuleNameSplat + @{
        'SourceCodeDir'                = $SourceCodeDir
        'BuildCompileModule'           = $BuildCompileModule
        'BuildCompileDirectories'      = $BuildCompileDirectories
        'DocsDefaultLocale'            = $DocsDefaultLocale
        'BuildExclude'                 = $BuildExclude
        'DocsConvertReadMeToAboutFile' = $DocsConvertReadMeToAboutFile
        'DocsMarkdownReadMePath'       = $DocsMarkdownReadMeToAboutFile
    }

    # Splat for New-BuildMarkdownHelp
    [hashtable]$MarkdownHelpParams = @{
        'DocsDefaultLocale'            = $DocsDefaultLocale
        'DocsMarkdownDefaultLocaleDir' = $DocsMarkdownDefaultLocaleDir
    }

    # Splat for Copy-MarkdownForOnlineHelp
    [hashtable]$MarkdownCopyParams = @{
        'DocsMarkdownDir'          = $DocsMarkdownDir
        'OnlineHelpSourceMarkdown' = $OnlineHelpSourceMarkdown
        'MarkdownSourceCodeDir'    = $MarkdownSourceCode
    }

    # Splat for New-BuildMAMLHelp
    [hashtable]$UpdatableHelpParams = $ModuleNameSplat + @{
        'DocsMarkdownDir'              = $DocsMarkdownDir
        'DocsMarkdownDefaultLocaleDir' = $DocsMarkdownDefaultLocaleDir
        'DocsUpdateableDir'            = $DocsUpdateableDir
    }

    # Splat for New-BuildGitHubRelease
    [hashtable]$releaseSplat = $ModuleNameSplat + $IO + @{
        'GitHubToken'   = $env:GHFGPATADSI
        'GitHubOrgName' = $GitHubOrgName
        'DistPath'      = $BuildOutDir
        'ReleaseNotes'  = $CommitMessage
    }

    # Splat for Wait-RepoUpdate
    [hashtable]$waitRepoSplat = $IO + $ModuleNameSplat + @{
        'Repository'      = $PublishPSRepository
        'TimeoutSeconds'  = 60
        'IntervalSeconds' = 1
    }

    # Splat for Publish-BuildModule
    [hashtable]$publishRepoSplat = $IO + @{
        'ApiKey'     = $PublishPSRepositoryApiKey
        'Repository' = $PublishPSRepository
        'NoPublish'  = $NoPublish
    }

    # Splat for Test-OnlineHelpWebsite
    [hashtable]$TestOnlineHelpWebsiteSplat = $ModuleNameSplat + $lineSplat + $IO + @{
        'DocsOnlineHelpRoot' = $DocsOnlineHelpRoot
        'Root'               = $PSScriptRoot
    }

    # Splat for Format-SourceCode
    [hashtable]$formatSplat = $IO + @{
        'Path'         = $SourceCodeDir
        'SettingsPath' = $LintSettingsFile
    }

    # Splat for Invoke-Lint
    [hashtable]$lintSplat = $IO + @{
        'SourceCodeDir'    = $SourceCodeDir
        'LintSettingsFile' = $LintSettingsFile
    }

    # Splat for New-BuildFolder (Markdown help)
    [hashtable]$markdownFolderSplat = $IO + @{
        'Path'        = $DocsMarkdownDir
        'Description' = 'Markdown help'
    }

    # Splat for Remove-BuildMarkdownHelp
    [hashtable]$removeMarkdownHelpSplat = $IO + @{
        'DocsMarkdownDir'   = $DocsMarkdownDir
        'DocsDefaultLocale' = $DocsDefaultLocale
    }

    # Splat for New-BuildFolder (MAML help)
    [hashtable]$mamlFolderSplat = $IO + @{
        'Path'        = $DocsMamlDir
        'Description' = 'MAML help'
    }


    # Splat for New-BuildMAMLHelp
    [hashtable]$buildMAMLHelpSplat = $IO + @{
        'DocsMarkdownDir' = $DocsMarkdownDir
        'DocsMamlDir'     = $DocsMamlDir
    }

    # Splat for New-BuildFolder (Updateable help)
    [hashtable]$updateableFolderSplat = $IO + @{
        'Path'        = $DocsUpdateableDir
        'Description' = 'Updateable help'
    }

    # Splat for New-BuildFolder (Online help root)
    [hashtable]$onlineHelpFolderSplat = $IO + @{
        'Path'        = $DocsOnlineHelpRoot
        'Description' = 'Online help root'
    }

    # Splat for New-OnlineHelpScaffolding
    [hashtable]$onlineHelpScaffoldingSplat = $ModuleNameSplat + $IO + @{
        'DocsOnlineHelpRoot' = $DocsOnlineHelpRoot
        'DocsOnlineHelpDir'  = $DocsOnlineHelpDir
    }

    # Splat for New-BuildArt
    [hashtable]$buildArtSplat = $IO + $lineSplat + @{
        'In'  = $DocsImageSourceCodeDir
        'Out' = $DocsOnlineStaticImageDir
    }

    # Splat for Copy-BuildArt
    [hashtable]$copyArtSplat = $IO + @{
        'DocsImageSourceCodeDir'   = $DocsImageSourceCodeDir
        'DocsOnlineStaticImageDir' = $DocsOnlineStaticImageDir
    }

    # Splat for Update-DocusaurusConfig
    [hashtable]$fixWebsiteSplat = $IO + @{
        'GitHubOrgName'     = $GitHubOrgName
        'DocsOnlineHelpDir' = $DocsOnlineHelpDir
    }

    # Splat for New-BuildFolder (Unit test output)
    [hashtable]$unitTestFolderSplat = $IO + @{
        'Path'        = $UnitTestOutputDir
        'Description' = 'Unit test output'
    }

    [hashtable]$copyMarkdownSplat = $MarkdownCopyParams + $IO # Splat for Copy-MarkdownForOnlineHelp
    [hashtable]$MarkdownRepairParams = $lineSplat + $MarkdownHelpParams + $ModuleNameSplat # Splat for Repair-BuildMarkdownHelp
    [hashtable]$buildMarkdownHelpSplat = $MarkdownHelpParams + $ModuleNameSplat + $IO # Splat for New-BuildMarkdownHelp
    [hashtable]$fixMarkdownHelpSplat = $MarkdownRepairParams + $IO # Splat for Repair-BuildMarkdownHelp
    [hashtable]$buildUpdateableHelpSplat = $UpdatableHelpParams + $IO # Splat for New-BuildUpdatableHelp



    # Preparation for task execution

    $InformationPreference = 'Continue'

    # Dot-source the Write-InfoColor.ps1 script once to make the function available throughout the script
    # This must be done in the psakeFile, or Write-InfoColor output to the information stream is invisible in the console
    $WriteInfoColorPath = [IO.Path]::Combine($PSScriptRoot, 'functions', 'Write-InfoColor.ps1')
    . $WriteInfoColorPath

}

FormatTaskName {

    param(
        [string]$taskName
    )

    Write-InfoColor "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-InfoColor $taskName -ForegroundColor Blue

}

Task -name ? -description 'Lists the available tasks' -action {
    'Available tasks:'
    $psake.context.Peek().Tasks.Keys | Sort-Object
}

# Define the default task that runs all tasks in the build process
Task -name Default -description 'Run the default build tasks' -depends SetLocation, # Prepare the build environment.
ExportPublicFunctions, # Update the module source code.
Format, # Format the source code files.
LintAnalysis, # Perform linting and analysis of the source code.
FixModule, # Build the module.
UpdateChangeLog, # Add an entry to the Change Log.
DeleteUpdateableHelp, # Create Markdown and MAML help documentation.
BuildUpdatableHelp, # Create Updateable help documentation.
CreateOnlineHelpFolder, # Create a folder for the Online Help website.
CreateOnlineHelpWebsite, # Create the Online Help website scaffolding (Docusaurus).
BuildArt, # Build dynamic SVG art files for the Online Help website.
CopyArt, # Build and copy static SVG art files to the Online Help website.
ConvertArt, # Convert SVGs to PNG using Inkscape.
FixOnlineHelpWebsite, # Fix the online help website configuration.
UnitTests, # Perform unit testing.
SourceControl, # Commit changes to source control.
CreateGitHubRelease, # Create a GitHub release.
Publish # Publish the module to the a PowerShell repository.

# Prepare the build environment.
Task -name SetLocation -action {

    Set-BuildLocation @buildLocationSplat

} -description 'Set the working directory to the project root to ensure all relative paths are correct'

Task -name TestModuleManifest -action {

    $script:ManifestTest = Test-BuildManifest @testManifestSplat

} -description 'Validate the module manifest'


# Update the module source code.
Task -name DetermineNewVersionNumber -Depends TestModuleManifest -action {

    $script:NewModuleVersion = Get-NewVersion -OldVersion $script:ManifestTest.Version @versionSplat
    $script:HelpInfoUri = "https://github.com/$GitHubOrgName/$ModuleName/releases/download/v$script:NewModuleVersion"

} -description 'Determine the new version number based on the build parameters'

task -name UpdateBuildOutputDirVariable -depends DetermineNewVersionNumber -action {

    $script:BuildOutputDir = Update-BuildOutputDir -ModuleVersion $script:NewModuleVersion @buildOutDirSplat

} -description 'Update the build output directory environment variable'

Task -name UpdateModuleVersion -depends UpdateBuildOutputDirVariable -action {

    Update-BuildModuleMetadatum -NewVersion $script:NewModuleVersion -HelpInfoUri $script:HelpInfoUri @metadataSplat

} -description 'Update the module manifest with the new version number'

Task -name FindPublicFunctionFiles -depends UpdateModuleVersion -action {

    $script:PublicFunctionFiles = Find-PublicFunction @findPublicFunctionsSplat

} -description 'Find all public function files'

Task -name ExportPublicFunctions -depends FindPublicFunctionFiles -action {

    Export-PublicFunction -PublicFunctionFile $script:PublicFunctionFiles @exportPublicFunctionsSplat

} -description 'Export all public functions in the module'


# Perform linting and analysis of the source code.
$LintPrerequisite = { Test-LintPrereq -LintEnabled $LintEnabled @lineSplat @IO }

Task -name Format -precondition $LintPrerequisite -action {

    Format-SourceCode @formatSplat

} -description 'Format PowerShell script files using PSScriptAnalyzer rules and ensure UTF8 with BOM encoding.'

Task -name Lint -depends Format -action {

    $script:LintResult = Invoke-Lint @lintSplat

} -description 'Perform linting with PSScriptAnalyzer.'

Task -name LintAnalysis -depends Lint -action {

    Select-LintResult -LintResult $script:LintResult @lintAnalysisSplat

} -description 'Analyze the linting results and determine if the build should fail.'


# Build the module.
Task -name DeleteOldBuilds -action {

    Remove-OldBuild @removeOldBuildSplat

} -description 'Delete old builds'

Task -name FindBuildCopyDirectories -depends DeleteOldBuilds -action {

    $Script:CopyDirectories = Find-BuildCopyDirectory @findCopyDirSplat

} -description 'Find all directories to copy to the build output directory, excluding empty directories'

$FindBuildPrerequisite = { Test-BuildPrereq -BuildCompileModule $BuildCompileModule @lineSplat @IO }

Task -name BuildModule -depends FindBuildCopyDirectories -precondition $FindBuildPrerequisite -action {

    New-BuildModule -BuildOutputDir $script:BuildOutputDir -CopyDirectories $script:CopyDirectories @buildModuleSplat

} -description 'Build a PowerShell script module based on the source directory'

Task -name FixModule -depends BuildModule -action {

    Remove-ExtraBuildFile -BuildOutputDir $script:BuildOutputDir @removeExtraBuildFileSplat

} -description 'Fix the built module by removing unnecessary files. This is a workaround until PowerShellBuild usage is replaced with custom build scripts.'


# Add an entry to the Change Log.
Task -name UpdateChangeLog -action {

    Update-BuildChangeLog -Version $script:NewModuleVersion -CommitMessage $CommitMessage @changeLogSplat

} -description 'Add an entry to the the Change Log.'


# Create Markdown and MAML help documentation.
Task -name CreateMarkdownHelpFolder -action {

    New-BuildFolder @markdownFolderSplat

} -description 'Create a folder for the Markdown help documentation.'

$DocsPrereq = { Test-BuildDocumentationPrereq -DocumentationEnabled $DocumentationEnabled @lineSplat @IO }

Task -name DeleteMarkdownHelp -depends CreateMarkdownHelpFolder -precondition $DocsPrereq -action {

    Remove-BuildMarkdownHelp @removeMarkdownHelpSplat

} -description 'Delete existing Markdown files to prepare for PlatyPS to build new ones.'

Task -name InstallTempModule -depends DeleteMarkdownHelp -action {

    $script:ModuleInstallDir = Install-TempModule @installTempModuleSplat

} -description 'Install the module so it can be loaded by name for help generation.'

Task -name ImportModule -depends InstallTempModule -action {

    Import-BuildModule @importModuleSplat

} -description 'Import the module to ensure it is loaded for help generation.'

Task -name UpdateMarkDownHelp -depends ImportModule -action {

    Update-BuildMarkdownHelp @updateMarkdownHelpSplat

} -description 'Update existing Markdown help files using PlatyPS.'

Task -name BuildMarkdownHelp -depends UpdateMarkDownHelp -action {

    New-BuildMarkdownHelp -HelpVersion $script:NewModuleVersion -HelpInfoUri $script:HelpInfoUri @buildMarkdownHelpSplat

} -description 'Generate markdown files from the module help using PlatyPS'

Task -name RemoveModule -depends BuildMarkdownHelp -action {

    Remove-BuildModule @removeModuleSplat

} -description 'Remove the module from the current PowerShell session now that help generation is complete.'

Task -Name UninstallTempModule -depends RemoveModule -action {

    Uninstall-TempModule -ModuleInstallDir $script:ModuleInstallDir @IO

} -description 'Uninstall the temporary module used for help generation.'

Task -name FixMarkdownHelp -depends UninstallTempModule -action {

    Repair-BuildMarkdownHelp -BuildOutputDir $script:BuildOutputDir -PublicFunctionFiles $script:PublicFunctionFiles @fixMarkdownHelpSplat

} -description 'Fix Markdown help files for proper formatting and parameter documentation.'

Task -name CreateMAMLHelpFolder -depends FixMarkdownHelp -action {

    New-BuildFolder @mamlFolderSplat

} -description 'Create a folder for the MAML help files.'

Task -name DeleteMAMLHelp -depends CreateMAMLHelpFolder -action {

    Remove-BuildMAMLHelp @removeMAMLHelpSplat

} -description 'Delete existing MAML help files to prepare for PlatyPS to build new ones.'

Task -name BuildMAMLHelp -depends DeleteMAMLHelp -action {

    New-BuildMAMLHelp @buildMAMLHelpSplat

} -description 'Build MAML help files from the Markdown files by using PlatyPS invoked by PowerShellBuild.'

Task -name CopyMAMLHelp -depends BuildMAMLHelp -action {

    Copy-BuildMAMLHelp -BuildOutputDir $script:BuildOutputDir @copyMAMLHelpSplat

} -description 'Copy MAML help files to the build output directory.'

Task -name CreateUpdateableHelpFolder -depends CopyMAMLHelp -action {

    New-BuildFolder @updateableFolderSplat

} -description 'Create a folder for the Updateable help files.'

Task -name DeleteUpdateableHelp -depends CreateUpdateableHelpFolder -action {

    $script:ReadyForUpdateableHelp = Remove-BuildUpdatableHelp @removeUpdateableHelpSplat

} -description 'Delete existing Updateable help files to prepare for PlatyPS to build new ones.'


# Create Updateable help documentation.
$UpdateableHelpPrereq = { Test-BuildUpdateableHelpPrereq -ReadyForUpdateableHelp $script:ReadyForUpdateableHelp @lineSplat @IO }

Task -name BuildUpdatableHelp -precondition $UpdateableHelpPrereq -action {

    New-BuildUpdatableHelp -BuildOutputDir $script:BuildOutputDir @buildUpdateableHelpSplat

} -description 'Create updatable help .cab files based on PlatyPS markdown help.'


# Create a folder for the Online help documentation.
$OnlineHelpPrereqs = { Test-BuildOnlineHelpPrereq @lineSplat @IO }

Task -name CreateOnlineHelpFolder -precondition $OnlineHelpPrereqs -action {

    New-BuildFolder @onlineHelpFolderSplat

} -description 'Create a folder for the Online Help website.'


# Create the Online help documentation website.
$OnlineHelpWebsiteMissing = { -not (Test-OnlineHelpWebsite @TestOnlineHelpWebsiteSplat) }

Task -name CreateOnlineHelpWebsite -precondition $OnlineHelpWebsiteMissing -action {

    New-OnlineHelpWebsite @onlineHelpScaffoldingSplat

} -description 'Scaffold the skeleton of the Online Help website with Docusaurus which is written in TypeScript and uses React.js.'

Task -name VerifyNpmCache -action {

    Test-NpmCache @npmCacheSplat

} -description 'Clear npm cache to ensure clean dependency installation.'

Task -name InstallOnlineHelpDependencies -action {

    Install-OnlineHelpDependency @installDependencySplat

} -description 'Install the dependencies for the Online Help website.'

Task -name CopyMarkdownAsSourceForOnlineHelp -depends InstallOnlineHelpDependencies -action {

    Copy-MarkdownForOnlineHelp @copyMarkdownSplat

} -description 'Copy Markdown help files as source for online help website.'

Task -name BuildArt -depends CopyMarkdownAsSourceForOnlineHelp -action {

    $script:ArtExists = [bool]( New-BuildArt @buildArtSplat )

} -description 'Build static SVG art using PSSVG.'

Task -name CopyArt -precondition { $script:ArtExists } -action {

    $script:ArtCopied = [bool]( Copy-BuildArt @copyArtSplat )

} -description 'Copy static SVG art to the online help website.'

$InkscapePrereq = { (Test-Inkscape) -and $script:ArtCopied }

Task -name ConvertArt -precondition $InkscapePrereq -action {

    ConvertTo-BuildArt @convertArtSplat

} -description 'Convert SVGs to PNG using Inkscape.'

Task -name BuildOnlineHelpWebsite -action {

    Update-OnlineHelpWebsite @buildWebsiteSplat

} -description 'Build an Online help website based on the Markdown help files by using Docusaurus.'

Task -name FixOnlineHelpWebsite -depends BuildOnlineHelpWebsite -action {

    Update-DocusaurusConfig -ModuleInfo $script:ManifestTest @fixWebsiteSplat

} -description 'Fix the online help website configuration to use module-specific settings instead of default template.'


# Perform unit testing.
$UnitTestPrereq = { Test-BuildUnitTestPrereq -TestEnabled $TestEnabled @lineSplat @IO }

Task -name CreateUnitTestOutputDir -precondition $UnitTestPrereq -action {

    New-BuildFolder @unitTestFolderSplat

} -description 'Create a folder for the unit test results.'

Task -name UnitTests -action {

    $script:UnitTestResults = Test-Unit @IO

} -description 'Perform unit tests using Pester.'


# Commit changes to source control.
Task -name SourceControl -action {

    Invoke-SourceControl @sourceControlSplat

} -description 'git add, commit, and push'


# Create a GitHub release.
Task -name CreateGitHubRelease -action {

    Assert -conditionToCheck $env:GHFGPATADSI -failureMessage 'GitHub Personal Access Token was not defined.'

    $null = New-BuildGitHubRelease @releaseSplat

} -description 'Create a GitHub release and upload the module files to it'


# Publish the module to a PowerShell repository.
Task -name Publish -action {

    Assert -conditionToCheck $PublishPSRepositoryApiKey -failureMessage "API key not defined to authenticate with [$PublishPSRepository]."

    Publish-BuildModule -Path $script:BuildOutputDir @publishRepoSplat

} -description 'Publish module to the defined PowerShell repository'

Task -name AwaitRepoUpdate -depends Publish -action {

    $null = Wait-RepoUpdate -ExpectedVersion $script:NewModuleVersion @waitRepoSplat

} -description 'Await the new version in the defined PowerShell repository'

Task -name Uninstall -depends AwaitRepoUpdate -action {

    Uninstall-BuildModule -ModuleInstallDir $script:ModuleInstallDir @uninstallBuildModuleSplat

} -description 'Uninstall all versions of the module'

Task -name Reinstall -depends Uninstall -action {

    $null = Install-BuildModule -ExpectedVersion $script:NewModuleVersion @installBuildModuleSplat

} -description 'Reinstall the latest version of the module from the defined PowerShell repository'
