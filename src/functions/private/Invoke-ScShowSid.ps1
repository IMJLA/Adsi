function Invoke-ScShowSid {
    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/Invoke-ScShowSid')]

    # Invoke sc.exe showsid
    param (
        [string]$ServiceName,
        [string]$ComputerName,
        [string]$ThisHostName,
        [string]$ThisFqdn,
        [hashtable]$Log
    )

    if (
        $ComputerName -eq $ThisFqdn -or
        $ComputerName -eq $ThisHostName -or
        $ComputerName -eq 'localhost' -or
        $ComputerName -eq '127.0.0.1'
    ) {

        Write-LogMsg @Log -Text "& sc.exe showsid $ServiceName"
        & sc.exe showsid $ServiceName

    } else {

        Write-LogMsg @Log -Text "Invoke-Command -ComputerName $ComputerName -ScriptBlock { & sc.exe showsid `$args[0] } -ArgumentList $ServiceName"
        Invoke-Command -ComputerName $ComputerName -ScriptBlock { & sc.exe showsid $args[0] } -ArgumentList $ServiceName

    }

}
