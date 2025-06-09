function Copy-BuildUpdateableHelp {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$DocsUpdateableDir,

        [Parameter(Mandatory)]
        [string]$DocsOnlineHelpDir,

        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    $destinationPath = [IO.Path]::Combine($DocsOnlineHelpDir, 'static', 'UpdateableHelp')

    # Create the destination directory if it doesn't exist
    if (-not (Test-Path $destinationPath)) {
        if ($PSCmdlet.ShouldProcess($destinationPath, 'Create Directory')) {
            New-Item -Path $destinationPath -ItemType Directory -Force | Out-Null
            Write-Information "`tCreated directory: $destinationPath"
        }
    }

    # Get the Updateable Help files (.cab files and HelpInfo.xml file) but exclude .zip files
    Write-Information "`tGet-ChildItem -Path '$DocsUpdateableDir' -Exclude '*.zip'"
    $UpdateableHelpFiles = Get-ChildItem -Path $DocsUpdateableDir -File -Exclude '*.zip'

    if ($UpdateableHelpFiles.Count -eq 0) {
        Write-Warning "No updatable help files found in '$DocsUpdateableDir'"
        return $false
    }

    foreach ($helpFile in $UpdateableHelpFiles) {
        $destinationFile = [IO.Path]::Combine($destinationPath, $helpFile.Name)

        if ($PSCmdlet.ShouldProcess($helpFile.FullName, 'Copy Help File to Online Help Website')) {
            Write-Information "`tCopy-Item -Path '$($helpFile.FullName)' -Destination '$destinationFile' -Force"
            Copy-Item -Path $helpFile.FullName -Destination $destinationFile -Force
        }
    }

    Write-InfoColor "`t# Successfully copied updatable help files to online help website." -ForegroundColor Green
    return $true
}
