function ConvertTo-DistinguishedName {
    # https://docs.microsoft.com/en-us/windows/win32/api/iads/nn-iads-iadsnametranslate
    param ([string]$Domain)
    $IADsNameTranslateComObject = New-Object -comObject "NameTranslate"
    $IADsNameTranslateInterface = $IADsNameTranslateComObject.GetType()
    $null = $IADsNameTranslateInterface.InvokeMember("Init", "InvokeMethod", $Null, $IADsNameTranslateComObject, (3, $Null))
    $null = $IADsNameTranslateInterface.InvokeMember("Set", "InvokeMethod", $Null, $IADsNameTranslateComObject, (3, "$Domain\"))
    $DNSDomain = $IADsNameTranslateInterface.InvokeMember("Get", "InvokeMethod", $Null, $IADsNameTranslateComObject, 1)
    Write-Output $DNSDomain
}
