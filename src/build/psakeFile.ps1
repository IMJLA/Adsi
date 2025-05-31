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

    # Whether or not to generate markdown documentation using PlatyPS
    [boolean]$DocumentationEnabled = $true

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

    # Online help website will be created in this folder.
    [string]$DocsOnlineHelpRoot = [IO.Path]::Combine($DocsRootDir, 'online')

    # Online help website will be created in this folder.
    [string]$DocsOnlineHelpDir = [IO.Path]::Combine($DocsOnlineHelpRoot, $ModuleName)

    $OnlineHelpSourceMarkdown = [IO.Path]::Combine($DocsOnlineHelpDir, 'docs')

    $DocsOnlineStaticImageDir = [IO.Path]::Combine($DocsOnlineHelpDir, 'static', 'img')

    $ChangeLog = [IO.Path]::Combine('.', 'CHANGELOG.md')

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
CreateOnlineHelpFolder, # Create a folder for the Online help documentation.
BuildOnlineHelpWebsite, # Create the Online help documentation website.
UnitTests, # Perform unit testing.
SourceControl, # Commit changes to source control.
CreateGitHubRelease, # Create a GitHub release.
Reinstall, # Publish the module to the a PowerShell repository.
ReturnToStartingLocation # Reset the build environment to its starting state.


# Prepare the build environment.
Task -name SetLocation -action {

    Write-InfoColor "`tSet-Location -Path '$ModuleName'"
    Set-Location -Path $PSScriptRoot
    [string]$ProjectRoot = [IO.Path]::Combine('..', '..')
    Set-Location -Path $ProjectRoot

    if (((Get-Location -PSProvider FileSystem -ErrorAction Stop).Path | Split-Path -Leaf) -eq $ModuleName) {
        Write-InfoColor "`t# Current Working Directory is now '$ModuleName'" -ForegroundColor Green
    } else {
        Write-Error "Failed to set Working Directory to '$ModuleName'."
    }

} -description 'Set the working directory to the project root to ensure all relative paths are correct'

Task -name TestModuleManifest -action {

    Write-Information "`tTest-ModuleManifest -Path '$ModuleManifestPath'"
    $script:ManifestTest = Test-ModuleManifest -Path $ModuleManifestPath -ErrorAction Stop

    if ($script:ManifestTest) {
        Write-InfoColor "`t# Successfully validated the module manifest." -ForegroundColor Green
    } else {
        Write-Error 'Failed to validate the module manifest.'
    }

} -description 'Validate the module manifest'

# Update the module source code.
Task -name DetermineNewVersionNumber -Depends TestModuleManifest -action {

    Write-Information "`tGet-NewVersion -IncrementMajorVersion:$IncrementMajorVersion -IncrementMinorVersion:$IncrementMinorVersion -OldVersion $script:ManifestTest.Version"
    $script:NewModuleVersion = Get-NewVersion -IncrementMajorVersion:$IncrementMajorVersion -IncrementMinorVersion:$IncrementMinorVersion -OldVersion $script:ManifestTest.Version
    $script:BuildOutputDir = [IO.Path]::Combine($BuildOutDir, $script:NewModuleVersion, $ModuleName)
    $env:BHBuildOutput = $script:BuildOutputDir # still used by Module.tests.ps1
    Write-InfoColor "`t# Successfully determined the new version number: $script:NewModuleVersion" -ForegroundColor Green

} -description 'Determine the new version number based on the build parameters'

Task -name UpdateModuleVersion -depends DetermineNewVersionNumber -action {

    Write-Information "`tUpdate-Metadata -Path '$ModuleManifestPath' -PropertyName ModuleVersion -Value $script:NewModuleVersion -ErrorAction Stop"
    Update-Metadata -Path $ModuleManifestPath -PropertyName ModuleVersion -Value $script:NewModuleVersion -ErrorAction Stop
    Write-InfoColor "`t# Successfully updated the module manifest with the new version number." -ForegroundColor Green

} -description 'Update the module manifest with the new version number'

Task -name FindPublicFunctionFiles -depends UpdateModuleVersion -action {

    Write-Information "`t`$script:PublicFunctionFiles = Get-ChildItem -Path '$publicFunctionPath' -Recurse"
    $script:PublicFunctionFiles = Get-ChildItem -Path $publicFunctionPath -Recurse
    if ($script:PublicFunctionFiles.Count -eq 0) {
        Write-InfoColor "`t# No public function files found." -ForegroundColor Yellow
    } else {
        Write-InfoColor "`t# Found $($script:PublicFunctionFiles.Count) public function files." -ForegroundColor Green
    }

} -description 'Find all public function files'

Task -name ExportPublicFunctions -depends FindPublicFunctionFiles -action {

    Write-Information "`tExport-PublicFunction -PublicFunctionFiles `$script:PublicFunctionFiles -ModuleFilePath '$ModuleFilePath' -ModuleManifestPath '$ModuleManifestPath'"
    Export-PublicFunction -PublicFunctionFiles $script:PublicFunctionFiles -ModuleFilePath $ModuleFilePath -ModuleManifestPath $ModuleManifestPath
    Write-InfoColor "`t# Successfully exported public functions in the module." -ForegroundColor Green

} -description 'Export all public functions in the module'


# Perform linting and analysis of the source code.
$LintPrerequisite = {

    # 'Find the PSScriptAnalyzer module for linting the source code.'
    Write-InfoColor "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-InfoColor "FindLintPrerequisites$NewLine" -ForegroundColor Blue

    if ($LintEnabled) {

        Write-Information "`tGet-Module -Name PSScriptAnalyzer -ListAvailable"

        if (Get-Module -Name PSScriptAnalyzer -ListAvailable) {
            Write-InfoColor "`t# 'PSScriptAnalyzer' PowerShell module is installed. Linting will be performed." -ForegroundColor Green
            return $true
        } else {
            Write-InfoColor "`t# 'PSScriptAnalyzer' PowerShell module is not installed. Linting will be skipped." -ForegroundColor Yellow
            return $false
        }

    } else {
        Write-InfoColor "`t# Linting is disabled. Linting will be skipped." -ForegroundColor Cyan
    }

}

