<#
.SYNOPSIS
Creates a directory for the build process.

.DESCRIPTION
Creates a directory if it doesn't exist and provides appropriate success or error messaging.

.PARAMETER Path
Path to the directory to create

.PARAMETER Description
Description of the directory being created for output messages

.NOTES
This function supports ShouldProcess for the New verb.
#>

function New-BuildFolder {

    [CmdletBinding(SupportsShouldProcess)]

    param(

        # Path to the directory to create
        [Parameter(Mandatory)]
        [string]$Path,

        # Description of the directory being created for output messages
        [Parameter(Mandatory)]
        [string]$Description

    )

    if ($PSCmdlet.ShouldProcess($Path, 'Create directory')) {

        Write-Information "`tNew-Item -Path '$Path' -ItemType Directory"
        $null = New-Item -Path $Path -ItemType Directory -ErrorAction SilentlyContinue

        if (Test-Path -Path $Path) {
            Write-InfoColor "`t# $Description directory exists." -ForegroundColor Green
        } else {

            $ErrorMessage = "Failed to create the $Description directory"

            if ($ErrorActionPreference -eq 'Stop') {
                Write-Error $ErrorMessage
            } else {
                Write-Warning $ErrorMessage
            }

        }
    }

}
