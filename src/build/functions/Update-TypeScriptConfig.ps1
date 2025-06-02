function Update-TypeScriptConfig {

    # ToDo: Use the TypeScript Compiler API to update the configuration file instead of string manipulation.

    [CmdletBinding()]

    param (
        # The directory containing the Docusaurus website
        [string]$DocsOnlineHelpDir = '.',

        # The GitHub organization name
        [Parameter(Mandatory)]
        [string]$GitHubOrgName,

        # The module information object, ideally from Get-Module or Test-ModuleManifest
        [Parameter(Mandatory)]
        [PSModuleInfo]$ModuleInfo

    )

    $ModuleName = $ModuleInfo.Name
    $ModuleDescription = $ModuleInfo.Description
    $configPath = [IO.Path]::Combine($DocsOnlineHelpDir, 'docusaurus.config.ts')

    if (-not (Test-Path $configPath)) {
        Write-Error "Docusaurus config file not found at: $configPath"
        return
    }

    Write-Verbose "`t[string]`$configContent = Get-Content -LiteralPath '$configPath' -Raw"
    [string]$configContent = Get-Content -LiteralPath $configPath -Raw

    # Update navbar title only if it is still set to the default value
    $configContent = $configContent -replace "title: 'My Site'", "title: '$ModuleName'"

    # Always update tagline to the latest module description
    $configContent = $configContent -replace "tagline: '[^']*'", "tagline: '$ModuleDescription'"

    # Add trailingSlash configuration after projectName only if it is still set to the default value (missing)
    if ($configContent -notmatch 'trailingSlash:') {
        $configContent = $configContent -replace "(projectName: '$ModuleName',)([ ]*\/\/[^\r\n]*)?", "`$1`$2`r`n`r`n  trailingSlash: false,"
    }

    # Update favicon only if the favicon is in SVG format in the img directory
    if (
        (
            Test-Path -Path (
                [IO.Path]::Combine($DocsOnlineHelpDir, 'build', 'img', 'logo.svg')
            )
        )
    ) {
        $configContent = $configContent -replace "favicon: 'img/favicon.ico'", "favicon: 'img/logo.svg'"
    }

    # Update URL only if it is still set to the default value
    $configContent = $configContent -replace "url: 'https://your-docusaurus-site.example.com'", "url: 'https://$($GitHubOrgName.ToLower()).github.io'"

    # Update baseUrl only if it is still set to the default value
    $configContent = $configContent -replace "baseUrl: '/'", "baseUrl: '/$ModuleName/'"

    $configContent = $configContent -replace 'const config: Config = {\s*title:', "const config: Config = {`r`n`r`n  // Set the title of your site here`r`n  title:"

    # Ensure double line spacing between top-level config elements
    $topLevelElements = @(
        '//Set the title of your site here\s*title:',
        'tagline:',
        'favicon:',
        'url:',
        'baseUrl:',
        'organizationName:',
        'projectName:',
        'trailingSlash:',
        'onBrokenLinks:',
        'onBrokenMarkdownLinks:',
        'i18n:',
        'markdown:',
        'themes:',
        'presets:',
        'themeConfig:'
    )

    foreach ($element in $topLevelElements) {
        # Match the element followed by its value/block, optional whitespace, optional inline comments, then ensure double spacing before next element or comment
        $configContent = $configContent -replace "($element[^,}]+[,}])([ ]*\/\/[^\r\n]*)?\s*(?=\s*(?:\/\/|[a-zA-Z]+:|\}))", "`$1`$2`r`n`r`n  "
    }

    # Clean up any triple or more line breaks that might have been created
    $configContent = $configContent -replace '\r\n\r\n\r\n+', "`r`n`r`n"

    # Update organization name only if it is still set to the default value
    $configContent = $configContent -replace "organizationName: 'facebook'", "organizationName: '$GitHubOrgName'"

    # Update project name only if it is still set to the default value
    $configContent = $configContent -replace "projectName: 'docusaurus'", "projectName: '$ModuleName'"

    # Always disable the blog
    $configContent = $configContent -replace 'blog: \{[\s\S]*?\}(?=,\s*theme: \{)', 'blog: false'

    # Always Remove blog navbar item
    $configContent = $configContent -replace "\{to: '/blog', label: 'Blog', position: 'left'\},?\s*", ''

    # Update navbar logo alternative text only if it is still set to the default value
    $configContent = $configContent -replace "alt: 'My Site Logo'", "alt: '$ModuleName Logo'"

    # Update navbar items to point to docs
    $configContent = $configContent -replace "\{\s*type: 'docSidebar',\s*sidebarId: 'tutorialSidebar',\s*position: 'left',\s*label: 'Tutorial',\s*\}", "{ to: 'docs/en-US/$ModuleName', label: 'Docs', position: 'left' }"

    # Update GitHub link
    $configContent = $configContent -replace "href: 'https://github.com/facebook/docusaurus'", "href: 'https://github.com/$GitHubOrgName/$ModuleName'"

    # Update editUrl only if it is still set to the default value
    $configContent = $configContent -replace "editUrl:\s*'https://github.com/facebook/docusaurus/tree/main/packages/create-docusaurus/templates/shared/'", "editUrl: 'https://github.com/$GitHubOrgName/$ModuleName/tree/main/docs/online/$ModuleName/'"

    # Update footer links
    $configContent = $configContent -replace "label: 'Tutorial',\s*to: '/docs/intro'", "label: 'ReadMe', to: '/docs/en-US/$ModuleName'"

    # Remove unnecessary footer sections and update community section
    $footerPattern = "title: 'Community',\s*items: \[[^\]]+\]"
    $newCommunitySection = @"
title: 'Community',
          items: [
            {
              label: 'GitHub',
              href: 'https://github.com/$GitHubOrgName/$ModuleName',
            }
          ]
"@
    $configContent = $configContent -replace $footerPattern, $newCommunitySection

    # Remove 'More' section from footer
    $configContent = $configContent -replace ",\s*\{\s*title: 'More',\s*items: \[[^\]]+\]\s*\}", ''

    # Update copyright only if it is still set to the default value
    $configContent = $configContent -replace 'Copyright © \$\{new Date\(\)\.getFullYear\(\)\} My Project, Inc\. Built with Docusaurus\.', "Copyright © Jeremy La Camera. All rights reserved. $ModuleName Online Help and Documentation Built with Docusaurus."

    # Update social image only if the favicon is in SVG format in the img directory
    if (
        (
            Test-Path -Path (
                [IO.Path]::Combine($DocsOnlineHelpDir, 'build', 'img', 'social-card.svg')
            )
        )
    ) {
        $configContent = $configContent -replace "image: 'img/docusaurus-social-card.jpg'", "image: 'img/social-card.svg'"
    }

    # Add MermaidJS support if not present
    if ($configContent -notmatch 'markdown:') {
        $mermaidConfig = @'

  // Enable MermaidJS
  markdown: {
    mermaid: true,
  },
  themes: ['@docusaurus/theme-mermaid'],
'@
        $configContent = $configContent -replace '(presets: \[)', "$mermaidConfig`r`n`r`n  `$1"
    }

    Write-Verbose "`tSet-Content -LiteralPath '$configPath' -Value `$configContent -Encoding UTF8"
    Set-Content -LiteralPath $configPath -Value $configContent -Encoding UTF8
    Write-InfoColor "`t# Successfully updated TypeScript configuration for $ModuleName" -ForegroundColor Green

}
