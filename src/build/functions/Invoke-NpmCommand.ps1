function Invoke-NpmCommand {

    <#
    .SYNOPSIS
    Wrapper function for executing npm commands with proper output handling.

    .DESCRIPTION
    Executes npm commands in a separate job to handle Node.js output properly and provide
    real-time feedback. Manages working directory changes and handles common npm issues.

    .EXAMPLE
    Invoke-NpmCommand -Command 'install' -WorkingDirectory 'C:\MyProject'

    .EXAMPLE
    Invoke-NpmCommand -Command 'run build'
    #>

    [CmdletBinding()]
    param(

        # The npm command to execute (e.g., 'install', 'run build', 'audit fix')
        [Parameter(Mandatory)]
        [string]$Command,

        # The directory where the npm command should be executed. Defaults to current directory
        [string]$WorkingDirectory = (Get-Location).Path

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

    Write-Verbose "`t`t`$EnvironmentVariables = @{ 'FORCE_COLOR'='1'; 'NPM_CONFIG_COLOR'='always'; 'TERM'='xterm-256color'; 'COLUMNS'='200'; 'LINES'='50' }"
    Write-Verbose "`t`tInvoke-FileWithOutputPrefix -Command 'cmd' -ArgumentString '$cmdArguments' -WorkingDirectory '$WorkingDirectory' -OutputPrefix `"``t``t``t`" -PassThru:`$$PassThru -EnvironmentVariables `$EnvironmentVariables"
    Write-Information "`tSet-Location '$WorkingDirectory'"
    Write-Information "`t& npm $Command"
    $output = Invoke-FileWithOutputPrefix @splat

    if ($PassThru) {
        return $output
    }

}
