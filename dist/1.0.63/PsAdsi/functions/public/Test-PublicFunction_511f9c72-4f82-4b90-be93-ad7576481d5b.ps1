function Test-PublicFunction_511f9c72-4f82-4b90-be93-ad7576481d5b {
    <#
        .SYNOPSIS
        Short synopsis of the function
        .DESCRIPTION
        Long description of the function
        .EXAMPLE
        ----------  EXAMPLE 1  ----------
        This is a demo example with no parameters. It may not even be valid.

        Test-PublicFunction_511f9c72-4f82-4b90-be93-ad7576481d5b
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

