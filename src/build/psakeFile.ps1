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
    [string]$LintSettingsFile = [IO.Path]::Combine($TestRootDir, 'ScriptAnalyzerSettings.psd1')



    # PowerShellBuild (Compilation, Build Processes, and MAML help)

    # The PowerShell module will be created in this folder
    [string]$BuildOutDir = [IO.Path]::Combine('.', 'dist')

    # Controls whether to "compile" module into single PSM1 or not
    [boolean]$BuildCompileModule = $true

    # List of directories that if BuildCompileModule is $true, will be concatenated into the PSM1
    [string[]]$BuildCompileDirectories = @('classes', 'enums', 'filters', 'functions/private', 'functions/public')

    # List of directories that will always be copied "as is" to output directory
    [string[]]$BuildCopyDirectories = @('../bin', '../config', '../data', '../lib')

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

}

FormatTaskName {

    param(
        [string]$taskName
    )

    Write-Host "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-Host $taskName -ForegroundColor Blue

}

Task Default -depends SetLocation, DeleteOldBuilds, DeleteOldDocs, ReturnToStartingLocation

$FindLintPrerequisites = {

    Write-Host "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-Host "FindLintPrerequisites$NewLine" -ForegroundColor Blue

    if ($LintEnabled) {
        Write-Host "`tGet-Module -Name PSScriptAnalyzer -ListAvailable"
        [boolean](Get-Module -Name PSScriptAnalyzer -ListAvailable)
    }
    else {
        Write-Host "`tLinting is disabled. Skipping PSScriptAnalyzer check."
    }

}

$FindBuildPrerequisite = {

    Write-Host "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-Host "FindBuildPrerequisite$NewLine" -ForegroundColor Blue

    if ($BuildCompileModule) {
        Write-Host "`tGet-Module -Name PowerShellBuild -ListAvailable"
        [boolean](Get-Module -Name PowerShellBuild -ListAvailable)
    }
    else {
        Write-Host "`tBuilding is disabled. Skipping PowerShellBuild check."
    }

}

$FindUnitTestPrerequisite = {

    Write-Host "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-Host "FindUnitTestPrerequisite$NewLine" -ForegroundColor Blue

    if ($TestEnabled) {
        Write-Host "`tGet-Module -Name Pester -ListAvailable"
        [boolean](Get-Module -Name Pester -ListAvailable)
    }
    else {
        Write-Host "`tUnit testing is disabled. Skipping Pester check."
    }

}

$FindDocsPrerequisite = {

    Write-Host "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-Host "FindDocsPrerequisite$NewLine" -ForegroundColor Blue

    Write-Host "`tGet-Module -Name PlatyPS -ListAvailable"
    [boolean](Get-Module -Name PlatyPS -ListAvailable)

}

$FindDocsUpdateablePrerequisite = {

    Write-Host "$NewLine`Task: " -ForegroundColor Cyan -NoNewline
    Write-Host "FindDocsUpdateablePrerequisite$NewLine" -ForegroundColor Blue

    if ($FindDocsPrerequisite) {

        Write-Host "`tGet-CimInstance -ClassName CIM_OperatingSystem"
        $OS = (Get-CimInstance -ClassName CIM_OperatingSystem).Caption

        if ($OS -match 'Windows') {

            Write-Host "`tGet-Command -Name MakeCab.exe"
            [boolean](Get-Command -Name MakeCab.exe)

        }
        else {
            Write-Host "`tMakeCab.exe is not available on this operating system. Skipping Updateable Help generation."
        }

    }
    else {
        Write-Host "`tPrerequisite module PlatyPS not found so Markdown docs will not be generated or converted to MAML for input to MakeCab.exe. Skipping Updateable Help generation."
    }

}

Task SetLocation -action {
    Write-Host "`tSet-Location -Path '$ModuleName'"
    Set-Location -Path $PSScriptRoot
    [string]$ProjectRoot = [IO.Path]::Combine('..', '..')
    Set-Location -Path $ProjectRoot
} -description 'Set the location to the project root'

Task FindPublicFunctionFiles -action {
    Write-Host "`tGet-ChildItem -Path '$publicFunctionPath' -Recurse"
    $script:PublicFunctionFiles = Get-ChildItem -Path $publicFunctionPath -Recurse
} -description 'Find all public function files'

