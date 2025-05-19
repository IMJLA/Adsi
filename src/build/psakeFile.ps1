using namespace System.Management.Automation
#TODO : Use Fixer 'Get-TextFilesList $pwd | ConvertTo-SpaceIndentation'.

Properties {

    # Whether or not this build is a new Major version
    [boolean]$IncrementMajorVersion = $false

    # Whether or not this build is a new Minor version
    [boolean]$IncrementMinorVersion = $false

    # Folder containing the script .ps1 file
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
    [string[]]$BuildExclude = @( [IO.Path]::Combine('build', '*'), 'gitkeep')



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
    $ReadMePath = [IO.Path]::Combine('.', 'README.md')

    $ChangeLog = [IO.Path]::Combine('.', 'CHANGELOG.md')

    $WriteInfoScript = [IO.Path]::Combine('.', 'Write-InfoColor.ps1')

    # Dot-source the Write-InfoColor.ps1 script once to make the function available
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

Task Default -depends SetLocation, DeleteOldBuilds, DeleteOldDocs, ReturnToStartingLocation

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

} -description 'Set the location to the project root'

Task TestModuleManifest -action {

    Write-InfoColor "`tTest-ModuleManifest -Path '$ModuleManifestPath'"
    $script:ManifestTest = Test-ModuleManifest -Path $ModuleManifestPath

} -description 'Validate the module manifest'

Task DetermineNewModuleVersion -depends TestModuleManifest -action {

    $ScriptToRun = [IO.Path]::Combine($SourceCodeDir, 'build', 'Get-NewVersion.ps1')
    Write-InfoColor "`t& '$ScriptToRun' -IncrementMajorVersion:`$$IncrementMajorVersion -IncrementMinorVersion:`$$IncrementMinorVersion -OldVersion '$($script:ManifestTest.Version)'"
    $script:NewModuleVersion = & $ScriptToRun -IncrementMajorVersion:$IncrementMajorVersion -IncrementMinorVersion:$IncrementMinorVersion -OldVersion $script:ManifestTest.Version
    $script:BuildOutputDir = [IO.Path]::Combine($BuildOutDir, $script:NewModuleVersion, $ModuleName)
    $env:BHBuildOutput = $script:BuildOutputDir # still used by Module.tests.ps1

} -description 'Determine the new module version based on the build parameters'

Task UpdateModuleVersion -depends DetermineNewModuleVersion -action {

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

}

Task FindPublicFunctionFiles -depends UpdateChangeLog -action {

    Write-InfoColor "`t`$script:PublicFunctionFiles = Get-ChildItem -Path '$publicFunctionPath' -Recurse"
    $script:PublicFunctionFiles = Get-ChildItem -Path $publicFunctionPath -Recurse

} -description 'Find all public function files'

Task ExportPublicFunctions -depends FindPublicFunctionFiles -action {

    $ScriptToRun = [IO.Path]::Combine($SourceCodeDir, 'build', 'Export-PublicFunction.ps1')
    Write-InfoColor "`t& '$ScriptToRun' -PublicFunctionFiles `$script:PublicFunctionFiles -ModuleFilePath '$ModuleFilePath' -ModuleManifestPath '$ModuleManifestPath'"
    & $ScriptToRun -PublicFunctionFiles $script:PublicFunctionFiles -ModuleFilePath $ModuleFilePath -ModuleManifestPath $ModuleManifestPath

} -description 'Export all public functions in the module'

