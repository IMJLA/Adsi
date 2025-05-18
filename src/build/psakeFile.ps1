#TODO : Use Fixer 'Get-TextFilesList $pwd | ConvertTo-SpaceIndentation'.

# Initialize the BuildHelpers environment variables here so they are usable in all child scopes including the psake properties block
#BuildHelpers\Set-BuildEnvironment -Force

Properties {

    $StartingLocation = Get-Location
    Set-Location $PSScriptRoot
    $ProjectRoot = [IO.Path]::Combine('..', '..')
    Set-Location $ProjectRoot

    $SourceCodeDir = [IO.Path]::Combine('.', 'src')

    $ModuleManifestDir = [IO.Path]::Combine($SourceCodeDir, '*.psd1')

    $ModuleManifest = Get-ChildItem -Path $ModuleManifestDir

    $ModuleName = [IO.Path]::GetFileNameWithoutExtension($ModuleManifest)

    $ModuleFilePath = [IO.Path]::Combine($SourceCodeDir, "$ModuleName.psm1")

    $IncrementMajorVersion = $false

    $IncrementMinorVersion = $false

    $ManifestTest = Test-ModuleManifest -Path $ModuleManifest

    $CurrentVersion = $ManifestTest.Version
    "`tOld Version: $CurrentVersion"
    if ($IncrementMajorVersion) {
        "`tThis is a new major version"
        $NewModuleVersion = "$($CurrentVersion.Major + 1).0.0"
    }
    elseif ($IncrementMinorVersion) {
        "`tThis is a new minor version"
        $NewModuleVersion = "$($CurrentVersion.Major).$($CurrentVersion.Minor + 1).0"
    }
    else {
        "`tThis is a new build"
        $NewModuleVersion = "$($CurrentVersion.Major).$($CurrentVersion.Minor).$($CurrentVersion.Build + 1)"
    }

    # Discover public function files so their help files can be fixed (multi-line default parameter values)
    $publicFunctionPath = [IO.Path]::Combine($SourceCodeDir, 'functions', 'public', '*.ps1')
    $PublicFunctionFiles = Get-ChildItem -Path $publicFunctionPath -Recurse

    # Controls whether to "compile" module into single PSM1 or not
    $BuildCompileModule = $true

    # List of directories that if BuildCompileModule is $true, will be concatenated into the PSM1
    $BuildCompileDirectories = @('classes', 'enums', 'filters', 'functions/private', 'functions/public')

    # List of directories that will always be copied "as is" to output directory
    $BuildCopyDirectories = @('../bin', '../config', '../data', '../lib')

    # List of files (regular expressions) to exclude from output directory
    $BuildExclude = @('gitkeep', "$ModuleName.psm1")

    # Output directory when building a module
    $DistDir = [IO.Path]::Combine('.', 'dist')

    $BuildOutputDir = [IO.Path]::Combine($DistDir, $NewModuleVersion, $ModuleName)

    # Default Locale used for help generation, defaults to en-US
    # Get-UICulture doesn't return a name on Linux so default to en-US
    $HelpDefaultLocale = if (-not (Get-UICulture).Name) { 'en-US' } else { (Get-UICulture).Name }

    # Convert project readme into the module about file
    $HelpConvertReadMeToAboutHelp = $true

    # Directory PlatyPS markdown documentation will be saved to
    $DocsRootDir = [IO.Path]::Combine('.', 'docs')

    $TestRootDir = [IO.Path]::Combine('.', 'tests')
    $TestOutputFile = [IO.Path]::Combine('out', 'testResults.xml')

    # Path to updatable help CAB
    $HelpUpdatableHelpOutDir = [IO.Path]::Combine($DocsRootDir, 'UpdatableHelp')

    # Enable/disable use of PSScriptAnalyzer to perform script analysis
    $TestLintEnabled = $true

    # When PSScriptAnalyzer is enabled, control which severity level will generate a build failure.
    # Valid values are Error, Warning, Information and None.  "None" will report errors but will not
    # cause a build failure.  "Error" will fail the build only on diagnostic records that are of
    # severity error.  "Warning" will fail the build on Warning and Error diagnostic records.
    # "Any" will fail the build on any diagnostic record, regardless of severity.
    $TestLintFailBuildOnSeverityLevel = 'Error'

    # Path to the PSScriptAnalyzer settings file.
    $TestLintSettingsPath = [IO.Path]::Combine($TestRootDir, 'ScriptAnalyzerSettings.psd1')

    $TestEnabled = $true

    $TestOutputFormat = 'NUnitXml'

    # Enable/disable Pester code coverage reporting.
    $TestCodeCoverageEnabled = $false

    # Fail Pester code coverage test if below this threshold
    $TestCodeCoverageThreshold = .75

    # CodeCoverageFiles specifies the files to perform code coverage analysis on. This property
    # acts as a direct input to the Pester -CodeCoverage parameter, so will support constructions
    # like the ones found here: https://pester.dev/docs/usage/code-coverage.
    $TestCodeCoverageFiles = @()

    # Path to write code coverage report to
    $TestCodeCoverageOutputFile = [IO.Path]::Combine($TestRootDir, 'out', 'codeCoverage.xml')

    # The code coverage output format to use
    $TestCodeCoverageOutputFileFormat = 'JaCoCo'

    $TestImportModuleFirst = $false

    # PowerShell repository name to publish modules to
    $PublishPSRepository = 'PSGallery'

    # API key to authenticate to PowerShell repository with
    $PublishPSRepositoryApiKey = $env:PSGALLERY_API_KEY

    # Credential to authenticate to PowerShell repository with
    $PublishPSRepositoryCredential = $null

    $NewLine = [System.Environment]::NewLine

}

