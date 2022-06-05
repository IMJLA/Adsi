function Test-PublicFunction_511f9c72-4f82-4b90-be93-ad7576481d5b {
    <#
        .SYNOPSIS
        Short synopsis of the function
        .DESCRIPTION
        Long description of the function
        .INPUTS
        [PSObject] InputObject parameter
        .OUTPUTS
        [PSObject]
        .EXAMPLE
        ----------  EXAMPLE 1  ----------
        Test-PublicFunction_511f9c72-4f82-4b90-be93-ad7576481d5b

        This demo example with no parameters will return nothing
    #>
    [OutputType([PSObject[]])]
    [CmdletBinding()]
    param (

        # Comment-based help for $InputObject
        [Parameter(ValueFromPipeline)]
        [PSObject[]]$InputObject

    )
    begin {

    }
    process {
        ForEach ($ThisObject in $InputObject) {
            Write-Output $ThisObject
        }
    }
    end {

    }
}

