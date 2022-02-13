Remove-Variable -Name PSBPreference -Scope Script -Force -ErrorAction Ignore

Set-Variable -Name PSBPreference -Scope Script -Value ([ordered]@{
        General = @{
            # Root directory for the project
            ProjectRoot        = $env:BHProjectPath

            # Root directory for the module
            SrcRootDir         = $env:BHPSModulePath

            # The name of the module. This should match the basename of the PSD1 file
            ModuleName         = $env:BHProjectName

            # Module version
            ModuleVersion      = $moduleVersion

            # Module manifest path
            ModuleManifestPath = $env:BHPSModuleManifest
        }
        Build   = @{

            Dependencies       = @('StageFiles', 'BuildUpdateableHelp')

            # Output directory when building a module
            OutDir             = $BuildOutDir

            # Module output directory
            ModuleOutDir       = "$BuildOutDir\$moduleVersion\$env:BHProjectName"

            # Controls whether to "compile" module into single PSM1 or not
            CompileModule      = $BuildCompileModule

            # List of directories that if CompileModule is $true, will be concatenated into the PSM1
            CompileDirectories = $BuildCompileDirectories

            # List of directories that will always be copied "as is" to output directory
            CopyDirectories    = $BuildCopyDirectories

            # List of files (regular expressions) to exclude from output directory
            Exclude            = $BuildExclude
        }
        Test    = @{
            # Enable/disable Pester tests
            Enabled        = $true

            # Directory containing Pester tests
            RootDir        = [IO.Path]::Combine($env:BHProjectPath, 'tests')

            # Specifies an output file path to send to Invoke-Pester's -OutputFile parameter.
            # This is typically used to write out test results so that they can be sent to a CI system
            # This path is relative to the directory containing Pester tests
            OutputFile     = $TestOutputFile

            # Specifies the test output format to use when the TestOutputFile property is given
            # a path.  This parameter is passed through to Invoke-Pester's -OutputFormat parameter.
            OutputFormat   = 'NUnitXml'

            ScriptAnalysis = @{
                # Enable/disable use of PSScriptAnalyzer to perform script analysis
                Enabled                  = $true

                # When PSScriptAnalyzer is enabled, control which severity level will generate a build failure.
                # Valid values are Error, Warning, Information and None.  "None" will report errors but will not
                # cause a build failure.  "Error" will fail the build only on diagnostic records that are of
                # severity error.  "Warning" will fail the build on Warning and Error diagnostic records.
                # "Any" will fail the build on any diagnostic record, regardless of severity.
                FailBuildOnSeverityLevel = 'Error'

                # Path to the PSScriptAnalyzer settings file.
                SettingsPath             = [IO.Path]::Combine($PSScriptRoot, 'tests\ScriptAnalyzerSettings.psd1')
            }

            # Import module from OutDir prior to running Pester tests.
            ImportModule   = $false

            CodeCoverage   = @{
                # Enable/disable Pester code coverage reporting.
                Enabled          = $false

                # Fail Pester code coverage test if below this threshold
                Threshold        = .75

                # CodeCoverageFiles specifies the files to perform code coverage analysis on. This property
                # acts as a direct input to the Pester -CodeCoverage parameter, so will support constructions
                # like the ones found here: https://pester.dev/docs/usage/code-coverage.
                Files            = @()

                # Path to write code coverage report to
                OutputFile       = [IO.Path]::Combine($env:BHProjectPath, 'codeCoverage.xml')

                # The code coverage output format to use
                OutputFileFormat = 'JaCoCo'
            }
        }
        Help    = @{
            # Path to updateable help CAB
            UpdatableHelpOutDir      = [IO.Path]::Combine($outDir, 'UpdatableHelp')

            # Default Locale used for help generation, defaults to en-US
            # Get-UICulture doesn't return a name on Linux so default to en-US
            DefaultLocale            = if (-not (Get-UICulture).Name) { 'en-US' } else { (Get-UICulture).Name }

            # Convert project readme into the module about file
            ConvertReadMeToAboutHelp = $false
        }
        Docs    = @{
            # Directory PlatyPS markdown documentation will be saved to
            RootDir = [IO.Path]::Combine($env:BHProjectPath, 'docs')
        }
        Publish = @{
            # PowerShell repository name to publish modules to
            PSRepository           = 'PSGallery'

            # API key to authenticate to PowerShell repository with
            PSRepositoryApiKey     = $env:PSGALLERY_API_KEY

            # Credential to authenticate to PowerShell repository with
            PSRepositoryCredential = $null
        }
    })

