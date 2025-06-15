function Update-DocusaurusConfig {

    <#
    .SYNOPSIS
    Updates Docusaurus configuration file with module-specific settings.

    .DESCRIPTION
    This function updates the docusaurus.config.ts file with module-specific information including
    titles, URLs, GitHub organization details, and various configuration settings for optimal
    documentation site generation.

    .EXAMPLE
    Update-DocusaurusConfig -DocsOnlineHelpDir './docs/online/MyModule' -GitHubOrgName 'MyOrg' -ModuleInfo $moduleInfo
    #>

    # ToDo: Use the TypeScript Compiler API or Bun to update the configuration file instead of string manipulation.
    [CmdletBinding(SupportsShouldProcess = $true)]

    param (

        # The directory containing the Docusaurus website
        [string]$DocsOnlineHelpDir = '.',

        # The GitHub organization name
        [Parameter(Mandatory)]
        [string]$GitHubOrgName,

        # The module information object, ideally from Get-Module or Test-ModuleManifest
        [Parameter(Mandatory)]
        [PSModuleInfo]$ModuleInfo,

        # Comments to add to the configuration file
        [hashtable]$ElementComment = @{

            'title'                 = @(

                'Set the title of your site here',

                'The title appears in the browser tab and is used across various parts of your documentation'
            )
            'tagline'               = @(
                'Set the tagline of your site here.',
                'The Docusaurus tagline is a short description of your site.',
                'It is displayed in metadata, browser tabs, the header, and the social card.',
                'It can be accessed within components.',
                "If you don't want a tagline, you can remove this line."
            )
            'onBrokenLinks'         = @(
                'Determines how the site handles broken links during the build process.',
                'If a page contains a link to a non-existent path, this setting dictates whether the build should fail, warn, or ignore.',
                'Accepted values:',
                '	"throw" (which stops the build)',
                '	"warn" (which logs a warning but allows the build to continue)',
                '	"ignore" (which suppresses any errors or warnings)'
            )
            'onBrokenMarkdownLinks' = @(
                'Determines how the site handles broken links within Markdown files during the build process.',
                'This setting is useful for catching incorrect references to Markdown files early in the process, ensuring documentation integrity.',
                'It runs before the broader onBrokenLinks check, which validates all internal links across the site.',
                'If a Markdown file contains a link to a non-existent path, this setting dictates whether the build should fail, warn, or ignore.',
                'Accepted values:',
                '	"throw" (which stops the build)',
                '	"warn" (which logs a warning but allows the build to continue)',
                '	"ignore" (which suppresses any errors or warnings)'
            )
            'presets'               = @(
                "Define collections of plugins and themes that simplify your site's setup.",
                'Instead of manually specifying individual plugins and themes, you can use presets to bundle them together.',
                'For example, the @docusaurus/preset-classic preset includes commonly used plugins like:',
                '    @docusaurus/plugin-content-docs (for documentation)',
                '    @docusaurus/plugin-content-blog (for blogging)',
                '    @docusaurus/plugin-content-pages (for static pages)',
                '    @docusaurus/theme-classic (for styling)'
            )
            'themeConfig'           = "Customize various aspects of your site's theme, including color modes, metadata, announcement bars, and more"
            'favicon'               = @(
                "Set the path to your site's favicon (the small icon displayed in the browser tab and bookmarks).",
                'The path should be relative to the static directory (e.g. static/img/favicon.ico)',
                'It should be a valid image file in .svg .ico or .png format.'
            )
            'projectName'           = @(
                'Used in GitHub Pages deployment to define the repository where the site is hosted.',
                'Often combined with organizationName to construct URLs for documentation editing.',
                "If deploying to GitHub Pages, ensure baseUrl is set correctly (e.g., '/<projectName>/')."
            )
            'trailingSlash'         = @(
                'Controls whether URLs in your site end with a trailing slash (/). It also affects how static HTML files are generated.',
                'This setting is useful for ensuring consistency in URL structure, especially when deploying to different hosting providers.',
                'Some hosts may require a specific trailing slash behavior for proper routing.',
                'Accepted values:',
                '    undefined (default): Keeps URLs unchanged.',
                '    "false": Removes trailing slashes and generates /docs/myDoc.html for /docs/myDoc.md',
                '    "true":  Adds trailing slashes to URLs and generates /docs/myDoc/index.html for /docs/myDoc.md',

                'This can affect how links are resolved and should be consistent across your site.'

            )
        }

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

    # Update site title AND navbar title only if it is still set to the default value
    $configContent = $configContent -replace "title: 'My Site'", "title: '$ModuleName'"

    # Update organization name only if it is still set to the default value
    $configContent = $configContent -replace "organizationName: 'facebook'", "organizationName: '$GitHubOrgName'"

    # Update project name only if it is still set to the default value
    $configContent = $configContent -replace "projectName: 'docusaurus'", "projectName: '$ModuleName'"

    # Remove 'More' section from footer
    $configContent = $configContent -replace ",\s*\{\s*title: 'More',\s*items: \[[^\]]+\],\s*\}", ''

    # Always disable the blog
    $configContent = $configContent -replace 'blog: \{[\s\S]*?\n        \}', 'blog: false'

    # Add MermaidJS support if not present
    if ($configContent -notmatch 'mermaid: true') {
        $mermaidConfig = @'
// Enable MermaidJS Markdown support
  markdown: {
    mermaid: true,
  },

  // Add MermaidJS theme
  themes: ['@docusaurus/theme-mermaid'],
'@
        $configContent = $configContent -replace '(presets: \[)', "$mermaidConfig`r`n`r`n  `$1"
    }

    # Add trailingSlash setting only if it is missing (which is the default)
    if ($configContent -notmatch 'trailingSlash:') {
        $configContent = $configContent -replace "(projectName: '[^']*',)([ ]*\/\/[^\r\n]*)?", "`$1`$2`r`n`r`n  trailingSlash: false,"
    }

    # Add comments above specified elements
    foreach ($elementKey in $ElementComment.Keys) {

        $comments = $ElementComment[$elementKey]

        # Build the comment block
        $commentBlock = ''
        foreach ($comment in $comments) {
            $commentBlock += "`r`n  // $comment"
        }

        # Find the element and add comments above it (only if comments don't already exist)
        $element = [regex]::Escape($elementKey)
        $pattern = "(\n  $element`:)"

        # Only add comments if they don't already exist above the element
        if ($configContent -notmatch "\n  \/\/[ ]*.*\r?\n  $element`:") {
            $configContent = $configContent -replace $pattern, "$commentBlock`$1"
        }
    }

    # Always update tagline to the latest module description
    $configContent = $configContent -replace "tagline: '[^']*'", "tagline: '$ModuleDescription'"

    # Update favicon only if the favicon is in SVG format in the img directory
    if (
        (
            Test-Path -Path (
                [IO.Path]::Combine($DocsOnlineHelpDir, 'build', 'img', 'logo.svg')
            )
        )
    ) {
        $configContent = $configContent -replace "favicon: 'img/favicon.ico'', 'favicon: 'img/logo.svg'"
    }

    # Update URL only if it is still set to the default value
    $configContent = $configContent -replace " url: 'https://your-docusaurus-site.example.com'", " url: 'https://$($GitHubOrgName.ToLower()).github.io'"

    # Update baseUrl only if it is still set to the default value
    $configContent = $configContent -replace "baseUrl: '/'", "baseUrl: '/$ModuleName/'"

    # Dynamically detect top-level elements using regex
    $topLevelElements = [regex]::Matches($configContent, '\n  (\w*): ').Groups | Where-Object { $_.Name -eq '1' } | ForEach-Object { $_.Value }

    # Ensure double line spacing between top-level config elements
    foreach ($element in $topLevelElements) {
        # Match the element followed by its value/block, optional whitespace, optional inline comments, then ensure double spacing before next element or comment
        $configContent = $configContent -replace "(\n  $element`:[^,}]+[,}])([ ]*\/\/[^\r\n]*)?\s*(?=\s*(?:\/\/ | [a-zA-Z]+: | \}))", "`$1`$2`r`n`r`n  "
    }

    # Clean up any triple or more line breaks that might have been created
    $configContent = $configContent -replace '\r\n\r\n\r\n+', "`r`n`r`n"

    # Always Remove blog navbar item
    $configContent = $configContent -replace "\ { to: '/blog', label: 'Blog', position: 'left'\ }, ?\s*", ''

    # Update navbar logo alternative text only if it is still set to the default value
    $configContent = $configContent -replace "alt: 'My Site Logo'", "alt: '$ModuleName Logo'"

    # Update navbar items to point to docs
    $configContent = $configContent -replace "\ { \s*type: 'docSidebar', \s*sidebarId: 'tutorialSidebar', \s*position: 'left', \s*label: 'Tutorial', \s*\ }", " { to: 'docs/en-US/$ModuleName', label: 'Docs', position: 'left' }"

    # Update GitHub link
    $configContent = $configContent -replace "href: 'https://github.com/facebook/docusaurus'", "href: 'https://github.com/$GitHubOrgName/$ModuleName'"

    # Update editUrl only if it is still set to the default value
    $configContent = $configContent -replace "editUrl:\s*'https://github.com/facebook/docusaurus/tree/main/packages/create-docusaurus/templates/shared/'", "editUrl: 'https://github.com/$GitHubOrgName/$ModuleName/tree/main/docs/online/$ModuleName/'"

    # Remove the comment about changing the repo URL
    $configContent = $configContent -replace '// Please change this to your repo.', ''

    # Update footer links
    $configContent = $configContent -replace "label: 'Tutorial', \s*to: '/docs/intro'", "label: 'ReadMe', to: '/docs/en-US/$ModuleName'"

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

    # Update copyright only if it is still set to the default value
    $configContent = $configContent -replace 'Copyright © \$\ { new Date\(\)\.getFullYear\(\)\ } My Project, Inc\. Built with Docusaurus\.', "Copyright © Jeremy La Camera. All rights reserved. $ModuleName Online Help and Documentation Built with Docusaurus."

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

    # Add a blank line between the opening brace and the first element if not already present
    $configContent = $configContent -replace 'const config: Config \= \{\r?\n  \/\/', "const config: Config = {`r`n`r`n  //"

    # Remove any trailing blank lines at the end of the file
    $configContent = "$($configContent.Trim())"

    if ($PSCmdlet.ShouldProcess($configPath, 'Update Docusaurus configuration')) {
        Write-Information "`tSet-Content -LiteralPath '$configPath' -Value `$configContent -Encoding UTF8"
        Set-Content -LiteralPath $configPath -Value $configContent -Encoding UTF8 -ErrorAction Stop
        Write-InfoColor "`t# Successfully fixed online help website configuration." -ForegroundColor Green
    }
}
