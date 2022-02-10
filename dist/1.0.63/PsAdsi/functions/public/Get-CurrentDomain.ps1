function Get-CurrentDomain {
    $Obj = [adsi]::new()
    $Obj.RefreshCache({ 'objectSid' })
    Write-Output $Obj
}