properties {
    $outDir = [IO.Path]::Combine($env:BHProjectPath, $BuildOutputFolderName)
    $moduleVersion = (Import-PowerShellDataFile -Path $env:BHPSModuleManifest).ModuleVersion
    $BuildOutputFolderName = 'dist'
    $BuildCompileModule = $true
    $BuildCompileDirectories = @('classes', 'enums', 'filters', 'functions/private', 'functions/public')
    $BuildCopyDirectories = @('../bin', '../config', '../data', '../lib')
    $BuildExclude = @('gitkeep', "$env:BHProjectName.psm1")
    $BuildOutDir = "$env:BHProjectPath\$BuildOutputFolderName"
    $TestOutputFile = 'out/testResults.xml'
    $NewLine = [System.Environment]::NewLine
}

FormatTaskName {
    param($taskName)
    Write-Host 'Task: ' -ForegroundColor Cyan -NoNewline
    Write-Host $taskName -ForegroundColor Blue
}

task Default -depends Publish

#Task Init -FromModule PowerShellBuild -minimumVersion 0.6.1

task InitializeBuildHelpers {
    BuildHelpers\Set-BuildEnvironment -Force
    $env:BHCommitMessage = $CommitMessage
    Write-Host "`tBuildHelp environment variables:" -ForegroundColor Yellow
    (Get-Item ENV:BH*).Foreach({
            "`t{0,-20}{1}" -f $_.name, $_.value
        })
    $NewLine
} -description 'Initialize the environment variables from the BuildHelpers module'

task UpdateModuleVersion -depends InitializeBuildHelpers -Action {
    $CurrentVersion = (Test-ModuleManifest $env:BHPSModuleManifest).Version
    "`tOld Version: $CurrentVersion"
    if ($IncrementMajorVersion) {
        "`tThis is a new major version"
        $NextVersion = "$($CurrentVersion.Major + 1).0.0"
    } elseif ($IncrementMinorVersion) {
        "`tThis is a new minor version"
        $NextVersion = "$($CurrentVersion.Major).$($CurrentVersion.Minor + 1).0"
    } else {
        "`tThis is a new build"
        $NextVersion = "$($CurrentVersion.Major).$($CurrentVersion.Minor).$($CurrentVersion.Build + 1)"
    }
    "`tNew Version: $NextVersion$NewLine"

    Update-Metadata -Path $env:BHPSModuleManifest -PropertyName ModuleVersion -Value $NextVersion -ErrorAction Stop
} -description 'Increment the module version and update the module manifest accordingly'

