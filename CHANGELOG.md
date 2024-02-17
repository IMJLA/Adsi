# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## [4.0.62] - 2024-02-17 - bugfix get-directoryentryproperty param name fka propertytable

## [4.0.61] - 2024-02-17 - troubleshoot convertfrom-identityreferenceresolved

## [4.0.60] - 2024-02-17 - troubleshoot convertfrom-identityreferenceresolved

## [4.0.59] - 2024-02-17 - add get-directoryentryproperty in convertfrom-identityreferenceresolved

## [4.0.58] - 2024-02-12 - bugfix convertfrom-identityreferenceresolved missing update ace cache for group members

## [4.0.57] - 2024-02-12 - code cleanup

## [4.0.56] - 2024-02-12 - bugfix convertfrom-identityreferenceresolved

## [4.0.55] - 2024-02-12 - bugfix convertfrom-identityreferenceresolved

## [4.0.54] - 2024-02-11 - mega caching

## [4.0.53] - 2024-02-11 - bugfix convertfrom-identityreferenceresolved

## [4.0.52] - 2024-02-11 - bugfix resolve-ace and resolve-identityreference

## [4.0.51] - 2024-02-11 - bugfix resolve-acl

## [4.0.50] - 2024-02-11 - implement resolve-acl

## [4.0.49] - 2024-02-11 - troubleshoot convertfrom-identityreferenceresolved

## [4.0.48] - 2024-02-11 - fix caching convertfrom-identityreferenceresolved

## [4.0.47] - 2024-02-10 - troubleshoot convertfrom-identityreferenceresolved

## [4.0.46] - 2024-02-10 - troubleshoot convertfrom-identityreferenceresolved

## [4.0.45] - 2024-02-10 - troubleshoot convertfrom-identityreferenceresolved

## [4.0.44] - 2024-02-10 - update comment

## [4.0.43] - 2024-02-10 - efficiency improvement get-currentdomain added sidstring output prop

## [4.0.42] - 2024-02-10 - troubleshoot convertfrom-identityreferenceresolved

## [4.0.41] - 2024-02-10 - troubleshoot convertfrom-identityreferenceresolved

## [4.0.40] - 2024-02-10 - troubleshoot convertfrom-identityreferenceresolved

## [4.0.39] - 2024-02-10 - add caching to resolve-ace to avoid using group-object later

## [4.0.38] - 2024-02-05 - expanded cim caching

## [4.0.37] - 2024-02-05 - updated passing of params to get-directoryentry (some still missing)

## [4.0.36] - 2024-02-05 - add cim caching to get-directoryentry and search-directory

## [4.0.35] - 2024-02-05 - bugfix missing .SID property before LastIndexOf method

## [4.0.34] - 2024-02-05 - more cim caching

## [4.0.33] - 2024-02-04 - implement cim caching

## [4.0.32] - 2024-02-04 - working on cim caching

## [4.0.31] - 2024-02-04 - cleanup whitespace

## [4.0.30] - 2024-02-04 - update comments and debug output

## [4.0.29] - 2024-02-04 - rename expand-identityreference to convertfrom-identityreferenceresolved

## [4.0.28] - 2024-02-03 - ps 5.1 workaround

## [4.0.27] - 2024-02-03 - commented ps5.1-incompatible class attribute

## [4.0.26] - 2024-02-02 - cleaner debug output expand-identityreference

## [4.0.25] - 2024-02-02 - add debug output to expand-identityreference

## [4.0.24] - 2024-02-02 - add debug output to expand-identityreference

## [4.0.23] - 2024-02-02 - add more debugoutputstream usage to expand-identityreference

## [4.0.22] - 2024-02-02 - implement DebugOutputStream param

## [4.0.21] - 2024-01-31 - rename resolve-ace3 back to resolve-ace

## [4.0.20] - 2024-01-31 - oops

## [4.0.19] - 2024-01-31 - reverted to function New-FakeDirectoryEntry instead of PS Class due to class limitations

