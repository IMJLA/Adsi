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

            #2: Convert service name to upper case.
            $UppercaseName = $Svc.Name.ToUpper()

            #3: Get the Unicode bytes()  from the upper case service name.
            $nameBytes = [System.Text.Encoding]::Unicode.GetBytes($UppercaseName)

            #4: Run bytes() thru the sha1 hash function.
            $hashBytes = ([System.Security.Cryptography.SHA1]::Create()).ComputeHash($nameBytes, 0, $nameBytes.Length)

            #5: Reverse the byte() string returned from the SHA1 hash function (on Little Endian systems Not tested on Big Endian systems)
            [Array]::Reverse($hashBytes)
            [string[]]$hashString = $hashBytes | % { $_.ToString("X2") }

            #6: Split the reversed string into 5 blocks of 4 bytes each.
            $blocks = @()
            for ($i = 0; $i -lt 5; $i++) {

                #7: Convert each block of hex bytes() to Decimal
                $blocks += [Convert]::ToInt64("0x$([String]::Join([String]::Empty, $hashString, ($i * 4), 4))", 16)
            }

            #8: Reverse the Position of the blocks
            [Array]::Reverse($blocks)

            #9: Create the first part of the SID “S-1-5-80“
            #10: Tack on each block of Decimal strings with a “-“ in between each block that was converted and reversed.
            #11: Finally out put the complete SID for the service.
            $SID = "S-1-5-80-$([String]::Join("-", $blocks))"

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