Task -name Format -precondition $LintPrerequisite -action {

    Write-Information "`tGet-ChildItem -Path '$SourceCodeDir' -Filter '*.ps*1' -Recurse"
    $ScriptFiles = Get-ChildItem -Path $SourceCodeDir -Filter '*.ps*1' -Recurse

    foreach ($File in $ScriptFiles) {

        $CurrentDirectory = (Get-Location -PSProvider FileSystem).Path
        $PartialRelativePath = [IO.Path]::GetRelativePath($CurrentDirectory, $File.FullName)
        $FullRelativePath = [IO.Path]::Combine('.', $PartialRelativePath)

        # Read the original content of the file
        Write-Verbose "`t`$OriginalContent = Get-Content -Path '$FullRelativePath' -Raw -ErrorAction Stop"
        $OriginalContent = Get-Content $File.FullName -Raw -ErrorAction Stop

        # Check current file encoding
        $FileBytes = [System.IO.File]::ReadAllBytes($File.FullName)
        $HasBOM = $FileBytes.Length -ge 3 -and $FileBytes[0] -eq 0xEF -and $FileBytes[1] -eq 0xBB -and $FileBytes[2] -eq 0xBF

        <#
        Normalize line endings to Windows format (CRLF) before formatting
        In addition to ensuring consistency this prevents the following error from Invoke-Formatter:

            Cannot determine line endings as the text probably contain mixed line endings. (Parameter 'text')
        #>
        Write-Verbose "`t`$NormalizedContent = `$OriginalContent -replace '``r``n|``n|``r', '``r``n'"
        $NormalizedContent = $OriginalContent -replace "`r`n|`n|`r", "`r`n"

        Write-Verbose "`t`$FormattedContent = Invoke-Formatter -ScriptDefinition `$NormalizedContent -Settings '$LintSettingsFile' -ErrrorAction Stop"
        $FormattedContent = Invoke-Formatter -ScriptDefinition $NormalizedContent -Settings $LintSettingsFile -ErrorAction Stop

        # Update file if content changed or encoding needs to be fixed
        $ContentChanged = $FormattedContent -ne $OriginalContent
        $EncodingNeedsUpdate = -not $HasBOM

        if ($ContentChanged -or $EncodingNeedsUpdate) {

            if ($ContentChanged -and $EncodingNeedsUpdate) {
                Write-InfoColor "`tSet-Content -Path '$FullRelativePath' -Value `$FormattedContent -Encoding UTF8BOM -NoNewLine -ErrorAction Stop"
                Set-Content -Path $File.FullName -Value $FormattedContent -Encoding UTF8BOM -NoNewline -ErrorAction Stop
            }

        }

    }

    Write-InfoColor "`t# Successfully formatted PowerShell script files and ensured UTF8 with BOM encoding." -ForegroundColor Green

} -description 'Format PowerShell script files using PSScriptAnalyzer rules and ensure UTF8 with BOM encoding.'

Task -name Lint -depends Format -action {

    Write-Information "`tInvoke-ScriptAnalyzer -Path '$SourceCodeDir' -Settings '$LintSettingsFile' -Recurse -ErrorAction Stop"
    $script:LintResult = Invoke-ScriptAnalyzer -Path $SourceCodeDir -Settings $LintSettingsFile -Recurse -ErrorAction Stop
    Write-InfoColor "`t# Completed linting successfully. Found '$($script:LintResult.Count)' rule violations" -ForegroundColor Green

} -description 'Perform linting with PSScriptAnalyzer.'

Task -name LintAnalysis -depends Lint -action {

    Write-Information "`tSelect-LintResult -SeverityThreshold '$LintSeverityThreshold' -LintResult `$script:LintResult"
    Select-LintResult -SeverityThreshold $LintSeverityThreshold -LintResult $script:LintResult
    Write-InfoColor "`t# Completed lint output analysis successfully." -ForegroundColor Green

} -description 'Analyze the linting results and determine if the build should fail.'


# Build the module.
Task -name DeleteOldBuilds -action {

    Write-Information "`tGet-ChildItem -Path '$BuildOutDir' -Recurse -ErrorAction Stop | Remove-Item -Recurse -Force -ErrorAction Stop"
    Get-ChildItem -Path $BuildOutDir -Recurse -ErrorAction Stop | Remove-Item -Recurse -Force -ErrorAction Stop -ProgressAction SilentlyContinue
    Write-InfoColor "`t# Successfully deleted old builds." -ForegroundColor Green

} -description 'Delete old builds'

Task -name FindBuildCopyDirectories -depends DeleteOldBuilds -action {

    Write-Information "`tFind-BuildCopyDirectory -BuildCopyDirectory `$BuildCopyDirectories"
    $Script:CopyDirectories = Find-BuildCopyDirectory -BuildCopyDirectory $BuildCopyDirectories
    Write-InfoColor "`t# Found $($Script:CopyDirectories.Count) directories to copy to the build output directory." -ForegroundColor Green

} -description 'Find all directories to copy to the build output directory, excluding empty directories'

$FindBuildPrerequisite = {

    # 'Find the PSScriptAnalyzer module for linting the source code.'
    Write-InfoColor "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-InfoColor "FindBuildPrerequisites$NewLine" -ForegroundColor Blue

    if ($BuildCompileModule) {

        Write-Information "`tGet-Module -Name PowerShellBuild -ListAvailable"

        if (Get-Module -Name PowerShellBuild -ListAvailable) {
            Write-InfoColor "`t# 'PowerShellBuild' PowerShell module is installed. Build will be performed." -ForegroundColor Green
            return $true
        } else {
            Write-InfoColor "`t# 'PowerShellBuild' PowerShell module is not installed. Build will be skipped." -ForegroundColor Yellow
            return $false
        }

    } else {
        Write-InfoColor "`t# Building is disabled. Build will be skipped." -ForegroundColor Cyan
    }

}

Task -name BuildModule -depends FindBuildCopyDirectories -precondition $FindBuildPrerequisite -action {

    $buildParams = @{
        Compile            = $BuildCompileModule
        CompileDirectories = $BuildCompileDirectories
        CopyDirectories    = $script:CopyDirectories
        Culture            = $DocsDefaultLocale
        DestinationPath    = $script:BuildOutputDir
        ErrorAction        = 'Stop' # Stop on any error
        Exclude            = $BuildExclude + "$ModuleName.psm1"
        ModuleName         = $ModuleName
        Path               = $SourceCodeDir
    }

    if ($DocsConvertReadMeToAboutFile) {
        $buildParams.ReadMePath = $DocsMarkdownReadMePath
    }

    # only add these configuration values to the build parameters if they have been been set
    $CompileParamStr = ''
    'CompileHeader', 'CompileFooter', 'CompileScriptHeader', 'CompileScriptFooter' | ForEach-Object {
        $Val = Get-Variable -name $_ -ValueOnly -ErrorAction SilentlyContinue
        if ($Val -ne '' -and $Val -ne $null) {
            $buildParams.$_ = $Val
            $CompileParamStr += "-$_ '$($Val.Replace("'", "''"))' "
        }
    }

    $ExcludeJoined = $buildParams['Exclude'] -join "','"
    $CompileDirectoriesJoined = $buildParams['CompileDirectories'] -join "','"
    $CopyDirectoriesJoined = $buildParams['CopyDirectories'] -join "','"
    Write-Information "`tBuild-PSBuildModule -Path '$SourceCodeDir' -ModuleName '$ModuleName' -DestinationPath '$script:BuildOutputDir' -Exclude @('$ExcludeJoined') -Compile '$BuildCompileModule' -CompileDirectories @('$CompileDirectoriesJoined') -CopyDirectories @('$CopyDirectoriesJoined') -Culture '$DocsDefaultLocale' -ReadMePath '$DocsMarkdownReadMePath' $CompileParamStr-ErrorAction 'Stop'"
    Build-PSBuildModule @buildParams
    Write-InfoColor "`t# Successfully built the module." -ForegroundColor Green

} -description 'Build a PowerShell script module based on the source directory'

