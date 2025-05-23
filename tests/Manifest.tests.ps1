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
            $manifestData | Should -Not -BeNullOrEmpty
        }

        It 'has a valid name in the manifest' {
            $manifestData.Name | Should -Be $moduleName
        }

        It 'has a valid root module' {
            $manifestData.RootModule | Should -Be $moduleName
        }

        It 'has a valid version' {
            $manifestData.Version -as [Version] | Should -Not -BeNullOrEmpty
        }

        It 'has a valid description' {
            $manifestData.Description | Should -Not -BeNullOrEmpty
        }

        It 'has a valid author' {
            $manifestData.Author | Should -Not -BeNullOrEmpty
        }

        It 'has a valid guid' {
            { [guid]::Parse($manifestData.Guid) } | Should -Not -Throw
        }

        It 'has a valid copyright' {
            $manifestData.CopyRight | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Git tagging' -Skip {
    BeforeAll {
        $gitTagVersion = $null

        if ($git = Get-Command git -CommandType Application -ErrorAction SilentlyContinue) {
            $thisCommit = & $git log --decorate --oneline HEAD~1..HEAD
            if ($thisCommit -match 'tag:\s*(\d+(?:\.\d+)*)') { $gitTagVersion = $matches[1] }
        }
    }

    Context "- Git tag version '$gitTagVersion'" {

        It 'is a valid version' {
            $gitTagVersion | Should -Not -BeNullOrEmpty
            $gitTagVersion -as [Version] | Should -Not -BeNullOrEmpty
        }

        It 'matches the module manifest version' {
            $manifestData.Version -as [Version] | Should -Be ( $gitTagVersion -as [Version])
        }
    }
}
