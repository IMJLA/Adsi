using namespace System.Management.Automation

function Write-InfoColor {
    <#
        .SYNOPSIS
            Write an information message to the console with custom colors.
        .DESCRIPTION
            This function writes an information message to the console with specified foreground and background colors.
        .PARAMETER MessageData
            The message data to be written to the console.
        .PARAMETER ForegroundColor
            The foreground color for the message. Default is the current foreground color.
        .PARAMETER BackgroundColor
            The background color for the message. Default is the current background color.
        .PARAMETER NoNewline
            If specified, does not append a newline after the message.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MessageData,
        [ConsoleColor]$ForegroundColor = $Host.UI.RawUI.ForegroundColor, # Make sure we use the current colours by default
        [ConsoleColor]$BackgroundColor = $Host.UI.RawUI.BackgroundColor,
        [Switch]$NoNewline
    )

    $msg = [HostInformationMessage]@{
        Message         = $MessageData
        ForegroundColor = $ForegroundColor
        BackgroundColor = $BackgroundColor
        NoNewline       = $NoNewline.IsPresent
    }

    Write-Information $msg

}