Task BuildModule -depends ExportPublicFunctions -precondition $FindBuildPrerequisite -action {

    $buildParams = @{
        Path               = $SourceCodeDir
        ModuleName         = $ModuleName
        DestinationPath    = $script:BuildOutputDir
        Exclude            = $BuildExclude + "$ModuleName.psm1"
        Compile            = $BuildCompileModule
        CompileDirectories = $BuildCompileDirectories
        CopyDirectories    = $BuildCopyDirectories
        Culture            = $DocsDefaultLocale
    }

    if ($DocsConvertReadMeToAboutFile) {
        $buildParams.ReadMePath = $readMePath
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
    Write-InfoColor "`tBuild-PSBuildModule -Path '$SourceCodeDir' -ModuleName '$ModuleName' -DestinationPath '$script:BuildOutputDir' -Exclude @('$ExcludeJoined') -Compile '$BuildCompileModule' -CompileDirectories @('$CompileDirectoriesJoined') -CopyDirectories @('$CopyDirectoriesJoined') -Culture '$DocsDefaultLocale' -ReadMePath '$readMePath' -CompileHeader '$($buildParams['CompileHeader'])' -CompileFooter '$($buildParams['CompileFooter'])' -CompileScriptHeader '$($buildParams['CompileScriptHeader'])' -CompileScriptFooter '$($buildParams['CompileScriptFooter'])'"
    Build-PSBuildModule @buildParams

} -description 'Build a PowerShell script module based on the source directory'

Task DeletePSDependRequirementsFileFromBuildOutput -depends BuildModule -action {

    # Remove the psdependRequirements.psd1 file if it exists
    $RequirementsFile = [IO.Path]::Combine($script:BuildOutputDir, 'psdependRequirements.psd1')
    Write-InfoColor "`tRemove-Item -Path '$RequirementsFile'"
    Remove-Item -Path $RequirementsFile -ErrorAction SilentlyContinue

}

Task DeleteOldBuilds -depends DeletePSDependRequirementsFileFromBuildOutput -action {

    Write-InfoColor "`tRemove-Item -Path '$BuildOutDir.old' -Recurse -Force -ErrorAction SilentlyContinue"
    Remove-Item -Path "$BuildOutDir.old" -Recurse -Force -ErrorAction SilentlyContinue

}



Task BackupOldDocs -action {

    Write-InfoColor "`tRemove-Item -Path '$DocsRootDir.old' -Recurse -Force -ErrorAction SilentlyContinue"
    Remove-Item -Path "$DocsRootDir.old" -Recurse -Force -ErrorAction SilentlyContinue
    Write-InfoColor "`tRename-Item -Path '$DocsRootDir' -NewName '$DocsRootDir.old' -Force -ErrorAction SilentlyContinue"
    Rename-Item -Path $DocsRootDir -NewName "$DocsRootDir.old" -Force -ErrorAction SilentlyContinue

} -description 'Backup old documentation files'

Task BuildMarkdownHelp -depends BackupOldDocs -precondition $FindDocsPrerequisite -action {

    $ManifestPath = [IO.Path]::Combine($script:BuildOutputDir, "$ModuleName.psd1")
    $NewManifestTest = Test-ModuleManifest -Path $ManifestPath

    if ($NewManifestTest.ExportedCommands.Keys.Count -eq 0) {
        Write-Warning 'No commands have been exported. Skipping markdown generation.'
        return
    }
    if (-not (Test-Path -LiteralPath $DocsMarkdownDir)) {
        New-Item -Path $DocsMarkdownDir -ItemType Directory > $null
    }
    try {

        if (Get-ChildItem -LiteralPath $DocsMarkdownDir -Filter *.md -Recurse) {
            Get-ChildItem -LiteralPath $DocsMarkdownDir -Directory | ForEach-Object {
                Write-InfoColor "`tUpdate-MarkdownHelp -Path '$($_.FullName)'"
                Update-MarkdownHelp -Path $_.FullName -Verbose:$VerbosePreference > $null
            }
        }

        $newMDParams = @{
            AlphabeticParamsOrder = $true
            Locale                = $DocsDefaultLocale
            ErrorAction           = 'SilentlyContinue' # SilentlyContinue will not overwrite an existing MD file.
            HelpVersion           = $NewManifestTest.Version
            Module                = $ModuleName
            # TODO: Using GitHub pages as a container for PowerShell Updatable Help https://gist.github.com/TheFreeman193/fde11aee6998ad4c40a314667c2a3005
            # OnlineVersionUrl = $GitHubPagesLinkForThisModule
            OutputFolder          = $DocsMarkdownDefaultLocaleDir
            UseFullTypeName       = $true
            WithModulePage        = $true
        }
        Write-InfoColor "`tNew-MarkdownHelp -AlphabeticParamsOrder `$true -HelpVersion '$($NewManifestTest.Version)' -Locale '$DocsDefaultLocale' -Module '$ModuleName' -OutputFolder '$DocsMarkdownDefaultLocaleDir' -UseFullTypeName `$true -WithModulePage `$true"
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

Task BuildMAMLHelp -depends FixMarkdownHelp -action {

    Write-InfoColor "`tBuild-PSBuildMAMLHelp -Path '$DocsMarkdownDir' -DestinationPath '$script:BuildOutputDir'"
    Build-PSBuildMAMLHelp -Path $DocsMarkdownDir -DestinationPath $script:BuildOutputDir

} -description 'Generates MAML-based help from PlatyPS markdown files'

Task BuildUpdatableHelp -depends BuildMAMLHelp -precondition $FindDocsUpdateablePrerequisite -action {

    $helpLocales = (Get-ChildItem -Path $DocsMarkdownDir -Directory).Name

    # Create updatable help output directory
    $null = New-Item $DocsUpdateableDir -ItemType Directory -Verbose:$VerbosePreference

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

} -description 'Create updatable help .cab file based on PlatyPS markdown help'

Task DeleteOldDocs -depends BuildUpdatableHelp -action {
    Write-InfoColor "`tRemove-Item -Path '$DocsRootDir.old' -Recurse -Force -ErrorAction SilentlyContinue"
    Remove-Item -Path "$DocsRootDir.old" -Recurse -Force -ErrorAction SilentlyContinue
} -description 'Delete old documentation file backups'



Task Lint -precondition $FindLintPrerequisites -action {

    Write-InfoColor "`tTest-PSBuildScriptAnalysis -Path '$SourceCodeDir' -SeverityThreshold '$LintSeverityThreshold' -SettingsPath '$LintSettingsFile'"
    Test-PSBuildScriptAnalysis -Path $SourceCodeDir -SeverityThreshold $LintSeverityThreshold -SettingsPath $LintSettingsFile

} -description 'Execute PSScriptAnalyzer tests'

Task UnitTests -depends Lint -precondition $FindUnitTestPrerequisite -action {

    $PesterConfigParams = @{
        Run          = @{
            Path = "$TestRootDir"
        }
        CodeCoverage = @{
            CoveragePercentTarget = $TestCodeCoverageThreshold
            Enabled               = $TestCodeCoverageEnabled
            OutputFormat          = $TestCodeCoverageOutputFormat
            OutputPath            = $TestCodeCoverageOutputFile
            Path                  = $TestCodeCoverageFiles
        }
        Output       = @{
            #Verbosity = 'Diagnostic'
            Verbosity = 'Normal'
        }
        TestResult   = @{
            Enabled      = $true
            OutputPath   = $TestResultsFile
            OutputFormat = $TestOutputFormat
        }
    }


    Write-InfoColor "`t`$PesterConfigParams = @{
`t        Run          = @{
`t            Path = '$TestRootDir'
`t        }
`t        CodeCoverage = @{
`t            CoveragePercentTarget = $TestCodeCoverageThreshold
`t            Enabled               = $TestCodeCoverageEnabled
`t            OutputFormat          = '$TestCodeCoverageOutputFormat'
`t            OutputPath            = '$TestCodeCoverageOutputFile'
`t            Path                  = '$TestCodeCoverageFiles'
`t        }
`t        Output       = @{
`t            #Verbosity = 'Diagnostic'
`t            Verbosity = 'Normal'
`t        }
`t        TestResult   = @{
`t            Enabled      = $true
`t            OutputPath   = '$TestResultsFile'
`t            OutputFormat = '$TestOutputFormat'
`t        }
`t    }"
    Write-InfoColor "`t`$PesterConfiguration = New-PesterConfiguration -Hashtable `$PesterConfigParams"
    $PesterConfiguration = New-PesterConfiguration -Hashtable $PesterConfigParams

    Write-InfoColor "`tInvoke-Pester -Configuration `$PesterConfiguration"
    Invoke-Pester -Configuration $PesterConfiguration

} -description 'Perform unit tests using Pester.'

Task SourceControl -depends UnitTests -action {

    # Find the current git branch
    $CurrentBranch = git branch --show-current

    # Commit to Git
    git add .
    git commit -m $CommitMessage
    git push origin $CurrentBranch

} -description 'git add, commit, and push'

Task Publish -depends SourceControl -action {
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
