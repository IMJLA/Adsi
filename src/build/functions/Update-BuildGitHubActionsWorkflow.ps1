function Update-BuildGitHubActionsWorkflow {

    <#
    .SYNOPSIS
    Updates GitHub Actions workflow files to use the correct module name.

    .DESCRIPTION
    This function updates the working-directory and cache-dependency-path settings in GitHub Actions
    workflow files to match the current module name instead of hardcoded values.

    .EXAMPLE
    Update-BuildGitHubActionsWorkflow -ModuleName 'MyModule'
    #>

    [CmdletBinding(SupportsShouldProcess)]

    param(

        # The name of the module to use in the workflow files
        [Parameter(Mandatory)]
        [string]$ModuleName,

        # The directory containing the GitHub Actions workflow files. Defaults to '.github/workflows'

        [string]$WorkflowDir = [IO.Path]::Combine('.github', 'workflows')

    )

    if (-not (Test-Path $WorkflowDir)) {
        Write-InfoColor "`t# No GitHub Actions workflow directory found at '$WorkflowDir'." -ForegroundColor Yellow
        return
    }

    Write-Verbose "`tGet-ChildItem -Path '$WorkflowDir' -Filter '*.yml'"
    $workflowFiles = Get-ChildItem -Path $WorkflowDir -Filter '*.yml'

    if ($workflowFiles.Count -eq 0) {
        Write-InfoColor "`t# No GitHub Actions workflow files found in '$WorkflowDir'." -ForegroundColor Green
        return
    }

    $updatedFiles = 0

    foreach ($workflowFile in $workflowFiles) {

        Write-Verbose "`t[string]`$workflowContent = Get-Content -LiteralPath '$($workflowFile.FullName)' -Raw"
        [string]$workflowContent = Get-Content -LiteralPath $workflowFile.FullName -Raw
        $originalContent = $workflowContent

        # Update working-directory to use the correct module name
        $workflowContent = $workflowContent -replace 'working-directory: \./docs/online/[^/\s]+', "working-directory: ./docs/online/$ModuleName"

        # Update cache-dependency-path to use the correct module name
        $workflowContent = $workflowContent -replace 'cache-dependency-path: \./docs/online/[^/\s]+/package-lock\.json', "cache-dependency-path: ./docs/online/$ModuleName/package-lock.json"

        # Update path references in upload-pages-artifact
        $workflowContent = $workflowContent -replace 'path: \./docs/online/[^/\s]+/build', "path: ./docs/online/$ModuleName/build"

        if ($workflowContent -ne $originalContent) {
            if ($PSCmdlet.ShouldProcess($workflowFile.FullName, 'Update GitHub Actions workflow file')) {
                Write-Information "`tSet-Content -LiteralPath '$($workflowFile.FullName)' -Value `$workflowContent -Encoding UTF8BOM -NoNewLine"
                Set-Content -LiteralPath $workflowFile.FullName -Value $workflowContent -Encoding UTF8BOM -NoNewLine -ErrorAction Stop
                $updatedFiles++
            }
        }
    }

    if ($updatedFiles -gt 0) {
        Write-InfoColor "`t# Successfully updated $updatedFiles GitHub Actions workflow file(s) with module name '$ModuleName'." -ForegroundColor Green
    } else {
        Write-InfoColor "`t# No GitHub Actions workflow files needed updating (already using correct module name)." -ForegroundColor Green
    }
}
