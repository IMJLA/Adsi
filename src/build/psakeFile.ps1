using namespace System.Management.Automation
#TODO : Use Fixer 'Get-TextFilesList $pwd | ConvertTo-SpaceIndentation'.

Properties {

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



    # PlatyPS (Markdown and Updateable help)

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

    # Unit test results will be saved to this file by Pester.
    [string]$TestResultsFile = [IO.Path]::Combine($TestsRootDir, 'out', 'testResults.xml')

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
    [LintSeverity]$LintSeverityThreshold = 'Error'

    # Path to the PSScriptAnalyzer settings file.
    [string]$LintSettingsFile = [IO.Path]::Combine($SourceCodeDir, 'build', 'psscriptanalyzerSettings.psd1')



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

    # Credential to authenticate to PowerShell repository with
    [string]$PublishPSRepositoryCredential = $null




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

    $DocsOnlineStaticImageDir = [IO.Path]::Combine($DocsOnlineHelpDir, 'static', 'img')

    # Online help website will be created in this folder.
    $DocsOnlineHelpDir = [IO.Path]::Combine('..', '..', 'docs', 'online', $ModuleName)

    $ChangeLog = [IO.Path]::Combine('.', 'CHANGELOG.md')

    # Dot-source the Write-InfoColor.ps1 script once to make the function available throughout the script
    $WriteInfoScript = [IO.Path]::Combine('.', 'Write-InfoColor.ps1')
    . $WriteInfoScript

    $InformationPreference = 'Continue'

}

FormatTaskName {

    param(
        [string]$taskName
    )

    Write-InfoColor "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-InfoColor $taskName -ForegroundColor Blue

}

Task Default -depends SetLocation, DeleteOldBuilds, ReturnToStartingLocation

$FindLintPrerequisites = {

    Write-InfoColor "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-InfoColor "FindLintPrerequisites$NewLine" -ForegroundColor Blue

    if ($LintEnabled) {
        Write-InfoColor "`tGet-Module -Name PSScriptAnalyzer -ListAvailable"
        [boolean](Get-Module -Name PSScriptAnalyzer -ListAvailable)
    }
    else {
        Write-InfoColor "`tLinting is disabled. Skipping PSScriptAnalyzer check."
    }

}

$FindBuildPrerequisite = {

    Write-InfoColor "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-InfoColor "FindBuildPrerequisite$NewLine" -ForegroundColor Blue

    if ($BuildCompileModule) {
        Write-InfoColor "`tGet-Module -Name PowerShellBuild -ListAvailable"
        [boolean](Get-Module -Name PowerShellBuild -ListAvailable)
    }
    else {
        Write-InfoColor "`tBuilding is disabled. Skipping PowerShellBuild check."
    }

}

$FindUnitTestPrerequisite = {

    Write-InfoColor "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-InfoColor "FindUnitTestPrerequisite$NewLine" -ForegroundColor Blue

    if ($TestEnabled) {
        Write-InfoColor "`tGet-Module -Name Pester -ListAvailable"
        [boolean](Get-Module -Name Pester -ListAvailable)
    }
    else {
        Write-InfoColor "`tUnit testing is disabled. Skipping Pester check."
    }

}

$FindDocsPrerequisite = {

    Write-InfoColor "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-InfoColor "FindDocsPrerequisite$NewLine" -ForegroundColor Blue

    Write-InfoColor "`tGet-Module -Name PlatyPS -ListAvailable"
    [boolean](Get-Module -Name PlatyPS -ListAvailable)

}