Task -name FixModule -depends BuildModule -action {

    $File = [IO.Path]::Combine($script:BuildOutputDir, 'psdependRequirements.psd1')
    Write-Information "`tRemove-Item -Path '$File'"
    Remove-Item -Path $File -ErrorAction SilentlyContinue

    if (Test-Path -Path $File) {
        Write-Error 'Failed to remove unnecessary file '$File' from the build output directory.'
    }

    $File = [IO.Path]::Combine($script:BuildOutputDir, 'psscriptanalyzerSettings.psd1')
    Write-Information "`tRemove-Item -Path '$File'"
    Remove-Item -Path $File -ErrorAction SilentlyContinue

    if ((Test-Path -Path $File)) {
        Write-Error 'Failed to remove unnecessary file '$File' from the build output directory.'
    } else {
        Write-InfoColor "`t# Successfully removed unnecessary files from the build output directory." -ForegroundColor Green
    }

} -description 'Fix the module after building it by removing unnecessary files. This is a workaround until PowerShellBuild usage is replaced with custom build scripts.'


# Add an entry to the Change Log.
Task -name UpdateChangeLog -action {

    Write-Information "`tUpdate-ChangeLogFile -Version '$script:NewModuleVersion' -CommitMessage '$CommitMessage' -ChangeLog '$ChangeLog'"
    Update-ChangeLogFile -Version $script:NewModuleVersion -CommitMessage $CommitMessage -ChangeLog $ChangeLog
    Write-InfoColor "`t# Successfully updated the Change Log with the new version and commit message." -ForegroundColor Green

    <#
    TODO
        This task runs before the Test task so that tests of the change log will pass
        But I also need one that runs *after* the build to compare it against the previous build
        The post-build UpdateChangeLog will automatically add to the change log any:
            New/removed exported commands
            New/removed files
    #>

} -description 'Add an entry to the the Change Log.'


# Create Markdown and MAML help documentation.
Task -name CreateMarkdownHelpFolder -action {

    Write-Information "`tNew-Item -Path '$DocsMarkdownDir' -ItemType Directory -ErrorAction SilentlyContinue"
    $null = New-Item -Path $DocsMarkdownDir -ItemType Directory -ErrorAction SilentlyContinue
    if (Test-Path -Path $DocsMarkdownDir) {
        Write-InfoColor "`t# Markdown help directory exists." -ForegroundColor Green
    } else {
        Write-Error 'Failed to create the Markdown help directory'
    }

} -description 'Create a folder for the Markdown help documentation.'

$DocsPrereq = {

    # 'Find the PlatyPS module for generating Markdown help documentation.'
    Write-InfoColor "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-InfoColor "FindDocumentationPrerequisites$NewLine" -ForegroundColor Blue

    if ($DocumentationEnabled) {

        Write-Information "`tGet-Module -Name PlatyPS -ListAvailable"

        if (Get-Module -Name PlatyPS -ListAvailable) {
            Write-InfoColor "`t# 'PlatyPS' PowerShell module is installed. Documentation will be performed." -ForegroundColor Green
            return $true
        } else {
            Write-InfoColor "`t# 'PlatyPS' PowerShell module is not installed. Documentation will be skipped." -ForegroundColor Yellow
            return $false
        }

    } else {
        Write-InfoColor "`tDocumentation is disabled. Documentation will be skipped." -ForegroundColor Cyan
    }

}

Task -name DeleteMarkdownHelp -depends CreateMarkdownHelpFolder -precondition $DocsPrereq -action {

    $MarkdownDir = [IO.Path]::Combine($DocsMarkdownDir, $DocsDefaultLocale)
    Write-Information "`tGet-ChildItem -Path '$MarkdownDir' -Recurse -ErrorAction Stop | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue"
    Get-ChildItem -Path $MarkdownDir -Recurse -ErrorAction Stop | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue -ProgressAction SilentlyContinue
    if (Get-ChildItem -Path $MarkdownDir -Recurse -ErrorAction SilentlyContinue) {
        Write-Error 'Failed to delete existing Markdown help files.'
    } else {
        Write-InfoColor "`t# Successfully deleted existing Markdown help files." -ForegroundColor Green
    }

} -description 'Delete existing Markdown files to prepare for PlatyPS to build new ones.'

Task -name InstallTempModule -depends DeleteMarkdownHelp -action {

    $script:ModuleInstallDir = $env:PSModulePath -split ';' | Select-Object -First 1
    $script:ModuleInstallDir = [IO.Path]::Combine($script:ModuleInstallDir, $ModuleName)
    Write-Information "`tNew-Item -Path '$script:ModuleInstallDir' -ItemType Directory -ErrorAction SilentlyContinue"
    $null = New-Item -Path $script:ModuleInstallDir -ItemType Directory -ErrorAction SilentlyContinue
    if (Test-Path -Path $script:ModuleInstallDir) {
        Write-InfoColor "`t# Module installation directory exists." -ForegroundColor Green
    } else {
        Write-Error 'Failed to create the module installation directory.'
    }
    $script:ModuleInstallDir = [IO.Path]::Combine($script:ModuleInstallDir, $script:NewModuleVersion)
    Write-Information "`tNew-Item -Path '$script:ModuleInstallDir' -ItemType Directory -ErrorAction SilentlyContinue"
    $null = New-Item -Path $script:ModuleInstallDir -ItemType Directory -ErrorAction SilentlyContinue
    if (Test-Path -Path $script:ModuleInstallDir) {
        Write-InfoColor "`t# Module version installation directory exists." -ForegroundColor Green
    } else {
        Write-Error 'Failed to create the module version installation directory.'
    }

    Write-Information "`tCopy-Item -Path '$script:BuildOutputDir\*' -Destination '$script:ModuleInstallDir' -Recurse -Force -ErrorAction Stop"
    Copy-Item -Path "$script:BuildOutputDir\*" -Destination $script:ModuleInstallDir -Recurse -Force -ErrorAction Stop
    Write-InfoColor "`t# Successfully copied the module files to the version installation directory." -ForegroundColor Green

} -description 'Install the module so it can be loaded by name for help generation.'

