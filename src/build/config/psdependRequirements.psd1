@{
    PSDependOptions       = @{
        Target = 'CurrentUser'
    }
    'BuildHelpers'        = @{
        Version = '2.0.16'
    }
    'ChangelogManagement' = @{
        Version = '3.1.0'
    }
    'Pester'              = @{
        Version    = '5.1.1'
        Parameters = @{
            SkipPublisherCheck = $true
        }
    }
    'platyPS'             = @{
        Version = '0.14.2'
    }
    'PowerShellBuild'     = @{
        Version = '0.7.2'
    }
    'psake'               = @{
        Version = '4.9.0'
    }
    'PSScriptAnalyzer'    = @{
        Version = '1.19.1'
    }
}
