param ($Path)

$MarkdownFiles = Get-ChildItem -Path $Path -Filter '*.md' -Recurse

foreach ($Folder in $MarkdownFiles | Select-Object -ExpandProperty DirectoryName -Unique) {
    Write-InfoColor "Processing folder: $Folder"
}

foreach ($File in $MarkdownFiles) {

    $Content = Get-Content -Path $File.FullName -Raw

    # Convert to Docusaurus format by updating links.
    # In the source Markdown, links point to files with `.md` extension, but Docusaurus converts each of these to a page with no extension.
    if ($Content -match '\((?<File>[^\.]*).md\)') {
        $FileName = $Matches['File']
        $Content = $Content.Replace($Matches[0], "($FileName)")
    }

    # Write back to the file
    $FullPath = [io.path]::Combine($Path, $File.Name)
    Write-InfoColor "`t`tSet-Content -Path $FullPath -Value `$Content"
    Set-Content -Path $File.FullName -Value $Content

}