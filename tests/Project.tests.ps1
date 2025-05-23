BeforeAll {

    [string]$SourceCodeDir = [IO.Path]::Combine('.', 'src')
    $ModuleName = $PSScriptRoot | Split-Path -Parent | Split-Path -Leaf
    $ModuleManifestPath = [IO.Path]::Combine($SourceCodeDir, "$ModuleName.psd1")
    $manifest = Import-PowerShellDataFile -Path $ModuleManifestPath
    [string]$outputDir = [IO.Path]::Combine('.', 'dist')
    $outputModVerDir = Join-Path -Path $outputDir -ChildPath $manifest.ModuleVersion
    $outputModDir = Join-Path -Path $outputModVerDir -ChildPath $ModuleName
    $outputManifestPath = Join-Path -Path $outputModDir -ChildPath "$($ModuleName).psd1"
    $manifestData = Test-ModuleManifest -Path $outputManifestPath -Verbose:$false -ErrorAction Stop -WarningAction SilentlyContinue

    $changelogPath = Join-Path -Path $env:BHProjectPath -Child 'CHANGELOG.md'
    Get-Content $changelogPath | ForEach-Object {
        if ($_ -match '^##\s\[(?<Version>(\d+\.){1,3}\d+)\]') {
            $changelogVersion = $matches.Version
            break
        }
    }

}

Describe 'change log' {

    Context '- Version' {

        It 'has a valid version' {
            $changelogVersion | Should -Not -BeNullOrEmpty
            $changelogVersion -as [Version] | Should -Not -BeNullOrEmpty
        }

        It 'has the same version as the manifest' {
            $changelogVersion -as [Version] | Should -Be ( $manifestData.Version -as [Version] )
        }

    }

}
