function Resolve-ServiceNameToSID {

    # Use sc.exe to enrich a Service object with the SID and Status of the service

    param (

        # Output of Get-Service or an instance of the Win32_Service CIM class
        [Parameter(ValueFromPipeline)]
        $InputObject,
        [string]$ComputerName,
        [string]$ThisHostName,
        [string]$ThisFqdn,
        [hashtable]$Log

    )

    process {

        ForEach ($Svc in $InputObject) {

            #9: Create the first part of the SID “S-1-5-80“
            #10: Tack on each block of Decimal strings with a “-“ in between each block that was converted and reversed.
            #11: Finally out put the complete SID for the service.
            $SID = ConvertTo-ServiceSID -ServiceName $Svc.Name

            <#
            #Write-LogMsg @Log -Text "Invoke-ScShowSid -ServiceName '$($Svc.Name)' -ComputerName '$ComputerName' -ThisFqdn '$ThisFqdn' -ThisHostName '$ThisHostName' -Log `$Log"
            $ScShowSidResults = Invoke-ScShowSid -ServiceName $Svc.Name -ComputerName $ComputerName -ThisFqdn $ThisFqdn -ThisHostName $ThisHostName -Log $Log
            $ServiceSidAndStatus = ConvertFrom-ScShowSidResult -Result $ScShowSidResults

            $OutputObject = @{
                Name   = $Svc.Name
                SID    = $ServiceSidAndStatus.'SERVICE SID'
                Status = $ServiceSidAndStatus.Status
            }
            #>

            $OutputObject = @{
                Name = $Svc.Name
                SID  = $SID
            }

            ForEach ($Prop in ($Svc | Get-Member -View All -MemberType Property, NoteProperty).Name) {
                $OutputObject[$Prop] = $Svc.$Prop
            }

            [PSCustomObject]$OutputObject

        }

    }

}
