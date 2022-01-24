properties {
    # Set this to $true to create a module with a monolithic PSM1
    $PSBPreference.Build.CompileModule = $true
    $PSBPreference.Build.OutDir = "$env:BHProjectPath/dist"
    $PSBPreference.Help.DefaultLocale = 'en-US'
    $PSBPreference.Test.OutputFile = 'out/testResults.xml'
}

task Default -depends Test

task Test -FromModule PowerShellBuild -minimumVersion '0.6.1'