$FindDocsUpdateablePrerequisite = {

    Write-InfoColor "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-InfoColor "FindDocsUpdateablePrerequisite$NewLine" -ForegroundColor Blue

    if ($FindDocsPrerequisite) {

        Write-InfoColor "`tGet-CimInstance -ClassName CIM_OperatingSystem"
        $OS = (Get-CimInstance -ClassName CIM_OperatingSystem).Caption

        if ($OS -match 'Windows') {

            Write-InfoColor "`tGet-Command -Name MakeCab.exe"
            [boolean](Get-Command -Name MakeCab.exe)

        }
        else {
            Write-InfoColor "`tMakeCab.exe is not available on this operating system. Skipping Updateable Help generation."
        }

    }
    else {
        Write-InfoColor "`tPrerequisite module PlatyPS not found so Markdown docs will not be generated or converted to MAML for input to MakeCab.exe. Skipping Updateable Help generation."
    }

}

Task SetLocation -action {

    Write-InfoColor "`tSet-Location -Path '$ModuleName'"
    Set-Location -Path $PSScriptRoot
    [string]$ProjectRoot = [IO.Path]::Combine('..', '..')
    Set-Location -Path $ProjectRoot

} -description 'Set the working directory to the project root to ensure all relative paths are correct'

Task TestModuleManifest -depends SetLocation -action {

    Write-InfoColor "`tTest-ModuleManifest -Path '$ModuleManifestPath'"
    $script:ManifestTest = Test-ModuleManifest -Path $ModuleManifestPath

} -description 'Validate the module manifest'

Task Lint -precondition $FindLintPrerequisites -depends TestModuleManifest -action {

    Write-InfoColor "`tInvoke-ScriptAnalyzer -Path '$SourceCodeDir' -Settings '$LintSettingsFile' -Severity '$LintSeverityThreshold' -Recurse -Verbose:$VerbosePreference"
    $script:LintResult = Invoke-ScriptAnalyzer -Path $SourceCodeDir -Settings $LintSettingsFile -Severity $LintSeverityThreshold -Recurse -Verbose:$VerbosePreference

} -description 'Perform linting with PSScriptAnalyzer.'

Task LintAnalysis -depends Lint -action {

    $ScriptToRun = [IO.Path]::Combine($SourceCodeDir, 'build', 'Select-LintResult.ps1')
    Write-InfoColor "`t& '$ScriptToRun' -Path '$SourceCodeDir' -SeverityThreshold '$LintSeverityThreshold' -SettingsPath '$LintSettingsFile' -LintResult `$script:LintResult"
    & $ScriptToRun -Path $SourceCodeDir -SeverityThreshold $LintSeverityThreshold -SettingsPath $LintSettingsFile -LintResult $script:LintResult

} -description 'Analyze the linting results and determine if the build should fail.'

Task DetermineNewVersionNumber -depends LintAnalysis -action {

    $ScriptToRun = [IO.Path]::Combine($SourceCodeDir, 'build', 'Get-NewVersion.ps1')
    Write-InfoColor "`t& '$ScriptToRun' -IncrementMajorVersion:`$$IncrementMajorVersion -IncrementMinorVersion:`$$IncrementMinorVersion -OldVersion '$($script:ManifestTest.Version)'"
    $script:NewModuleVersion = & $ScriptToRun -IncrementMajorVersion:$IncrementMajorVersion -IncrementMinorVersion:$IncrementMinorVersion -OldVersion $script:ManifestTest.Version
    $script:BuildOutputDir = [IO.Path]::Combine($BuildOutDir, $script:NewModuleVersion, $ModuleName)
    $env:BHBuildOutput = $script:BuildOutputDir # still used by Module.tests.ps1

} -description 'Determine the new version number based on the build parameters'

Task UpdateModuleVersion -depends DetermineNewVersionNumber -action {

    Write-InfoColor "`tUpdate-Metadata -Path '$ModuleManifestPath' -PropertyName ModuleVersion -Value $script:NewModuleVersion -ErrorAction Stop"
    Update-Metadata -Path $ModuleManifestPath -PropertyName ModuleVersion -Value $script:NewModuleVersion -ErrorAction Stop

} -description 'Update the module manifest with the new version number'

Task BackupOldBuilds -depends UpdateModuleVersion -action {

    Write-InfoColor "`tRename-Item -Path '$BuildOutDir' -NewName '$BuildOutDir.old' -Force"
    Rename-Item -Path $BuildOutDir -NewName "$BuildOutDir.old" -Force -ErrorAction SilentlyContinue

} -description 'Backup old builds'