FormatTaskName {

    param(
        [string]$taskName
    )

    Write-Host "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-Host $taskName -ForegroundColor Blue

}

Task Default -depends ReturnToStartingLocation

#Task Init -FromModule PowerShellBuild -minimumVersion 0.6.1

Task UpdateModuleVersion -action {

    "`tUpdate-Metadata -Path '$ModuleManifest' -PropertyName ModuleVersion -Value $NewModuleVersion -ErrorAction Stop"
    Update-Metadata -Path $ModuleManifest -PropertyName ModuleVersion -Value $NewModuleVersion -ErrorAction Stop

} -description 'Increment the module version and update the module manifest accordingly'

Task RotateBuilds -depends UpdateModuleVersion -action {
    $BuildVersionsToRetain = 1

    Write-Host "`tGet-ChildItem -Directory -Path '$DistDir'"
    Get-ChildItem -Directory -Path $DistDir |
    Sort-Object -Property Name |
    Select-Object -SkipLast ($BuildVersionsToRetain - 1) |
    ForEach-Object {
        Write-Host "'$_' | Remove-Item -Recurse -Force"
        $_ | Remove-Item -Recurse -Force
    }

} -description 'Delete all but the last 4 builds, so we will have our 5 most recent builds after the new one is complete'

Task UpdateChangeLog -depends RotateBuilds -action {
    <#
    TODO
        This task runs before the Test task so that tests of the change log will pass
        But I also need one that runs *after* the build to compare it against the previous build
        The post-build UpdateChangeLog will automatically add to the change log any:
            New/removed exported commands
            New/removed files
    #>
    $ChangeLog = [IO.Path]::Combine('.', 'CHANGELOG.md')
    $NewModuleVersion = (Import-PowerShellDataFile -Path $ModuleManifest).ModuleVersion
    $NewChanges = "## [$NewModuleVersion] - $(Get-Date -Format 'yyyy-MM-dd') - $CommitMessage$NewLine"
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

Task ExportPublicFunctions -depends UpdateChangeLog -action {
    # Export public functions in the module
    $publicFunctions = $PublicFunctionFiles.BaseName
    "`t$($publicFunctions -join "$NewLine`t")$NewLine"
    $PublicFunctionsJoined = $publicFunctions -join "','"
    $ModuleContent = Get-Content -Path $ModuleFilePath -Raw
    $NewFunctionExportStatement = "Export-ModuleMember -Function @('$PublicFunctionsJoined')"
    if ($ModuleContent -match 'Export-ModuleMember -Function') {
        $ModuleContent = $ModuleContent -replace 'Export-ModuleMember -Function.*' , $NewFunctionExportStatement
        $ModuleContent | Out-File -Path $ModuleFilePath -Force
    }
    else {
        $NewFunctionExportStatement | Out-File $ModuleFilePath -Append
    }

    # Export public functions in the manifest
    Update-Metadata -Path $ModuleManifest -PropertyName FunctionsToExport -Value $publicFunctions

} -description 'Export all public functions in the module'

Task CleanOutputDir -depends ExportPublicFunctions -action {
    "`tOutput: $BuildOutputDir"
    Clear-PSBuildOutputFolder -Path $BuildOutputDir
    $NewLine
} -description 'Clears module output directory'

Task BuildModule -depends CleanOutputDir {
    $buildParams = @{
        Path               = $SourceCodeDir
        ModuleName         = $ModuleName
        DestinationPath    = $BuildOutputDir
        Exclude            = $BuildExclude
        Compile            = $BuildCompileModule
        CompileDirectories = $BuildCompileDirectories
        CopyDirectories    = $BuildCopyDirectories
        Culture            = $HelpDefaultLocale
    }

    if ($HelpConvertReadMeToAboutHelp) {
        $readMePath = Get-ChildItem -Path '.' -Include 'readme.md', 'readme.markdown', 'readme.txt' -Depth 1 |
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
    if (-not (Get-Module PlatyPS -ListAvailable)) {
        Write-Warning "PlatyPS module is not installed. Skipping [$($psake.context.currentTaskName)] task."
        $result = $false
    }
    $result
}

Task DeleteMarkdownHelp -depends BuildModule -precondition $genMarkdownPreReqs -action {
    $MarkdownDir = [IO.Path]::Combine($DocsRootDir, $HelpDefaultLocale)
    "`tDeleting folder: '$MarkdownDir'"
    Get-ChildItem -Path $MarkdownDir -Recurse | Remove-Item
    $NewLine
} -description 'Delete existing .md files to prepare for PlatyPS to build new ones'

Task BuildMarkdownHelp -depends DeleteMarkdownHelp {
    $ManifestPath = [IO.Path]::Combine($BuildOutputDir, "$ModuleName.psd1")
    $moduleInfo = Import-Module $ManifestPath  -Global -Force -PassThru
    $manifestInfo = Test-ModuleManifest -Path $ManifestPath
    if ($moduleInfo.ExportedCommands.Count -eq 0) {
        Write-Warning 'No commands have been exported. Skipping markdown generation.'
        return
    }
    if (-not (Test-Path -LiteralPath $DocsRootDir)) {
        New-Item -Path $DocsRootDir -ItemType Directory > $null
    }
    try {
        if (Get-ChildItem -LiteralPath $DocsRootDir -Filter *.md -Recurse) {
            Get-ChildItem -LiteralPath $DocsRootDir -Directory | ForEach-Object {
                Update-MarkdownHelp -Path $_.FullName -Verbose:$VerbosePreference > $null
            }
        }

        $newMDParams = @{
            AlphabeticParamsOrder = $true
            Locale                = $HelpDefaultLocale
            # ErrorAction set to SilentlyContinue so this command will not overwrite an existing MD file.
            ErrorAction           = 'SilentlyContinue'
            HelpVersion           = $moduleInfo.Version
            Module                = $ModuleName
            # TODO: Using GitHub pages as a container for PowerShell Updatable Help https://gist.github.com/TheFreeman193/fde11aee6998ad4c40a314667c2a3005
            # OnlineVersionUrl = $GitHubPagesLinkForThisModule
            OutputFolder          = [IO.Path]::Combine($DocsRootDir, $HelpDefaultLocale)
            UseFullTypeName       = $true
            Verbose               = $VerbosePreference
            WithModulePage        = $true
        }
        New-MarkdownHelp @newMDParams
    }
    finally {
        Remove-Module $ModuleName -Force
    }
} -description 'Generate markdown files from the module help'

Task FixMarkdownHelp -depends BuildMarkdownHelp -action {
    $ManifestPath = [IO.Path]::Combine($BuildOutputDir, "$ModuleName.psd1")
    $moduleInfo = Import-Module $ManifestPath  -Global -Force -PassThru
    $manifestInfo = Test-ModuleManifest -Path $ManifestPath

    #Fix the Module Page () things PlatyPS does not do):
    $ModuleHelpFile = [IO.Path]::Combine($DocsRootDir, $HelpDefaultLocale, "$ModuleName.md")
    [string]$ModuleHelp = Get-Content -LiteralPath $ModuleHelpFile -Raw

    #Update the module description
    $RegEx = '(?ms)\#\#\ Description\s*[^\r\n]*\s*'
    $NewString = "## Description$NewLine$($moduleInfo.Description)$NewLine$NewLine"
    $ModuleHelp = $ModuleHelp -replace $RegEx, $NewString

    Write-Host "`t'`$ModuleHelp' -replace '$RegEx', '$NewString'"

    #Update the description of each function (use its synopsis for brevity)
    ForEach ($ThisFunction in $ManifestInfo.ExportedCommands.Keys) {
        $Synopsis = (Get-Help -name $ThisFunction).Synopsis
        $RegEx = "(?ms)\#\#\#\ \[$ThisFunction]\($ThisFunction\.md\)\s*[^\r\n]*\s*"
        $NewString = "### [$ThisFunction]($ThisFunction.md)$NewLine$Synopsis$NewLine$NewLine"
        $ModuleHelp = $ModuleHelp -replace $RegEx, $NewString
    }

    # Change multi-line default parameter values (especially hashtables) to be a single line to avoid the error below:
    <#
        Error: 4/8/2025 11:35:12 PM:
        At C:\Users\User\OneDrive\Documents\PowerShell\Modules\platyPS\0.14.2\platyPS.psm1:1412 char:22 +     $markdownFiles | ForEach-Object { +                      ~~~~~~~~~~~~~~~~ [<<==>>] Exception: Exception calling "NodeModelToMamlModel" with "1" argument(s): "C:\Export-Permission\Entire Project\Adsi\docs\en-US\New-FakeDirectoryEntry.md:90:(200) '```yamlType: System.Collections.HashtableParam...'
        Invalid yaml: expected simple key-value pairs" --> C:\blah.md:90:(200) '```yamlType: System.Collections.HashtableParam...'
        Invalid yaml: expected simple key-value pairs
    #>
    $ModuleHelp = $ModuleHelp -replace '\r?\n[ ]{12}', ' ; '
    $ModuleHelp = $ModuleHelp -replace '{ ;', '{ '
    $ModuleHelp = $ModuleHelp -replace '[ ]{2,}', ' '
    $ModuleHelp = $ModuleHelp -replace '\r?\n\s\}', ' }'

    $ModuleHelp | Set-Content -LiteralPath $ModuleHelpFile -Encoding utf8
    Remove-Module $ModuleName -Force

    ForEach ($ThisFunction in $PublicFunctionFiles.Name) {
        $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($ThisFunction)
        $ThisFunctionHelpFile = [IO.Path]::Combine($DocsRootDir, $HelpDefaultLocale, "$fileNameWithoutExtension.md")
        $ThisFunctionHelp = Get-Content -LiteralPath $ThisFunctionHelpFile -Raw
        $ThisFunctionHelp = $ThisFunctionHelp -replace '\r?\n[ ]{12}', ' ; '
        $ThisFunctionHelp = $ThisFunctionHelp -replace '{ ;', '{ '
        $ThisFunctionHelp = $ThisFunctionHelp -replace '[ ]{2,}', ' '
        $ThisFunctionHelp = $ThisFunctionHelp -replace '\r?\n\s\}', ' }'
        Set-Content -LiteralPath $ThisFunctionHelpFile -Value $ThisFunctionHelp
    }

    # Fix the readme file to point to the correct location of the markdown files
    $ReadMeContents = $ModuleHelp
    $DocsRootForURL = "docs/$HelpDefaultLocale"
    [regex]::Matches($ModuleHelp, '[^(]*\.md').Value |
    ForEach-Object {
        $EscapedTextToReplace = [regex]::Escape($_)
        $Replacement = "$DocsRootForURL/$_"
        $ReadMeContents = $ReadMeContents -replace $EscapedTextToReplace, $Replacement
    }
    $readMePath = Get-ChildItem -Path '.' -Include 'readme.md', 'readme.markdown', 'readme.txt' -Depth 1 |
    Select-Object -First 1

    Set-Content -Path $ReadMePath.FullName -Value $ReadMeContents

}

$genHelpFilesPreReqs = {
    $result = $true
    if (-not (Get-Module platyPS -ListAvailable)) {
        Write-Warning "platyPS module is not installed. Skipping [$($psake.context.currentTaskName)] task."
        $result = $false
    }
    $result
}

Task BuildMAMLHelp -depends FixMarkdownHelp -precondition $genHelpFilesPreReqs -action {
    Build-PSBuildMAMLHelp -Path $DocsRootDir -DestinationPath $BuildOutputDir
} -description 'Generates MAML-based help from PlatyPS markdown files'

$genUpdatableHelpPreReqs = {
    $result = $true
    if (-not (Get-Module platyPS -ListAvailable)) {
        Write-Warning "platyPS module is not installed. Skipping [$($psake.context.currentTaskName)] task."
        $result = $false
    }
    $result
}

Task BuildUpdatableHelp -depends BuildMAMLHelp -precondition $genUpdatableHelpPreReqs -action {

    $OS = (Get-CimInstance -ClassName CIM_OperatingSystem).Caption
    if ($OS -notmatch 'Windows') {
        Write-Warning 'MakeCab.exe is only available on Windows. Cannot create help cab.'
        return
    }

    $helpLocales = (Get-ChildItem -Path $DocsRootDir -Directory -Exclude 'UpdatableHelp').Name

    if ($null -eq $HelpUpdatableHelpOutDir) {
        $HelpUpdatableHelpOutDir = [IO.Path]::Combine($DocsRootDir, 'UpdatableHelp')
    }

    # Create updatable help output directory
    if (-not (Test-Path -LiteralPath $HelpUpdatableHelpOutDir)) {
        New-Item $HelpUpdatableHelpOutDir -ItemType Directory -Verbose:$VerbosePreference > $null
    }
    else {
        Write-Verbose "Removing existing directory: [$HelpUpdatableHelpOutDir]."
        Get-ChildItem $HelpUpdatableHelpOutDir | Remove-Item -Recurse -Force -Verbose:$VerbosePreference
    }

    # Generate updatable help files.  Note: this will currently update the version number in the module's MD
    # file in the metadata.
    foreach ($locale in $helpLocales) {
        $cabParams = @{
            CabFilesFolder  = [IO.Path]::Combine($BuildOutputDir, $locale)
            LandingPagePath = [IO.Path]::Combine($DocsRootDir, $locale, "$ModuleName.md")
            OutputFolder    = $HelpUpdatableHelpOutDir
            Verbose         = $VerbosePreference
        }
        New-ExternalHelpCab @cabParams > $null
    }

} -description 'Create updatable help .cab file based on PlatyPS markdown help'

$analyzePreReqs = {
    $result = $true
    if (-not $TestLintEnabled) {
        Write-Warning 'Script analysis is not enabled.'
        $result = $false
    }
    if (-not (Get-Module -Name PSScriptAnalyzer -ListAvailable)) {
        Write-Warning 'PSScriptAnalyzer module is not installed'
        $result = $false
    }
    $result
}

Task Lint -depends BuildUpdatableHelp -precondition $analyzePreReqs -action {
    $analyzeParams = @{
        Path              = $BuildOutputDir
        SeverityThreshold = $TestLintFailBuildOnSeverityLevel
        SettingsPath      = $TestLintSettingsPath
    }
    Test-PSBuildScriptAnalysis @analyzeParams
} -description 'Execute PSScriptAnalyzer tests'

$pesterPreReqs = {
    $result = $true
    if (-not $TestEnabled) {
        Write-Warning 'Pester testing is not enabled.'
        $result = $false
    }
    if (-not (Get-Module -Name Pester -ListAvailable)) {
        Write-Warning 'Pester module is not installed'
        $result = $false
    }
    if (-not (Test-Path -Path $TestRootDir)) {
        Write-Warning "Test directory [$TestRootDir)] not found"
        $result = $false
    }
    return $result
}

Task UnitTests -depends Lint -precondition $pesterPreReqs -action {

    $PesterConfigParams = @{
        Run          = @{
            Path = "$TestsDir"
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
            OutputPath   = $TestsResultFile
            OutputFormat = $TestOutputFormat
        }
    }

    Write-Host "`tNew-PesterConfiguration -Hashtable `$PesterConfigParams"
    $PesterConfiguration = New-PesterConfiguration -Hashtable $PesterConfigParams

    Write-Host "`tInvoke-Pester -Configuration `$PesterConfiguration$NewLine"
    Invoke-Pester -Configuration $PesterConfiguration

} -description 'Perform unit tests using Pester.'

Task SourceControl -depends UnitTests -action {
    $CurrentBranch = git branch --show-current
    # Commit to Git
    git add .
    git commit -m $CommitMessage
    git push origin $CurrentBranch
} -description 'git add, commit, and push'

Task Publish -depends SourceControl -action {
    Assert -conditionToCheck ($PublishPSRepositoryApiKey -or $PublishPSRepositoryCredential) -failureMessage "API key or credential not defined to authenticate with [$PublishPSRepository)] with."

    $publishParams = @{
        Path       = $BuildOutputDir
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
        Write-Host "`tPublish-Module -Path '$BuildOutputDir' -Repository 'PSGallery'"
        # Publish to PSGallery
        Publish-Module @publishParams
    }
    else {
        Write-Verbose 'Skipping publishing. NoPublish is $NoPublish and current git branch is $CurrentBranch'
    }
} -description 'Publish module to the defined PowerShell repository'

Task AwaitRepoUpdate -depends Publish -action {
    $timer = 0
    $timer = 30
    do {
        Start-Sleep -Seconds 1
        $timer++
        $VersionInGallery = Find-Module -Name $ModuleName -Repository $PublishPSRepository
    } while (
        $VersionInGallery.Version -lt $NewModuleVersion -and
        $timer -lt $timeout
    )

    if ($timer -eq $timeout) {
        Write-Warning "Cannot retrieve version '$NewModuleVersion' of module '$ModuleName' from repo '$PublishPSRepository'"
    }
} -description 'Await the new version in the defined PowerShell repository'

Task Uninstall -depends AwaitRepoUpdate -action {

    Write-Host "`tGet-Module -Name '$ModuleName' -ListAvailable"

    if (Get-Module -name $ModuleName -ListAvailable) {
        Write-Host "`tUninstall-Module -Name '$ModuleName' -AllVersions"
        Uninstall-Module -Name $ModuleName -AllVersions
    }
    else {
        Write-Host ''
    }

} -description 'Uninstall all versions of the module'

Task Reinstall -depends Uninstall -action {

    [int]$attempts = 0

    do {
        $attempts++
        Write-Host "`tInstall-Module -Name '$ModuleName' -Force"
        Install-Module -name $ModuleName -Force -ErrorAction Continue
        Start-Sleep -Seconds 1
    } while ($null -eq (Get-Module -Name $ModuleName -ListAvailable) -and ($attempts -lt 3))

} -description 'Reinstall the latest version of the module from the defined PowerShell repository'

Task RemoveScriptScopedVariables -depends Reinstall -action {

    # Remove script-scoped variables to avoid their accidental re-use
    Remove-Variable -Name ModuleOutDir -Scope Script -Force -ErrorAction SilentlyContinue

}

Task ReturnToStartingLocation -depends RemoveScriptScopedVariables -action {
    Set-Locationion $StartingLocation
}

Task ? -description 'Lists the available tasks' -action {
    'Available tasks:'
    $psake.context.Peek().Tasks.Keys | Sort-Object
}
