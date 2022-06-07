# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## [1.0.141] - 2022-06-06 - fixed Function.tests.ps1

## [1.0.140] - 2022-06-06 - Removed tests for Test-PublicFunction, added basic standardized function tests

## [1.0.139] - 2022-06-06 - Removed Test-PublicFunction

## [1.0.138] - 2022-06-06 - Commented Search-Directory

## [1.0.137] - 2022-06-05 - Updated Resolve-IdentityReference

## [1.0.136] - 2022-06-03 - Minor performance improvements and comment-based help on all functions up through the I's.  The I's have it!

## [1.0.135] - 2022-06-03 - reproducing bug in platyps

## [1.0.134] - 2022-06-03 - Worked around PlatyPS bug with multi-line arrays in default param values

## [1.0.133] - 2022-06-03 - Wrapped param in parens to see if it bypasses PlatyPS bug

## [1.0.132] - 2022-06-03 - Troubleshooting platyPS

## [1.0.131] - 2022-06-03 - Implemented PropertiesToLoad across Get-ADSIGroup, Get-WinNTGroupMember, and Get-ADSIGroupMember.  Also added much splatting

## [1.0.130] - 2022-06-03 - Bug fixes in Get-ADSIGroup and Get-TrustedDomainSidNameMap

## [1.0.129] - 2022-05-29 - Added comment-based help with example help for all functions up thru F

## [1.0.128] - 2022-05-29 - Added example help where needed

## [1.0.127] - 2022-05-29 - Added comment-based help and OutputType to all functions up through the Fs

## [1.0.126] - 2022-05-22 - Fixed test failures for Add-SidInfo comment-based help

## [1.0.125] - 2022-05-22 - Added comment-based help for Add-SidInfo

## [1.0.124] - 2022-05-22 - Trying agin with plugins enabled

## [1.0.123] - 2022-05-22 - Fixed line breaks in comment-based help for Add-DomainFqdnToLdapPath

## [1.0.122] - 2022-05-22 - Updated RotateBuilds psake task to only retain 1 version

## [1.0.121] - 2022-05-22 - hmm

## [1.0.120] - 2022-05-22 - Using PS7 native format

## [1.0.119] - 2022-05-22 - grr

## [1.0.118] - 2022-05-22 - PlatyPS not living up to promises

## [1.0.117] - 2022-05-22 - who knows at this point

## [1.0.116] - 2022-05-22 - Fixed again

## [1.0.115] - 2022-05-22 - Fixed

## [1.0.114] - 2022-05-22 - PlatyPS claims to have fixed this

## [1.0.113] - 2022-05-22 - Finally settled on balance between what is PS's fault vs. PlatyPS's fault

## [1.0.112] - 2022-05-22 - PlatyPS is the enemy

## [1.0.111] - 2022-05-22 - PlatyPS not working for me

## [1.0.110] - 2022-05-22 - PlatyPS vs. Me round 2

## [1.0.109] - 2022-05-22 - Let's see what happens

## [1.0.108] - 2022-05-22 - Inconthievable

## [1.0.107] - 2022-05-22 - Fixed comment-based help example for Add-DomainFqdnToDLdapPath

## [1.0.106] - 2022-05-22 - testing

## [1.0.105] - 2022-05-22 - no time for this

## [1.0.104] - 2022-05-22 - Adding Remarks in comment-based help Examples for Add-DomainFqdnToLdapPath

## [1.0.103] - 2022-05-22 - Troubleshooting Help tests

## [1.0.102] - 2022-05-22 - Adjusted example for Add-DomainFqdnToLdapPath

## [1.0.101] - 2022-05-22 - Updated comment-based help for Add-DomainFqdnToLdapPath

## [1.0.100] - 2022-05-22 - Added comment-based help to Add-DomainFqdnToLdapPath

## [1.0.99] - 2022-02-21 - Updated tests, updated manifest to remove wildcards

## [1.0.123] - 2022-02-21 - Updated tests

## [1.0.122] - 2022-02-20 - Bug fix in build rotation psake task

## [1.0.121] - 2022-02-13 - Bug fix in psakefile

## [1.0.120] - 2022-02-13 - More buildhelpers, less powershellbuild

## [1.0.119] - 2022-02-13 - Geronimo

## [1.0.118] - 2022-02-13 - More PSBPreference replacement in psakefile