Task UpdateChangeLog -depends BackupOldBuilds -action {

    $ScriptToRun = [IO.Path]::Combine($SourceCodeDir, 'build', 'Update-ChangeLog.ps1')
    Write-InfoColor "`t& '$ScriptToRun' -Version $script:NewModuleVersion -CommitMessage '$CommitMessage' -ChangeLog '$ChangeLog'"
    & $ScriptToRun -Version $script:NewModuleVersion -CommitMessage $CommitMessage -ChangeLog $ChangeLog

    <#
    TODO
        This task runs before the Test task so that tests of the change log will pass
        But I also need one that runs *after* the build to compare it against the previous build
        The post-build UpdateChangeLog will automatically add to the change log any:
            New/removed exported commands
            New/removed files
    #>

} -description 'Add an entry to the the Change Log.'

Task FindPublicFunctionFiles -depends UpdateChangeLog -action {

    Write-InfoColor "`t`$script:PublicFunctionFiles = Get-ChildItem -Path '$publicFunctionPath' -Recurse"
    $script:PublicFunctionFiles = Get-ChildItem -Path $publicFunctionPath -Recurse

} -description 'Find all public function files'

Task ExportPublicFunctions -depends FindPublicFunctionFiles -action {

    $ScriptToRun = [IO.Path]::Combine($SourceCodeDir, 'build', 'Export-PublicFunction.ps1')
    Write-InfoColor "`t& '$ScriptToRun' -PublicFunctionFiles `$script:PublicFunctionFiles -ModuleFilePath '$ModuleFilePath' -ModuleManifestPath '$ModuleManifestPath'"
    & $ScriptToRun -PublicFunctionFiles $script:PublicFunctionFiles -ModuleFilePath $ModuleFilePath -ModuleManifestPath $ModuleManifestPath

} -description 'Export all public functions in the module'

Task FindBuildCopyDirectories -depends ExportPublicFunctions -action {

    $ScriptToRun = [IO.Path]::Combine($SourceCodeDir, 'build', 'Find-BuildCopyDirectory.ps1')
    Write-InfoColor "`t& '$ScriptToRun' -BuildCopyDirectory @('$($BuildCopyDirectories -join "','")')"
    & $ScriptToRun -BuildCopyDirectory $BuildCopyDirectories

} -description 'Find all directories to copy to the build output directory, excluding empty directories'

Task BuildModule -depends FindBuildCopyDirectories -precondition $FindBuildPrerequisite -action {

    $buildParams = @{
        Path               = $SourceCodeDir
        ModuleName         = $ModuleName
        DestinationPath    = $script:BuildOutputDir
        Exclude            = $BuildExclude + "$ModuleName.psm1"
        Compile            = $BuildCompileModule
        CompileDirectories = $BuildCompileDirectories
        CopyDirectories    = $script:CopyDirectories
        Culture            = $DocsDefaultLocale
    }

    if ($DocsConvertReadMeToAboutFile) {
        $buildParams.ReadMePath = $DocsMarkdownReadMePath
    }

    # only add these configuration values to the build parameters if they have been been set
    'CompileHeader', 'CompileFooter', 'CompileScriptHeader', 'CompileScriptFooter' | ForEach-Object {
        $Val = Get-Variable -name $_ -ValueOnly -ErrorAction SilentlyContinue
        if ($Val -ne '') {
            $buildParams.$_ = $Val
        }
    }

    $ExcludeJoined = $buildParams['Exclude'] -join "','"
    $CompileDirectoriesJoined = $buildParams['CompileDirectories'] -join "','"
    $CopyDirectoriesJoined = $buildParams['CopyDirectories'] -join "','"
    Write-InfoColor "`tBuild-PSBuildModule -Path '$SourceCodeDir' -ModuleName '$ModuleName' -DestinationPath '$script:BuildOutputDir' -Exclude @('$ExcludeJoined') -Compile '$BuildCompileModule' -CompileDirectories @('$CompileDirectoriesJoined') -CopyDirectories @('$CopyDirectoriesJoined') -Culture '$DocsDefaultLocale' -ReadMePath '$DocsMarkdownReadMePath' -CompileHeader '$($buildParams['CompileHeader'])' -CompileFooter '$($buildParams['CompileFooter'])' -CompileScriptHeader '$($buildParams['CompileScriptHeader'])' -CompileScriptFooter '$($buildParams['CompileScriptFooter'])'"
    Build-PSBuildModule @buildParams

} -description 'Build a PowerShell script module based on the source directory'

