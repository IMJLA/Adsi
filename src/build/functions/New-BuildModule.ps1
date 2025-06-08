function New-BuildModule {
    <#
    .SYNOPSIS
    Builds a PowerShell script module based on the source directory.

    .DESCRIPTION
    Creates a new PowerShell module build by compiling source files, copying directories, and handling various build configurations.

    .EXAMPLE
    New-ModuleBuild -SourceCodeDir './src' -ModuleName 'MyModule' -BuildOutputDir './dist' -BuildCompileModule $true
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # Path to the source code directory
        [Parameter(Mandatory)]
        [string]$SourceCodeDir,

        # Name of the module being built
        [Parameter(Mandatory)]
        [string]$ModuleName,

        # Path to the build output directory
        [Parameter(Mandatory)]
        [string]$BuildOutputDir,

        # Whether to compile module into single PSM1 or not
        [Parameter(Mandatory)]
        [boolean]$BuildCompileModule,

        # List of directories to concatenate into the PSM1 if compiling
        [string[]]$BuildCompileDirectories = @(),

        # List of directories to copy to output directory
        [string[]]$CopyDirectories = @(),

        # Default locale for the module
        [Parameter(Mandatory)]
        [string]$DocsDefaultLocale,

        # List of files (regular expressions) to exclude from output directory
        [string[]]$BuildExclude = @(),

        # Whether to convert ReadMe to about file
        [boolean]$DocsConvertReadMeToAboutFile = $false,

        # Path to the ReadMe file
        [string]$DocsMarkdownReadMePath
    )

    if ($PSCmdlet.ShouldProcess($BuildOutputDir, 'Build PowerShell module')) {

        $buildParams = @{
            Compile            = $BuildCompileModule
            CompileDirectories = $BuildCompileDirectories
            CopyDirectories    = $CopyDirectories
            Culture            = $DocsDefaultLocale
            DestinationPath    = $BuildOutputDir
            ErrorAction        = 'Stop'
            Exclude            = $BuildExclude + "$ModuleName.psm1"
            ModuleName         = $ModuleName
            Path               = $SourceCodeDir
        }

        if ($DocsConvertReadMeToAboutFile -and $DocsMarkdownReadMePath) {
            $buildParams.ReadMePath = $DocsMarkdownReadMePath
        }

        # only add these configuration values to the build parameters if they have been been set
        $CompileParamStr = ''
        'CompileHeader', 'CompileFooter', 'CompileScriptHeader', 'CompileScriptFooter' | ForEach-Object {
            $Val = Get-Variable -name $_ -ValueOnly -ErrorAction SilentlyContinue
            if ($Val -ne '' -and $Val -ne $null) {
                $buildParams.$_ = $Val
                $CompileParamStr += "-$_ '$($Val.Replace("'", "''"))' "
            }
        }

        $ExcludeJoined = $buildParams['Exclude'] -join "','"
        $CompileDirectoriesJoined = $buildParams['CompileDirectories'] -join "','"
        $CopyDirectoriesJoined = $buildParams['CopyDirectories'] -join "','"
        Write-Information "`tBuild-PSBuildModule -Path '$SourceCodeDir' -ModuleName '$ModuleName' -DestinationPath '$BuildOutputDir' -Exclude @('$ExcludeJoined') -Compile '$BuildCompileModule' -CompileDirectories @('$CompileDirectoriesJoined') -CopyDirectories @('$CopyDirectoriesJoined') -Culture '$DocsDefaultLocale' -ReadMePath '$DocsMarkdownReadMePath' $CompileParamStr-ErrorAction 'Stop'"
        Build-PSBuildModule @buildParams
        Write-InfoColor "`t# Successfully built the module." -ForegroundColor Green

    }

}
