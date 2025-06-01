function Invoke-NpmCommand {

    # Custom npm wrapper function

    [CmdletBinding()]
    param(
        # The npm command to execute
        [Parameter(Mandatory)]
        [string]$Command,

        [string]$WorkingDirectory = (Get-Location).Path,

        [switch]$PassThru

    )

    $InformationPreference = 'Continue'

    # Set up npm-specific environment variables for better output
    $npmEnvironment = @{
        'FORCE_COLOR'      = '1'
        'NPM_CONFIG_COLOR' = 'always'
        'TERM'             = 'xterm-256color'
        'COLUMNS'          = '200'
        'LINES'            = '50'
    }

    # Use cmd wrapper for npm to ensure proper encoding
    $cmdArguments = "/c chcp 65001 >nul && npm $Command"

    # Use the generic command wrapper
    $splat = @{
        Command              = 'cmd'
        ArgumentString       = $cmdArguments
        WorkingDirectory     = $WorkingDirectory
        OutputPrefix         = ''
        EnvironmentVariables = $npmEnvironment
        InformationAction    = 'Continue'
    }

    if ($PassThru) {
        $splat.PassThru = $true
    }

    Write-Verbose "`t`t`$EnvironmentVariables = @{ 'FORCE_COLOR'='1'; 'NPM_CONFIG_COLOR'='always'; 'TERM'='xterm-256color'; 'COLUMNS'='200'; 'LINES'='50' }"
    Write-Verbose "`t`tInvoke-CommandWithOutputPrefix -Command 'cmd' -ArgumentString '$cmdArguments' -WorkingDirectory '$WorkingDirectory' -OutputPrefix `"``t``t``t`" -PassThru:`$$PassThru -EnvironmentVariables `$EnvironmentVariables"
    Write-Information "`t& npm $Command"
    $output = Invoke-CommandWithOutputPrefix @splat

    if ($PassThru) {
        return $output
    }

}
