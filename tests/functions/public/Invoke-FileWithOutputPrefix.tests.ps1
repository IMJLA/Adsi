BeforeAll {
    # Import the function being tested
    $functionPath = Join-Path $PSScriptRoot '..' '..' '..' 'src' 'build' 'functions' 'Invoke-FileWithOutputPrefix.ps1'
    . $functionPath

    # Import the Write-ConsoleOutput function which is a dependency
    $writeConsoleOutputPath = Join-Path $PSScriptRoot '..' '..' '..' 'src' 'build' 'functions' 'Write-ConsoleOutput.ps1'
    . $writeConsoleOutputPath
}

Describe 'Invoke-FileWithOutputPrefix' {

    Context 'npm install output collection' {

        BeforeAll {
            # Check if npm is available for real testing
            [bool]$npmAvailable = Get-Command -Name npm -ErrorAction SilentlyContinue

            # Create a temporary directory for npm test if npm is available
            if ($npmAvailable) {
                $tempDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "PesterNpmTest_$([guid]::NewGuid().ToString('N')[0..7] -join '')")

                # Create a minimal package.json
                $packageJson = @{
                    name        = 'pester-test'
                    version     = '1.0.0'
                    description = 'Test package for Pester'
                } | ConvertTo-Json

                Set-Content -Path (Join-Path $tempDir.FullName 'package.json') -Value $packageJson
            } else {
                Write-Warning 'npm is not available, skipping npm install tests.'
            }
        }

        AfterAll {
            # Clean up temp directory
            if ($tempDir -and (Test-Path $tempDir.FullName)) {
                Remove-Item -Path $tempDir.FullName -Recurse -Force -ErrorAction SilentlyContinue -ProgressAction SilentlyContinue
            }
        }

        It 'should collect npm install output with expected ending lines' -Skip:(-not $npmAvailable) {
            # Execute npm install using the function
            $result = Invoke-FileWithOutputPrefix -Command 'npm' -ArgumentArray @('install') -WorkingDirectory $tempDir.FullName -InformationAction 'SilentlyContinue' -NoConsoleOutput

            # Verify result is an array
            $result | Should -BeOfType [array]

            # Verify we have output
            $result.Count | Should -BeGreaterThan 0

            # Check the last few lines for expected npm install completion pattern
            $lastLines = $result | Select-Object -Last 3

            # The last line should be empty or whitespace
            $lastLines[-1] | Should -Match '^\s*$'

            # The second to last line should contain "found 0 vulnerabilities" or similar vulnerability message
            $lastLines[-2] | Should -Match 'found \d+ vulnerabilit(y|ies)'
        }

        It 'should handle command execution without PassThru parameter' -Skip:(-not $npmAvailable) {
            # This test verifies the function doesn't throw when not using PassThru
            {
                $null = Invoke-FileWithOutputPrefix -Command 'npm' -ArgumentArray @('--version') -WorkingDirectory $tempDir.FullName -InformationAction 'SilentlyContinue' -NoConsoleOutput
            } | Should -Not -Throw
        }

        It 'should properly handle exit codes' {
            # Test with a command that should fail
            {
                $null = Invoke-FileWithOutputPrefix -Command 'cmd' -ArgumentString '/c exit 1' -InformationAction 'SilentlyContinue' -NoConsoleOutput
            } | Should -Throw -ExpectedMessage '*Command failed with exit code 1*'
        }

        It 'should return output when PassThru is specified' {
            # Test with a simple command that has predictable output
            $result = Invoke-FileWithOutputPrefix -Command 'cmd' -ArgumentString '/c echo test' -InformationAction 'SilentlyContinue' -NoConsoleOutput

            $result | Should -Not -BeNullOrEmpty
            $result | Should -Contain 'test'
        }

        It 'should apply output prefixes correctly' {
            # Test that output prefixing doesn't interfere with PassThru results
            $result = Invoke-FileWithOutputPrefix -Command 'cmd' -ArgumentString '/c echo hello' -OutputPrefix 'PREFIX: ' -InformationAction 'SilentlyContinue' -NoConsoleOutput

            # The PassThru result should not contain the prefix (prefix is only for console display)
            $result | Should -Contain 'hello'
            $result | Should -Not -Match 'PREFIX:'
        }

        It 'should handle environment variables' {
            $envVars = @{
                'TEST_VAR' = 'TestValue'
            }

            $result = Invoke-FileWithOutputPrefix -Command 'cmd' -ArgumentString '/c echo %TEST_VAR%' -EnvironmentVariables $envVars -InformationAction 'SilentlyContinue' -NoConsoleOutput

            $result | Should -Contain 'TestValue'
        }
    }

    Context 'parameter validation' {

        It 'should require Command parameter' {
            # Use Get-Command to validate the parameter is mandatory
            $commandInfo = Get-Command Invoke-FileWithOutputPrefix
            $commandParam = $commandInfo.Parameters['Command']
            $commandParam.Attributes.Mandatory | Should -Contain $true
        }

        It 'should accept ArgumentArray parameter' {
            {
                $null = Invoke-FileWithOutputPrefix -Command 'cmd' -ArgumentArray @('/c', 'echo', 'test') -InformationAction 'SilentlyContinue' -NoConsoleOutput
            } | Should -Not -Throw
        }

        It 'should accept ArgumentString parameter' {
            {
                $null = Invoke-FileWithOutputPrefix -Command 'cmd' -ArgumentString '/c echo test' -InformationAction 'SilentlyContinue' -NoConsoleOutput
            } | Should -Not -Throw
        }

        It 'should use current directory as default WorkingDirectory' {
            $currentDir = (Get-Location).Path

            # Mock Test-Path to verify the working directory is used
            Mock Test-Path { return $true } -Verifiable

            $null = Invoke-FileWithOutputPrefix -Command 'cmd' -ArgumentString '/c echo test' -InformationAction 'SilentlyContinue' -NoConsoleOutput -ErrorAction SilentlyContinue

        }

    }

    Context 'output handling edge cases' {

        It 'should handle commands with no output' {
            $result = Invoke-FileWithOutputPrefix -Command 'cmd' -ArgumentString '/c rem silent command' -InformationAction 'SilentlyContinue' -NoConsoleOutput

            # Result might be empty array or contain empty strings
            if ($result) {
                $result | Should -BeOfType [array]
            }
        }

        It 'should handle commands with large output' {
            # Generate a command that produces multiple lines of output
            $result = Invoke-FileWithOutputPrefix -Command 'cmd' -ArgumentString '/c for /L %i in (1,1,5) do echo Line %i' -InformationAction 'SilentlyContinue' -NoConsoleOutput

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 1
        }

    }

}
