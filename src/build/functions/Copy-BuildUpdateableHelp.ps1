function Copy-BuildUpdateableHelp {

    <#
    .SYNOPSIS
    Copies updatable help files to the online help website directory.

    .DESCRIPTION
    This function copies updatable help .cab files and HelpInfo.xml files from the updatable help
    directory to the online help website's static directory for download by users.

    .EXAMPLE
    Copy-BuildUpdateableHelp -DocsUpdateableDir './docs/updateable' -DocsOnlineHelpDir './docs/online/MyModule'
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        # Directory containing the updatable help files
        [Parameter(Mandatory)]
        [string]$DocsUpdateableDir,

        # Directory of the online help website
        [Parameter(Mandatory)]
        [string]$DocsOnlineHelpDir
    )

    $destinationPath = [IO.Path]::Combine($DocsOnlineHelpDir, 'static', 'UpdateableHelp')

    # Create the destination directory if it doesn't exist
    if (-not (Test-Path $destinationPath)) {
        if ($PSCmdlet.ShouldProcess($destinationPath, 'Create Directory')) {
            Write-Information "`tNew-Item -Path '$destinationPath' -ItemType Directory -Force"
            New-Item -Path $destinationPath -ItemType Directory -Force | Out-Null
        }
    }

    # Get the Updateable Help files (.cab files and HelpInfo.xml file) but exclude .zip files
    Write-Verbose "`tGet-ChildItem -Path '$DocsUpdateableDir' -Exclude '*.zip'"
    $UpdateableHelpFiles = Get-ChildItem -Path $DocsUpdateableDir -Exclude '*.zip'

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