Task TestModuleManifest -action {

    Write-Host "`tTest-ModuleManifest -Path '$ModuleManifestPath'"
    $script:ManifestTest = Test-ModuleManifest -Path $ModuleManifestPath

} -description 'Validate the module manifest'

Task DetermineNewModuleVersion -depends TestModuleManifest -action {

    $CurrentVersion = $script:ManifestTest.Version
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

    $script:BuildOutputDir = [IO.Path]::Combine($BuildOutDir, $script:NewModuleVersion, $ModuleName)
    $env:BHBuildOutput = $script:BuildOutputDir # still used by Module.tests.ps1

} -description 'Determine the new module version based on the build parameters'

Task UpdateModuleVersion -depends DetermineNewModuleVersion -action {

    "`tUpdate-Metadata -Path '$ModuleManifestPath' -PropertyName ModuleVersion -Value $script:NewModuleVersion -ErrorAction Stop"
    Update-Metadata -Path $ModuleManifestPath -PropertyName ModuleVersion -Value $script:NewModuleVersion -ErrorAction Stop

} -description 'Update the module manifest with the new version number'

Task BackupOldBuilds -depends UpdateModuleVersion -action {
    Write-Host "`tRename-Item -Path '$BuildOutDir' -NewName '$BuildOutDir.old' -Force"
    Rename-Item -Path $BuildOutDir -NewName "$BuildOutDir.old" -Force
} -description 'Backup old builds'

Task UpdateChangeLog -depends BackupOldBuilds -action {
    <#
    TODO
        This task runs before the Test task so that tests of the change log will pass
        But I also need one that runs *after* the build to compare it against the previous build
        The post-build UpdateChangeLog will automatically add to the change log any:
            New/removed exported commands
            New/removed files
    #>
    $ChangeLog = [IO.Path]::Combine('.', 'CHANGELOG.md')
    $script:NewModuleVersion = (Import-PowerShellDataFile -Path $ModuleManifestPath).ModuleVersion
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
    $publicFunctions = $script:PublicFunctionFiles.BaseName
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
    Write-Host "`tUpdate-Metadata -Path '$ModuleManifestPath' -PropertyName FunctionsToExport -Value $publicFunctionsAsString"
    Update-Metadata -Path $ModuleManifestPath -PropertyName FunctionsToExport -Value $publicFunctions

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
        if ($Val) {
            $buildParams.$_ = $Val
        }
    }

    $ExcludeJoined = $buildParams['Exclude'] -join "','"
    $CompileDirectoriesJoined = $buildParams['CompileDirectories'] -join "','"
    $CopyDirectoriesJoined = $buildParams['CopyDirectories'] -join "','"
    Write-Host "`tBuild-PSBuildModule -Path '$SourceCodeDir' -ModuleName '$ModuleName' -DestinationPath '$script:BuildOutputDir' -Exclude @('$ExcludeJoined') -Compile '$BuildCompileModule' -CompileDirectories @('$CompileDirectoriesJoined') -CopyDirectories @('$CopyDirectoriesJoined') -Culture '$DocsDefaultLocale' -ReadMePath '$readMePath' -CompileHeader '$($buildParams['CompileHeader'])' -CompileFooter '$($buildParams['CompileFooter'])' -CompileScriptHeader '$($buildParams['CompileScriptHeader'])' -CompileScriptFooter '$($buildParams['CompileScriptFooter'])'"
    Build-PSBuildModule @buildParams

    # Remove the psdependRequirements.psd1 file if it exists
    $RequirementsFile = [IO.Path]::Combine($script:BuildOutputDir, 'psdependRequirements.psd1')
    Write-Host "`tRemove-Item -Path '$RequirementsFile'"
    Remove-Item -Path $RequirementsFile -ErrorAction SilentlyContinue

} -description 'Build a PowerShell script module based on the source directory'

Task DeleteOldBuilds -depends BuildModule -action {
    Write-Host "`tRemove-Item -Path '$BuildOutDir.old' -Recurse -Force -ErrorAction SilentlyContinue"
    Remove-Item -Path "$BuildOutDir.old" -Recurse -Force -ErrorAction SilentlyContinue
}



