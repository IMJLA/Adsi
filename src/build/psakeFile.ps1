#TODO : Use Fixer 'Get-TextFilesList $pwd | ConvertTo-SpaceIndentation'.

Properties {

    # Whether or not this build is a new Major version
    [boolean]$IncrementMajorVersion = $false

    # Whether or not this build is a new Minor version
    [boolean]$IncrementMinorVersion = $false

    # Folder containing the script .ps1 file
    [string]$SourceCodeDir = [IO.Path]::Combine('.', 'src')

    # This character sequence will be used to separate lines in the console output.
    [string]$NewLine = [System.Environment]::NewLine



    # PlatyPS (Markdown and Updateable help)

    # Directory PlatyPS markdown documentation will be saved to
    [string]$DocsRootDir = [IO.Path]::Combine('.', 'docs')

    # Culture of the current UI thread
    [cultureinfo]$UICulture = Get-UICulture

    # Default Locale used for help generation
    # Get-UICulture doesn't return a name on Linux so default to en-US
    [string]$HelpDefaultLocale = if (-not $UICulture.Name) { 'en-US' } else { $UICulture.Name }

    # Convert project readme into the module 'about file'
    [boolean]$HelpConvertReadMeToAboutHelp = $true

    # Markdown-formatted Help will be created in this folder
    [string]$MarkdownHelpDir = [IO.Path]::Combine($DocsRootDir, 'markdown')

    # .CAB-formatted Updatable Help will be created in this folder
    [string]$UpdatableHelpDir = [IO.Path]::Combine($DocsRootDir, 'updateable')

    # Directory where the markdown help files will be copied to
    [string]$LocaleOutputDir = [IO.Path]::Combine($MarkdownHelpDir, $HelpDefaultLocale)




    $StartingLocation = Get-Location
    Set-Location $PSScriptRoot
    $ProjectRoot = [IO.Path]::Combine('..', '..')
    Set-Location $ProjectRoot

    $ModuleManifestDir = [IO.Path]::Combine($SourceCodeDir, '*.psd1')

    $ModuleManifest = Get-ChildItem -Path $ModuleManifestDir

    $ModuleName = [IO.Path]::GetFileNameWithoutExtension($ModuleManifest)

    $ModuleFilePath = [IO.Path]::Combine($SourceCodeDir, "$ModuleName.psm1")

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
    $BuildExclude = @('build/*', 'gitkeep', "$ModuleName.psm1")

    # Output directory when building a module
    $DistDir = [IO.Path]::Combine('.', 'dist')

    $TestRootDir = [IO.Path]::Combine('.', 'tests')
    $TestOutputFile = [IO.Path]::Combine('out', 'testResults.xml')

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

}

FormatTaskName {

    param(
        [string]$taskName
    )

    Write-Host "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-Host $taskName -ForegroundColor Blue

}

Task Default -depends ReturnToStartingLocation

Task DetermineNewModuleVersion -action {

    Write-Host "`tTest-ModuleManifest -Path '$ModuleManifest'"
    $ManifestTest = Test-ModuleManifest -Path $ModuleManifest

    $CurrentVersion = $ManifestTest.Version
    Write-Host "`t# Old Version: $CurrentVersion"
    if ($IncrementMajorVersion) {
        Write-Host "`t# This is a new major version"
        $script:NewModuleVersion = "$($CurrentVersion.Major + 1).0.0"
    }
    elseif ($IncrementMinorVersion) {
        Write-Host "`t# This is a new minor version"
        $script:NewModuleVersion = "$($CurrentVersion.Major).$($CurrentVersion.Minor + 1).0"
    }
    else {
        Write-Host "`t# This is a new build"
        $script:NewModuleVersion = "$($CurrentVersion.Major).$($CurrentVersion.Minor).$($CurrentVersion.Build + 1)"
    }

    $script:BuildOutputDir = [IO.Path]::Combine($DistDir, $script:NewModuleVersion, $ModuleName)
    $env:BHBuildOutput = $script:BuildOutputDir # still used by Module.tests.ps1

}