## [4.0.18] - 2024-01-28 - replace remaining instances of write-debug/warning with write-logmsg

## [4.0.17] - 2024-01-28 - replace remaining instances of write-debug/warning with write-logmsg

## [4.0.16] - 2024-01-28 - updated warning output in expand-identityreference

## [4.0.15] - 2024-01-28 - bugfix and code cleanup fakedirectoryentry class

## [4.0.14] - 2024-01-28 - removed resolve-ace

## [4.0.13] - 2024-01-28 - bug workaround duplicate SchemaClassName in FakeDirectoryEntry class

## [4.0.12] - 2024-01-28 - Updated to show progress in single-threaded mode Resolve-Ace and Resolve-Ace3

## [4.0.11] - 2024-01-28 - Added support for additional built-in accounts to Get-DirectoryEntry

## [4.0.10] - 2024-01-27 - bugfix resolve-identityreference and get-directoryentry

## [4.0.9] - 2024-01-27 - bugfix resolve-identityreference usinv invalid param when calling add-domainfqdntoldappath

## [4.0.8] - 2024-01-27 - bugfix resolve-identityreference calls to get-directoryentry.  also optimize expand-identityreference

## [4.0.7] - 2024-01-21 - bugfix Get-TrustedDomain suppress nltest errors from transcript

## [4.0.6] - 2024-01-21 - enhancement-performance remove usage of select-object -first

## [4.0.5] - 2024-01-15 - bugfix forgot to replace new-fakedirectoryentry with fakedirectoryentry constructor in get-directoryentry

## [4.0.4] - 2024-01-15 - added comments to FakeDirectoryEntry class

## [4.0.3] - 2024-01-15 - replaced New-FakeDirectoryEntry with FakeDirectoryEntry class

## [4.0.2] - 2024-01-15 - fix double-domain bug in Win32AccountCaptionCache in Get-AdsiServer and Resolve-IdentityReference;fix OnlyReturnLastWinNTGroupMember bug in Get-WinNTGroupMember

## [4.0.1] - 2024-01-15 - Added support for non-domain-joined local computers to Get-CurrentDomain

## [4.0.0] - 2024-01-13 - removed Find-ServerNameInPath (belongs in PsNtfs module more than Adsi module)

## [3.0.57] - 2022-09-03 - removed repetitive timestamps from get-directoryentry

## [3.0.56] - 2022-09-03 - Implemented support for LDAP "members" who have a group as their Primary Group

## [3.0.55] - 2022-09-03 - Implemented support for LDAP "members" who have a group as their Primary Group

## [3.0.54] - 2022-09-03 - Implemented support for LDAP "members" who have a group as their Primary Group

## [3.0.53] - 2022-09-03 - Implemented support for LDAP "members" who have a group as their Primary Group

## [3.0.52] - 2022-08-31 - Added convertfrom-searchresult and convertfrom-resultpropertyvaluecollectiontostring

## [3.0.51] - 2022-08-31 - Added convertfrom-searchresult and convertfrom-resultpropertyvaluecollectiontostring

## [3.0.50] - 2022-08-31 - Added convertfrom-searchresult and convertfrom-resultpropertyvaluecollectiontostring

## [3.0.49] - 2022-08-27 - bugfix for ps 5.1 (removed redundant -ThisHostname param usage when already including that in the splat)

## [3.0.48] - 2022-08-27 - improved handling of CIM sessions by Get-AdsiServer and dependencies

## [3.0.47] - 2022-08-26 - Added -replace operation to caption in Resolve-IdentityReference to ensure correct capitalization of hostname in IdentityReferenceNetBios prop

## [3.0.46] - 2022-08-26 - Added -replace operation to caption in Resolve-IdentityReference to ensure correct capitalization of hostname in IdentityReferenceNetBios prop

## [3.0.45] - 2022-08-26 - Debug output cleanup

## [3.0.44] - 2022-08-26 - Removed metadata from debug output (now inserted by Write-LogMsg)