task InitializePowershellBuild -depends UpdateModuleVersion {


    $outDir = [IO.Path]::Combine($env:BHProjectPath, $BuildOutputFolderName)
    $moduleVersion = (Import-PowerShellDataFile -Path $env:BHPSModuleManifest).ModuleVersion
    Set-Variable -Name PSBPreference -Scope Script -Value ([ordered]@{
            General = @{
                # Root directory for the project
                ProjectRoot        = $env:BHProjectPath

                # Root directory for the module
                SrcRootDir         = $env:BHPSModulePath

                # The name of the module. This should match the basename of the PSD1 file
                ModuleName         = $env:BHProjectName

                # Module version
                ModuleVersion      = $moduleVersion

                # Module manifest path
                ModuleManifestPath = $env:BHPSModuleManifest
            }
            Build   = @{

                Dependencies       = @('StageFiles', 'BuildUpdateableHelp')

                # Output directory when building a module
                OutDir             = $BuildOutDir

                # Module output directory
                ModuleOutDir       = "$BuildOutDir\$moduleVersion\$env:BHProjectName"

                # Controls whether to "compile" module into single PSM1 or not
                CompileModule      = $BuildCompileModule

                # List of directories that if CompileModule is $true, will be concatenated into the PSM1
                CompileDirectories = $BuildCompileDirectories

                # List of directories that will always be copied "as is" to output directory
                CopyDirectories    = $BuildCopyDirectories

                # List of files (regular expressions) to exclude from output directory
                Exclude            = $BuildExclude
            }
            Test    = @{
                # Enable/disable Pester tests
                Enabled        = $true

                # Directory containing Pester tests
                RootDir        = [IO.Path]::Combine($env:BHProjectPath, 'tests')

                # Specifies an output file path to send to Invoke-Pester's -OutputFile parameter.
                # This is typically used to write out test results so that they can be sent to a CI system
                # This path is relative to the directory containing Pester tests
                OutputFile     = $TestOutputFile

                # Specifies the test output format to use when the TestOutputFile property is given
                # a path.  This parameter is passed through to Invoke-Pester's -OutputFormat parameter.
                OutputFormat   = 'NUnitXml'

                ScriptAnalysis = @{
                    # Enable/disable use of PSScriptAnalyzer to perform script analysis
                    Enabled                  = $true

                    # When PSScriptAnalyzer is enabled, control which severity level will generate a build failure.
                    # Valid values are Error, Warning, Information and None.  "None" will report errors but will not
                    # cause a build failure.  "Error" will fail the build only on diagnostic records that are of
                    # severity error.  "Warning" will fail the build on Warning and Error diagnostic records.
                    # "Any" will fail the build on any diagnostic record, regardless of severity.
                    FailBuildOnSeverityLevel = 'Error'

                    # Path to the PSScriptAnalyzer settings file.
                    SettingsPath             = [IO.Path]::Combine($PSScriptRoot, 'tests\ScriptAnalyzerSettings.psd1')
                }

                # Import module from OutDir prior to running Pester tests.
                ImportModule   = $false

                CodeCoverage   = @{
                    # Enable/disable Pester code coverage reporting.
                    Enabled          = $false

                    # Fail Pester code coverage test if below this threshold
                    Threshold        = .75

                    # CodeCoverageFiles specifies the files to perform code coverage analysis on. This property
                    # acts as a direct input to the Pester -CodeCoverage parameter, so will support constructions
                    # like the ones found here: https://pester.dev/docs/usage/code-coverage.
                    Files            = @()

                    # Path to write code coverage report to
                    OutputFile       = [IO.Path]::Combine($env:BHProjectPath, 'codeCoverage.xml')

                    # The code coverage output format to use
                    OutputFileFormat = 'JaCoCo'
                }
            }
            Help    = @{
                # Path to updateable help CAB
                UpdatableHelpOutDir      = [IO.Path]::Combine($outDir, 'UpdatableHelp')

                # Default Locale used for help generation, defaults to en-US
                # Get-UICulture doesn't return a name on Linux so default to en-US
                DefaultLocale            = if (-not (Get-UICulture).Name) { 'en-US' } else { (Get-UICulture).Name }

                # Convert project readme into the module about file
                ConvertReadMeToAboutHelp = $false
            }
            Docs    = @{
                # Directory PlatyPS markdown documentation will be saved to
                RootDir = [IO.Path]::Combine($env:BHProjectPath, 'docs')
            }
            Publish = @{
                # PowerShell repository name to publish modules to
                PSRepository           = 'PSGallery'

                # API key to authenticate to PowerShell repository with
                PSRepositoryApiKey     = $env:PSGALLERY_API_KEY

                # Credential to authenticate to PowerShell repository with
                PSRepositoryCredential = $null
            }
        })

    if ([IO.Path]::IsPathFullyQualified($BuildOutDir)) {
        $PSBPreference.Build.ModuleOutDir = [IO.Path]::Combine(
            $BuildOutDir,
            $moduleVersion,
            $env:BHProjectName
        )
    } else {
        $PSBPreference.Build.ModuleOutDir = [IO.Path]::Combine(
            $env:BHProjectPath,
            $BuildOutDir,
            $moduleVersion,
            $env:BHProjectName
        )
    }

    $params = @{
        BuildOutput = $PSBPreference.Build.ModuleOutDir
    }
    Set-BuildEnvironment @params -Force

    Write-Host "`tBuild System Details:" -ForegroundColor Yellow
    $psVersion = $PSVersionTable.PSVersion.ToString()
    $buildModuleName = $MyInvocation.MyCommand.Module.Name
    $buildModuleVersion = $MyInvocation.MyCommand.Module.Version
    "`tBuild Module:       $buildModuleName`:$buildModuleVersion"
    "`tPowerShell Version: $psVersion$NewLine"



} -description 'Initialize environment variables from the PowerShellBuild module'

task RotateBuilds -depends InitializePowershellBuild {
    $BuildVersionsToRetain = 5
    Get-ChildItem -Directory -Path $BuildOutDir |
    Select-Object -SkipLast ($BuildVersionsToRetain - 1) |
    ForEach-Object {
        "`tDeleting old build .\$((($_.FullName -split '\\') | Select-Object -Last 2) -join '\')"
        $_ | Remove-Item -Recurse -Force
    }
    $NewLine
} -description 'Delete all but the last 4 builds, so we will have our 5 most recent builds after the new one is complete'