Task -name ImportModule -depends InstallTempModule -action {

    Write-Information "`tImport-Module -Name '$ModuleName' -Force -ErrorAction Stop"
    Import-Module -Name $ModuleName -Force -ErrorAction Stop
    Write-Information "`tGet-Module -Name '$ModuleName' -ErrorAction Stop"
    $Result = Get-Module -Name $ModuleName -ErrorAction Stop

    if ($Result) {
        if ($Result.Count -gt 1) {
            Write-Error "`t# Multiple versions of the module '$ModuleName' are loaded: $($Result.Version -join ' & ')."
        } else {
            Write-InfoColor "`t# Successfully imported the '$($Result.Name)' module (version $($Result.Version))" -ForegroundColor Green
        }
    } else {
        Write-Error "Failed to import the module '$ModuleName'."
    }

} -description 'Import the module to ensure it is loaded for help generation.'

Task -name UpdateMarkDownHelp -depends ImportModule -action {

    Write-Information "`tGet-ChildItem -LiteralPath '$DocsMarkdownDir' -Filter *.md -Recurse"

    if (Get-ChildItem -LiteralPath $DocsMarkdownDir -Filter *.md -Recurse) {

        Write-Information "`tGet-ChildItem -LiteralPath '$DocsMarkdownDir' -Directory"
        Get-ChildItem -LiteralPath $DocsMarkdownDir -Directory | ForEach-Object {

            $DirName = $_.FullName
            Write-Information "`tUpdate-MarkdownHelp -Path '$($_.FullName)'"
            Update-MarkdownHelp -Path $_.FullName -ErrorAction Stop

        }

        Write-InfoColor "`t# Successfully updated existing Markdown help files." -ForegroundColor Green

    } else {
        Write-InfoColor "`t# No existing Markdown help files found to update." -ForegroundColor Green
    }
} -description 'Update existing Markdown help files using PlatyPS.'

Task -name BuildMarkdownHelp -depends UpdateMarkDownHelp -action {

    $VerbosePreference = 'Continue'

    $newMDParams = @{
        AlphabeticParamsOrder = $true
        Locale                = $DocsDefaultLocale
        ErrorAction           = 'Stop' # SilentlyContinue will not overwrite an existing MD file.
        HelpVersion           = $script:NewModuleVersion
        Module                = $ModuleName
        # TODO: Using GitHub pages as a container for PowerShell Updatable Help https://gist.github.com/TheFreeman193/fde11aee6998ad4c40a314667c2a3005
        # OnlineVersionUrl = $GitHubPagesLinkForThisModule
        OutputFolder          = $DocsMarkdownDefaultLocaleDir
        UseFullTypeName       = $true
        WithModulePage        = $true
    }

    Write-Information "`tNew-MarkdownHelp -AlphabeticParamsOrder `$true -HelpVersion '$($Result.Version)' -Locale '$DocsDefaultLocale' -Module '$($Result.Name)' -OutputFolder '$DocsMarkdownDefaultLocaleDir' -UseFullTypeName `$true -WithModulePage `$true"
    $null = New-MarkdownHelp @newMDParams
    Write-InfoColor "`t# Successfully generated Markdown help files." -ForegroundColor Green
    $VerbosePreference = 'SilentlyContinue'

} -description 'Generate markdown files from the module help'

Task -name RemoveModule -depends BuildMarkdownHelp -action {

    Write-Information "`tRemove-Module -Name '$ModuleName' -Force -ErrorAction Stop"
    Remove-Module -Name $ModuleName -Force -ErrorAction Stop
    Write-InfoColor "`t# Successfully removed the module." -ForegroundColor Green

} -description 'Remove the module from the current PowerShell session now that help generation is complete.'

Task -Name UninstallTempModule -depends RemoveModule -action {

    Write-Information "`tRemove-Item -Path '$script:ModuleInstallDir' -Recurse -Force -ErrorAction Stop"
    Remove-Item -Path $script:ModuleInstallDir -Recurse -Force -ErrorAction Stop -ProgressAction SilentlyContinue

    if (Test-Path -Path $script:ModuleInstallDir) {
        Write-Error 'Failed to remove the temporary module installation directory.'
    } else {
        Write-InfoColor "`t# Successfully removed the temporary module installation directory." -ForegroundColor Green
    }

} -description 'Uninstall the temporary module used for help generation.'

Task -name FixMarkdownHelp -depends UninstallTempModule -action {

    Write-Information "`tRepair-MarkdownHelp -BuildOutputDir '$script:BuildOutputDir' -ModuleName '$ModuleName' -DocsMarkdownDefaultLocaleDir '$DocsMarkdownDefaultLocaleDir' -NewLine '``r``n' -DocsDefaultLocale '$DocsDefaultLocale' -PublicFunctionFiles `$script:PublicFunctionFiles"
    Repair-MarkdownHelp -BuildOutputDir $script:BuildOutputDir -ModuleName $ModuleName -DocsMarkdownDefaultLocaleDir $DocsMarkdownDefaultLocaleDir -NewLine $NewLine -DocsDefaultLocale $DocsDefaultLocale -PublicFunctionFiles $script:PublicFunctionFiles
    Write-InfoColor "`t# Successfully fixed Markdown help files for proper formatting and parameter documentation." -ForegroundColor Green

} -description 'Fix Markdown help files for proper formatting and parameter documentation.'

Task -name CreateMAMLHelpFolder -depends FixMarkdownHelp -action {

    Write-Information "`tNew-Item -Path '$DocsMamlDir' -ItemType Directory -ErrorAction SilentlyContinue"
    $null = New-Item -Path $DocsMamlDir -ItemType Directory -ErrorAction SilentlyContinue

    if (Test-Path -Path $DocsMamlDir) {
        Write-InfoColor "`t# MAML help folder exists." -ForegroundColor Green
    } else {
        Write-Error 'Failed to create the MAML help folder'
    }

} -description 'Create a folder for the MAML help files.'

Task -name DeleteMAMLHelp -depends CreateMAMLHelpFolder -action {

    Write-Information "`tGet-ChildItem -Path '$DocsMamlDir' -Recurse | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue"
    Get-ChildItem -Path $DocsMamlDir -Recurse -ErrorAction Stop | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue -ProgressAction SilentlyContinue
    Write-InfoColor "`t# Successfully deleted existing MAML help files." -ForegroundColor Green

} -description 'Delete existing MAML help files to prepare for PlatyPS to build new ones.'

