$Scripts = Get-ChildItem -Path $env:BHBuildOutput -Include *.ps1, *.psm1, *.psd1 -Recurse

$ModuleManifest = $Scripts |
Where-Object {
    $_.Extension -eq '.psd1'
} |
Sort-Object -Property FullName |
Select-Object -First 1

$ModuleFile = $Scripts |
Where-Object {
    $_.Extension -eq '.psm1'
} |
Select-Object -First 1

$ModuleName = $ModuleManifest.Name -split '\.' | Select-Object -SkipLast 1

Describe "'$ModuleName' Function Tests" {
    # TestCases are splatted to the script so we need hashtables
    $functionTestCases = $Scripts | ForEach-Object { @{Script = $_ } }
    It "Script '<Script>' is valid PowerShell" -TestCases $functionTestCases {
        param ($Script)
        $Script.FullName | Should -Exist

        $ScriptContents = Get-Content -LiteralPath $Script.FullName -ErrorAction Stop
        $Errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize($ScriptContents, [ref]$Errors)
        $Errors.Count | Should -Be 0
    }
}

Describe "module" {
    $moduleTestCase = @{ ThisModule = $ModuleFile.FullName }
    It "can be imported without any errors" -TestCases $moduleTestCase {
        param ($ThisModule)
        { Import-Module -Name $ThisModule -Force -ErrorAction Stop } | Should -Not -Throw
    }
}