## [3.0.43] - 2022-08-26 - Implemented LogMsgCache and WhoAmI params for Write-LogMsg

## [3.0.42] - 2022-08-25 - bugfix Resolve-IdentityReference missing DirectoryEntryCache param

## [3.0.41] - 2022-08-25 - bugfix ConvertTo-DomainNetBIOS to handle non-FQDN FQDNs

## [3.0.40] - 2022-08-25 - bugfix get-adsiserver typo in param name for get-win32account

## [3.0.39] - 2022-08-25 - bugfix was not using cache properly in resolve-ace

## [3.0.38] - 2022-08-25 - bugfix was not using cache properly in resolve-ace

## [3.0.37] - 2022-08-25 - fixed ReadMe

## [3.0.36] - 2022-08-25 - trying build script fix

## [3.0.35] - 2022-08-25 - Testing updated build script

## [3.0.34] - 2022-08-25 - Testing updated build script

## [3.0.33] - 2022-08-25 - Added AdsiProvider param to Get-Win32Account to reduce calls to Find-AdsiProvider

## [3.0.32] - 2022-08-25 - Fixed psake bug publish-module vs publish-script

## [3.0.31] - 2022-08-25 - troubleshoot psgallery publication

## [3.0.30] - 2022-08-25 - further implemented ThisHostname param, also implemented ThisFqdn

## [3.0.29] - 2022-08-25 - improved comment-based help

## [3.0.28] - 2022-08-25 - fixed broken psd1 file

## [3.0.27] - 2022-08-25 - merge conflicts resolved

## [3.0.26] - 2022-08-25 - Debug output improvements for resolve-identityreference

## [3.0.25] - 2022-08-25 - Reduced usage of Find-AdsiProvider by adding -AdsiServer param for when it is already known

## [3.0.24] - 2022-08-24 - Removed AdsiServersByDns, Get-WellKnownSid, Get-DomainInfo, Get-TrustedDomainInfo

## [3.0.23] - 2022-08-24 - bugfixes in Get-AdsiServer

## [3.0.22] - 2022-08-24 - Get-TrustedDomain, Get-Win32Account, and upgrades to Get-AdsiServer. Deprecated Get-WellKnownSid and Get-TrustedDomainInfo

## [3.0.21] - 2022-08-22 - Improved caching

## [3.0.20] - 2022-08-21 - Efficiency and debug output improvements for Expand-IdentityReference

## [3.0.19] - 2022-08-17 - test version of resolve-ace

## [3.0.18] - 2022-08-17 - test version of resolve-ace

## [3.0.17] - 2022-08-17 - test version of resolve-ace

## [3.0.16] - 2022-08-17 - test build

## [3.0.15] - 2022-08-14 - bugfix in Add-SidInfo

## [3.0.14] - 2022-08-14 - bugfix in resolve-identityreference and improved debug output in expand-identityreference

## [3.0.13] - 2022-08-14 - changes to expand-identityreference

## [3.0.12] - 2022-08-06 - bugfix for winnt groups in expand-identityreference

## [3.0.11] - 2022-08-05 - bugfixes and readability improvements

## [3.0.10] - 2022-08-05 - bugfix in expand-identityreference, needed FullMembers property of Get-AdsiGroupMember output

## [3.0.9] - 2022-08-05 - Readability improvements

## [3.0.8] - 2022-08-05 - Caching fix in Resolve-IdentityReference

## [3.0.7] - 2022-08-05 - Bug fix in Get-WinNTGroupMember when detecting domain vs local users

## [3.0.6] - 2022-08-05 - Added missing cache param on get-adsiserver

## [3.0.5] - 2022-08-05 - Latest build

## [3.0.4] - 2022-08-05 - Implemented broader caching, fixed many bugs

## [3.0.3] - 2022-08-01 - Improved caching in Resolve-IdentityReference (more improvements possible but this will do, pig)

## [3.0.2] - 2022-07-31 - Bug fix in ConvertFrom-DirectoryEntry

