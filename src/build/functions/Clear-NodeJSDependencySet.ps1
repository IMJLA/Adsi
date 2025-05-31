function Clear-NodeJSDependencySet {
    <#
    .SYNOPSIS
    Clears corrupted Node.js dependencies by removing node_modules and package-lock.json files.

    .DESCRIPTION
    This function removes corrupted node_modules directory and package-lock.json file,
    then triggers a clean reinstallation of dependencies.

    .PARAMETER WorkingDirectory
    The directory containing the Node.js project with corrupted dependencies.

    .EXAMPLE
    Clear-NodeJSDependencySet -WorkingDirectory "C:\MyProject"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$WorkingDirectory
    )

    $InformationPreference = 'Continue'

    # Remove corrupted node_modules and package-lock.json
    $NodeModulesPath = [IO.Path]::Combine($WorkingDirectory, 'node_modules')
    $PackageLockPath = [IO.Path]::Combine($WorkingDirectory, 'package-lock.json')
    $YarnLockPath = [IO.Path]::Combine($WorkingDirectory, 'yarn.lock')

    # More aggressive cleanup - retry removal if it fails initially
    if (Test-Path $NodeModulesPath) {
        Write-Information "`tRemove-Item -Path '$NodeModulesPath' -Recurse -Force"
        try {
            Remove-Item -Path $NodeModulesPath -Recurse -Force -ErrorAction Stop -ProgressAction SilentlyContinue
        } catch {
            Write-Information "& cmd /c 'rmdir /s /q `"$NodeModulesPath`""
            & cmd /c "rmdir /s /q `"$NodeModulesPath`"" 2>$null
        }

        # Verify removal
        if (Test-Path $NodeModulesPath) {
            Write-Warning 'Unable to completely remove node_modules directory'
        }
    }

    # Remove lock files
    @($PackageLockPath, $YarnLockPath) | ForEach-Object {
        if (Test-Path $_) {
            Write-Information "`tRemove-Item -Path '$_' -Force"
            Remove-Item -Path $_ -Force -ErrorAction SilentlyContinue
        }
    }

    # Clear npm cache more aggressively
    Write-Information "`tInvoke-NpmCommand -Command 'cache clean --force' -WorkingDirectory '$WorkingDirectory'"
    try {
        Invoke-NpmCommand -Command 'cache clean --force' -WorkingDirectory $WorkingDirectory -ErrorAction Stop
    } catch {
        Write-Information "`t# npm cache clean failed, trying verify"
    }

    try {
        Invoke-NpmCommand -Command 'cache verify' -WorkingDirectory $WorkingDirectory -ErrorAction SilentlyContinue
    } catch {
        Write-Information "`t# npm cache verify failed, continuing"
    }

    # Try different installation strategies
    $installStrategies = @(
        'install',
        'install --no-package-lock --no-optional --legacy-peer-deps',
        'install --force --no-optional --legacy-peer-deps',
        'ci --legacy-peer-deps',
        'install --prefer-offline --no-audit --legacy-peer-deps'
    )

    $installSuccess = $false
    foreach ($strategy in $installStrategies) {
        Write-Information "`tTrying: Invoke-NpmCommand -Command '$strategy' -WorkingDirectory '$WorkingDirectory'"
        try {
            Invoke-NpmCommand -Command $strategy -WorkingDirectory $WorkingDirectory -ErrorAction Stop

            # Test if critical babel package is properly installed
            $babelTypesPath = [IO.Path]::Combine($NodeModulesPath, '@babel', 'types', 'lib', 'index.js')
            if (Test-Path $babelTypesPath) {
                $installSuccess = $true
                Write-Information "`t# Installation strategy '$strategy' succeeded"
                break
            } else {
                Write-Information "`t# Strategy '$strategy' completed but @babel/types is still incomplete"
            }
        } catch {
            Write-Information "`t# Strategy '$strategy' failed: $_"
            # Clean up partial installation before trying next strategy
            if (Test-Path $NodeModulesPath) {
                Remove-Item -Path $NodeModulesPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    # Verify installation
    if ($installSuccess -and (Test-Path $NodeModulesPath)) {
        Write-InfoColor "`t# Successfully cleared and reinstalled Node.js dependencies." -ForegroundColor Green
    } else {
        # Last resort: try yarn if available
        Write-Information "`t# Trying yarn as last resort"
        try {
            if (Get-Command yarn -ErrorAction SilentlyContinue) {
                & yarn install --no-lockfile --legacy-peer-deps --cwd $WorkingDirectory
                if (Test-Path $NodeModulesPath) {
                    Write-InfoColor "`t# Successfully installed dependencies using yarn." -ForegroundColor Green
                    return
                }
            }
        } catch {
            Write-Information "`t# Yarn installation also failed"
        }

        throw 'Failed to reinstall Node.js dependencies after trying multiple strategies. Consider updating Node.js version or checking filesystem permissions.'
    }
}