Task -name BuildMAMLHelp -depends DeleteMAMLHelp -action {

    Write-Information "`tBuild-PSBuildMAMLHelp -Path '$DocsMarkdownDir' -DestinationPath '$DocsMamlDir' -ErrorAction Stop"
    Build-PSBuildMAMLHelp -Path $DocsMarkdownDir -DestinationPath $DocsMamlDir -ErrorAction Stop
    Write-InfoColor "`t# Successfully built MAML help files from the Markdown files." -ForegroundColor Green

} -description 'Build MAML help files from the Markdown files by using PlatyPS invoked by PowerShellBuild.'

Task -name CopyMAMLHelp -depends BuildMAMLHelp -action {

    Write-Information "`tCopy-Item -Path '$DocsMamlDir\*' -Destination '$script:BuildOutputDir' -Recurse -ErrorAction SilentlyContinue"
    Copy-Item -Path "$DocsMamlDir\*" -Destination $script:BuildOutputDir -Recurse -ErrorAction SilentlyContinue

    # Test if MAML help files were copied successfully
    $copiedFiles = Get-ChildItem -Path $script:BuildOutputDir -Filter '*.xml' -Recurse -ErrorAction SilentlyContinue
    if ($copiedFiles) {
        Write-InfoColor "`t# Successfully copied MAML help files to the build output directory." -ForegroundColor Green
    } else {
        Write-Error 'Failed to copy MAML help files to the build output directory.'
    }

} -description 'Copy MAML help files to the build output directory.'

Task -name CreateUpdateableHelpFolder -depends CopyMAMLHelp -action {

    Write-Information "`tNew-Item -Path '$DocsUpdateableDir' -ItemType Directory -ErrorAction SilentlyContinue"
    $null = New-Item -Path $DocsUpdateableDir -ItemType Directory -ErrorAction SilentlyContinue

    if (Test-Path -Path $DocsUpdateableDir) {
        Write-InfoColor "`t# Updateable help directory exists." -ForegroundColor Green
    } else {
        Write-Error 'Failed to create the Updateable help directory'
    }

} -description 'Create a folder for the Updateable help files.'

Task -name DeleteUpdateableHelp -depends CreateUpdateableHelpFolder -action {

    Write-Information "`tGet-ChildItem -Path '$DocsUpdateableDir' -Recurse -ErrorAction Stop | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue"
    Get-ChildItem -Path $DocsUpdateableDir -Recurse -ErrorAction Stop | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue -ProgressAction SilentlyContinue
    Write-InfoColor "`t# Successfully deleted existing Updateable help files." -ForegroundColor Green
    $script:ReadyForUpdateableHelp = $true

} -description 'Delete existing Updateable help files to prepare for PlatyPS to build new ones.'


# Create Updateable help documentation.
$UpdateableHelpPrereq = {

    # Find prerequisites for creating updatable help files.
    Write-InfoColor "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-InfoColor "FindUpdateableHelpPrerequisites$NewLine" -ForegroundColor Blue

    if ($script:ReadyForUpdateableHelp) {

        Write-InfoColor "`tGet-CimInstance -ClassName CIM_OperatingSystem"
        $OS = (Get-CimInstance -ClassName CIM_OperatingSystem).Caption

        if ($OS -match 'Windows') {

            Write-InfoColor "`tGet-Command -Name MakeCab.exe"
            if (Get-Command -Name MakeCab.exe) {
                Write-InfoColor "`t# MakeCab.exe is available on this operating system. Updateable Help will be generated." -ForegroundColor Green
                return $true
            } else {
                Write-InfoColor "`t# MakeCab.exe is not available on this operating system. Updateable Help generation will be skipped." -ForegroundColor Yellow
                return $false
            }

        } else {
            Write-InfoColor "`t# MakeCab.exe is not available on this operating system. Skipping Updateable Help generation." -ForegroundColor Yellow
            return $false
        }

    } else {
        Write-InfoColor "`tMAML Help files are not avaialable. Updateable Help generation will be skipped." -ForegroundColor Cyan
        return $false
    }

}

Task -name BuildUpdatableHelp -precondition $UpdateableHelpPrereq -action {

    $helpLocales = (Get-ChildItem -Path $DocsMarkdownDir -Directory).Name

    # Generate updatable help files.  Note: this will currently update the version number in the module's MD
    # file in the metadata.
    foreach ($locale in $helpLocales) {
        $cabParams = @{
            CabFilesFolder  = [IO.Path]::Combine($script:BuildOutputDir, $locale)
            LandingPagePath = [IO.Path]::Combine($DocsMarkdownDefaultLocaleDir, "$ModuleName.md")
            OutputFolder    = $DocsUpdateableDir
            ErrorAction     = 'Stop' # Stop on any error
        }
        Write-Information "`tNew-ExternalHelpCab -CabFilesFolder '$($cabParams.CabFilesFolder)' -LandingPagePath '$($cabParams.LandingPagePath)' -OutputFolder '$($cabParams.OutputFolder)' -ErrorAction 'Stop'"
        $null = New-ExternalHelpCab @cabParams
    }
    Write-InfoColor "`t# Successfully created updatable help .cab files." -ForegroundColor Green

} -description 'Create updatable help .cab file based on PlatyPS markdown help.'


# Create a folder for the Online help documentation.
$OnlineHelpPrereqs = {

    # Find Node.js installation.
    Write-InfoColor "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-InfoColor "FindOnlineHelpPrerequisites$NewLine" -ForegroundColor Blue
    Write-Information "`tGet-Command -Name node -ErrorAction SilentlyContinue"
    $NodeCommand = Get-Command -Name node -ErrorAction SilentlyContinue

    if ($NodeCommand) {

        Write-InfoColor "`t& node -v 2>`$null"
        $NodeJsVersion = & node -v 2>$null

        if ($NodeJsVersion -and [version]($NodeJsVersion.Replace('v', '')) -lt [version]'18.0.0') {
            Write-InfoColor "`t# Node.js is installed but version 18 or newer is required (detected version: $NodeJsVersion). Online Help generation will be skipped." -ForegroundColor Yellow
            return $false
        } else {
            Write-InfoColor "`t# Node.js is installed (version: $NodeJsVersion). Online Help will be generated." -ForegroundColor Green
            return $true
        }

    } else {
        Write-InfoColor "`tNode.js is not installed or not found in the PATH. Online Help generation will be skipped." -ForegroundColor Yellow
        return $false
    }

}

