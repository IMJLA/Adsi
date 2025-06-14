function Copy-BuildUpdatableHelp {

    <#
    .SYNOPSIS
    Copies updatable help files to the online help website directory.

    .DESCRIPTION
    This function copies updatable help .cab files and HelpInfo.xml files from the updatable help
    directory to the online help website's static directory for download by users.

    .EXAMPLE
    Copy-BuildUpdatableHelp -DocsUpdatableDir './docs/updatable' -DocsOnlineHelpDir './docs/online/MyModule'
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        # Directory containing the updatable help files
        [Parameter(Mandatory)]
        [string]$DocsUpdatableDir,

        # Directory of the online help website
        [Parameter(Mandatory)]
        [string]$DocsOnlineHelpDir
    )

    $destinationPath = [IO.Path]::Combine($DocsOnlineHelpDir, 'static', 'UpdatableHelp')

    # Create the destination directory if it doesn't exist
    if (-not (Test-Path $destinationPath)) {
        if ($PSCmdlet.ShouldProcess($destinationPath, 'Create Directory')) {
            Write-Information "`tNew-Item -Path '$destinationPath' -ItemType Directory -Force"
            New-Item -Path $destinationPath -ItemType Directory -Force | Out-Null
        }
    }

    # Get the Updatable Help files (.cab files and HelpInfo.xml file) but exclude .zip files
    Write-Verbose "`tGet-ChildItem -Path '$DocsUpdatableDir' -Exclude '*.zip'"
    $UpdatableHelpFiles = Get-ChildItem -Path $DocsUpdatableDir -Exclude '*.zip'

    if ($UpdatableHelpFiles.Count -eq 0) {
        Write-Warning "No updatable help files found in '$DocsUpdatableDir'"
        return $false
    }

    foreach ($helpFile in $UpdatableHelpFiles) {
        $destinationFile = [IO.Path]::Combine($destinationPath, $helpFile.Name)

        if ($PSCmdlet.ShouldProcess($helpFile.FullName, 'Copy Help File to Online Help Website')) {

            <#
            PowerShell’s Update-Help does exactly two lookups for your HelpInfo.xml:

            A “lower-case” trial: It takes your module’s Name (Adsi) and does a ToLowerInvariant(), so it first GETs …/UpdatableHelp/adsi_<GUID>_HelpInfo.xml (hence your 404).

            The “correct-case” retry: It then GETs …/UpdatableHelp/Adsi_<GUID>_HelpInfo.xml which succeeds and lets it parse the <HelpContentUri> element properly.

            Because GitHub Pages is case-sensitive, that first lowercase attempt will always 404 if you only checked in the PascalCase file. There’s no built-in way to suppress it—it’s simply Update-Help’s fallback logic at work, logged because you ran -Verbose.

            You have three options:

            • Ignore it It’s only a verbose log line, and Update-Help proceeds normally once the correct file is found.

            • Mirror the lowercase filename Add a second copy (or redirect) named adsi_282a2aed-9567-49a1-901c-122b7831a805_HelpInfo.xml in the same folder. Then both requests return 200.

            • Host locally via -SourcePath If you don’t want any HTTP lookups at all, build cab + xml locally and call: powershell Update-Help -Module Adsi -SourcePath 'C:\MyHelpRepo' -Force -Verbose (bypasses the web lookup entirely).

            In practice most folks just ignore the first 404—once the correct-case URI succeeds, your updatable help installs without any further errors.
            #>
            # If the file is the HelpInfo.xml, also copy it with a lowercase name to avoid 404 errors
            if ($helpFile.Name -like '*_HelpInfo.xml') {
                $HelpInfoXml = $helpFile
                $ModuleName = $HelpInfoXml.Name -replace '_HelpInfo.xml$', ''
                $ModuleGuid = $ModuleName -replace '^[^_]+_', ''
                $ModuleName = $ModuleName -replace "_$ModuleGuid$", ''

                # Copy the HelpInfo.xml with a lowercase name
                $lowerCaseFileName = $ModuleName.ToLowerInvariant() + "_$ModuleGuid" + '_HelpInfo.xml'
                $lowerCaseFilePath = $destinationFile = [IO.Path]::Combine($destinationPath, $lowerCaseFileName)

                Write-Information "`tCopy-Item -Path '$($helpFile.FullName)' -Destination '$lowerCaseFilePath' -Force"
                Copy-Item -Path $helpFile.FullName -Destination $lowerCaseFilePath -Force -ErrorAction Stop
                pause
            }

            # Copy the original file to the website's directory for static content
            Write-Information "`tCopy-Item -Path '$($helpFile.FullName)' -Destination '$destinationFile' -Force"
            Copy-Item -Path $helpFile.FullName -Destination $destinationFile -Force -ErrorAction Stop
            pause

        }
    }

    Write-InfoColor "`t# Successfully copied updatable help files to online help website." -ForegroundColor Green
    return $true

}
