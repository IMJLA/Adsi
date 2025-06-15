function ConvertFrom-ScShowSidResult {
    [CmdletBinding(HelpUri = 'https://IMJLA.github.io/Adsi/docs/en-US/ConvertFrom-ScShowSidResult')]
    # Convert the results from sc.exe into an object

    param (

        [string[]]$Result

    )

    $dict = @{}
    ForEach ($Line in $Result) {

        if ([string]::IsNullOrEmpty($Line)) {
            if ($dict.Keys.Count -ge 1) {
                [PSCustomObject]$dict
                $dict = @{}
                continue
            }
        } else {
            $Prop, $Value = ($Line -split ':').Trim()
            $dict[$Prop] = $Value
        }

    }
    if ($dict.Keys.Count -ge 1) {
        [PSCustomObject]$dict
    }
}