Task FixModule -depends BuildModule -action {

    $File = [IO.Path]::Combine($script:BuildOutputDir, 'psdependRequirements.psd1')
    Write-InfoColor "`tRemove-Item -Path '$File'"
    Remove-Item -Path $File -ErrorAction SilentlyContinue

    $File = [IO.Path]::Combine($script:BuildOutputDir, 'psscriptanalyzerSettings.psd1')
    Write-InfoColor "`tRemove-Item -Path '$File'"
    Remove-Item -Path $File -ErrorAction SilentlyContinue

} -description 'Fix the module after building it by removing unnecessary files. This is a workaround until PowerShellBuild usage is replaced with custom build scripts.'

Task DeleteOldBuilds -depends FixModule -action {

    Write-InfoColor "`tRemove-Item -Path '$BuildOutDir.old' -Recurse -Force -ErrorAction SilentlyContinue"
    Remove-Item -Path "$BuildOutDir.old" -Recurse -Force -ErrorAction SilentlyContinue

} -description 'Delete old builds'

Task CreateMarkdownHelpFolder -depends DeleteOldBuilds -action {

    Write-Host "`tNew-Item -Path '$DocsMarkdownDir' -ItemType Directory -ErrorAction SilentlyContinue"
    $null = New-Item -Path $DocsMarkdownDir -ItemType Directory -ErrorAction SilentlyContinue

} -description 'Create a folder for the Markdown help documentation.'

Task DeleteMarkdownHelp -depends CreateMarkdownHelpFolder -precondition { $FindDocsPrerequisite } -action {

    $MarkdownDir = [IO.Path]::Combine($DocsMarkdownDir, $HelpDefaultLocale)
    Write-Host "`tGet-ChildItem -Path '$MarkdownDir' -Recurse | Remove-Item -Force -ErrorAction SilentlyContinue"
    Get-ChildItem -Path $MarkdownDir -Recurse | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

} -description 'Delete existing Markdown files to prepare for PlatyPS to build new ones.'

Task UpdateMarkDownHelp -depends DeleteMarkdownHelp -action {

    if (Get-ChildItem -LiteralPath $DocsMarkdownDir -Filter *.md -Recurse) {

        Get-ChildItem -LiteralPath $DocsMarkdownDir -Directory | ForEach-Object {

            $DirName = $_.FullName
            Write-InfoColor "`tUpdate-MarkdownHelp -Path '$($_.FullName)'"

            try {
                Update-MarkdownHelp -Path $_.FullName -Verbose:$VerbosePreference > $null
            }
            catch {
                Write-Warning "Failed to update markdown help for $DirName`: $($_.Exception.Message)"
            }

        }

    }
    else {
        Write-InfoColor "`tNo existing Markdown help files found to update." -ForegroundColor Cyan
    }

} -description 'Update existing Markdown help files using PlatyPS.'