Task UpdateModuleVersion -depends DetermineNewModuleVersion -action {

    "`tUpdate-Metadata -Path '$ModuleManifest' -PropertyName ModuleVersion -Value $script:NewModuleVersion -ErrorAction Stop"
    Update-Metadata -Path $ModuleManifest -PropertyName ModuleVersion -Value $script:NewModuleVersion -ErrorAction Stop

} -description 'Increment the module version and update the module manifest accordingly'

Task RotateBuilds -depends UpdateModuleVersion -action {
    $BuildVersionsToRetain = 1

    Write-Host "`tGet-ChildItem -Directory -Path '$DistDir'"

    Get-ChildItem -Directory -Path $DistDir |
    Sort-Object -Property Name |
    Select-Object -SkipLast ($BuildVersionsToRetain - 1) |
    ForEach-Object {
        Write-Host "`t'$_' | Remove-Item -Recurse -Force"
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
    $script:NewModuleVersion = (Import-PowerShellDataFile -Path $ModuleManifest).ModuleVersion
    $NewChanges = "## [$script:NewModuleVersion] - $(Get-Date -Format 'yyyy-MM-dd') - $CommitMessage$NewLine"
    Write-Host "`tChange Log:  $ChangeLog"
    Write-Host "`tNew Changes: $($NewChanges.Trim())"
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

    # Create a string representation of the public functions array
    $publicFunctionsAsString = "@('" + ($publicFunctions -join "','") + "')"

    # Export public functions in the manifest
    Write-Host "`tUpdate-Metadata -Path '$ModuleManifest' -PropertyName FunctionsToExport -Value $publicFunctionsAsString"
    Update-Metadata -Path $ModuleManifest -PropertyName FunctionsToExport -Value $publicFunctions

} -description 'Export all public functions in the module'

Task BuildModule -depends ExportPublicFunctions {

    $buildParams = @{
        Path               = $SourceCodeDir
        ModuleName         = $ModuleName
        DestinationPath    = $script:BuildOutputDir
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

    Write-Host "`tBuild-PSBuildModule -Path '$SourceCodeDir' -ModuleName '$ModuleName' -DestinationPath '$script:BuildOutputDir' -Exclude '$BuildExclude' -Compile '$BuildCompileModule' -CompileDirectories '$BuildCompileDirectories' -CopyDirectories '$BuildCopyDirectories' -Culture '$HelpDefaultLocale' -ReadMePath '$readMePath' -CompileHeader '$($buildParams['CompileHeader'])' -CompileFooter '$($buildParams['CompileFooter'])' -CompileScriptHeader '$($buildParams['CompileScriptHeader'])' -CompileScriptFooter '$($buildParams['CompileScriptFooter'])'"
    Build-PSBuildModule @buildParams

    # Remove the psdependRequirements.psd1 file if it exists
    $RequirementsFile = [IO.Path]::Combine($script:BuildOutputDir, 'psdependRequirements.psd1')
    Write-Host "`tRemove-Item -Path '$RequirementsFile'"
    Remove-Item -Path $RequirementsFile -ErrorAction SilentlyContinue

} -description 'Build a PowerShell script module based on the source directory'

Task BackupOldDocs -depends BuildModule -action {
    Write-Host "`tRename-Item -Path '$DocsRootDir' -NewName '$DocsRootDir.old' -Force"
    Rename-Item -Path $DocsRootDir -NewName "$DocsRootDir.old" -Force
} -description 'Backup old documentation files'

$genMarkdownPreReqs = {
    $result = $true
    if (-not (Get-Module PlatyPS -ListAvailable)) {
        Write-Warning "PlatyPS module is not installed. Skipping [$($psake.context.currentTaskName)] task."
        $result = $false
    }
    $result
}

Task BuildMarkdownHelp -depends BackupOldDocs -precondition $genMarkdownPreReqs -action {

    $ManifestPath = [IO.Path]::Combine($script:BuildOutputDir, "$ModuleName.psd1")
    $moduleInfo = Import-Module $ManifestPath  -Global -Force -PassThru
    $manifestInfo = Test-ModuleManifest -Path $ManifestPath

    if ($moduleInfo.ExportedCommands.Count -eq 0) {
        Write-Warning 'No commands have been exported. Skipping markdown generation.'
        return
    }
    if (-not (Test-Path -LiteralPath $MarkdownHelpDir)) {
        New-Item -Path $MarkdownHelpDir -ItemType Directory > $null
    }
    try {

        if (Get-ChildItem -LiteralPath $MarkdownHelpDir -Filter *.md -Recurse) {
            Get-ChildItem -LiteralPath $MarkdownHelpDir -Directory | ForEach-Object {
                Update-MarkdownHelp -Path $_.FullName -Verbose:$VerbosePreference > $null
            }
        }

        $newMDParams = @{
            AlphabeticParamsOrder = $true
            Locale                = $HelpDefaultLocale
            ErrorAction           = 'SilentlyContinue' # SilentlyContinue will not overwrite an existing MD file.
            HelpVersion           = $moduleInfo.Version
            Module                = $ModuleName
            # TODO: Using GitHub pages as a container for PowerShell Updatable Help https://gist.github.com/TheFreeman193/fde11aee6998ad4c40a314667c2a3005
            # OnlineVersionUrl = $GitHubPagesLinkForThisModule
            OutputFolder          = $LocaleOutputDir
            UseFullTypeName       = $true
            WithModulePage        = $true
        }
        Write-Host "`tNew-MarkdownHelp -AlphabeticParamsOrder `$true -HelpVersion '$($moduleInfo.Version)' -Locale '$HelpDefaultLocale' -Module '$ModuleName' -OutputFolder '$LocaleOutputDir' -UseFullTypeName `$true -WithModulePage `$true"
        $null = New-MarkdownHelp @newMDParams
    }
    finally {
        Remove-Module $ModuleName -Force
    }
} -description 'Generate markdown files from the module help'

Task FixMarkdownHelp -depends BuildMarkdownHelp -action {
    $ManifestPath = [IO.Path]::Combine($script:BuildOutputDir, "$ModuleName.psd1")
    $moduleInfo = Import-Module $ManifestPath  -Global -Force -PassThru
    $manifestInfo = Test-ModuleManifest -Path $ManifestPath

    #Fix the Module Page () things PlatyPS does not do):
    $ModuleHelpFile = [IO.Path]::Combine($LocaleOutputDir, "$ModuleName.md")

    Write-Host "`t[string]`$ModuleHelp = Get-Content -LiteralPath '$ModuleHelpFile' -Raw"
    [string]$ModuleHelp = Get-Content -LiteralPath $ModuleHelpFile -Raw

    #Update the module description
    $RegEx = '(?ms)\#\#\ Description\s*[^\r\n]*\s*'
    $NewString = "## Description$NewLine$($moduleInfo.Description)$NewLine$NewLine"

    Write-Host "`t`$ModuleHelp -replace '$RegEx', `"$($NewString -replace '\r', '`r' -replace '\n', '`n')`""
    $ModuleHelp = $ModuleHelp -replace $RegEx, $NewString

    #Update the description of each function (use its synopsis for brevity)
    ForEach ($ThisFunction in $ManifestInfo.ExportedCommands.Keys) {
        $Synopsis = (Get-Help -name $ThisFunction).Synopsis
        $RegEx = "(?ms)\#\#\#\ \[$ThisFunction]\($ThisFunction\.md\)\s*[^\r\n]*\s*"
        $NewString = "### [$ThisFunction]($ThisFunction.md)$NewLine$Synopsis$NewLine$NewLine"
        $ModuleHelp = $ModuleHelp -replace $RegEx, $NewString
        Write-Host "`t`$ModuleHelp -replace '$RegEx', `"$($NewString -replace '\r', '`r' -replace '\n', '`n')`""
    }

    # Change multi-line default parameter values (especially hashtables) to be a single line to avoid the error below:
    <#
        Error: 4/8/2025 11:35:12 PM:
        At C:\Users\User\OneDrive\Documents\PowerShell\Modules\platyPS\0.14.2\platyPS.psm1:1412 char:22 +     $markdownFiles | ForEach-Object { +                      ~~~~~~~~~~~~~~~~ [<<==>>] Exception: Exception calling "NodeModelToMamlModel" with "1" argument(s): "C:\Export-Permission\Entire Project\Adsi\docs\en-US\New-FakeDirectoryEntry.md:90:(200) '```yamlType: System.Collections.HashtableParam...'
        Invalid yaml: expected simple key-value pairs" --> C:\blah.md:90:(200) '```yamlType: System.Collections.HashtableParam...'
        Invalid yaml: expected simple key-value pairs
    #>
    Write-Host "`t`$ModuleHelp -replace '\r?\n[ ]{12}', ' ; ' -replace '{ ;', '{ ' -replace '[ ]{2,}', ' ' -replace '\r?\n\s\}', ' }'"
    $ModuleHelp = $ModuleHelp -replace '\r?\n[ ]{12}', ' ; '
    $ModuleHelp = $ModuleHelp -replace '{ ;', '{ '
    $ModuleHelp = $ModuleHelp -replace '[ ]{2,}', ' '
    $ModuleHelp = $ModuleHelp -replace '\r?\n\s\}', ' }'

    Write-Host "`t`$ModuleHelp | Set-Content -LiteralPath $ModuleHelpFile -Encoding utf8"
    $ModuleHelp | Set-Content -LiteralPath $ModuleHelpFile -Encoding utf8

    Remove-Module $ModuleName -Force

    ForEach ($ThisFunction in $PublicFunctionFiles.Name) {
        $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($ThisFunction)
        $ThisFunctionHelpFile = [IO.Path]::Combine($LocaleOutputDir, "$fileNameWithoutExtension.md")
        Write-Host "`t[string]`$ThisFunctionHelp = Get-Content -LiteralPath '$ThisFunctionHelpFile' -Raw"
        [string]$ThisFunctionHelp = Get-Content -LiteralPath $ThisFunctionHelpFile -Raw
        Write-Host "`t`$ThisFunctionHelp -replace '\r?\n[ ]{12}', ' ; ' -replace '{ ;', '{ ' -replace '[ ]{2,}', ' ' -replace '\r?\n\s\}', ' }'"
        $ThisFunctionHelp = $ThisFunctionHelp -replace '\r?\n[ ]{12}', ' ; '
        $ThisFunctionHelp = $ThisFunctionHelp -replace '{ ;', '{ '
        $ThisFunctionHelp = $ThisFunctionHelp -replace '[ ]{2,}', ' '
        $ThisFunctionHelp = $ThisFunctionHelp -replace '\r?\n\s\}', ' }'
        Write-Host "`tSet-Content -LiteralPath '$ThisFunctionHelpFile' -Value `$ThisFunctionHelp"
        Set-Content -LiteralPath $ThisFunctionHelpFile -Value $ThisFunctionHelp
    }

    # Fix the readme file to point to the correct location of the markdown files
    Write-Host "`t`$ReadMeContents = `$ModuleHelp"
    $ReadMeContents = $ModuleHelp
    $DocsRootForURL = "docs/$HelpDefaultLocale"
    [regex]::Matches($ModuleHelp, '[^(]*\.md').Value |
    ForEach-Object {
        $EscapedTextToReplace = [regex]::Escape($_)
        $Replacement = "$DocsRootForURL/$_"
        Write-Host "`t`$ReadMeContents -replace '$EscapedTextToReplace', '$Replacement'"
        $ReadMeContents = $ReadMeContents -replace $EscapedTextToReplace, $Replacement
    }
    $readMePath = Get-ChildItem -Path '.' -Include 'readme.md', 'readme.markdown', 'readme.txt' -Depth 1 |
    Select-Object -First 1

    Write-Host "`tSet-Content -LiteralPath '$($ReadMePath.FullName)' -Value `$ReadMeContents"
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
    Write-Host "`tBuild-PSBuildMAMLHelp -Path '$MarkdownHelpDir' -DestinationPath '$script:BuildOutputDir'"
    Build-PSBuildMAMLHelp -Path $MarkdownHelpDir -DestinationPath $script:BuildOutputDir
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

    $helpLocales = (Get-ChildItem -Path $MarkdownHelpDir -Directory).Name

    # Create updatable help output directory
    if (-not (Test-Path -LiteralPath $UpdatableHelpDir)) {
        New-Item $UpdatableHelpDir -ItemType Directory -Verbose:$VerbosePreference > $null
    }
    else {
        Write-Verbose "Removing existing directory: [$UpdatableHelpDir]."
        Get-ChildItem $UpdatableHelpDir | Remove-Item -Recurse -Force -Verbose:$VerbosePreference
    }

    # Generate updatable help files.  Note: this will currently update the version number in the module's MD
    # file in the metadata.
    foreach ($locale in $helpLocales) {
        $cabParams = @{
            CabFilesFolder  = [IO.Path]::Combine($script:BuildOutputDir, $locale)
            LandingPagePath = [IO.Path]::Combine($LocaleOutputDir, "$ModuleName.md")
            OutputFolder    = $UpdatableHelpDir
        }
        Write-Host "`tNew-ExternalHelpCab -CabFilesFolder '$($cabParams.CabFilesFolder)' -LandingPagePath '$($cabParams.LandingPagePath)' -OutputFolder '$($cabParams.OutputFolder)'"
        New-ExternalHelpCab @cabParams > $null
    }

} -description 'Create updatable help .cab file based on PlatyPS markdown help'

Task DeleteOldDocs -depends BuildUpdatableHelp -action {
    Write-Host "`tRemove-Item -Path '$DocsRootDir.old' -Recurse -Force -ErrorAction SilentlyContinue"
    Remove-Item -Path "$DocsRootDir.old" -Recurse -Force -ErrorAction SilentlyContinue
} -description 'Delete old documentation file backups'

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

Task Lint -depends DeleteOldDocs -precondition $analyzePreReqs -action {
    $analyzeParams = @{
        Path              = $script:BuildOutputDir
        SeverityThreshold = $TestLintFailBuildOnSeverityLevel
        SettingsPath      = $TestLintSettingsPath
    }
    Write-Host "`tTest-PSBuildScriptAnalysis -Path '$($analyzeParams.Path)' -SeverityThreshold '$($analyzeParams.SeverityThreshold)' -SettingsPath '$($analyzeParams.SettingsPath)'"
    # Run PSScriptAnalyzer
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
            OutputPath   = $TestOutputFile
            OutputFormat = $TestOutputFormat
        }
    }


    Write-Host "`t`$PesterConfigParams = @{
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
`t            OutputPath   = '$TestOutputFile'
`t            OutputFormat = '$TestOutputFormat'
`t        }
`t    }"
    Write-Host "`tNew-PesterConfiguration -Hashtable `$PesterConfigParams"
    $PesterConfiguration = New-PesterConfiguration -Hashtable $PesterConfigParams

    Write-Host "`tInvoke-Pester -Configuration `$PesterConfiguration"
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
        Write-Host "`tPublish-Module -Path '$script:BuildOutputDir' -Repository 'PSGallery'"
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
        $VersionInGallery.Version -lt $script:NewModuleVersion -and
        $timer -lt $timeout
    )

    if ($timer -eq $timeout) {
        Write-Warning "Cannot retrieve version '$script:NewModuleVersion' of module '$ModuleName' from repo '$PublishPSRepository'"
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
    Set-Location $StartingLocation
}

Task ? -description 'Lists the available tasks' -action {
    'Available tasks:'
    $psake.context.Peek().Tasks.Keys | Sort-Object
}
