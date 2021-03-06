[cmdletbinding(DefaultParameterSetName = 'Task')]
param(
    # Build task(s) to execute
    [parameter(ParameterSetName = 'task', position = 0)]
    [string[]]$Task = 'default',

    [switch]$IncrementMajorVersion,

    # Bootstrap dependencies
    [switch]$Bootstrap,

    # List available build tasks
    [parameter(ParameterSetName = 'Help')]
    [switch]$Help,

    # Optional properties to pass to psake
    [hashtable]$Properties = @{
        IncrementMajorVersion = $IncrementMajorVersion
    },

    # Optional parameters to pass to psake
    [hashtable]$Parameters,

    # Commit message for source control
    [parameter(Mandatory)]
    [string]$CommitMessage
)

$ErrorActionPreference = 'Stop'

if (!($PSBoundParameters.ContainsKey('Parameters'))) {
    $Parameters = @{}
}
$Parameters['CommitMessage'] = $CommitMessage

# Bootstrap dependencies
if ($Bootstrap.IsPresent) {
    Get-PackageProvider -Name Nuget -ForceBootstrap | Out-Null
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    if ((Test-Path -Path ./requirements.psd1)) {
        if (-not (Get-Module -Name PSDepend -ListAvailable)) {
            Install-Module -Name PSDepend -Repository PSGallery -Scope CurrentUser -Force
        }
        Import-Module -Name PSDepend -Verbose:$false
        Invoke-PSDepend -Path './requirements.psd1' -Install -Import -Force -WarningAction SilentlyContinue
    } else {
        Write-Warning 'No [requirements.psd1] found. Skipping build dependency installation.'
    }
}

# Execute psake task(s)
$psakeFile = './psakeFile.ps1'
if ($PSCmdlet.ParameterSetName -eq 'Help') {
    Get-PSakeScriptTasks -buildFile $psakeFile |
    Format-Table -Property Name, Description, Alias, DependsOn
} else {
    Set-BuildEnvironment -Force
    Invoke-psake -buildFile $psakeFile -taskList $Task -properties $Properties -parameters $Parameters
    exit ([int](-not $psake.build_success))
}
