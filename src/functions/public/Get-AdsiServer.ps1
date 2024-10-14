function Get-AdsiServer {
    <#
        .SYNOPSIS
        Get information about a directory server including the ADSI provider it hosts and its well-known SIDs
        .DESCRIPTION
        Uses the ADSI provider to query the server using LDAP first, then WinNT upon failure
        Uses WinRM to query the CIM class Win32_SystemAccount for well-known SIDs
        .INPUTS
        [System.String]$Fqdn
        .OUTPUTS
        [PSCustomObject] with AdsiProvider and WellKnownSidBySid properties
        .EXAMPLE
        Get-AdsiServer -Fqdn localhost

        Find the ADSI provider of the local computer
        .EXAMPLE
        Get-AdsiServer -Fqdn 'ad.contoso.com'

        Find the ADSI provider of the AD domain 'ad.contoso.com'
    #>

    [OutputType([System.String])]

    param (

        # IP address or hostname of the directory server whose ADSI provider type to determine
        [Parameter(ValueFromPipeline)]
        [string[]]$Fqdn,

        # NetBIOS name of the ADSI server whose information to determine
        [string[]]$Netbios,

        # Cache of CIM sessions and instances to reduce connections and queries
        [hashtable]$CimCache = ([hashtable]::Synchronized(@{})),

        <#
        Dictionary to cache directory entries to avoid redundant lookups

        Defaults to an empty thread-safe hashtable
        #>
        [hashtable]$DirectoryEntryCache = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain NetBIOS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsByNetbios = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain SIDs as keys and objects with Dns,NetBIOS,SID,DistinguishedName properties as values
        [hashtable]$DomainsBySid = ([hashtable]::Synchronized(@{})),

        # Hashtable with known domain DNS names as keys and objects with Dns,NetBIOS,SID,DistinguishedName,AdsiProvider,Win32Accounts properties as values
        [hashtable]$DomainsByFqdn = ([hashtable]::Synchronized(@{})),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Log messages which have not yet been written to disk
        [hashtable]$LogBuffer = ([hashtable]::Synchronized(@{})),

        # Output stream to send the log messages to
        [ValidateSet('Silent', 'Quiet', 'Success', 'Debug', 'Verbose', 'Output', 'Host', 'Warning', 'Error', 'Information', $null)]
        [string]$DebugOutputStream = 'Debug',

        [switch]$RemoveCimSession,

        # Output from Get-KnownSidHashTable
        [hashtable]$WellKnownSidBySid = (Get-KnownSidHashTable),

        # Output from Get-KnownSidHashTable but keyed by account Name
        [hashtable]$WellKnownSidByName = @{}

    )

    begin {

        $LogParams = @{
            ThisHostname = $ThisHostname
            Type         = $DebugOutputStream
            Buffer       = $LogBuffer
            WhoAmI       = $WhoAmI
        }

        $LogThis = @{
            ThisHostname = $ThisHostname
            LogBuffer    = $LogBuffer
            WhoAmI       = $WhoAmI
        }

        $CacheParams = @{
            DirectoryEntryCache = $DirectoryEntryCache
            DomainsByFqdn       = $DomainsByFqdn
            DomainsByNetbios    = $DomainsByNetbios
            DomainsBySid        = $DomainsBySid
        }

        $CimParams = @{
            CimCache          = $CimCache
            DebugOutputStream = $DebugOutputStream
            ThisFqdn          = $ThisFqdn
        }

    }

    process {

        ForEach ($DomainFqdn in $Fqdn) {

            $OutputObject = $DomainsByFqdn[$DomainFqdn]

            if ($OutputObject) {

                #Write-LogMsg @LogParams -Text " # Domain FQDN cache hit for '$DomainFqdn'"
                $OutputObject
                continue

            }

            #Write-LogMsg @LogParams -Text "Find-AdsiProvider -AdsiServer '$DomainFqdn' # Domain FQDN cache miss for '$DomainFqdn'"
            $AdsiProvider = Find-AdsiProvider -AdsiServer $DomainFqdn -CimCache $CimCache -ThisFqdn $ThisFqdn @LogThis
            $CacheParams['AdsiProvider'] = $AdsiProvider

            Write-LogMsg @LogParams -Text "ConvertTo-DistinguishedName -DomainFQDN '$DomainFqdn' -AdsiProvider '$AdsiProvider' # for '$DomainFqdn'"
            $DomainDn = ConvertTo-DistinguishedName -DomainFQDN $DomainFqdn -AdsiProvider $AdsiProvider -DomainsByFqdn $DomainsByFqdn @LogThis

            Write-LogMsg @LogParams -Text "ConvertTo-DomainSidString -DomainDnsName '$DomainFqdn' -ThisFqdn '$ThisFqdn' # for '$DomainFqdn'"
            $DomainSid = ConvertTo-DomainSidString -DomainDnsName $DomainFqdn -ThisFqdn $ThisFqdn -CimCache $CimCache @CacheParams @LogThis

            Write-LogMsg @LogParams -Text "ConvertTo-DomainNetBIOS -DomainFQDN '$DomainFqdn' # for '$DomainFqdn'"
            $DomainNetBIOS = ConvertTo-DomainNetBIOS -DomainFQDN $DomainFqdn -ThisFqdn $ThisFqdn -CimCache $CimCache @CacheParams @LogThis

            <#
            PS C:\Users\Owner> wmic SYSACCOUNT get name,sid
                Name                           SID
                Everyone                       S-1-1-0
                LOCAL                          S-1-2-0
                CREATOR OWNER                  S-1-3-0
                CREATOR GROUP                  S-1-3-1
                CREATOR OWNER SERVER           S-1-3-2
                CREATOR GROUP SERVER           S-1-3-3
                OWNER RIGHTS                   S-1-3-4
                DIALUP                         S-1-5-1
                NETWORK                        S-1-5-2
                BATCH                          S-1-5-3
                INTERACTIVE                    S-1-5-4
                SERVICE                        S-1-5-6
                ANONYMOUS LOGON                S-1-5-7
                PROXY                          S-1-5-8
                SYSTEM                         S-1-5-18
                ENTERPRISE DOMAIN CONTROLLERS  S-1-5-9
                SELF                           S-1-5-10
                Authenticated Users            S-1-5-11
                RESTRICTED                     S-1-5-12
                TERMINAL SERVER USER           S-1-5-13
                REMOTE INTERACTIVE LOGON       S-1-5-14
                IUSR                           S-1-5-17
                LOCAL SERVICE                  S-1-5-19
                NETWORK SERVICE                S-1-5-20
                BUILTIN                        S-1-5-32

            PS C:\Users\Owner> $logonDomainSid = 'S-1-5-21-1340649458-2707494813-4121304102'
            PS C:\Users\Owner> ForEach ($SidType in [System.Security.Principal.WellKnownSidType].GetEnumNames()) {$var = [System.Security.Principal.WellKnownSidType]::$SidType; [System.Security.Principal.SecurityIdentifier]::new($var,$LogonDomainSid) |Add-Member -PassThru -NotePropertyMembers @{'WellKnownSidType' = $SidType}}

                # PS 5.1 returns fewer results than PS 7.4
                    WellKnownSidType                          BinaryLength AccountDomainSid                          Value
                    ----------------                          ------------ ----------------                          -----
                    NullSid                                             12                                           S-1-0-0
                    WorldSid                                            12                                           S-1-1-0
                    LocalSid                                            12                                           S-1-2-0
                    CreatorOwnerSid                                     12                                           S-1-3-0
                    CreatorGroupSid                                     12                                           S-1-3-1
                    CreatorOwnerServerSid                               12                                           S-1-3-2
                    CreatorGroupServerSid                               12                                           S-1-3-3
                    NTAuthoritySid                                       8                                           S-1-5
                    DialupSid                                           12                                           S-1-5-1
                    NetworkSid                                          12                                           S-1-5-2
                    BatchSid                                            12                                           S-1-5-3
                    InteractiveSid                                      12                                           S-1-5-4
                    ServiceSid                                          12                                           S-1-5-6
                    AnonymousSid                                        12                                           S-1-5-7
                    ProxySid                                            12                                           S-1-5-8
                    EnterpriseControllersSid                            12                                           S-1-5-9
                    SelfSid                                             12                                           S-1-5-10
                    AuthenticatedUserSid                                12                                           S-1-5-11
                    RestrictedCodeSid                                   12                                           S-1-5-12
                    TerminalServerSid                                   12                                           S-1-5-13
                    RemoteLogonIdSid                                    12                                           S-1-5-14
                    Exception calling ".ctor" with "2" argument(s): "Well-known SIDs of type LogonIdsSid cannot be created.
                    Parameter name: sidType"
                    At line:1 char:147
                    + ... ::$SidType; [System.Security.Principal.SecurityIdentifier]::new($var, ...
                    +                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                        + CategoryInfo          : NotSpecified: (:) [], MethodInvocationException
                        + FullyQualifiedErrorId : ArgumentException

                    LocalSystemSid                                      12                                           S-1-5-18
                    LocalServiceSid                                     12                                           S-1-5-19
                    NetworkServiceSid                                   12                                           S-1-5-20
                    BuiltinDomainSid                                    12                                           S-1-5-32
                    BuiltinAdministratorsSid                            16                                           S-1-5-32-544
                    BuiltinUsersSid                                     16                                           S-1-5-32-545
                    BuiltinGuestsSid                                    16                                           S-1-5-32-546
                    BuiltinPowerUsersSid                                16                                           S-1-5-32-547
                    BuiltinAccountOperatorsSid                          16                                           S-1-5-32-548
                    BuiltinSystemOperatorsSid                           16                                           S-1-5-32-549
                    BuiltinPrintOperatorsSid                            16                                           S-1-5-32-550
                    BuiltinBackupOperatorsSid                           16                                           S-1-5-32-551
                    BuiltinReplicatorSid                                16                                           S-1-5-32-552
                    BuiltinPreWindows2000CompatibleAccessSid            16                                           S-1-5-32-554
                    BuiltinRemoteDesktopUsersSid                        16                                           S-1-5-32-555
                    BuiltinNetworkConfigurationOperatorsSid             16                                           S-1-5-32-556
                    AccountAdministratorSid                             28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-500
                    AccountGuestSid                                     28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-501
                    AccountKrbtgtSid                                    28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-502
                    AccountDomainAdminsSid                              28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-512
                    AccountDomainUsersSid                               28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-513
                    AccountDomainGuestsSid                              28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-514
                    AccountComputersSid                                 28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-515
                    AccountControllersSid                               28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-516
                    AccountCertAdminsSid                                28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-517
                    AccountSchemaAdminsSid                              28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-518
                    AccountEnterpriseAdminsSid                          28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-519
                    AccountPolicyAdminsSid                              28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-520
                    AccountRasAndIasServersSid                          28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-553
                    NtlmAuthenticationSid                               16                                           S-1-5-64-10
                    DigestAuthenticationSid                             16                                           S-1-5-64-21
                    SChannelAuthenticationSid                           16                                           S-1-5-64-14
                    ThisOrganizationSid                                 12                                           S-1-5-15
                    OtherOrganizationSid                                12                                           S-1-5-1000
                    BuiltinIncomingForestTrustBuildersSid               16                                           S-1-5-32-557
                    BuiltinPerformanceMonitoringUsersSid                16                                           S-1-5-32-558
                    BuiltinPerformanceLoggingUsersSid                   16                                           S-1-5-32-559
                    BuiltinAuthorizationAccessSid                       16                                           S-1-5-32-560
                    WinBuiltinTerminalServerLicenseServersSid           16                                           S-1-5-32-561
                    MaxDefined                                          16                                           S-1-5-32-561

                # PS 7 returns more results
                    WellKnownSidType                           BinaryLength AccountDomainSid                          Value
                    ----------------                           ------------ ----------------                          -----
                    NullSid                                              12                                           S-1-0-0
                    WorldSid                                             12                                           S-1-1-0
                    LocalSid                                             12                                           S-1-2-0
                    CreatorOwnerSid                                      12                                           S-1-3-0
                    CreatorGroupSid                                      12                                           S-1-3-1
                    CreatorOwnerServerSid                                12                                           S-1-3-2
                    CreatorGroupServerSid                                12                                           S-1-3-3
                    NTAuthoritySid                                        8                                           S-1-5
                    DialupSid                                            12                                           S-1-5-1
                    NetworkSid                                           12                                           S-1-5-2
                    BatchSid                                             12                                           S-1-5-3
                    InteractiveSid                                       12                                           S-1-5-4
                    ServiceSid                                           12                                           S-1-5-6
                    AnonymousSid                                         12                                           S-1-5-7
                    ProxySid                                             12                                           S-1-5-8
                    EnterpriseControllersSid                             12                                           S-1-5-9
                    SelfSid                                              12                                           S-1-5-10
                    AuthenticatedUserSid                                 12                                           S-1-5-11
                    RestrictedCodeSid                                    12                                           S-1-5-12
                    TerminalServerSid                                    12                                           S-1-5-13
                    RemoteLogonIdSid                                     12                                           S-1-5-14
                    MethodInvocationException: Exception calling ".ctor" with "2" argument(s): "Well-known SIDs of type LogonIdsSid cannot be created. (Parameter 'sidType')"
                    LocalSystemSid                                       12                                           S-1-5-18
                    LocalServiceSid                                      12                                           S-1-5-19
                    NetworkServiceSid                                    12                                           S-1-5-20
                    BuiltinDomainSid                                     12                                           S-1-5-32
                    BuiltinAdministratorsSid                             16                                           S-1-5-32-544
                    BuiltinUsersSid                                      16                                           S-1-5-32-545
                    BuiltinGuestsSid                                     16                                           S-1-5-32-546
                    BuiltinPowerUsersSid                                 16                                           S-1-5-32-547
                    BuiltinAccountOperatorsSid                           16                                           S-1-5-32-548
                    BuiltinSystemOperatorsSid                            16                                           S-1-5-32-549
                    BuiltinPrintOperatorsSid                             16                                           S-1-5-32-550
                    BuiltinBackupOperatorsSid                            16                                           S-1-5-32-551
                    BuiltinReplicatorSid                                 16                                           S-1-5-32-552
                    BuiltinPreWindows2000CompatibleAccessSid             16                                           S-1-5-32-554
                    BuiltinRemoteDesktopUsersSid                         16                                           S-1-5-32-555
                    BuiltinNetworkConfigurationOperatorsSid              16                                           S-1-5-32-556
                    AccountAdministratorSid                              28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-500
                    AccountGuestSid                                      28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-501
                    AccountKrbtgtSid                                     28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-502
                    AccountDomainAdminsSid                               28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-512
                    AccountDomainUsersSid                                28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-513
                    AccountDomainGuestsSid                               28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-514
                    AccountComputersSid                                  28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-515
                    AccountControllersSid                                28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-516
                    AccountCertAdminsSid                                 28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-517
                    AccountSchemaAdminsSid                               28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-518
                    AccountEnterpriseAdminsSid                           28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-519
                    AccountPolicyAdminsSid                               28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-520
                    AccountRasAndIasServersSid                           28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-553
                    NtlmAuthenticationSid                                16                                           S-1-5-64-10
                    DigestAuthenticationSid                              16                                           S-1-5-64-21
                    SChannelAuthenticationSid                            16                                           S-1-5-64-14
                    ThisOrganizationSid                                  12                                           S-1-5-15
                    OtherOrganizationSid                                 12                                           S-1-5-1000
                    BuiltinIncomingForestTrustBuildersSid                16                                           S-1-5-32-557
                    BuiltinPerformanceMonitoringUsersSid                 16                                           S-1-5-32-558
                    BuiltinPerformanceLoggingUsersSid                    16                                           S-1-5-32-559
                    BuiltinAuthorizationAccessSid                        16                                           S-1-5-32-560
                    WinBuiltinTerminalServerLicenseServersSid            16                                           S-1-5-32-561
                    MaxDefined                                           16                                           S-1-5-32-561
                    WinBuiltinDCOMUsersSid                               16                                           S-1-5-32-562
                    WinBuiltinIUsersSid                                  16                                           S-1-5-32-568
                    WinIUserSid                                          12                                           S-1-5-17
                    WinBuiltinCryptoOperatorsSid                         16                                           S-1-5-32-569
                    WinUntrustedLabelSid                                 12                                           S-1-16-0
                    WinLowLabelSid                                       12                                           S-1-16-4096
                    WinMediumLabelSid                                    12                                           S-1-16-8192
                    WinHighLabelSid                                      12                                           S-1-16-12288
                    WinSystemLabelSid                                    12                                           S-1-16-16384
                    WinWriteRestrictedCodeSid                            12                                           S-1-5-33
                    WinCreatorOwnerRightsSid                             12                                           S-1-3-4
                    WinCacheablePrincipalsGroupSid                       28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-571
                    WinNonCacheablePrincipalsGroupSid                    28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-572
                    WinEnterpriseReadonlyControllersSid                  12                                           S-1-5-22
                    WinAccountReadonlyControllersSid                     28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-521
                    WinBuiltinEventLogReadersGroup                       16                                           S-1-5-32-573
                    WinNewEnterpriseReadonlyControllersSid               28 S-1-5-21-1340649458-2707494813-4121304102 S-1-5-21-1340649458-2707494813-4121304102-498
                    WinBuiltinCertSvcDComAccessGroup                     16                                           S-1-5-32-574
                    WinMediumPlusLabelSid                                12                                           S-1-16-8448
                    MethodInvocationException: Exception calling ".ctor" with "2" argument(s): "The parameter is incorrect. (Parameter 'sidType/domainSid')"
                    WinConsoleLogonSid                                   12                                           S-1-2-1
                    WinThisOrganizationCertificateSid                    16                                           S-1-5-65-1
                    MethodInvocationException: Exception calling ".ctor" with "2" argument(s): "The parameter is incorrect. (Parameter 'sidType/domainSid')"
                    WinBuiltinAnyPackageSid                              16                                           S-1-15-2-1
                    WinCapabilityInternetClientSid                       16                                           S-1-15-3-1
                    WinCapabilityInternetClientServerSid                 16                                           S-1-15-3-2
                    WinCapabilityPrivateNetworkClientServerSid           16                                           S-1-15-3-3
                    WinCapabilityPicturesLibrarySid                      16                                           S-1-15-3-4
                    WinCapabilityVideosLibrarySid                        16                                           S-1-15-3-5
                    WinCapabilityMusicLibrarySid                         16                                           S-1-15-3-6
                    WinCapabilityDocumentsLibrarySid                     16                                           S-1-15-3-7
                    WinCapabilitySharedUserCertificatesSid               16                                           S-1-15-3-9
                    WinCapabilityEnterpriseAuthenticationSid             16                                           S-1-15-3-8
                    WinCapabilityRemovableStorageSid                     16                                           S-1-15-3-10
            #>

            Write-LogMsg @LogParams -Text "Get-CachedCimInstance -ComputerName '$DomainFqdn' -ClassName 'Win32_Account' # for '$DomainFqdn'"
            $Win32Accounts = Get-CachedCimInstance -ComputerName $DomainFqdn -ClassName 'Win32_Account' -KeyProperty Caption -CacheByProperty @() @CimParams @LogThis

            Write-LogMsg @LogParams -Text "Get-CachedCimInstance -ComputerName '$DomainFqdn' -ClassName 'Win32_Service' # for '$DomainFqdn'"
            $Win32Services = Get-CachedCimInstance -ComputerName $DomainFqdn -ClassName 'Win32_Service' -KeyProperty Name -CacheByProperty @() @CimParams @LogThis

            Write-LogMsg @LogParams -Text "Resolve-ServiceNameToSID -ComputerName '$DomainFqdn' -ThisFqdn $ThisFqdn -ThisHostName $ThisHostName -InputObject `$Win32Services # for '$DomainFqdn'"
            $ResolvedWin32Services = Resolve-ServiceNameToSID -InputObject $Win32Services

            #Add-CachedCimInstance -ComputerName $DomainFqdn -ClassName 'Win32_Service' -InputObject $ResolvedWin32Services -CacheByProperty @('Name', 'SID') -CimCache $CimCache -DebugOutputStream $DebugOutputStream @LogThis
            ConvertTo-AccountCache -Account $Win32Accounts -SidCache $WellKnownSidBySid -NameCache $WellKnownSidByName
            ConvertTo-AccountCache -Account $ResolvedWin32Services -SidCache $WellKnownSidBySid -NameCache $WellKnownSidByName

            $OutputObject = [PSCustomObject]@{
                DistinguishedName  = $DomainDn
                Dns                = $DomainFqdn
                Sid                = $DomainSid
                Netbios            = $DomainNetBIOS
                AdsiProvider       = $AdsiProvider
                #Win32Accounts      = $Win32Accounts
                #Win32Services      = $ResolvedWin32Services
                WellKnownSidBySid  = $WellKnownSidBySid
                WellKnownSidByName = $WellKnownSidByName
            }

            $DomainsBySid[$OutputObject.Sid] = $OutputObject
            $DomainsByNetbios[$OutputObject.Netbios] = $OutputObject
            $DomainsByFqdn[$DomainFqdn] = $OutputObject
            $OutputObject

        }

        ForEach ($DomainNetbios in $Netbios) {

            $OutputObject = $DomainsByNetbios[$DomainNetbios]

            if ($OutputObject) {

                #Write-LogMsg @LogParams -Text " # Domain NetBIOS cache hit for '$DomainNetbios'"
                $OutputObject
                continue

            }

            #Write-LogMsg @LogParams -Text "Get-CachedCimSession -ComputerName '$DomainNetbios' # Domain NetBIOS cache miss for '$DomainNetbios'"
            $CimSession = Get-CachedCimSession -ComputerName $DomainNetbios -ThisFqdn $ThisFqdn -CimCache $CimCache @LogThis

            Write-LogMsg @LogParams -Text "Find-AdsiProvider -AdsiServer '$DomainDnsName' # for '$DomainNetbios'"
            $AdsiProvider = Find-AdsiProvider -AdsiServer $DomainDnsName -CimCache $CimCache -ThisFqdn $ThisFqdn @LogThis
            $CacheParams['AdsiProvider'] = $AdsiProvider

            Write-LogMsg @LogParams -Text "ConvertTo-DistinguishedName -Domain '$DomainNetBIOS' # for '$DomainNetbios'"
            $DomainDn = ConvertTo-DistinguishedName -Domain $DomainNetBIOS -DomainsByNetbios $DomainsByNetbios -DomainsByFqdn $DomainsByFqdn @LogThis

            if ($DomainDn) {

                Write-LogMsg @LogParams -Text "ConvertTo-Fqdn -DistinguishedName '$DomainDn' # for '$DomainNetbios'"
                $DomainDnsName = ConvertTo-Fqdn -DistinguishedName $DomainDn -ThisFqdn $ThisFqdn -CimCache $CimCache @LogThis

            } else {

                $ParentDomainDnsName = Get-ParentDomainDnsName -DomainsByNetbios $DomainNetBIOS -CimSession $CimSession -ThisFqdn $ThisFqdn -CimCache $CimCache @LogThis
                $DomainDnsName = "$DomainNetBIOS.$ParentDomainDnsName"

            }

            Write-LogMsg @LogParams -Text "ConvertTo-DomainSidString -DomainDnsName '$DomainFqdn' -AdsiProvider '$AdsiProvider' -ThisFqdn '$ThisFqdn' # for '$DomainNetbios'"
            $DomainSid = ConvertTo-DomainSidString -DomainDnsName $DomainDnsName -ThisFqdn $ThisFqdn -CimCache $CimCache @CacheParams @LogThis

            Write-LogMsg @LogParams -Text "Get-CachedCimInstance -ComputerName '$DomainDnsName' -ClassName 'Win32_Account' # for '$DomainNetbios'"
            $Win32Accounts = Get-CachedCimInstance -ComputerName $DomainDnsName -ClassName 'Win32_Account' -KeyProperty Caption -CacheByProperty @('Caption', 'SID') @CimParams @LogThis

            Write-LogMsg @LogParams -Text "Get-CachedCimInstance -ComputerName '$DomainDnsName' -ClassName 'Win32_Service' # for '$DomainNetbios'"
            $Win32Services = Get-CachedCimInstance -ComputerName $DomainDnsName -ClassName 'Win32_Service' -KeyProperty Name -CacheByProperty @() @CimParams @LogThis

            Write-LogMsg @LogParams -Text "Resolve-ServiceNameToSID -ComputerName '$DomainDnsName' -ThisFqdn $ThisFqdn -ThisHostName $ThisHostName -InputObject `$Win32Services # for '$DomainFqdn'"
            $ResolvedWin32Services = Resolve-ServiceNameToSID -InputObject $Win32Services
            Add-CachedCimInstance -ComputerName $DomainDnsName -ClassName 'Win32_Service' -InputObject $ResolvedWin32Services -CacheByProperty @('Name', 'SID') @CimParams @LogThis

            if ($RemoveCimSession) {
                Remove-CimSession -CimSession $CimSession
            }

            $OutputObject = [PSCustomObject]@{
                DistinguishedName  = $DomainDn
                Dns                = $DomainDnsName
                Sid                = $DomainSid
                Netbios            = $DomainNetBIOS
                AdsiProvider       = $AdsiProvider
                Win32Accounts      = $Win32Accounts
                Win32Services      = $ResolvedWin32Services
                WellKnownSidBySid  = $WellKnownSidBySid
                WellKnownSidByName = $WellKnownSidByName
            }

            $DomainsBySid[$OutputObject.Sid] = $OutputObject
            $DomainsByNetbios[$OutputObject.Netbios] = $OutputObject
            $DomainsByFqdn[$OutputObject.Dns] = $OutputObject
            $OutputObject

        }

    }

}
