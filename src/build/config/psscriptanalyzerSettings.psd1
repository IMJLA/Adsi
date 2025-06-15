@{
    # Need a test to detect missing [CmdletBinding()] in public function
    # Need a test to detect missing pipeline support (at least 1 parameter needs to support [Parameter(ValueFromPipeline)])
    # Need a test to detect missing pipeline support (needs a process block)
    # Need a test to detect missing pipeline AND full collection support (process block needs to loop through the pipeline input parameter)
    # Need a test to detect .Net type accelerators (aliases) and a Fix to replace them with their corresponding fully-qualified types
    #####[System.Management.Automation.PSObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")::Get

    # Path to custom rules module
    CustomRulePath      = @(
        '.\src\build\config\psscriptanalyzerCustomRules.psm1'
    )

    # Include all default PSScriptAnalyzer rules
    IncludeDefaultRules = $true

    # Specify which rules to run (using wildcard to include all)
    IncludeRules        = @('*')

    # Specify rules to exclude (if any)
    ExcludeRules        = @(
        # Add any rules you want to exclude here
        # Example: 'PSAvoidUsingWriteHost'
        'PSAvoidLongLines'
    )

    # Configure severity levels for rules
    Rules               = @{
        PSProvideCommentHelp                 = @{
            Enable                  = $true
            ExportedOnly            = $true
            BlockComment            = $true
            VSCodeSnippetCorrection = $true
            Placement               = 'before'
        }

        PSReviewUnusedParameter              = @{
            CommandsToTraverse = @(
                'Invoke-Expression'
                'Invoke-Command'
                'Invoke-RestMethod'
                'Invoke-WebRequest'
                'Start-Process'
            )
        }

        PSUseDeclaredVarsMoreThanAssignments = @{
            Enable = $true
        }

        PSAvoidLongLines                     = @{
            Enable            = $true
            MaximumLineLength = 120
        }

        PSAlignAssignmentStatement           = @{
            Enable         = $true
            CheckHashtable = $true
        }

        PSUseConsistentIndentation           = @{
            Enable              = $true
            Kind                = 'space'
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            IndentationSize     = 4
        }

        PSUseConsistentWhitespace            = @{
            Enable                          = $true
            CheckInnerBrace                 = $true
            CheckOpenBrace                  = $true
            CheckOpenParen                  = $true
            CheckOperator                   = $false  # Let PSAlignAssignmentStatement handle this
            CheckPipe                       = $true
            CheckPipeForRedundantWhitespace = $false
            CheckSeparator                  = $true
            CheckParameter                  = $false
        }

        PSPlaceOpenBrace                     = @{
            Enable             = $true
            OnSameLine         = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
        }

        PSPlaceCloseBrace                    = @{
            Enable             = $true
            NewLineAfter       = $false
            IgnoreOneLineBlock = $true
            NoEmptyLineBefore  = $false
        }

        PSUseCorrectCasing                   = @{
            Enable = $false  # Disabled because ForEach is better than foreach and PSScriptAnalyzer's opinion is wrong!
        }

        # Additional formatting rules
        PSAvoidTrailingWhitespace            = @{
            Enable = $true
        }

        PSAvoidSemicolonsAsLineTerminators   = @{
            Enable = $true
        }
    }
}