task UpdateChangeLog -depends RotateBuilds -Action {
    <#
TODO
    This task runs before the Test task so that tests of the change log will pass
    But I also need one that runs *after* the build to compare it against the previous build
    The post-build UpdateChangeLog will automatically add to the change log any:
        New/removed exported commands
        New/removed files
#>
    $ChangeLog = "$env:BHProjectPath\CHANGELOG.md"
    $NewVersion = (Test-ModuleManifest $env:BHPSModuleManifest).Version
    $NewChanges = "## [$NewVersion] - $(Get-Date -format 'yyyy-MM-dd') - $CommitMessage$NewLine"
    "`tChange Log:  $ChangeLog"
    "`tNew Changes: $NewChanges"
    [string[]]$ChangeLogContents = Get-Content -Path $ChangeLog
    $LineNumberOfLastChange = Select-String -Path $ChangeLog -Pattern '^\#\# \[\d*\.\d*\.\d*\]' |
    Select-Object -First 1 -ExpandProperty LineNumber
    $HeaderLineCount = $LineNumberOfLastChange - 1
    $NewChangeLogContents = [System.Collections.Specialized.StringCollection]::new()
    $null = $NewChangeLogContents.AddRange(($ChangeLogContents |
            Select-Object -First $HeaderLineCount))
    $null = $NewChangeLogContents.Add($NewChanges)
    $null = $NewChangeLogContents.AddRange(($ChangeLogContents |
            Select-Object -Skip $HeaderLineCount))
    $NewChangeLogContents | Out-File -FilePath $ChangeLog -Encoding utf8 -Force
}

task ExportPublicFunctions -depends UpdateChangeLog -Action {
    # Discover public functions
    $ScriptFiles = Get-ChildItem -Path "$env:BHPSModulePath\*.ps1" -Recurse
    $PublicScriptFiles = $ScriptFiles | Where-Object -FilterScript {
        ($_.PSParentPath | Split-Path -Leaf) -eq 'public'
    }

    # Export public functions in the module
    $publicFunctions = $PublicScriptFiles.BaseName
    $PublicFunctionsJoined = $publicFunctions -join "','"
    $ModuleFilePath = "$env:BHProjectPath\src\$env:BHProjectName.psm1"
    $ModuleContent = Get-Content -Path $ModuleFilePath -Raw
    $NewFunctionExportStatement = "Export-ModuleMember -Function @('$PublicFunctionsJoined')"
    if ($ModuleContent -match 'Export-ModuleMember -Function') {
        $ModuleContent = $ModuleContent -replace 'Export-ModuleMember -Function.*' , $NewFunctionExportStatement
        $ModuleContent | Out-File -Path $ModuleFilePath -Force
    } else {
        $NewFunctionExportStatement | Out-File $ModuleFilePath -Append
    }

    # Export public functions in the manifest
    Update-MetaData -Path $env:BHPSModuleManifest -PropertyName FunctionsToExport -Value $publicFunctions

} -description 'Export all public functions in the module'

task CleanOutputDir -depends ExportPublicFunctions {
    "`tOutput: $($PSBPreference.Build.ModuleOutDir)"
    Clear-PSBuildOutputFolder -Path $PSBPreference.Build.ModuleOutDir
    $NewLine
} -description 'Clears module output directory'

task StageFiles -depends CleanOutputDir {
    $buildParams = @{
        Path               = $env:BHPSModulePath
        ModuleName         = $env:BHProjectName
        DestinationPath    = $PSBPreference.Build.ModuleOutDir
        Exclude            = $PSBPreference.Build.Exclude
        Compile            = $PSBPreference.Build.CompileModule
        CompileDirectories = $PSBPreference.Build.CompileDirectories
        CopyDirectories    = $PSBPreference.Build.CopyDirectories
        Culture            = $PSBPreference.Help.DefaultLocale
    }

    if ($PSBPreference.Help.ConvertReadMeToAboutHelp) {
        $readMePath = Get-ChildItem -Path $env:BHProjectPath -Include 'readme.md', 'readme.markdown', 'readme.txt' -Depth 1 |
        Select-Object -First 1
        if ($readMePath) {
            $buildParams.ReadMePath = $readMePath
        }
    }

    # only add these configuration values to the build parameters if they have been been set
    'CompileHeader', 'CompileFooter', 'CompileScriptHeader', 'CompileScriptFooter' | ForEach-Object {
        if ($PSBPreference.Build.Keys -contains $_) {
            $buildParams.$_ = $PSBPreference.Build.$_
        }
    }

    Build-PSBuildModule @buildParams
} -description 'Build a PowerShell script module based on the source directory'

