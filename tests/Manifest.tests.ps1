BeforeAll {

    [string]$SourceCodeDir = [IO.Path]::Combine('.', 'src')
    $script:ModuleName = $PSScriptRoot | Split-Path -Parent | Split-Path -Leaf
    $script:ManifestName = "$ModuleName.psd1"
    $script:sourceManifestPath = [IO.Path]::Combine($SourceCodeDir, $ManifestName)
    $script:sourceManifestData = Test-ModuleManifest -Path $sourceManifestPath -Verbose:$false -ErrorAction Stop -WarningAction SilentlyContinue
    $script:sourceManifestImportedDataFile = Import-PowerShellDataFile -Path $sourceManifestPath

}

Describe "module manifest '$ManifestName'" {

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
            $sourceManifestData.RootModule | Should -Be $ModuleName
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
            $sourceLicensePath = [IO.Path]::Combine('.', 'LICENSE')
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

        It 'has a valid RequiredModules setting' -Skip {
            $sourceManifestData.RequiredModules | Should -Not -BeNullOrEmpty
        }

        It 'has a valid RequiredAssemblies setting' -Skip {
            $sourceManifestData.RequiredAssemblies | Should -Not -BeNullOrEmpty
        }

    }

    Context '- PowerShell version' {

        It 'has a valid PowerShellVersion setting to require a minimum PowerShell version' {
            $sourceManifestData.PowerShellVersion | Should -Not -BeNullOrEmpty
            $sourceManifestData.PowerShellVersion | Should -Match '^\d+\.\d+(\.\d+)?$'
        }

        It 'requires a minimum PowerShell version of 5.1 or higher to ensure only supported versions are used' {
            $sourceManifestData.PowerShellVersion -as [Version] | Should -BeGreaterOrEqual ([Version]'5.1')
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

            if (
                $sourceManifestData.ProcessorArchitecture -eq 'None' -or
                $null -eq $sourceManifestData.ProcessorArchitecture
            ) {
                $true | Should -Be $true
            } else {
                $sourceManifestData.ProcessorArchitecture | Should -Be $env:PROCESSOR_ARCHITECTURE
            }
        }

    }

    Context '- Tags' {

        It 'has a valid tags section' {
            $sourceManifestData.Tags | Should -Not -BeNullOrEmpty
            Should -ActualValue $sourceManifestData.Tags -BeOfType 'System.Collections.Generic.List[string]'
        }

        It 'has a valid tag for the module name' {
            [string[]]$Tags = $sourceManifestData.Tags
            Should -ActualValue $Tags -Contain $ModuleName
        }
    }
    Context '- Functions' {

        It 'has a valid FunctionsToExport section' {
            $sourceManifestData.ExportedFunctions | Should -Not -BeNullOrEmpty
            $sourceManifestData.ExportedFunctions | Should -BeOfType 'System.Collections.Generic.Dictionary[string,System.Management.Automation.FunctionInfo]'
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
            $sourceManifestData.ExportedVariables | Should -Not -BeNullOrEmpty
            $sourceManifestData.ExportedVariables | Should -BeOfType 'System.Collections.Generic.Dictionary[string,psvariable]'
        }

        It 'does not export any private variables' {
            $sourceManifestData.PrivateData.PrivateVariables | Should -BeNullOrEmpty
        }

    }

    Context '- Formats, Types, and Scripts' {

        It 'has a valid FormatsToProcess setting' {
            $sourceManifestData.ExportedFormatFiles | Should -Not -BeNullOrEmpty
            $sourceManifestData.ExportedFormatFiles | Should -BeOfType 'System.String'

            $ExportedFormatFileNames = $sourceManifestData.ExportedFormatFiles | ForEach-Object {
                $_ | Split-Path -Leaf
            }
            Should -ActualValue $ExportedFormatFileNames -Contain "$ModuleName.format.ps1xml"
        }

        It 'has a valid TypesToProcess setting' {
            $sourceManifestData.ExportedTypeFiles | Should -Not -BeNullOrEmpty
            $sourceManifestData.ExportedTypeFiles | Should -BeOfType 'System.String'

            $ExportedTypeFileNames = $sourceManifestData.ExportedTypeFiles | ForEach-Object {
                $_ | Split-Path -Leaf
            }
            Should -ActualValue $ExportedTypeFileNames -Contain "$ModuleName.types.ps1xml"
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

        $thisCommit = & git log --decorate --oneline HEAD~1..HEAD

        if ($thisCommit -match 'tag:\s*v*(\d+(?:\.\d+)*)') {
            $gitTagVersion = $matches[1]
        } else {
            $gitTagVersion = $null
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