## [3.0.1] - 2022-07-31 - Added ConvertFrom-DirectoryEntry

## [3.0.0] - 2022-07-31 - Removed Find-ServerNameInPath because it belongs in the PsNtfs module (it parses file paths)

## [2.0.7] - 2022-07-30 - Added error prevention to Get-TrustedDomainSidNameMap and Expand-IdentityReference

## [2.0.6] - 2022-07-30 - Added some error prevention in Get-TrustedDomainSidNameMap

## [2.0.5] - 2022-07-25 - Updated source psm1 file

## [2.0.4] - 2022-07-25 - testing psakefile changes

## [2.0.3] - 2022-07-25 - Changed TrustedInstaller to a User instead of a group in New-FakeDirectoryEntry

## [2.0.2] - 2022-07-24 - Efficiency improvements for Resolve-IdentityReference

## [2.0.1] - 2022-07-24 - Added TrustedInstaller to Get-DirectoryEntry as a system account to be mocked using New-FakeDirectoryEntry

## [2.0.0] - 2022-07-24 - Major breaking changes, functions removed, parameters modified.  Especially Resolve-IdentityReference and Expand-IdentityReference had significant changes.  Added Resolve-ACE and Expand-IdentityReference

## [1.0.204] - 2022-07-09 - Changed GroupMember boolean parameter on Expand-IdentityReference to a NoGroupMembers switch parameter

## [1.0.203] - 2022-07-08 - New version to publish to PSGallery

## [1.0.202] - 2022-07-08 - Applied consistent capitalization for ADSI in Cmdlet names (use Adsi for readability)

## [1.0.201] - 2022-07-08 - Removed useless GroupMemberRecursion parameter

## [1.0.200] - 2022-07-08 - Efficiency improvement in Expand-IdentityReference

## [1.0.199] - 2022-07-08 - Added ConvertFrom-PropertyValueCollectionToString

## [1.0.198] - 2022-07-08 - added missing single quotes in debug messages of Expand-WinNTGroupMember

## [1.0.197] - 2022-06-26 - Added ConvertTo-DecStringRepresentation

## [1.0.196] - 2022-06-25 - added debug outout to Find-AdsiProvider

## [1.0.195] - 2022-06-19 - Bug fixing in Add-SidInfo

## [1.0.194] - 2022-06-19 - Suppressed errors on the Invoke method in Get-WinNTGroupMember

## [1.0.193] - 2022-06-19 - Error handling for SecurityIdentifier constructor in begin block of Expand-IdentityReference

## [1.0.192] - 2022-06-19 - Added error handling for all RefreshCache method calls

## [1.0.191] - 2022-06-19 - Improved error handling in Expand-AdsiGroupMember

## [1.0.190] - 2022-06-19 - Bug fix in Get-TrustedDomainSidNameMap with the KeyByNetBios switch

## [1.0.189] - 2022-06-19 - Troubleshooting missing debug messages from Get-WinNTGroupMember

## [1.0.188] - 2022-06-19 - Troubleshooting missing debug messages from Get-WinNTGroupMember

## [1.0.187] - 2022-06-19 - Added another debug message to Get-WinNTGroupMember

## [1.0.186] - 2022-06-19 - Added debug message to Get-WinNTGroupMember

## [1.0.185] - 2022-06-19 - Added another debug message to Expand-IdentityReference

## [1.0.184] - 2022-06-19 - Added handling for another type of WinNT result (INTERACTIVE and Authenticated Users) where we get a hashtable with an objectSID key

## [1.0.183] - 2022-06-19 - Added handling for INTERACTIVE and Authenticated Users in Expand-WinNTGroupMember

## [1.0.182] - 2022-06-19 - Breaking Expand-WinNTGroupMember

## [1.0.181] - 2022-06-19 - Added debugging to Expand-IdentityReference

## [1.0.180] - 2022-06-19 - Troubleshooting and probably breaking Get-WinNTGroupMember

## [1.0.179] - 2022-06-19 - Moved Get-WellKnownSid functionality into dedicated function

