function Test-Unit {

    <#
    .SYNOPSIS
        Performs unit tests using Pester with configuration from JSON file.

    .DESCRIPTION
        Reads Pester configuration from a JSON file, creates a Pester configuration object,
        and executes the tests. Returns the test results for further processing.

    .OUTPUTS
        Returns the Pester test results object.

    .EXAMPLE
        $TestResults = Test-Unit

        Runs unit tests and stores the results in $TestResults variable.
    #>

    [CmdletBinding()]
    [OutputType([object])]

    param(

        # Path to the Pester configuration JSON file
        [string]$ConfigPath = '.\tests\config\pesterConfig.json',

        # Common parameters for Write-Information calls
        [hashtable]$IO = @{ 'ErrorAction' = 'Stop'; 'InformationAction' = 'Continue' ; 'ProgressAction' = 'SilentlyContinue' }

    )

    Write-Information "`t`$PesterConfigParams  = Get-Content -Path '$ConfigPath' | ConvertFrom-Json -AsHashtable" @IO
    $PesterConfigParams = Get-Content -Path $ConfigPath | ConvertFrom-Json -AsHashtable

    Write-Information "`t`$PesterConfiguration = New-PesterConfiguration -Hashtable `$PesterConfigParams" @IO
    $PesterConfiguration = New-PesterConfiguration -Hashtable $PesterConfigParams

    Write-Information "`tInvoke-Pester -Configuration `$PesterConfiguration" @IO
    $UnitTestResults = Invoke-Pester -Configuration $PesterConfiguration

    return $UnitTestResults
}