## [1.0.117] - 2022-02-13 - Trying to make use of psake properties

## [1.0.116] - 2022-02-13 - Added blank lines between versions in CHANGELOG.md per markdown linting

## [1.0.115] - 2022-02-13 - Fixed UpdateChangeLog psake task

## [1.0.114] - 2022-02-12 - Fixed UpdateChangeLog psake task

## [1.0.113] - 2022-02-12 - Trying $NextVersion as a string instead of $null

## [1.0.112] - 2022-02-12 - More psakefile fixes

## [1.0.111] - 2022-02-13 - Debugging

## [1.0.110] - 2022-02-13 - Updated UpdateChangeLog psake task

## [1.0.108] - 2022-02-12 - Fixed UpdatableHelp and Markdown generation

## [1.0.107] - 2022-02-12 - Added -WithModulePage to New-MarkdownHelp

## [1.0.106] - 2022-02-12 - Unsuppressed output from New-MarkdownHelp

## [1.0.105] - 2022-02-12 - More psakefile bug fixes

## [1.0.104] - 2022-02-12 - Fixed mistake in psakefile

## [1.0.103] - 2022-02-12 - More psakefile customization

## [1.0.102] - 2022-02-12 - More psakefile changes

## [1.0.101] - 2022-02-12 - Updated psakefile

## [1.0.100] - 2022-02-12 - Build output cleanup

## [1.0.99] - 2022-02-12 - Troubleshooting BuildUpdatableHelp

## [1.0.98] - 2022-02-12 - Workaround for Build-PSBuildUpdatableHelp implemented in psakefile

## [1.0.98] - 2022-02-12 - Getting mad at psake for scoping nonsense

## [1.0.97] - 2022-02-11 - More debugging

## [1.0.96] - 2022-02-11 - Debugging psakefile

## [1.0.95] - 2022-02-10 - How bout now

## [1.0.94] - 2022-02-10 - Trying again

## [1.0.93] - 2022-02-10 - Added DeleteExistingMarkdown psaketask in WhatIf mode

## [1.0.92] - 2022-02-10 - Discovered that PlatyPS did not update the markdown file for Get-DirectoryEntry during previous build

## [1.0.91] - 2022-02-10 - Updating help for Get-DirectoryEntry

## [1.0.90] - 2022-02-10 - Updated psake tasks

## [1.0.89] - 2022-02-10 - Wait a minute I already got rid of that WhatIf....oh well got rid of it again

## [1.0.88] - 2022-02-10 - Trying new build with fixed PSGallery API Key

## [1.0.87] - 2022-02-10 - Renamed from PsAdsi to Adsi due to unexpected conflict with unlisted module in PSGallery

## [1.0.86] - 2022-02-10 - Removed WhatIf from PSGallery Publish-Module command in psakefile

## [1.0.85] - 2022-02-10 - Added Git psake task

## [1.0.84] - 2022-02-10 - Repeating with verbose output

## [1.0.83] - 2022-02-10 - Fixed params for Publish-Module

## [1.0.82] - 2022-02-10 - Removing PowerShellbBuild from the equation

## [1.0.81] - 2022-02-10 - Bug fix one line 418 of psakefile

## [1.0.80] - 2022-02-10 - Trying with new API key for PSGallery

## [1.0.79] - 2022-02-10 - Trying again

## [1.0.78] - 2022-02-10 - Removed unnecessary update of PSBPreference variable in UpdateModuleVersion task before the var is created in a later task

## [1.0.76] - 2022-02-09 - more psakefile updates

## [1.0.75] - 2022-02-08 - pipelinified the RotateBuilds psake task

## [1.0.74] - 2022-02-08 - beautified psakefile output

## [1.0.73] - 2022-02-08 - fixed psakefile

## [1.0.72] - 2022-02-08 - more psakefile fixes

## [1.0.71] - 2022-02-08 - more psakefile upgrades

## [1.0.70] - 2022-02-08 - how about now

## [1.0.69] - 2022-02-08 - same as before, but it'll work this time

## [1.0.68] - 2022-02-08 - Fixed path to ScriptAnalyzerSettings.psd1

## [1.0.67] - 2022-02-08 - fixed tests

## [1.0.66] - 2022-02-08 - Always use BuildHelpers