$genMarkdownPreReqs = {
    $result = $true
    if (-not (Get-Module platyPS -ListAvailable)) {
        Write-Warning "platyPS module is not installed. Skipping [$($psake.context.currentTaskName)] task."
        $result = $false
    }
    $result
}

task DeleteMarkdownHelp -depends StageFiles -precondition $genMarkdownPreReqs {
    $MarkdownDir = [IO.Path]::Combine($PSBPreference.Docs.RootDir, $PSBPreference.Help.DefaultLocale)
    "`tDeleting folder: '$MarkdownDir'"
    Get-ChildItem -Path $MarkdownDir -Recurse | Remove-Item
    $NewLine
} -description 'Delete existing .md files to prepare for PlatyPS to build new ones'

task BuildMarkdownHelp -depends DeleteMarkdownHelp -precondition $genMarkdownPreReqs {

    $moduleInfo = Import-Module "$($PSBPreference.Build.ModuleOutDir)/$env:BHProjectName.psd1" -Global -Force -PassThru

    try {
        if ($moduleInfo.ExportedCommands.Count -eq 0) {
            Write-Warning 'No commands have been exported. Skipping markdown generation.'
            return
        }

        if (-not (Test-Path -LiteralPath $PSBPreference.Docs.RootDir)) {
            New-Item -Path $PSBPreference.Docs.RootDir -ItemType Directory > $null
        }

        if (Get-ChildItem -LiteralPath $PSBPreference.Docs.RootDir -Filter *.md -Recurse) {
            Get-ChildItem -LiteralPath $PSBPreference.Docs.RootDir -Directory | ForEach-Object {
                Update-MarkdownHelp -Path $_.FullName -Verbose:$VerbosePreference > $null
            }
        }

        # ErrorAction set to SilentlyContinue so this command will not overwrite an existing MD file.
        $newMDParams = @{
            Module         = $env:BHProjectName
            Locale         = $PSBPreference.Help.DefaultLocale
            OutputFolder   = [IO.Path]::Combine($PSBPreference.Docs.RootDir, $PSBPreference.Help.DefaultLocale)
            ErrorAction    = 'SilentlyContinue'
            Verbose        = $VerbosePreference
            WithModulePage = $true
        }
        New-MarkdownHelp @newMDParams
    } finally {
        Remove-Module $env:BHProjectName -Force
    }
} -description 'Generates PlatyPS markdown files from module help'

$genHelpFilesPreReqs = {
    $result = $true
    if (-not (Get-Module platyPS -ListAvailable)) {
        Write-Warning "platyPS module is not installed. Skipping [$($psake.context.currentTaskName)] task."
        $result = $false
    }
    $result
}

task BuildMAMLHelp -depends BuildMarkdownHelp -precondition $genHelpFilesPreReqs {
    Build-PSBuildMAMLHelp -Path $PSBPreference.Docs.RootDir -DestinationPath $PSBPreference.Build.ModuleOutDir
} -description 'Generates MAML-based help from PlatyPS markdown files'

$genUpdatableHelpPreReqs = {
    $result = $true
    if (-not (Get-Module platyPS -ListAvailable)) {
        Write-Warning "platyPS module is not installed. Skipping [$($psake.context.currentTaskName)] task."
        $result = $false
    }
    $result
}

task BuildUpdatableHelp -depends BuildMAMLHelp -precondition $genUpdatableHelpPreReqs {

    $OS = (Get-CimInstance -ClassName CIM_OperatingSystem).Caption
    if ($OS -notmatch 'Windows') {
        Write-Warning 'MakeCab.exe is only available on Windows. Cannot create help cab.'
        return
    }

    $helpLocales = (Get-ChildItem -Path $PSBPreference.Docs.RootDir -Directory).Name

    # Create updatable help output directory
    if (-not (Test-Path -LiteralPath $PSBPreference.Help.UpdatableHelpOutDir)) {
        New-Item $PSBPreference.Help.UpdatableHelpOutDir -ItemType Directory -Verbose:$VerbosePreference > $null
    } else {
        Write-Verbose "Directory already exists [$($PSBPreference.Help.UpdatableHelpOutDir)]."
        Get-ChildItem $PSBPreference.Help.UpdatableHelpOutDir | Remove-Item -Recurse -Force -Verbose:$VerbosePreference
    }

    # Generate updatable help files.  Note: this will currently update the version number in the module's MD
    # file in the metadata.
    foreach ($locale in $helpLocales) {
        $cabParams = @{
            CabFilesFolder  = [IO.Path]::Combine($PSBPreference.Build.ModuleOutDir, $locale)
            LandingPagePath = [IO.Path]::Combine($PSBPreference.Docs.RootDir, $locale, "$env:BHProjectName.md")
            OutputFolder    = $PSBPreference.Help.UpdatableHelpOutDir
            Verbose         = $VerbosePreference
        }
        New-ExternalHelpCab @cabParams > $null
    }

} -description 'Create updatable help .cab file based on PlatyPS markdown help'