Task BuildMarkdownHelp -depends UpdateMarkDownHelp -precondition $FindDocsPrerequisite -action {

    try {

        $newMDParams = @{
            AlphabeticParamsOrder = $true
            Locale                = $DocsDefaultLocale
            ErrorAction           = 'SilentlyContinue' # SilentlyContinue will not overwrite an existing MD file.
            HelpVersion           = $script:NewModuleVersion
            Module                = $ModuleName
            # TODO: Using GitHub pages as a container for PowerShell Updatable Help https://gist.github.com/TheFreeman193/fde11aee6998ad4c40a314667c2a3005
            # OnlineVersionUrl = $GitHubPagesLinkForThisModule
            OutputFolder          = $DocsMarkdownDefaultLocaleDir
            UseFullTypeName       = $true
            WithModulePage        = $true
        }
        Write-InfoColor "`tNew-MarkdownHelp -AlphabeticParamsOrder `$true -HelpVersion '$script:NewModuleVersion' -Locale '$DocsDefaultLocale' -Module '$ModuleName' -OutputFolder '$DocsMarkdownDefaultLocaleDir' -UseFullTypeName `$true -WithModulePage `$true"
        $null = New-MarkdownHelp @newMDParams
    }
    finally {
        Remove-Module $ModuleName -Force
    }
} -description 'Generate markdown files from the module help'

Task FixMarkdownHelp -depends BuildMarkdownHelp -action {

    $ScriptToRun = [IO.Path]::Combine($SourceCodeDir, 'build', 'Repair-MarkdownHelp.ps1')
    Write-InfoColor "`t& '$ScriptToRun' -BuildOutputDir '$script:BuildOutputDir' -ModuleName '$ModuleName' -DocsMarkdownDefaultLocaleDir '$DocsMarkdownDefaultLocaleDir' -NewLine `$NewLine -DocsDefaultLocale '$DocsDefaultLocale' -PublicFunctionFiles `$script:PublicFunctionFiles"
    & $ScriptToRun -BuildOutputDir $script:BuildOutputDir -ModuleName $ModuleName -DocsMarkdownDefaultLocaleDir $DocsMarkdownDefaultLocaleDir -NewLine $NewLine -DocsDefaultLocale $DocsDefaultLocale -PublicFunctionFiles $script:PublicFunctionFiles

}

Task CreateMAMLHelpFolder -depends FixMarkdownHelp -action {

    Write-Host "`tNew-Item -Path '$DocsMamlDir' -ItemType Directory -ErrorAction SilentlyContinue"
    $null = New-Item -Path $DocsMamlDir -ItemType Directory -ErrorAction SilentlyContinue

} -description 'Create a folder for the MAML help files.'

Task DeleteMAMLHelp -depends CreateMAMLHelpFolder -precondition { $FindDocsPrerequisite } -action {

    Write-Host "`tGet-ChildItem -Path '$DocsMamlDir' -Recurse | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue"
    Get-ChildItem -Path $DocsMamlDir -Recurse | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

} -description 'Delete existing MAML help files to prepare for PlatyPS to build new ones.'

Task BuildMAMLHelp -depends DeleteMAMLHelp -action {

    Write-InfoColor "`tBuild-PSBuildMAMLHelp -Path '$DocsMarkdownDir' -DestinationPath '$DocsMamlDir'"
    Build-PSBuildMAMLHelp -Path $DocsMarkdownDir -DestinationPath $DocsMamlDir

} -description 'Build MAML help files from the Markdown files by using PlatyPS invoked by PowerShellBuild.'

Task CopyMAMLHelp -depends BuildMAMLHelp -action {

    Write-InfoColor "`tCopy-Item -Path '$DocsMamlDir\*' -Destination '$script:BuildOutputDir' -Recurse -ErrorAction SilentlyContinue"
    Copy-Item -Path "$DocsMamlDir\*" -Destination $script:BuildOutputDir -Recurse -ErrorAction SilentlyContinue

} -description 'Copy MAML help files to the build output directory.'

Task CreateUpdateableHelpFolder -depends CopyMAMLHelp -action {

    Write-Host "`tNew-Item -Path '$DocsUpdateableDir' -ItemType Directory -ErrorAction SilentlyContinue"
    $null = New-Item -Path $DocsUpdateableDir -ItemType Directory -ErrorAction SilentlyContinue

} -description 'Create a folder for the Updateable help files.'

