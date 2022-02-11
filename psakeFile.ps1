properties {
    $BuildOutputFolderName = 'dist'
    $BuildCompileModule = $true
    $BuildCompileDirectories = @('classes', 'enums', 'filters', 'functions/private', 'functions/public')
    $BuildCopyDirectories = @('../bin', '../config', '../data', '../lib')
    $BuildExclude = @('gitkeep', "$env:BHProjectName.psm1")
    $BuildOutDir = "$env:BHProjectPath\$BuildOutputFolderName"
    $TestOutputFile = 'out/testResults.xml'
    $nl = [System.Environment]::NewLine
}


FormatTaskName {
    param($taskName)
    Write-Host 'Task: ' -ForegroundColor Cyan -NoNewline
    Write-Host $taskName.ToUpper() -ForegroundColor Blue
}

task Default -depends Publish

#Task Init -FromModule PowerShellBuild -minimumVersion 0.6.1

task InitializeBuildHelpers {
    BuildHelpers\Set-BuildEnvironment -Force
    $env:BHCommitMessage = $CommitMessage
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
    "`tNew Version: $NextVersion$nl"

    Update-Metadata -Path $env:BHPSModuleManifest -PropertyName ModuleVersion -Value $NextVersion -ErrorAction Stop
} -description 'Increment the module version and update the module manifest accordingly'

