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

            Write-LogMsg @Log -Text "Invoke-ScShowSid -ServiceName '$($Svc.Name)' -ComputerName '$ComputerName' -ThisFqdn '$ThisFqdn' -ThisHostName '$ThisHostName' -Log `$Log"
            $ScShowSidResults = Invoke-ScShowSid -ServiceName $Svc.Name -ComputerName $ComputerName -ThisFqdn $ThisFqdn -ThisHostName $ThisHostName -Log $Log
            $ServiceSidAndStatus = ConvertFrom-ScShowSidResult -Result $ScShowSidResults

            $OutputObject = @{
                Name   = $Svc.Name
                SID    = $ServiceSidAndStatus.'SERVICE SID'
                Status = $ServiceSidAndStatus.Status
            }

            ForEach ($Prop in ($Svc | Get-Member -View All -MemberType Property, NoteProperty).Name) {
                $OutputObject[$Prop] = $Svc.$Prop
            }

            [PSCustomObject]$OutputObject

        }

    }

}