Task DeleteUpdateableHelp -depends CreateUpdateableHelpFolder -precondition { $FindDocsPrerequisite } -action {

    Write-Host "`tGet-ChildItem -Path '$DocsUpdateableDir' -Recurse | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue"
    Get-ChildItem -Path $DocsUpdateableDir -Recurse | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

} -description 'Delete existing Updateable help files to prepare for PlatyPS to build new ones.'

Task BuildUpdatableHelp -depends DeleteUpdateableHelp -precondition $FindDocsUpdateablePrerequisite -action {

    $helpLocales = (Get-ChildItem -Path $DocsMarkdownDir -Directory).Name

    # Generate updatable help files.  Note: this will currently update the version number in the module's MD
    # file in the metadata.
    foreach ($locale in $helpLocales) {
        $cabParams = @{
            CabFilesFolder  = [IO.Path]::Combine($script:BuildOutputDir, $locale)
            LandingPagePath = [IO.Path]::Combine($DocsMarkdownDefaultLocaleDir, "$ModuleName.md")
            OutputFolder    = $DocsUpdateableDir
        }
        Write-InfoColor "`tNew-ExternalHelpCab -CabFilesFolder '$($cabParams.CabFilesFolder)' -LandingPagePath '$($cabParams.LandingPagePath)' -OutputFolder '$($cabParams.OutputFolder)'"
        New-ExternalHelpCab @cabParams > $null
    }

} -description 'Create updatable help .cab file based on PlatyPS markdown help.'

Task CopyMarkdownAsSourceForOnlineHelp -depends BuildUpdatableHelp -action {

    $OnlineHelpSourceMarkdown = [IO.Path]::Combine($DocsOnlineHelpDir, 'docs')
    $MarkdownSourceCode = [IO.Path]::Combine('..', '..', 'src', 'docs')
    $helpLocales = (Get-ChildItem -Path $DocsMarkdownDir -Directory -Exclude 'UpdatableHelp').Name

    ForEach ($Locale in $helpLocales) {
        Write-Host "`tCopy-Item -Path '$DocsMarkdownDir\*' -Destination '$OnlineHelpSourceMarkdown' -Recurse"
        Copy-Item -Path "$DocsMarkdownDir\*" -Destination $OnlineHelpSourceMarkdown -Recurse
        Write-Host "`tCopy-Item -Path '$MarkdownSourceCode\*' -Destination '$OnlineHelpSourceMarkdown\$Locale' -Recurse"
        Copy-Item -Path "$MarkdownSourceCode\*" -Destination "$OnlineHelpSourceMarkdown\$Locale" -Recurse
    }

}

Task BuildArt -depends BuildUpdatableHelp -action {

    $null = New-Item -ItemType Directory -Path $DocsOnlineStaticImageDir -ErrorAction SilentlyContinue

    ForEach ($ScriptToRun in (Get-ChildItem -Path $DocsImageSourceCodeDir -Filter '*.ps1')) {
        $ThisPath = [IO.Path]::Combine($DocsImageSourceCodeDir, $ScriptToRun.Name)
        Write-Information "`t. $ThisPath -OutputDir '$DocsOnlineStaticImageDir'"
        . $ThisPath -OutputDir $DocsOnlineStaticImageDir
    }

} -description 'Build dynamic SVG art using PSSVG.'

Task CopyArt -depends BuildArt -action {

    Write-Host "`tGet-ChildItem -Path '$DocsImageSourceCodeDir' -Filter '*.svg' |"
    Write-Host "`tCopy-Item -Destination '$DocsOnlineStaticImageDir'"

    Get-ChildItem -Path $DocsImageSourceCodeDir -Filter '*.svg' |
    Copy-Item -Destination $DocsOnlineStaticImageDir

} -description 'Copy static SVG art to the online help website.'