## [1.0.178] - 2022-06-19 - Bug fix in Resolve-IdentityReference

## [1.0.177] - 2022-06-19 - Fixed CIM session creation in Resolve-IdentityReference

## [1.0.176] - 2022-06-19 - Added debug output to Resolve-IdentityReference

## [1.0.175] - 2022-06-19 - Removed unnecessary begin block from Resolve-IdentityReference

## [1.0.174] - 2022-06-19 - Updated Resolve-IdentityReference to use the Path property on Input objects, also removed Add-Member for performance reasons

## [1.0.173] - 2022-06-19 - Removed usage of custom classes in favor of PSCustomObject

## [1.0.172] - 2022-06-19 - Removed explicit dependency on PsNtfs module

## [1.0.171] - 2022-06-19 - Trying again but I think prereqs are messed up

## [1.0.170] - 2022-06-19 - Changed Input type for Resolve-IdentityReference

## [1.0.169] - 2022-06-18 - Bug fixes in Resolve-IdentityReference

## [1.0.168] - 2022-06-18 - VS Code lies

## [1.0.167] - 2022-06-18 - Removed Write-Output to improve performance at large scale

## [1.0.166] - 2022-06-18 - Updated inputs in help docs for most functions

## [1.0.165] - 2022-06-17 - Typo corrected

## [1.0.164] - 2022-06-17 - last regex fix for fixmarkdownhelp I promise

## [1.0.163] - 2022-06-17 - Suspect problem in build environment, trying build again

## [1.0.162] - 2022-06-17 - Forgot to uncomment Set-Content in FixMarkdownHelp

## [1.0.161] - 2022-06-17 - Fixed RegEx in FixMarkdownHelp psake task

## [1.0.160] - 2022-06-16 - test

## [1.0.159] - 2022-06-16 - Fixed regex in FixMardownHelp psake task

## [1.0.158] - 2022-06-16 - Fixed bug in build process

## [1.0.157] - 2022-06-16 - Fixed bug in build process

## [1.0.156] - 2022-06-16 - Fixed bug in build process

## [1.0.155] - 2022-06-16 - Fixed the loop through the keys in the ExportedCommands dictionary in FixMarkdownHelp psake task

## [1.0.154] - 2022-06-16 - Trying utf8 encoding for the output of FixMarkdownHelp

## [1.0.153] - 2022-06-16 - Fixed sequence of events in FixMarkdownHelp psake build task

## [1.0.152] - 2022-06-16 - Implemented FixMarkdownHelp psake task

## [1.0.151] - 2022-06-16 - Added FixMarkDownHelp psake task

## [1.0.150] - 2022-06-16 - Updated parameters for New-MarkDownHelp in psakeFile.ps1

## [1.0.149] - 2022-06-16 - Updated parameters for New-MarkDownHelp in psakeFile.ps1

## [1.0.148] - 2022-06-16 - Updated parameters for New-MarkDownHelp in psakeFile.ps1

## [1.0.147] - 2022-06-16 - Updated parameters for New-MarkDownHelp in psakeFile.ps1

## [1.0.146] - 2022-06-16 - Updated parameters for New-MarkDownHelp in psakeFile.ps1

## [1.0.145] - 2022-06-16 - Trying to regenerate docs

## [1.0.144] - 2022-06-16 - Replace README

## [1.0.143] - 2022-06-06 - Now I really fixed it

## [1.0.142] - 2022-06-06 - trying again

## [1.0.141] - 2022-06-06 - fixed Function.tests.ps1

## [1.0.140] - 2022-06-06 - Removed tests for Test-PublicFunction, added basic standardized function tests

## [1.0.139] - 2022-06-06 - Removed Test-PublicFunction

## [1.0.138] - 2022-06-06 - Commented Search-Directory

## [1.0.137] - 2022-06-05 - Updated Resolve-IdentityReference

## [1.0.136] - 2022-06-03 - Minor performance improvements and comment-based help on all functions up through the I's.  The I's have it

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