Task -name CreateOnlineHelpFolder -precondition $OnlineHelpPrereqs -action {

    Write-Information "`tNew-Item -Path '$DocsOnlineHelpRoot' -ItemType Directory -ErrorAction SilentlyContinue"
    $null = New-Item -Path $DocsOnlineHelpRoot -ItemType Directory -ErrorAction SilentlyContinue

    if (Test-Path -Path $DocsOnlineHelpRoot) {
        Write-InfoColor "`t# Online help root directory exists." -ForegroundColor Green
    } else {
        Write-Error 'Failed to create the Online help root directory'
    }

} -description 'Create a folder for the Online Help website.'


# Create the Online help documentation website.
$OnlineHelpScaffoldingPrereq = {

    # Find prerequisites for creating updatable help files.
    Write-InfoColor "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-InfoColor "FindOnlineHelpScaffoldingPrerequisites$NewLine" -ForegroundColor Blue
    Write-InfoColor "`tSet-Location -Path '$ModuleName'"
    Set-Location -Path $PSScriptRoot
    [string]$ProjectRoot = [IO.Path]::Combine('..', '..')
    Set-Location -Path $ProjectRoot

    # Determine whether the Online Help scaffolding already exists.
    Write-Information "`tGet-ChildItem -Path '$DocsOnlineHelpRoot' -Directory -ErrorAction SilentlyContinue | Where-Object { `$_.Name -eq '$ModuleName' }"
    if (Get-ChildItem -Path $DocsOnlineHelpRoot -Directory -ErrorAction Stop | Where-Object { $_.Name -eq $ModuleName }) {
        Write-InfoColor "`t# Online Help scaffolding already exists. It will be updated.$NewLine" -ForegroundColor Green
        return $false
    } else {
        Write-InfoColor "`t# Online Help scaffolding does not exist. It will be created." -ForegroundColor Green
        return $true
    }

}

Task -name CreateOnlineHelpScaffolding -precondition $OnlineHelpScaffoldingPrereq -action {

    $Location = Get-Location
    Write-Information "`tSet-Location -Path '$DocsOnlineHelpRoot'"
    Set-Location $DocsOnlineHelpRoot

    # Check if package.json exists (indicating Docusaurus is already initialized)
    $PackageJsonPath = Join-Path $DocsOnlineHelpDir 'package.json'

    if (Test-Path $PackageJsonPath) {
        Write-Information "`tDocusaurus website already exists, skipping initialization"
        Write-InfoColor "`t# Docusaurus scaffolding already exists." -ForegroundColor Green
    } else {

        # & cmd /c "npx create-docusaurus@latest $ModuleName classic --typescript"

        try {
            Write-InfoColor "`t> npx create-docusaurus@latest $ModuleName classic --typescript" -ForegroundColor Cyan

            # Use Start-Process for better control over npx output
            $processArgs = @{
                FilePath         = 'npx'
                ArgumentList     = @('create-docusaurus@latest', $ModuleName, 'classic', '--typescript')
                WorkingDirectory = $DocsOnlineHelpRoot
                Wait             = $true
                NoNewWindow      = $true
                PassThru         = $true
            }

            $process = Start-Process @processArgs

            if ($process.ExitCode -eq 0) {
                # Test if scaffolding was created successfully
                if (Test-Path $PackageJsonPath) {
                    Write-InfoColor "`t# Successfully created Docusaurus scaffolding." -ForegroundColor Green
                } else {
                    Write-Error 'Failed to create Docusaurus scaffolding - package.json not found'
                }
            } else {
                Write-Error "Failed to create Docusaurus scaffolding - npx exited with code $($process.ExitCode)"
            }
        } catch {
            Write-Error "Failed to create Docusaurus scaffolding: $_"
        }
    }

    Set-Location $Location

} -description 'Scaffold the skeleton of the Online Help website with Docusaurus which is written in TypeScript and uses React.js.'

Task -name ClearNpmCache -depends CreateOnlineHelpScaffolding -action {

    # Clear npm cache to ensure clean installation
    Write-InfoColor "`tInvoke-NpmCommand -Command 'cache verify' -WorkingDirectory '$DocsOnlineHelpDir'"
    Invoke-NpmCommand -Command 'cache verify' -WorkingDirectory $DocsOnlineHelpDir -ErrorAction Stop
    Write-InfoColor "`t# Successfully verified npm cache." -ForegroundColor Green

} -description 'Clear npm cache to ensure clean dependency installation.'

Task -name InstallOnlineHelpDependencies -depends ClearNpmCache -action {

    # npm install
    Write-InfoColor "`tInvoke-NpmCommand -Command 'install' -WorkingDirectory '$DocsOnlineHelpDir' -ErrorAction Stop"
    Invoke-NpmCommand -Command 'install' -WorkingDirectory $DocsOnlineHelpDir -ErrorAction Stop

    # Determine whether the node_modules directory was created (indicating successful install)
    $TestPath = [IO.Path]::Combine($DocsOnlineHelpDir, 'node_modules')
    if (Test-Path $TestPath) {
        Write-InfoColor "`t# Successfully installed Online Help dependencies." -ForegroundColor Green
    } else {
        Write-Error 'Failed to install Online Help dependencies. The node_modules directory was not created.'
    }

} -description 'Install the dependencies for the Online Help website.'

Task -name CopyMarkdownAsSourceForOnlineHelp -depends InstallOnlineHelpDependencies -action {

    $MarkdownSourceCode = [IO.Path]::Combine($SourceCodeDir, 'docs')
    $helpLocales = (Get-ChildItem -Path $DocsMarkdownDir -Directory -Exclude 'UpdatableHelp').Name

    ForEach ($Locale in $helpLocales) {
        Write-Information "`tCopy-Item -Path '$DocsMarkdownDir\*' -Destination '$OnlineHelpSourceMarkdown' -Recurse -Force"
        Copy-Item -Path "$DocsMarkdownDir\*" -Destination $OnlineHelpSourceMarkdown -Recurse -Force
        Write-Information "`tCopy-Item -Path '$MarkdownSourceCode\*' -Destination '$OnlineHelpSourceMarkdown\$Locale' -Recurse -Force"
        Copy-Item -Path "$MarkdownSourceCode\*" -Destination "$OnlineHelpSourceMarkdown\$Locale" -Recurse -Force
    }

    # Test if markdown files were copied successfully
    $copiedMarkdown = Get-ChildItem -Path $OnlineHelpSourceMarkdown -Filter '*.md' -Recurse -ErrorAction SilentlyContinue
    if ($copiedMarkdown) {
        Write-InfoColor "`t# Successfully copied Markdown files for online help." -ForegroundColor Green
    } else {
        Write-Error 'Failed to copy Markdown files for online help'
    }

} -description 'Copy Markdown help files as source for online help website.'

