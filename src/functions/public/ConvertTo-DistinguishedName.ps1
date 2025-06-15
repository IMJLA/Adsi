function ConvertTo-DistinguishedName {

    <#
    .SYNOPSIS

    Convert a domain NetBIOS name to its distinguishedName
    .DESCRIPTION
    https://docs.microsoft.com/en-us/windows/win32/api/iads/nn-iads-iadsnametranslate
    .INPUTS
    [System.String]$Domain
    .OUTPUTS
    [System.String] distinguishedName of the domain
    .EXAMPLE
    ConvertTo-DistinguishedName -Domain 'CONTOSO' -Cache $Cache

    Resolves the NetBIOS domain name 'CONTOSO' to its distinguished name format 'DC=ad,DC=contoso,DC=com'.
    This conversion is necessary when constructing LDAP queries that require the domain in distinguished
    name format, particularly when working with Active Directory objects across different domains or forests.
    The function utilizes Windows API calls to perform accurate name translation.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertTo-DistinguishedName')]

    [OutputType([System.String])]


    param (

        # NetBIOS name of the domain
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'NetBIOS')]
        [string[]]$Domain,

        # FQDN of the domain
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'FQDN')]
        [string[]]$DomainFQDN,

        # Type of initialization to be performed
        # Will be translated to the corresponding integer for use as the lnSetType parameter of the IADsNameTranslate::Init method (iads.h)
        # https://docs.microsoft.com/en-us/windows/win32/api/iads/ne-iads-ads_name_inittype_enum
        [string]$InitType = 'ADS_NAME_INITTYPE_GC',

        # Format of the name of the directory object that will be used for the input
        # Will be translated to the corresponding integer for use as the lnSetType parameter of the IADsNameTranslate::Set method (iads.h)
        # https://docs.microsoft.com/en-us/windows/win32/api/iads/ne-iads-ads_name_type_enum
        [string]$InputType = 'ADS_NAME_TYPE_NT4',

        # Format of the name of the directory object that will be used for the output
        # Will be translated to the corresponding integer for use as the lnSetType parameter of the IADsNameTranslate::Get method (iads.h)
        # https://docs.microsoft.com/en-us/windows/win32/api/iads/ne-iads-ads_name_type_enum
        [string]$OutputType = 'ADS_NAME_TYPE_1779',

        <#
        AdsiProvider (WinNT or LDAP) of the servers associated with the provided FQDNs or NetBIOS names

        This parameter can be used to reduce calls to Find-AdsiProvider

        Useful when that has been done already but the DomainByFqdn and DomainByNetbios caches have not been updated yet
        #>

        [string]$AdsiProvider,

        # In-process cache to reduce calls to other processes or to disk
        [Parameter(Mandatory)]
        [ref]$Cache




    )




    begin {

        $DomainByNetbios = $Cache.Value['DomainByNetbios']
        $DomainByFqdn = $Cache.Value['DomainByFqdn']

        # Declare constants for these Windows enums
        # We need to because PowerShell makes it hard to directly use the Win32 API and read the enum definition
        # Use hashtables instead of enums since this use case is so simple
        $ADS_NAME_INITTYPE_dict = @{
            ADS_NAME_INITTYPE_DOMAIN = 1 #Initializes a NameTranslate object by setting the domain that the object binds to.
            ADS_NAME_INITTYPE_SERVER = 2 #Initializes a NameTranslate object by setting the server that the object binds to.
            ADS_NAME_INITTYPE_GC     = 3 #Initializes a NameTranslate object by locating the global catalog that the object binds to.
        }

        $ADS_NAME_TYPE_dict = @{
            ADS_NAME_TYPE_1779                    = 1 #Name format as specified in RFC 1779. For example, "CN=Jeff Smith,CN=users,DC=Fabrikam,DC=com".
            ADS_NAME_TYPE_CANONICAL               = 2 #Canonical name format. For example, "Fabrikam.com/Users/Jeff Smith".
            ADS_NAME_TYPE_NT4                     = 3 #Account name format used in Windows. For example, "Fabrikam\JeffSmith".
            ADS_NAME_TYPE_DISPLAY                 = 4 #Display name format. For example, "Jeff Smith".
            ADS_NAME_TYPE_DOMAIN_SIMPLE           = 5 #Simple domain name format. For example, "JeffSmith@Fabrikam.com".
            ADS_NAME_TYPE_ENTERPRISE_SIMPLE       = 6 #Simple enterprise name format. For example, "JeffSmith@Fabrikam.com".
            ADS_NAME_TYPE_GUID                    = 7 #Global Unique Identifier format. For example, "{95ee9fff-3436-11d1-b2b0-d15ae3ac8436}".
            ADS_NAME_TYPE_UNKNOWN                 = 8 #Unknown name type. The system will estimate the format. This element is a meaningful option only with the IADsNameTranslate.Set or the IADsNameTranslate.SetEx method, but not with the IADsNameTranslate.Get or IADsNameTranslate.GetEx method.
            ADS_NAME_TYPE_USER_PRINCIPAL_NAME     = 9 #User principal name format. For example, "JeffSmith@Fabrikam.com".
            ADS_NAME_TYPE_CANONICAL_EX            = 10 #Extended canonical name format. For example, "Fabrikam.com/Users Jeff Smith".
            ADS_NAME_TYPE_SERVICE_PRINCIPAL_NAME  = 11 #Service principal name format. For example, "www/www.fabrikam.com@fabrikam.com".
            ADS_NAME_TYPE_SID_OR_SID_HISTORY_NAME = 12 #A SID string, as defined in the Security Descriptor Definition Language (SDDL), for either the SID of the current object or one from the object SID history. For example, "O:AOG:DAD:(A;;RPWPCCDCLCSWRCWDWOGA;;;S-1-0-0)"
        }

        $ChosenInitType = $ADS_NAME_INITTYPE_dict[$InitType]
        $ChosenInputType = $ADS_NAME_TYPE_dict[$InputType]
        $ChosenOutputType = $ADS_NAME_TYPE_dict[$OutputType]

    }

    process {

        ForEach ($ThisDomain in $Domain) {

            $DomainCacheResult = $null
            $TryGetValueResult = $DomainByNetbios.Value.TryGetValue($ThisDomain, [ref]$DomainCacheResult)

            if ($TryGetValueResult) {

                #Write-LogMsg -Text " # Domain NetBIOS cache hit for '$ThisDomain'" -Cache $Cache
                $DomainCacheResult.DistinguishedName

            } else {

                #Write-LogMsg -Text " # Domain NetBIOS cache miss for '$ThisDomain'. Available keys: $($Cache.Value['DomainByNetbios'].Value.Keys -join ',')"
                Write-LogMsg -Text "`$IADsNameTranslateComObject = New-Object -comObject 'NameTranslate' # For '$ThisDomain'" -Cache $Cache
                $IADsNameTranslateComObject = New-Object -ComObject 'NameTranslate'
                Write-LogMsg -Text "`$IADsNameTranslateInterface = `$IADsNameTranslateComObject.GetType() # For '$ThisDomain'" -Cache $Cache
                $IADsNameTranslateInterface = $IADsNameTranslateComObject.GetType()
                Write-LogMsg -Text "`$null = `$IADsNameTranslateInterface.InvokeMember('Init', 'InvokeMethod', `$Null, `$IADsNameTranslateComObject, ($ChosenInitType, `$Null)) # For '$ThisDomain'" -Cache $Cache

                # Handle errors for this method
                #    Exception calling "InvokeMember" with "5" argument(s): "The specified domain either does not exist or could not be contacted. (0x8007054B)"
                try {
                    $null = $IADsNameTranslateInterface.InvokeMember('Init', 'InvokeMethod', $Null, $IADsNameTranslateComObject, ($ChosenInitType, $Null))
                } catch {

                    Write-LogMsg -Text " #Error: $($_.Exception.Message) # For $ThisDomain" -Cache $Cache
                    continue

                }

                # For a non-domain-joined system there is no DistinguishedName for the domain
                # Suppress errors when calling these next 2 methods
                #     Exception calling "InvokeMember" with "5" argument(s): "Name translation: Could not find the name or insufficient right to see name. (Exception from HRESULT: 0x80072116)"
                Write-LogMsg -Text "`$null = `$IADsNameTranslateInterface.InvokeMember('Set', 'InvokeMethod', `$Null, `$IADsNameTranslateComObject, ($ChosenInputType, '$ThisDomain\')) # For '$ThisDomain'" -Cache $Cache
                $null = { $IADsNameTranslateInterface.InvokeMember('Set', 'InvokeMethod', $Null, $IADsNameTranslateComObject, ($ChosenInputType, "$ThisDomain\")) } 2>$null
                #     Exception calling "InvokeMember" with "5" argument(s): "Unspecified error (Exception from HRESULT: 0x80004005 (E_FAIL))"
                Write-LogMsg -Text "`$IADsNameTranslateInterface.InvokeMember('Get', 'InvokeMethod', `$Null, `$IADsNameTranslateComObject, $ChosenOutputType) # For '$ThisDomain'" -Cache $Cache
                $null = { $null = { $IADsNameTranslateInterface.InvokeMember('Get', 'InvokeMethod', $Null, $IADsNameTranslateComObject, $ChosenOutputType) } 2>$null } 2>$null

            }

        }

        ForEach ($ThisDomain in $DomainFQDN) {

            $DomainCacheResult = $null
            $TryGetValueResult = $DomainByFqdn.Value.TryGetValue($ThisDomain, [ref]$DomainCacheResult)

            if ($TryGetValueResult) {

                #Write-LogMsg -Text " # Domain FQDN cache hit for '$ThisDomain'" -Cache $Cache
                $DomainCacheResult.DistinguishedName

            } else {

                #Write-LogMsg -Text " # Domain FQDN cache miss for '$ThisDomain'" -Cache $Cache

                if (-not $PSBoundParameters.ContainsKey('AdsiProvider')) {
                    $AdsiProvider = Find-AdsiProvider -AdsiServer $ThisDomain -Cache $Cache
                }

                if ($AdsiProvider -ne 'WinNT') {
                    "dc=$($ThisDomain.Replace('.', ',dc='))"
                }

            }

        }

    }

}