$analyzePreReqs = {
    $result = $true
    if (-not $PSBPreference.Test.ScriptAnalysis.Enabled) {
        Write-Warning 'Script analysis is not enabled.'
        $result = $false
    }
    if (-not (Get-Module -Name PSScriptAnalyzer -ListAvailable)) {
        Write-Warning 'PSScriptAnalyzer module is not installed'
        $result = $false
    }
    $result
}

task Lint -depends BuildUpdatableHelp -precondition $analyzePreReqs {
    $analyzeParams = @{
        Path              = $PSBPreference.Build.ModuleOutDir
        SeverityThreshold = $PSBPreference.Test.ScriptAnalysis.FailBuildOnSeverityLevel
        SettingsPath      = $PSBPreference.Test.ScriptAnalysis.SettingsPath
    }
    Test-PSBuildScriptAnalysis @analyzeParams
} -description 'Execute PSScriptAnalyzer tests'

$pesterPreReqs = {
    $result = $true
    #if (-not $PSBPreference.Test.Enabled) {
    #    Write-Warning 'Pester testing is not enabled.'
    #    $result = $false
    #}
    if (-not (Get-Module -Name Pester -ListAvailable)) {
        Write-Warning 'Pester module is not installed'
        $result = $false
    }
    #if (-not (Test-Path -Path $PSBPreference.Test.RootDir)) {
    #    Write-Warning "Test directory [$($PSBPreference.Test.RootDir)] not found"
    #    $result = $false
    #}
    return $result
}

task UnitTests -depends Lint -precondition $pesterPreReqs {
    $pesterParams = @{
        Path                         = $PSBPreference.Test.RootDir
        ModuleName                   = $env:BHProjectName
        ModuleManifest               = Join-Path $PSBPreference.Build.ModuleOutDir "$env:BHProjectName.psd1"
        OutputPath                   = $PSBPreference.Test.OutputFile
        OutputFormat                 = $PSBPreference.Test.OutputFormat
        CodeCoverage                 = $PSBPreference.Test.CodeCoverage.Enabled
        CodeCoverageThreshold        = $PSBPreference.Test.CodeCoverage.Threshold
        CodeCoverageFiles            = $PSBPreference.Test.CodeCoverage.Files
        CodeCoverageOutputFile       = $PSBPreference.Test.CodeCoverage.OutputFile
        CodeCoverageOutputFileFormat = $PSBPreference.Test.CodeCoverage.OutputFormat
        ImportModule                 = $PSBPreference.Test.ImportModule
    }
    Test-PSBuildPester @pesterParams
} -description 'Execute Pester tests'

task SourceControl -depends UnitTests {
    # Commit to Git
    git add .
    git commit -m $CommitMessage
    git push origin main
} -description 'git add, commit, and push'

task Publish -depends SourceControl {
    Assert -conditionToCheck ($PSBPreference.Publish.PSRepositoryApiKey -or $PSBPreference.Publish.PSRepositoryCredential) -failureMessage "API key or credential not defined to authenticate with [$($PSBPreference.Publish.PSRepository)] with."

    $publishParams = @{
        Path       = $PSBPreference.Build.ModuleOutDir
        Repository = $PSBPreference.Publish.PSRepository
        Verbose    = $VerbosePreference
    }
    if ($PSBPreference.Publish.PSRepositoryApiKey) {
        $publishParams.NuGetApiKey = $PSBPreference.Publish.PSRepositoryApiKey
    }

    if ($PSBPreference.Publish.PSRepositoryCredential) {
        $publishParams.Credential = $PSBPreference.Publish.PSRepositoryCredential
    }

    # Publish to PSGallery
    Publish-Module @publishParams
} -description 'Publish module to the defined PowerShell repository'

task ? -description 'Lists the available tasks' {
    'Available tasks:'
    $psake.context.Peek().Tasks.Keys | Sort-Object
}