Task -name BuildArt -depends CopyMarkdownAsSourceForOnlineHelp -action {

    $null = New-Item -ItemType Directory -Path $DocsOnlineStaticImageDir -ErrorAction SilentlyContinue
    $SourceArtFiles = Get-ChildItem -Path $DocsImageSourceCodeDir -Filter '*.ps1'

    ForEach ($ScriptToRun in $SourceArtFiles) {
        $ThisPath = [IO.Path]::Combine($DocsImageSourceCodeDir, $ScriptToRun.Name)
        Write-Information "`t. $ThisPath -OutputDir '$DocsOnlineStaticImageDir'"
        . $ThisPath -OutputDir $DocsOnlineStaticImageDir
    }

    # Test if art files were created
    $artFiles = Get-ChildItem -Path $DocsOnlineStaticImageDir -ErrorAction SilentlyContinue
    if ($artFiles.Count -eq $SourceArtFiles.Count) {
        Write-InfoColor "`t# Successfully built dynamic art files." -ForegroundColor Green
    } else {
        Write-InfoColor "`t# No art files were generated (this may be expected if no art scripts exist)." -ForegroundColor Green
    }

} -description 'Build dynamic SVG art using PSSVG.'

Task -name CopyArt -depends BuildArt -action {

    Write-Information "`tGet-ChildItem -Path '$DocsImageSourceCodeDir' -Filter '*.svg' -ErrorAction Stop |"
    Write-Information "`tCopy-Item -Destination '$DocsOnlineStaticImageDir'"
    Get-ChildItem -Path $DocsImageSourceCodeDir -Filter '*.svg' -ErrorAction Stop | Copy-Item -Destination $DocsOnlineStaticImageDir

    Write-InfoColor "`t# Successfully copied static SVG art files to the online help directory." -ForegroundColor Green

} -description 'Copy static SVG art to the online help website.'

Task -name ConvertArt -depends CopyArt -action {

    #$ScriptToRun = [IO.Path]::Combine('.', 'ConvertFrom-SVG.ps1')
    #$sourceSVG = [IO.Path]::Combine($DocsOnlineStaticImageDir, 'logo.svg')
    #Write-Information "`t. $ScriptToRun -Path '$sourceSVG' -ExportWidth 512"
    #. $ScriptToRun -Path $sourceSVG -ExportWidth 512

    Write-InfoColor "`t# Art conversion task completed (currently commented out)." -ForegroundColor Green

} -description 'Convert SVGs to PNG using Inkscape.'

Task -name BuildOnlineHelpWebsite -depends ConvertArt -action {

    # & npm run build
    Write-InfoColor "`tInvoke-NpmCommand -Command 'run build' -WorkingDirectory '$DocsOnlineHelpDir'"

    try {
        Invoke-NpmCommand -Command 'run build' -WorkingDirectory $DocsOnlineHelpDir -ErrorAction Stop
    } catch {
        Write-InfoColor "`t# Build failed, attempting to fix corrupted dependencies..." -ForegroundColor Yellow
        Clear-NodeJSDependencySet -WorkingDirectory $DocsOnlineHelpDir

        # Retry the build after clearing dependencies
        Write-InfoColor "`tRetrying: Invoke-NpmCommand -Command 'run build' -WorkingDirectory '$DocsOnlineHelpDir'"
        Invoke-NpmCommand -Command 'run build' -WorkingDirectory $DocsOnlineHelpDir -ErrorAction Stop
    }

    # Determine whether the build directory was created (indicating successful build)
    $TestPath = [IO.Path]::Combine($DocsOnlineHelpDir, 'build')
    if (Test-Path $TestPath) {
        Write-InfoColor "`t# Successfully built online help website." -ForegroundColor Green
    } else {
        Write-Error 'Failed to build online help website'
    }

} -description 'Build an Online help website based on the Markdown help files by using Docusaurus.'


# Perform unit testing.
$UnitTestPrereq = {

    Write-InfoColor "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-InfoColor "FindUnitTestingPrerequisites$NewLine" -ForegroundColor Blue

    if ($TestEnabled) {
        Write-Information "`tGet-Module -Name Pester -ListAvailable"
        if (Get-Module -Name Pester -ListAvailable) {
            Write-InfoColor "`t# 'Pester' PowerShell module is installed. Unit testing will be performed." -ForegroundColor Green
            return $true
        } else {
            Write-InfoColor "`t# 'Pester' PowerShell module is not installed. Unit testing will be skipped." -ForegroundColor Cyan
            return $false
        }
    } else {
        Write-InfoColor "`t# Unit testing is disabled. Unit testing will be skipped." -ForegroundColor Cyan
    }

}

Task -name UnitTests -precondition $UnitTestPrereq -action {

    Write-Information "`t`$PesterConfigParams  = Get-Content -Path '.\tests\config\pesterConfig.json' | ConvertFrom-Json -AsHashtable"
    $PesterConfigParams = Get-Content -Path '.\tests\config\pesterConfig.json' | ConvertFrom-Json -AsHashtable
    Write-Information "`t`$PesterConfiguration = New-PesterConfiguration -Hashtable `$PesterConfigParams"
    $PesterConfiguration = New-PesterConfiguration -Hashtable $PesterConfigParams
    Write-Information "`tInvoke-Pester -Configuration `$PesterConfiguration"
    Invoke-Pester -Configuration $PesterConfiguration

} -description 'Perform unit tests using Pester.'