Task ConvertArt -depends CopyArt -action {

    #$ScriptToRun = [IO.Path]::Combine('.', 'ConvertFrom-SVG.ps1')
    #$sourceSVG = [IO.Path]::Combine($DocsOnlineStaticImageDir, 'logo.svg')
    #Write-Host "`t. $ScriptToRun -Path '$sourceSVG' -ExportWidth 512"
    #. $ScriptToRun -Path $sourceSVG -ExportWidth 512

} -description 'Convert SVGs to PNG using Inkscape.'

Task FindNodeJS -depends ConvertArt -action {

    Write-Information "`tGet-Command -Name node -ErrorAction SilentlyContinue"
    $NodeCommand = Get-Command -name node -ErrorAction SilentlyContinue
    if ($NodeCommand) {

        Write-InfoColor "`t& node -v 2>`$null"
        $NodeJsVersion = & node -v 2>$null

        if ([version]($NodeJsVersion.Replace('v', '')) -lt [version]'18.0.0') {
            Write-Warning "Node.js is installed but version 18 or newer is required (detected version: $NodeJsVersion). Please update Node.js to continue."
            Exit 1
        }

    }
    else {
        Write-Warning 'Node.js is not installed or not found in the PATH. Please install Node.js to continue.'
        Exit 1
    }

} -description 'Find Node.js installation.'

Task CreateOnlineHelpWebsite -depends FindNodeJS {

    $Location = Get-Location
    Write-Information "`tSet-Location -Path '$DocsOnlineHelpDir'"
    Set-Location $DocsOnlineHelpDir

    # Check if package.json exists (indicating Docusaurus is already initialized)
    $PackageJsonPath = Join-Path $DocsOnlineHelpDir 'package.json'

    if (-not (Test-Path $PackageJsonPath)) {
        Write-Host "`tnpx 'create-docusaurus@latest' . classic --typescript"
        & npx 'create-docusaurus@latest' . classic --typescript

        Write-Host "`tnpm install"
        & npm install
    }
    else {
        Write-Host "`tDocusaurus website already exists, skipping initialization"
    }

    Set-Location $Location

} -description 'Scaffold the skeleton of the Online Help website with Docusaurus which is written in TypeScript and uses React.js.'

Task BuildOnlineHelp -depends CreateOnlineHelpWebsite {

    $Location = Get-Location
    Write-Information "`tSet-Location -Path '$DocsOnlineHelpDir'"
    Set-Location $DocsOnlineHelpDir
    Write-Host "`tnpm run build"
    & npm run build
    Set-Location $Location

} -description 'Build an Online help website based on the Markdown help files by using Docusaurus.'

Task UnitTests -depends BuildOnlineHelp -precondition $FindUnitTestPrerequisite -action {

    Write-InfoColor "`t`$PesterConfigParams  = Get-Content -Path '.\tests\config\pesterConfig.json' | ConvertFrom-Json -AsHashtable"
    $PesterConfigParams = Get-Content -Path '.\tests\config\pesterConfig.json' | ConvertFrom-Json -AsHashtable
    Write-InfoColor "`t`$PesterConfiguration = New-PesterConfiguration -Hashtable `$PesterConfigParams"
    $PesterConfiguration = New-PesterConfiguration -Hashtable $PesterConfigParams
    Write-InfoColor "`tInvoke-Pester -Configuration `$PesterConfiguration"
    Invoke-Pester -Configuration $PesterConfiguration

} -description 'Perform unit tests using Pester.'

Task SourceControl -depends UnitTests -action {

    # Find the current git branch
    $CurrentBranch = git branch --show-current

    # Commit to Git
    Write-InfoColor "`tgit add ."
    git add .
    Write-InfoColor "`tgit commit -m $CommitMessage"
    git commit -m $CommitMessage
    Write-InfoColor "`tgit push origin $CurrentBranch"
    git push origin $CurrentBranch

} -description 'git add, commit, and push'

