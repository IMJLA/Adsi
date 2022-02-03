properties {
    # Set this to $true to create a module with a monolithic PSM1
    $PSBPreference.Build.CompileModule = $true
    $PSBPreference.Build.CompileDirectories = @('enums', 'filters', 'classes', 'functions/private', 'functions/public')
    $PSBPreference.Build.CopyDirectories = @('../bin', '../config', '../data', '../lib')
    $PSBPreference.Build.Exclude = @('gitkeep', "$env:BHProjectName.psm1")
    $PSBPreference.Build.OutDir = "$env:BHProjectPath/dist"
    $PSBPreference.Docs.RootDir = "$env:BHProjectPath/docs"
    $PSBPreference.Help.DefaultLocale = 'en-US'
    $PSBPreference.Test.OutputFile = 'out/testResults.xml'
}

task Default -depends Test

task Test -FromModule PowerShellBuild -minimumVersion '0.6.1'

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

task UpdateChangeLog -depends UpdateModuleVersion -Action {
    <#
TODO
    This task runs before the Test task so that tests of the change log will pass
    But I also need one that runs *after* the build to compare it against the previous build
    The post-build UpdateChangeLog will automatically add to the change log any:
        New/removed exported commands
        New/removed files
#>
    $ChangeLog = "$env:BHProjectPath\CHANGELOG.md"
    $NewChanges = "## [$($PSBPreference.General.ModuleVersion)] - $(Get-Date -format 'yyyy-MM-dd') - $GitCommitMessage"
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

task UpdateModuleVersion -depends RotateBuilds -Action {
    $CurrentVersion = (Test-ModuleManifest $env:BHPSModuleManifest).Version
    Write-Verbose "Old Version: $CurrentVersion"
    if ($IncrementMajorVersion) {
        Write-Verbose "This is a new major version"
        $NextVersion = "$($CurrentVersion.Major + 1).0.0"
    } elseif ($IncrementMinorVersion) {
        Write-Verbose "This is a new minor version"
        $NextVersion = "$($CurrentVersion.Major).$($CurrentVersion.Minor + 1).0"
    } else {
        Write-Verbose "This is a new build"
        $NextVersion = "$($CurrentVersion.Major).$($CurrentVersion.Minor).$($CurrentVersion.Build + 1)"
    }
    Write-Verbose "New Version: $NextVersion"

    Update-Metadata -Path $env:BHPSModuleManifest -PropertyName ModuleVersion -Value $NextVersion -ErrorAction Stop
    $PSBPreference.General.ModuleVersion = $NextVersion
} -description 'Increment the module version and update the module manifest accordingly'

task RotateBuilds {
    $BuildVersionsToRetain = 10
    $BuildFolder = 'dist'
    $Builds = Get-ChildItem -Directory -Path "$env:BHProjectPath\$BuildFolder\$env:BHProjectName"

    $Builds |
    Select-Object -SkipLast ($BuildVersionsToRetain - 1) |
    Remove-Item -Recurse -Force
}
