function Invoke-ComObject {
    param (
        [Parameter(Mandatory)]
        $ComObject,

        [Parameter(Mandatory)]
        [String]$Property,

        $Value,

        [Switch]$Method
    )
    <#
    If ($ComObject -IsNot "__ComObject") {
        If (!$ComInvoke) {
            $Global:ComInvoke = @{}
        }
        If (!$ComInvoke.$ComObject) {
            $ComInvoke.$ComObject = New-Object -ComObject $ComObject
        }
        $ComObject = $ComInvoke.$ComObject
    }
    #>
    If ($Method) {
        $Invoke = "InvokeMethod"
    }
    ElseIf ($MyInvocation.BoundParameters.ContainsKey("Value")) {
        $Invoke = "SetProperty"
    }
    Else {
        $Invoke = "GetProperty"
    }
    [__ComObject].InvokeMember($Property, $Invoke, $Null, $ComObject, $Value)
}