Task CreateGitHubRelease -depends SourceControl -action {

    $GitHubOrgName = 'IMJLA'
    $RepositoryPath = "$GitHubOrgName/$ModuleName"
    $ScriptToRun = [IO.Path]::Combine($SourceCodeDir, 'build', 'New-GitHubRelease.ps1')
    Write-InfoColor "`t& '$ScriptToRun' -GitHubToken `$Token -Repository '$RepositoryPath' -DistPath '$BuildOutDir' -ReleaseNotes '$CommitMessage'"
    $release = & $ScriptToRun -GitHubToken $env:GHFGPATADSI -Repository $RepositoryPath -DistPath $BuildOutDir -ReleaseNotes $CommitMessage
    Write-InfoColor "$NewLine`tRelease URL: $($release.html_url)" -ForegroundColor Cyan

} -description 'Create a GitHub release and upload the module files to it'

Task Publish -depends CreateGitHubRelease -action {
    Assert -conditionToCheck ($PublishPSRepositoryApiKey -or $PublishPSRepositoryCredential) -failureMessage "API key or credential not defined to authenticate with [$PublishPSRepository)] with."

    $publishParams = @{
        Path       = $script:BuildOutputDir
        Repository = $PublishPSRepository
        Verbose    = $VerbosePreference
    }
    if ($PublishPSRepositoryApiKey) {
        $publishParams.NuGetApiKey = $PublishPSRepositoryApiKey
    }

    if ($PublishPSRepositoryCredential) {
        $publishParams.Credential = $PublishPSRepositoryCredential
    }

    # Only publish a release if we are working on the main branch
    $CurrentBranch = git branch --show-current
    if ($NoPublish -ne $true -and $CurrentBranch -eq 'main') {
        Write-InfoColor "`tPublish-Module -Path '$script:BuildOutputDir' -Repository 'PSGallery'"
        # Publish to PSGallery
        Publish-Module @publishParams
    }
    else {
        Write-Verbose 'Skipping publishing. NoPublish is $NoPublish and current git branch is $CurrentBranch'
    }
} -description 'Publish module to the defined PowerShell repository'

Task AwaitRepoUpdate -depends Publish -action {
    $timer = 30
    do {
        Start-Sleep -Seconds 1
        $timer++
        $VersionInGallery = Find-Module -Name $ModuleName -Repository $PublishPSRepository
    } while (
        $VersionInGallery.Version -lt $script:NewModuleVersion -and
        $timer -lt $timeout
    )

    if ($timer -eq $timeout) {
        Write-Warning "Cannot retrieve version '$script:NewModuleVersion' of module '$ModuleName' from repo '$PublishPSRepository'"
    }
} -description 'Await the new version in the defined PowerShell repository'

Task Uninstall -depends AwaitRepoUpdate -action {

    Write-InfoColor "`tGet-Module -Name '$ModuleName' -ListAvailable"

    if (Get-Module -Name $ModuleName -ListAvailable) {
        Write-InfoColor "`tUninstall-Module -Name '$ModuleName' -AllVersions"
        Uninstall-Module -Name $ModuleName -AllVersions
    }
    else {
        Write-InfoColor ''
    }

} -description 'Uninstall all versions of the module'

Task Reinstall -depends Uninstall -action {

    [int]$attempts = 0

    do {
        $attempts++
        Write-InfoColor "`tInstall-Module -Name '$ModuleName' -Force"
        Install-Module -name $ModuleName -Force -ErrorAction Continue
        Start-Sleep -Seconds 1
    } while ($null -eq (Get-Module -Name $ModuleName -ListAvailable) -and ($attempts -lt 3))

} -description 'Reinstall the latest version of the module from the defined PowerShell repository'

Task RemoveScriptScopedVariables -depends Reinstall -action {

    # Remove script-scoped variables to avoid their accidental re-use
    Remove-Variable -Name ModuleOutDir -Scope Script -Force -ErrorAction SilentlyContinue

}

Task ReturnToStartingLocation -depends RemoveScriptScopedVariables -action {
    Set-Location $StartingLocation
}

Task ? -description 'Lists the available tasks' -action {
    'Available tasks:'
    $psake.context.Peek().Tasks.Keys | Sort-Object
}
