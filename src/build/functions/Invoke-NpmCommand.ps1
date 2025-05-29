function Invoke-NpmCommand {

    # Custom npm wrapper function

    [CmdletBinding()]

    param(
        # The npm command to execute
        [Parameter(Mandatory)]
        [string]$Command,

        [string]$WorkingDirectory = (Get-Location).Path,

        [switch]$PassThru

    )

    $InformationPreference = 'Continue'
    $originalLocation = Get-Location
    Write-Information "`t`tSet-Location -Path '$WorkingDirectory'"
    Set-Location $WorkingDirectory
    Write-Information "`t`t& cmd /c `"npm $Command`""

    try {
        # Set console to UTF-8 to handle npm's unicode output properly
        $originalOutputEncoding = [Console]::OutputEncoding
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

        if ($PassThru) {
            # For PassThru, we need to capture while preserving encoding
            # chcp 65001 changes the Windows Command Prompt's code page to UTF-8 (code page 65001).
            $output = @()
            & cmd /c "chcp 65001 >nul && npm $Command" 2>&1 | ForEach-Object {
                $output += $_
                [Console]::Write("`t`t")
                [Console]::WriteLine($_)
            }

        } else {

            # Direct output with UTF-8 encoding
            # chcp 65001 changes the Windows Command Prompt's code page to UTF-8 (code page 65001).
            & cmd /c "chcp 65001 >nul && npm $Command" 2>&1 | ForEach-Object {
                [Console]::Write("`t`t")
                [Console]::WriteLine($_)
            }

        }

    } finally {
        # Restore original encoding
        if ($originalOutputEncoding) {
            [Console]::OutputEncoding = $originalOutputEncoding
        }
        Set-Location $originalLocation
    }

    # Check exit code
    if ($LASTEXITCODE -ne 0) {
        throw "npm command failed with exit code $LASTEXITCODE"
    }

    if ($PassThru) {
        return $output
    }

}
