[cmdletbinding(DefaultParameterSetName = 'Task')]
param(

    # Build task(s) to execute
    [parameter(ParameterSetName = 'task', position = 0)]
    [System.Collections.Generic.List[string]]$Task = @('default'),

    [switch]$NoPublish,

    # List available build tasks
    [parameter(ParameterSetName = 'Help')]
    [switch]$Help,

    # Optional properties to pass to psake
    [hashtable]$Properties = @{},

    # Optional parameters to pass to psake
    [hashtable]$Parameters,

    # Commit message for source control
    [parameter(Mandatory)]
    [string]$CommitMessage,

    [switch]$IncrementMajorVersion,

    [switch]$IncrementMinorVersion,

    # Bootstrap dependencies
    [switch]$Bootstrap

)

$ErrorActionPreference = 'Stop'

# Dot-source Write-InfoColor first so it's available to other functions
$WriteInfoColorPath = [IO.Path]::Combine($PSScriptRoot, 'functions', 'Write-InfoColor.ps1')
. $WriteInfoColorPath

# Dynamically load all build functions
$FunctionsPath = [IO.Path]::Combine($PSScriptRoot, 'functions', '*.ps1')
# Exclude the Write-InfoColor since we already loaded it above
Get-ChildItem -Path $FunctionsPath -Exclude 'Write-InfoColor.ps1' | ForEach-Object {
    Write-Verbose "Loading function from: $($_.Name)"
    . $_.FullName
}

if (!($PSBoundParameters.ContainsKey('Parameters'))) {
    $Parameters = @{}
}
$Parameters['CommitMessage'] = $CommitMessage
$Parameters['NoPublish'] = $NoPublish

# Bootstrap dependencies
if ($Bootstrap.IsPresent) {
    Get-PackageProvider -Name Nuget -ForceBootstrap | Out-Null
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    $PSDependFile = [IO.Path]::Combine('.', 'src', 'build', 'config', 'psdependRequirements.psd1')
    if ((Test-Path -Path $PSDependFile)) {
        if (-not (Get-Module -Name PSDepend -ListAvailable)) {
            Install-Module -Name PSDepend -Repository PSGallery -Scope CurrentUser -Force
        }
        Import-Module -Name PSDepend -Verbose:$false
        Invoke-PSDepend -Path $PSDependFile -Install -Import -Force -WarningAction SilentlyContinue
    } else {
        Write-Warning 'No [psdependRequirements.psd1] found. Skipping build dependency installation.'
    }
}

if ($IncrementMajorVersion) {
    $Properties['IncrementMajorVersion'] = $true
} else {
    if ($IncrementMinorVersion) {
        $Properties['IncrementMinorVersion'] = $true
    }
}

# Execute psake task(s)
$psakeFile = [IO.Path]::Combine('.', 'src', 'build', 'psakeFile.ps1')
if ($PSCmdlet.ParameterSetName -eq 'Help') {
    Get-PSakeScriptTasks -buildFile $psakeFile | Format-Table -Property Name, Description, Alias, DependsOn
} else {
    Invoke-psake -buildFile $psakeFile -taskList $Task -properties $Properties -parameters $Parameters
    exit ([int](-not $psake.build_success))
}