# Commit changes to source control.
Task -name SourceControl -action {

    # Find the current git branch
    Write-Information "`tInvoke-CommandWithOutputPrefix -Command 'git' -ArgumentArray @('branch', '--show-current') -PassThru"
    $CurrentBranch = Invoke-CommandWithOutputPrefix -Command 'git' -ArgumentArray @('branch', '--show-current') -PassThru

    # Commit to Git
    Write-Information "`tInvoke-CommandWithOutputPrefix -Command 'git' -ArgumentArray @('add', '.')"
    Invoke-CommandWithOutputPrefix -Command 'git' -ArgumentArray @('add', '.')
    Write-Information "`tInvoke-CommandWithOutputPrefix -Command 'git' -ArgumentArray @('commit', '-m', `$CommitMessage)"
    Invoke-CommandWithOutputPrefix -Command 'git' -ArgumentArray @('commit', '-m', "`"$CommitMessage`"")
    Write-Information "`tInvoke-CommandWithOutputPrefix -Command 'git' -ArgumentArray @('push', 'origin', '$CurrentBranch')"
    Invoke-CommandWithOutputPrefix -Command 'git' -ArgumentArray @('push', 'origin', $CurrentBranch)

    # Test if commit was successful by checking git status
    Write-Information "`tInvoke-CommandWithOutputPrefix -Command 'git' -ArgumentString 'status --porcelain' -PassThru"
    $gitStatus = Invoke-CommandWithOutputPrefix -Command 'git' -ArgumentArray @('status', '--porcelain') -PassThru
    if (-not $gitStatus) {
        Write-InfoColor "`t# Successfully committed and pushed changes to source control." -ForegroundColor Green
    } else {
        Write-Error 'Failed to commit all changes to source control'
    }

} -description 'git add, commit, and push'


# Create a GitHub release.
Task -name CreateGitHubRelease -action {

    $GitHubOrgName = 'IMJLA'
    $RepositoryPath = "$GitHubOrgName/$ModuleName"
    Write-Information "`tNew-BuildGitHubRelease -GitHubToken `$env:GHFGPATADSI -Repository '$RepositoryPath' -DistPath '$BuildOutDir' -ReleaseNotes '$CommitMessage'"
    $release = New-BuildGitHubRelease -GitHubToken $env:GHFGPATADSI -Repository $RepositoryPath -DistPath $BuildOutDir -ReleaseNotes $CommitMessage

    if ($release -and $release.html_url) {
        Write-InfoColor "$NewLine`tRelease URL: $($release.html_url)" -ForegroundColor Cyan
        Write-InfoColor "`t# Successfully created GitHub release." -ForegroundColor Green
    } else {
        Write-Error 'Failed to create GitHub release'
    }

} -description 'Create a GitHub release and upload the module files to it'


# Publish the module to a PowerShell repository.
Task -name Publish -action {

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
        Write-Information "`tPublish-Module -Path '$script:BuildOutputDir' -Repository 'PSGallery'"
        # Publish to PSGallery
        Publish-Module @publishParams
        Write-InfoColor "`t# Successfully published module to $PublishPSRepository." -ForegroundColor Green
    } else {
        Write-Verbose 'Skipping publishing. NoPublish is $NoPublish and current git branch is $CurrentBranch'
        Write-InfoColor "`t# Skipped publishing (NoPublish: $NoPublish, Branch: $CurrentBranch)." -ForegroundColor Green
    }
} -description 'Publish module to the defined PowerShell repository'

Task -name AwaitRepoUpdate -depends Publish -action {
    $timer = 30
    $timeout = 60
    do {
        Start-Sleep -Seconds 1
        $timer++
        Write-Information "`tFind-Module -Name '$ModuleName' -Repository '$PublishPSRepository'"
        $VersionInGallery = Find-Module -Name $ModuleName -Repository $PublishPSRepository
    } while (
        $VersionInGallery.Version -lt $script:NewModuleVersion -and
        $timer -lt $timeout
    )

    if ($timer -eq $timeout) {
        Write-Warning "Cannot retrieve version '$script:NewModuleVersion' of module '$ModuleName' from repo '$PublishPSRepository'"
        Write-Error "Timeout waiting for module version $script:NewModuleVersion to appear in $PublishPSRepository"
    } else {
        Write-InfoColor "`t# Successfully confirmed module version $script:NewModuleVersion is available in $PublishPSRepository." -ForegroundColor Green
    }
} -description 'Await the new version in the defined PowerShell repository'

Task -name Uninstall -depends AwaitRepoUpdate -action {

    Write-Information "`tGet-Module -Name '$ModuleName' -ListAvailable"
    $Result = Get-Module -Name $ModuleName -ListAvailable

    if ($Result) {
        Write-Information "`tGet-Module -Name '$ModuleName' -ListAvailable | Uninstall-Module -ErrorAction Stop"
        try {
            $Result | Uninstall-Module -ErrorAction Stop
        } catch {
            $ErrorMessage = "$_"
            switch ("$ErrorMessage") {
                "No match was found for the specified search criteria and module names '$ModuleName'." {
                    Write-Information "`tRemove-Item -Path '$script:ModuleInstallDir' -Recurse -Force -ErrorAction Stop"
                    Remove-Item $script:ModuleInstallDir -Recurse -Force -ErrorAction Stop -ProgressAction SilentlyContinue

                }
                default {
                    Write-Error "An unexpected error occurred while uninstalling module $ModuleName`: $ErrorMessage"
                }
            }
        }
        Write-InfoColor "`t# Successfully uninstalled all versions of module $ModuleName." -ForegroundColor Green
    } else {
        Write-InfoColor "`t# No versions of module $ModuleName found to uninstall." -ForegroundColor Green
    }

} -description 'Uninstall all versions of the module'

Task -name Reinstall -depends Uninstall -action {

    [int]$attempts = 0

    do {
        $attempts++
        Write-Information "`tInstall-Module -Name '$ModuleName' -Force"
        Install-Module -Name $ModuleName -Force -ErrorAction Continue
        Start-Sleep -Seconds 1
        $ModuleStatus = Get-Module -Name $ModuleName -ListAvailable | Where-Object { $_.Version -eq $script:NewModuleVersion }
    } while ((-not $ModuleStatus) -and ($attempts -lt 3))

    # Test if reinstall was successful
    if ($ModuleStatus) {
        Write-InfoColor "`t# Successfully reinstalled module $ModuleName (version: $($ModuleStatus.Version))." -ForegroundColor Green
    } else {
        Write-Error "Failed to reinstall module $ModuleName after $attempts attempts"
    }

} -description 'Reinstall the latest version of the module from the defined PowerShell repository'


# Reset the build environment to its starting state.

Task -name RemoveScriptScopedVariables -action {

    # Remove script-scoped variables to avoid their accidental re-use
    Write-Information "`tRemove-Variable -name ModuleOutDir -Scope Script -Force -ErrorAction SilentlyContinue"
    Remove-Variable -name ModuleOutDir -Scope Script -Force -ErrorAction SilentlyContinue
    Write-InfoColor "`t# Successfully cleaned up script-scoped variables." -ForegroundColor Green

} -description 'Remove script-scoped variables to clean up the environment.'

Task -name ReturnToStartingLocation -depends RemoveScriptScopedVariables -action {
    Write-Information "`tSet-Location '$($StartingLocation.Path)'"
    Set-Location $StartingLocation

    # Test if we're back at the starting location
    $currentLocation = Get-Location
    if ($currentLocation.Path -eq $StartingLocation.Path) {
        Write-InfoColor "`t# Successfully returned to starting location: $($StartingLocation.Path)" -ForegroundColor Green
    } else {
        Write-Error "Failed to return to starting location. Current: $($currentLocation.Path), Expected: $($StartingLocation.Path)"
    }
} -description 'Return to the original working directory.'
