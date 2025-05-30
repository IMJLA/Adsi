﻿function Get-VersionFolder {
    # Function to find the version folder dynamically
    param([string]$DistPath)

    if (-not (Test-Path $DistPath)) {
        throw "Dist folder not found at: $DistPath"
    }

    $InformationPreference = 'Continue'
    Write-InfoColor "`t`t`tGet-ChildItem -Path '$DistPath' -Directory | Where-Object {`$_.Name -match '^\d+\.\d+\.\d+'}"
    $versionFolders = Get-ChildItem -Path $DistPath -Directory | Where-Object { $_.Name -match '^\d+\.\d+\.\d+' }

    if ($versionFolders.Count -eq 0) {
        throw "No version folder found in: $DistPath"
    }

    if ($versionFolders.Count -gt 1) {
        Write-Warning "Multiple version folders found. Using the first one: $($versionFolders[0].Name)"
    }

    return $versionFolders[0]
}
