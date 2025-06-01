BeforeAll {

    [string]$SourceCodeDir = [IO.Path]::Combine('.', 'src')
    $ModuleName = $PSScriptRoot | Split-Path -Parent | Split-Path -Leaf
    $sourceManifestPath = [IO.Path]::Combine($SourceCodeDir, "$ModuleName.psd1")
    $sourceManifestData = Test-ModuleManifest -Path $sourceManifestPath -Verbose:$false -ErrorAction Stop -WarningAction SilentlyContinue
    $manifest = Import-PowerShellDataFile -Path $sourceManifestPath

}

Describe "module manifest '$sourceManifestPath'" {

    Context '- Basic Requirements' {

        It 'exists in the source code directory' {
            $sourceManifestPath | Should -Exist
        }

        It 'is a valid PowerShell module manifest file and the files it lists are actually in the specified paths.' {
            $sourceManifestData | Should -BeOfType 'System.Management.Automation.PSModuleInfo'
        }

        It 'has a valid ModuleName' {
            $sourceManifestData.Name | Should -Be $ModuleName
        }

    }

    Context '- Minimum Settings' {

        # These are the minimum settings created by New-ModuleManifest

        It 'has a valid ModuleVersion setting' {
            # Test-ModuleManifest returns the ModuleVersion setting as the Version property
            $sourceManifestData.Version -as [Version] | Should -Not -BeNullOrEmpty
        }

        It 'has a valid Author setting' {
            $sourceManifestData.Author | Should -Not -BeNullOrEmpty
        }

        It 'has a valid GUID setting' {
            { [guid]::Parse($sourceManifestData.Guid) } | Should -Not -Throw
        }

        It 'has a valid Copyright setting' {
            $sourceManifestData.CopyRight | Should -Not -BeNullOrEmpty
        }

        It 'has a valid CompanyName setting' {
            $sourceManifestData.CompanyName | Should -Not -BeNullOrEmpty
        }

    }

    Context '- Module Structure' {

        It 'has a valid RootModule setting which points to the main module file' {
            $sourceManifestData.RootModule | Should -Be $moduleName
        }

    }

    Context '- Additional Metadata' {

        It 'has a valid Description setting' {
            $sourceManifestData.Description | Should -Not -BeNullOrEmpty
        }

        It 'has a valid IconUri setting' -Skip {
            $sourceManifestData.IconUri | Should -Not -BeNullOrEmpty
            $sourceManifestData.IconUri | Should -Match '^https?://'
        }

    }

    Context '- Legal' {

        It 'has matching copyright and license information' {
            #Todo: read the license file source code, find the line with the copyright and compare it to the manifest
            $sourceLicensePath = [IO.Path]::Combine($SourceCodeDir, 'LICENSE')
            $sourceLicenseData = Get-Content -Path $sourceLicensePath -ErrorAction Stop -WarningAction SilentlyContinue
            $sourceLicenseData | Should -Not -BeNullOrEmpty
            $sourceLicenseData | Should -Contain $sourceManifestData.CopyRight
        }

        It 'has a valid LicenseUri setting' {
            $sourceManifestData.LicenseUri | Should -Not -BeNullOrEmpty
            $sourceManifestData.LicenseUri | Should -Match '^https?://'
        }

        It 'has a valid ProjectUri setting' {
            $sourceManifestData.ProjectUri | Should -Not -BeNullOrEmpty
            $sourceManifestData.ProjectUri | Should -Match '^https?://'
        }

    }

    Context '- Dependencies' {

        It 'has a valid RequiredModules setting' {
            $sourceManifestData.RequiredModules | Should -Not -BeNullOrEmpty
        }

        It 'has a valid RequiredAssemblies setting' {
            $sourceManifestData.RequiredAssemblies | Should -Not -BeNullOrEmpty
        }

    }

    Context '- PowerShell version' {

        It 'has a valid PowerShellVersion setting to require a minimum PowerShell version' {
            $sourceManifestData.PowerShellVersion | Should -Not -BeNullOrEmpty
            $sourceManifestData.PowerShellVersion | Should -Match '^\d+\.\d+(\.\d+)?$'
        }

        It 'requires a minimum PowerShell version of 5.1 or higher to ensure only supported versions are used' {
            $sourceManifestData.PowerShellVersion -as [Version] | Should -BeGreaterThanOrEqualTo ([Version]'5.1')
        }

        It 'is compatible with the current PowerShell version' {
            $sourceManifestData.PowerShellVersion -as [Version] | Should -BeLessOrEqual ($PSVersionTable.PSVersion -as [Version])
        }

    }

    Context '- Platform' {

        It 'has a valid CompatiblePSEditions setting' {
            $sourceManifestData.CompatiblePSEditions | Should -Not -BeNullOrEmpty
        }

        It 'is compatible with the current PowerShell edition' {
            $sourceManifestData.CompatiblePSEditions | Should -Contain $PSVersionTable.PSEdition
        }

        It 'has a valid ProcessorArchitecture setting' {
            $sourceManifestData.ProcessorArchitecture | Should -Not -BeNullOrEmpty
        }

        It 'is compatible with the current processor architecture' {
            $sourceManifestData.ProcessorArchitecture | Should -Contain $env:PROCESSOR_ARCHITECTURE
        }

    }

    Context '- Tags' {

        It 'has a valid tags section' {
            $sourceManifestData.Tags | Should -Not -BeNullOrEmpty
            $sourceManifestData.Tags | Should -BeOfType 'System.String[]'
        }

        It 'has a valid tag for the module name' {
            $sourceManifestData.Tags | Should -Contain $ModuleName
        }
    }
    Context '- Functions' {

        It 'has a valid FunctionsToExport section' {
            $sourceManifestData.FunctionsToExport | Should -Not -BeNullOrEmpty
            $sourceManifestData.FunctionsToExport | Should -BeOfType 'System.String[]'
        }

        #It 'exports all public functions' {
        #    $sourceManifestData.FunctionsToExport | Should -Contain 'Get-ADSIObject'
        #}

        It 'does not export any private functions' {
            $sourceManifestData.PrivateData.PrivateFunctions | Should -BeNullOrEmpty
        }

    }

    Context '- Variables' {

        It 'has a valid VariablesToExport setting which exports all public variables, or at least an empty array' {
            $sourceManifestData.VariablesToExport | Should -Not -BeNullOrEmpty
            $sourceManifestData.VariablesToExport | Should -BeOfType 'System.String[]'
        }

        It 'does not export any private variables' {
            $sourceManifestData.PrivateData.PrivateVariables | Should -BeNullOrEmpty
        }

    }

    Context '- Formats, Types, and Scripts' {

        It 'has a valid FormatsToProcess setting' {
            $sourceManifestData.FormatsToProcess | Should -Not -BeNullOrEmpty
            $sourceManifestData.FormatsToProcess | Should -BeOfType 'System.String[]'
            $sourceManifestData.FormatsToProcess | Should -Contain "$ModuleName.format.ps1xml"
        }

        It 'has a valid TypesToProcess setting' {
            $sourceManifestData.TypesToProcess | Should -Not -BeNullOrEmpty
            $sourceManifestData.TypesToProcess | Should -BeOfType 'System.String[]'
            $sourceManifestData.TypesToProcess | Should -Contain "$ModuleName.types.ps1xml"
        }

        It 'has a valid ScriptsToProcess setting' -Skip {
            $sourceManifestData.Scripts | Should -Not -BeNullOrEmpty
            $sourceManifestData.Scripts | Should -BeOfType 'System.String[]'
        }

    }

    Context '- Help' {

        It 'has a valid help section' -Skip {
            $sourceManifestData.HelpInfoUri | Should -Not -BeNullOrEmpty
            $sourceManifestData.HelpInfoUri | Should -Match '^https?://'
        }

    }

}

Describe 'Git tagging' {

    BeforeAll {

        $gitTagVersion = $null

        if ($git = Get-Command git -CommandType Application -ErrorAction SilentlyContinue) {

            $thisCommit = & $git log --decorate --oneline HEAD~1..HEAD

            if ($thisCommit -match 'tag:\s*v*(\d+(?:\.\d+)*)') {
                $gitTagVersion = $matches[1]
            }
        }

    }

    Context "- Git tag version '$gitTagVersion'" {

        It 'is a valid version' {
            $gitTagVersion | Should -Not -BeNullOrEmpty
            $gitTagVersion -as [Version] | Should -Not -BeNullOrEmpty
        }

        It 'be greater than the module manifest version in the source code' {
            $sourceManifestData.Version -as [Version] | Should -BeGreaterThan ( $gitTagVersion -as [Version])
        }

    }

}
