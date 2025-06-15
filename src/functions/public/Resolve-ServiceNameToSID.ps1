function Resolve-ServiceNameToSID {

    <#
    .SYNOPSIS

        Resolves Windows service names to their corresponding security identifiers (SIDs).
    .DESCRIPTION
        This function takes service objects (from Get-Service or Win32_Service) and
        calculates their corresponding SIDs using the same algorithm as sc.exe showsid.
        It enriches the input service objects with SID and Status and returns the
        enhanced objects with all original properties preserved.
    .EXAMPLE
        Get-Service -Name "BITS" | Resolve-ServiceNameToSID

        Remark: This example retrieves the Background Intelligent Transfer Service and resolves its service name to a SID.
        The output includes all original properties of the service plus the SID property.
    #>

    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Resolve-ServiceNameToSID')]

    param (

        # Output of Get-Service or an instance of the Win32_Service CIM class
        [Parameter(ValueFromPipeline)]
        $InputObject




    )



    process {

        ForEach ($Svc in $InputObject) {

            $SID = ConvertTo-ServiceSID -ServiceName $Svc.Name

            $OutputObject = @{
                Name = $Svc.Name
                SID  = $SID
            }

            ForEach ($Prop in $Svc.PSObject.Properties.GetEnumerator().Name) {
                $OutputObject[$Prop] = $Svc.$Prop
            }

            [PSCustomObject]$OutputObject

        }

    }

}