Task BackupOldDocs -action {
    Write-Host "`tRename-Item -Path '$DocsRootDir' -NewName '$DocsRootDir.old' -Force"
    Rename-Item -Path $DocsRootDir -NewName "$DocsRootDir.old" -Force
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
        Write-Host "`tNew-MarkdownHelp -AlphabeticParamsOrder `$true -HelpVersion '$($NewManifestTest.Version)' -Locale '$DocsDefaultLocale' -Module '$ModuleName' -OutputFolder '$DocsMarkdownDefaultLocaleDir' -UseFullTypeName `$true -WithModulePage `$true"
        $null = New-MarkdownHelp @newMDParams
    }
    finally {
        Remove-Module $ModuleName -Force
    }
} -description 'Generate markdown files from the module help'

Task FixMarkdownHelp -depends BuildMarkdownHelp -action {
    $ManifestPath = [IO.Path]::Combine($script:BuildOutputDir, "$ModuleName.psd1")
    $NewManifestTest = Test-ModuleManifest -Path $ManifestPath

    #Fix the Module Page () things PlatyPS does not do):
    $ModuleHelpFile = [IO.Path]::Combine($DocsMarkdownDefaultLocaleDir, "$ModuleName.md")

    Write-Host "`t[string]`$ModuleHelp = Get-Content -LiteralPath '$ModuleHelpFile' -Raw"
    [string]$ModuleHelp = Get-Content -LiteralPath $ModuleHelpFile -Raw

    #Update the module description
    $RegEx = '(?ms)\#\#\ Description\s*[^\r\n]*\s*'
    $NewString = "## Description$NewLine$($NewManifestTest.Description)$NewLine$NewLine"

    Write-Host "`t`$ModuleHelp -replace '$RegEx', `"$($NewString -replace '\r', '`r' -replace '\n', '`n')`""
    $ModuleHelp = $ModuleHelp -replace $RegEx, $NewString

    #Update the description of each function (use its synopsis for brevity)
    ForEach ($ThisFunction in $NewManifestTest.ExportedCommands.Keys) {
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

    ForEach ($ThisFunction in $script:PublicFunctionFiles.Name) {
        $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($ThisFunction)
        $ThisFunctionHelpFile = [IO.Path]::Combine($DocsMarkdownDefaultLocaleDir, "$fileNameWithoutExtension.md")
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
    $DocsRootForURL = "docs/$DocsDefaultLocale"
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

Task BuildMAMLHelp -depends FixMarkdownHelp -action {
    Write-Host "`tBuild-PSBuildMAMLHelp -Path '$DocsMarkdownDir' -DestinationPath '$script:BuildOutputDir'"
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
        Write-Host "`tNew-ExternalHelpCab -CabFilesFolder '$($cabParams.CabFilesFolder)' -LandingPagePath '$($cabParams.LandingPagePath)' -OutputFolder '$($cabParams.OutputFolder)'"
        New-ExternalHelpCab @cabParams > $null
    }

} -description 'Create updatable help .cab file based on PlatyPS markdown help'

Task DeleteOldDocs -depends BuildUpdatableHelp -action {
    Write-Host "`tRemove-Item -Path '$DocsRootDir.old' -Recurse -Force -ErrorAction SilentlyContinue"
    Remove-Item -Path "$DocsRootDir.old" -Recurse -Force -ErrorAction SilentlyContinue
} -description 'Delete old documentation file backups'



Task Lint -precondition $FindLintPrerequisites -action {

    $analyzeParams = @{
        Path              = $script:BuildOutputDir
        SeverityThreshold = $LintSeverityThreshold
        SettingsPath      = $LintSettingsFile
    }
    Write-Host "`tTest-PSBuildScriptAnalysis -Path '$($analyzeParams.Path)' -SeverityThreshold '$($analyzeParams.SeverityThreshold)' -SettingsPath '$($analyzeParams.SettingsPath)'"

    # Run PSScriptAnalyzer
    Test-PSBuildScriptAnalysis @analyzeParams

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
`t            OutputPath   = '$TestResultsFile'
`t            OutputFormat = '$TestOutputFormat'
`t        }
`t    }"
    Write-Host "`t`$PesterConfiguration = New-PesterConfiguration -Hashtable `$PesterConfigParams"
    $PesterConfiguration = New-PesterConfiguration -Hashtable $PesterConfigParams

    Write-Host "`tInvoke-Pester -Configuration `$PesterConfiguration"
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

    if (Get-Module -Name $ModuleName -ListAvailable) {
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
