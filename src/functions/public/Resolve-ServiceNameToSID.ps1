function Resolve-ServiceNameToSID {

    # Use the same math as sc.exe showsid to enrich a Service object with the SID and Status of the service

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
