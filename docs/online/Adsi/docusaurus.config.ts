import { themes as prismThemes } from 'prism-react-renderer';
import type { Config } from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const config: Config = {

  // Set the title of your site here
  // The title appears in the browser tab and is used across various parts of your documentation
  title: 'Adsi',

  // Set the tagline of your site here.
  // The Docusaurus tagline is a short description of your site.
  // It is displayed in metadata, browser tabs, the header, and the social card.
  // It can be accessed within components.
  // If you don't want a tagline, you can remove this line.
  tagline: 'Use Active Directory Service Interfaces to query LDAP and WinNT directories',

  // Set the path to your site's favicon (the small icon displayed in the browser tab and bookmarks).
  // The path should be relative to the static directory (e.g. static/img/favicon.ico)
  // It should be a valid image file in .svg .ico or .png format.
  favicon: 'img/favicon.ico',

  // Set the production url of your site here
  url: 'https://imjla.github.io',

  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: '/Adsi/',

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'IMJLA', // Usually your GitHub org/user name.

  // Used in GitHub Pages deployment to define the repository where the site is hosted.
  // Often combined with organizationName to construct URLs for documentation editing.
  // If deploying to GitHub Pages, ensure baseUrl is set correctly (e.g., '/<projectName>/').
  projectName: 'Adsi', // Usually your repo name.

  // Controls whether URLs in your site end with a trailing slash (/). It also affects how static HTML files are generated.
  // This setting is useful for ensuring consistency in URL structure, especially when deploying to different hosting providers.
  // Some hosts may require a specific trailing slash behavior for proper routing.
  // Accepted values:
  //     undefined (default): Keeps URLs unchanged.
  //     "false": Removes trailing slashes and generates /docs/myDoc.html for /docs/myDoc.md
  //     "true":  Adds trailing slashes to URLs and generates /docs/myDoc/index.html for /docs/myDoc.md
  // This can affect how links are resolved and should be consistent across your site.
  trailingSlash: false,

  // Determines how the site handles broken links during the build process.
  // If a page contains a link to a non-existent path, this setting dictates whether the build should fail, warn, or ignore.
  // Accepted values:
  // 	"throw" (which stops the build)
  // 	"warn" (which logs a warning but allows the build to continue)
  // 	"ignore" (which suppresses any errors or warnings)
  onBrokenLinks: 'throw',

  // Determines how the site handles broken links within Markdown files during the build process.
  // This setting is useful for catching incorrect references to Markdown files early in the process, ensuring documentation integrity.
  // It runs before the broader onBrokenLinks check, which validates all internal links across the site.
  // If a Markdown file contains a link to a non-existent path, this setting dictates whether the build should fail, warn, or ignore.
  // Accepted values:
  // 	"throw" (which stops the build)
  // 	"warn" (which logs a warning but allows the build to continue)
  // 	"ignore" (which suppresses any errors or warnings)
  onBrokenMarkdownLinks: 'warn',

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',

   locales: ['en'],
  },

  // Enable MermaidJS Markdown support
  markdown: {
    mermaid: true,

   },

  // Add MermaidJS theme
  themes: ['@docusaurus/theme-mermaid'],

  // Define collections of plugins and themes that simplify your site's setup.
  // Instead of manually specifying individual plugins and themes, you can use presets to bundle them together.
  // For example, the @docusaurus/preset-classic preset includes commonly used plugins like:
  //     @docusaurus/plugin-content-docs (for documentation)
  //     @docusaurus/plugin-content-blog (for blogging)
  //     @docusaurus/plugin-content-pages (for static pages)
  //     @docusaurus/theme-classic (for styling)
  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',

          // Remove this to remove the "edit this page" links.
          editUrl: 'https://github.com/IMJLA/Adsi/tree/main/docs/online/Adsi/',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  // Customize various aspects of your site's theme, including color modes, metadata, announcement bars, and more
  themeConfig: {
    // Replace with your project's social card
    image: 'img/docusaurus-social-card.jpg',

   navbar: {
      title: 'Adsi',
      logo: {
        alt: 'Adsi Logo',
        src: 'img/logo.svg',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'tutorialSidebar',
          position: 'left',
          label: 'Tutorial',
        },
        {
          href: 'https://github.com/IMJLA/Adsi',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            {
              label: 'Tutorial',
              to: '/docs/intro',
            },
          ],
        },
        {
          title: 'Community',
          items: [
          {
              label: 'GitHub',
              href: 'https://github.com/IMJLA/Adsi',
          }
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} My Project, Inc. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