task InitializePowershellBuild -depends UpdateModuleVersion {

    Remove-Variable -Name PSBPreference -Scope Script -Force -ErrorAction Ignore

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

                Dependencies       = @('StageFiles', 'BuildHelp')

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
                #PSRepositoryApiKey     = $env:PSGALLERY_API_KEY
                PSRepositoryApiKey     = $PSGAPIK

                # Credential to authenticate to PowerShell repository with
                PSRepositoryCredential = $null
            }
        })

    if ([IO.Path]::IsPathFullyQualified($PSBPreference.Build.OutDir)) {
        $PSBPreference.Build.ModuleOutDir = [IO.Path]::Combine(
            $PSBPreference.Build.OutDir,
            $PSBPreference.General.ModuleVersion,
            $env:BHProjectName
        )
    } else {
        $PSBPreference.Build.ModuleOutDir = [IO.Path]::Combine(
            $env:BHProjectPath,
            $PSBPreference.Build.OutDir,
            $PSBPreference.General.ModuleVersion,
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
    "`tPowerShell Version: $psVersion$nl"



} -description 'Initialize environment variables from the PowerShellBuild module'

task RotateBuilds -depends InitializePowershellBuild {
    $BuildVersionsToRetain = 5
    Get-ChildItem -Directory -Path $PSBPreference.Build.OutDir |
    Select-Object -SkipLast ($BuildVersionsToRetain - 1) |
    ForEach-Object {
        "`tDeleting old build .\$((($_.FullName -split '\\') | Select-Object -Last 2) -join '\')"
        $_ | Remove-Item -Recurse -Force
    }

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
    $NewChanges = "## [$($PSBPreference.General.ModuleVersion)] - $(Get-Date -format 'yyyy-MM-dd') - $CommitMessage"
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
    Write-Host "MODULE OUTPUT DIR - $($PSBPreference.Build.ModuleOutDir)" -ForegroundColor Cyan
    Clear-PSBuildOutputFolder -Path $PSBPreference.Build.ModuleOutDir
} -description 'Clears module output directory'

task StageFiles -depends CleanOutputDir {
    $buildParams = @{
        Path               = $PSBPreference.General.SrcRootDir
        ModuleName         = $PSBPreference.General.ModuleName
        DestinationPath    = $PSBPreference.Build.ModuleOutDir
        Exclude            = $PSBPreference.Build.Exclude
        Compile            = $PSBPreference.Build.CompileModule
        CompileDirectories = $PSBPreference.Build.CompileDirectories
        CopyDirectories    = $PSBPreference.Build.CopyDirectories
        Culture            = $PSBPreference.Help.DefaultLocale
    }

    if ($PSBPreference.Help.ConvertReadMeToAboutHelp) {
        $readMePath = Get-ChildItem -Path $PSBPreference.General.ProjectRoot -Include 'readme.md', 'readme.markdown', 'readme.txt' -Depth 1 |
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
} -description 'Builds module based on source directory'

$genMarkdownPreReqs = {
    $result = $true
    if (-not (Get-Module platyPS -ListAvailable)) {
        Write-Warning "platyPS module is not installed. Skipping [$($psake.context.currentTaskName)] task."
        $result = $false
    }
    $result
}
task GenerateMarkdown -depends StageFiles -precondition $genMarkdownPreReqs {
    $buildMDParams = @{
        ModulePath = $PSBPreference.Build.ModuleOutDir
        ModuleName = $PSBPreference.General.ModuleName
        DocsPath   = $PSBPreference.Docs.RootDir
        Locale     = $PSBPreference.Help.DefaultLocale
    }
    Build-PSBuildMarkdown @buildMDParams
} -description 'Generates PlatyPS markdown files from module help'

$genHelpFilesPreReqs = {
    $result = $true
    if (-not (Get-Module platyPS -ListAvailable)) {
        Write-Warning "platyPS module is not installed. Skipping [$($psake.context.currentTaskName)] task."
        $result = $false
    }
    $result
}

task GenerateMAML -depends GenerateMarkdown -precondition $genHelpFilesPreReqs {
    Build-PSBuildMAMLHelp -Path $PSBPreference.Docs.RootDir -DestinationPath $PSBPreference.Build.ModuleOutDir
} -description 'Generates MAML-based help from PlatyPS markdown files'

task BuildHelp -depends GenerateMarkdown, GenerateMAML {} -description 'Builds help documentation'

$genUpdatableHelpPreReqs = {
    $result = $true
    if (-not (Get-Module platyPS -ListAvailable)) {
        Write-Warning "platyPS module is not installed. Skipping [$($psake.context.currentTaskName)] task."
        $result = $false
    }
    $result
}
task GenerateUpdatableHelp -depends BuildHelp -precondition $genUpdatableHelpPreReqs {
    Build-PSBuildUpdatableHelp -DocsPath $PSBPreference.Docs.RootDir -OutputPath $PSBPreference.Help.UpdatableHelpOutDir
} -description 'Create updatable help .cab file based on PlatyPS markdown help'

task Build -depends StageFiles, BuildHelp {

    Write-Host "$nl`tEnvironment variables:" -ForegroundColor Yellow
    (Get-Item ENV:BH*).Foreach({
            "`t{0,-20}{1}" -f $_.name, $_.value
        })
} -description 'Builds module and generate help documentation'

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
task Analyze -depends Build -precondition $analyzePreReqs {
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
task Pester -depends Build -precondition $pesterPreReqs {
    $pesterParams = @{
        Path                         = $PSBPreference.Test.RootDir
        ModuleName                   = $PSBPreference.General.ModuleName
        ModuleManifest               = Join-Path $PSBPreference.Build.ModuleOutDir "$($PSBPreference.General.ModuleName).psd1"
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

task Test -depends Pester, Analyze {
} -description 'Execute Pester and ScriptAnalyzer tests'

task Git -depends Test {
    git add .
    git commit -m $CommitMessage
    git push origin main
}

task Publish -depends Git {
    Assert -conditionToCheck ($PSBPreference.Publish.PSRepositoryApiKey -or $PSBPreference.Publish.PSRepositoryCredential) -failureMessage "API key or credential not defined to authenticate with [$($PSBPreference.Publish.PSRepository)] with."

    $publishParams = @{
        Path       = $PSBPreference.Build.ModuleOutDir
        Repository = $PSBPreference.Publish.PSRepository
        Verbose    = $VerbosePreference
        WhatIf     = $true
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
