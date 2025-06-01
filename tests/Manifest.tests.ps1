BeforeAll {

    [string]$SourceCodeDir = [IO.Path]::Combine('.', 'src')
    $ModuleName = $PSScriptRoot | Split-Path -Parent | Split-Path -Leaf
    $sourceManifestPath = [IO.Path]::Combine($SourceCodeDir, "$ModuleName.psd1")
    $sourceManifestData = Test-ModuleManifest -Path $sourceManifestPath -Verbose:$false -ErrorAction Stop -WarningAction SilentlyContinue
    $manifest = Import-PowerShellDataFile -Path $sourceManifestPath
    #[string]$outputDir = [IO.Path]::Combine('.', 'dist')
    #$outputModVerDir = Join-Path -Path $outputDir -ChildPath $manifest.ModuleVersion
    #$outputModDir = Join-Path -Path $outputModVerDir -ChildPath $ModuleName
    #$outputManifestPath = Join-Path -Path $outputModDir -ChildPath "$($ModuleName).psd1"
    #$outputManifestData = Test-ModuleManifest -Path $outputManifestPath -Verbose:$false -ErrorAction Stop -WarningAction SilentlyContinue
    $changelogPath = [IO.Path]::Combine('.', 'CHANGELOG.md')
    $changelogVersion = Get-Content $changelogPath | ForEach-Object {
        if ($_ -match '^##\s\[(?<Version>(\d+\.){1,3}\d+)\]') {
            $changelogVersion = $matches.Version
            break
        }
    }

    $script:manifest = $null
}

Describe "module manifest '$($ModuleName).psd1'" {

    Context '- Validation' {

        It 'is a valid manifest' {
            $sourceManifestData | Should -Not -BeNullOrEmpty
        }

        It 'has a valid name in the manifest' {
            $sourceManifestData.Name | Should -Be $moduleName
        }

        It 'has a valid root module' {
            $sourceManifestData.RootModule | Should -Be $moduleName
        }

        It 'has a valid version' {
            $sourceManifestData.Version -as [Version] | Should -Not -BeNullOrEmpty
        }

        It 'has a valid description' {
            $sourceManifestData.Description | Should -Not -BeNullOrEmpty
        }

        It 'has a valid author' {
            $sourceManifestData.Author | Should -Not -BeNullOrEmpty
        }

        It 'has a valid guid' {
            { [guid]::Parse($sourceManifestData.Guid) } | Should -Not -Throw
        }

        It 'has a valid copyright' {
            $sourceManifestData.CopyRight | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Git tagging' {
    BeforeAll {
        $gitTagVersion = $null

        if ($git = Get-Command git -CommandType Application -ErrorAction SilentlyContinue) {
            $thisCommit = & $git log --decorate --oneline HEAD~1..HEAD
            if ($thisCommit -match 'tag:\s*v*(\d+(?:\.\d+)*)') { $gitTagVersion = $matches[1] }
        }
    }

    Context "- Git tag version '$gitTagVersion'" {

        It 'is a valid version' {
            $gitTagVersion | Should -Not -BeNullOrEmpty
            $gitTagVersion -as [Version] | Should -Not -BeNullOrEmpty
        }

        It 'matches the module manifest version in the source code' {
            $sourceManifestData.Version -as [Version] | Should -Be ( $gitTagVersion -as [Version])
        }
    }
}