## [1.0.65] - 2022-02-08 - lets try again

## [1.0.64] - 2022-02-08 - more psake fix attempts

## [1.0.63] - 2022-02-08 - Added Remove-Variable to psakefile Init

## [1.0.62] - 2022-02-08 - Removed RO from variable

## [1.0.61] - 2022-02-08 - removed extraneous space

## [1.0.60] - 2022-02-08 - fixed the fix for the fix

## [1.0.59] - 2022-02-08 - fixed the fix

## [1.0.58] - 2022-02-08 - fixed the psakefile upgrades

## [1.0.57] - 2022-02-08 - psakefile and build upgraded

## [1.0.56] - 2022-02-08 - psakefile upgraded

## [1.0.55] - 2022-02-08 - psake upgraded

## [1.0.54] - 2022-02-08 - test

## [1.0.53] - 2022-01-30 - Added task to rotate builds and retain the last 10

## [1.0.52] - 2022-01-30 - Replaced WMI with CIM

## [1.0.51] - 2022-01-29 - Fixed more issues identified by linter

## [1.0.50] - 2022-01-29 - Removed trailing whitespace

## [1.0.49] - 2022-01-29 - Fixed some linting issues

## [1.0.48] - 2022-01-28 - repeat after no changes

## [1.0.47] - 2022-01-28 - Switched from Set-ModuleFunction to Update-Metadata to avoid bug

## [1.0.46] - 2022-01-28 - def got it this time

## [1.0.45] - 2022-01-28 - trying again

## [1.0.44] - 2022-01-28 - same thing again

## [1.0.43] - 2022-01-28 - Updated replacement regex for public func export

## [1.0.42] - 2022-01-28 - Tried again to fix export of public functions

## [1.0.41] - 2022-01-28 - Fixing the automatic export of public functions

## [1.0.40] - 2022-01-28 - No need for src module, all I want is compiled end result

## [1.0.39] - 2022-01-28 - Removed unnecessary var assignment

## [1.0.38] - 2022-01-28 - That worked so let's try more cleanup

## [1.0.37] - 2022-01-28 - Trying BeforeAll again

## [1.0.36] - 2022-01-28 - Now it's really fixed

## [1.0.35] - 2022-01-28 - Project.tests.ps1 is working but shouldn't have the repeat code, just can't get Pester scopes working between scriptblocks

## [1.0.34] - 2022-01-28 - this shouldn't be necessary

## [1.0.33] - 2022-01-28 - how about now

## [1.0.32] - 2022-01-28 - now

## [1.0.31] - 2022-01-28 - again

## [1.0.30] - 2022-01-28 - that should help

## [1.0.29] - 2022-01-28 - that didn't work

## [1.0.28] - 2022-01-28 - how about now

## [1.0.27] - 2022-01-28 - huh

## [1.0.26] - 2022-01-28 - trying again

## [1.0.25] - 2022-01-28 - fake news

## [1.0.24] - 2022-01-28 - lies

## [1.0.23] - 2022-01-28 - Fixed change log tests

## [1.0.22] - 2022-01-28 - Take 4

## [1.0.21] - 2022-01-28 - Take 3

## [1.0.20] - 2022-01-28 - Troubleshooting build process

## [1.0.19] - 2022-01-28 - Fixed Project.tests.ps1

## [1.0.18] - 2022-01-28 - Trying again

## [1.0.17] - 2022-01-28 - Separated changelog tests

## [1.0.16] - 2022-01-28 - Fixed psake file

## [1.0.15] - 2022-01-28 - Tests updated further

## [1.0.14] - 2022-01-28 - Changed tests to target build directory

## [1.0.13] - 2022-01-28 - Streamlining tests

## [1.0.12] - 2022-01-28 - Fixing broken tests

## [1.0.11] - 2022-01-28 - More work on tests

## [1.0.10] - 2022-01-28 - Working on more tests

## [1.0.9] - 2022-01-28 - Working on tests

## [1.0.8] - 2022-01-26 - Another update to PsAdsi.tests.ps1

## [1.0.7] - 2022-01-26 - Updated PsAdsi.tests.ps1 to look at the newly build folder for testing

## [1.0.6] - 2022-01-25 - Added UpdateChangeLog psake task

## [1.0.0] - 2022-01-25 - Initial commit
