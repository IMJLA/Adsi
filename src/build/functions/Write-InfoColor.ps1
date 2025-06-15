using namespace System.Management.Automation

function Write-InfoColor {

    <#
        .SYNOPSIS
            Write an information message to the console with custom colors.
        .DESCRIPTION
            This function writes an information message to the console with specified foreground and background colors.
    #>

    [CmdletBinding()]

    param(

        # The message data to be written to the console.
        [Parameter(Mandatory)]
        [string]$MessageData,

        # The foreground color for the message. Default is the current foreground color.
        [ConsoleColor]$ForegroundColor = $Host.UI.RawUI.ForegroundColor, # Make sure we use the current colours by default

        # The background color for the message. Default is the current background color.
        [ConsoleColor]$BackgroundColor = $Host.UI.RawUI.BackgroundColor,

        # If specified, does not append a newline after the message.
        [Switch]$NoNewline

    )


    $msg = [HostInformationMessage]@{
        'Message'         = $MessageData
        'ForegroundColor' = $ForegroundColor
        'BackgroundColor' = $BackgroundColor
        'NoNewline'       = $NoNewline.IsPresent
    }

    Write-Information $msg

}
