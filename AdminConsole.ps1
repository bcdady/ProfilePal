
function global:Test-LocalAdmin 
{
<#
    .SYNOPSIS
        Test if you have Admin Permissions; returns simple boolean result
    .DESCRIPTION
        ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole] 'Administrator')
#>
    Return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
}

function Open-AdminConsole 
{
<#
    .SYNOPSIS
        Launch a new console window from the command line, with optional -NoProfile support
    .DESCRIPTION
        Simplifies opening a PowerShell console host, with Administrative permissions, by enabling the same result from the keyboard, instead of having to grab the mouse to Right-Click and select 'Run as Administrator'
        The following aliases are also provided:
        Open-AdminHost
        Start-AdminConsole
        Start-AdminHost
        New-AdminCons
        ole
        New-AdminHost
        Request-AdminConsole
        Request-AdminHost
        sudo
#>
    # Aliases added below
#    Param( [Switch]$noprofile )
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [Alias('Automatic','Silent','NonInteractive')]
        [Switch]
        $NoProfile = $true,

        [Parameter(Mandatory=$false, Position=1)]
        [Alias('script','ScriptBlock')]
        [object]
        $Command
    )

    if ($Variable:NoProfile) 
# can't add Command handling until including some kind of validation / safety checking
#    if ($Variable:Command)
    {
        Write-Debug -Message "`$Variable:NoProfile : $Variable:NoProfile"
        Write-Debug -Message "`$Command is $Command"
        $return = Start-Process -FilePath "$PSHOME\powershell.exe" -ArgumentList "-NoProfile $Command" -Verb RunAs -WindowStyle Normal -PassThru
    }
    else
    {
        $return = Start-Process -FilePath "$PSHOME\powershell.exe" -ArgumentList "$Command" -Verb RunAs -WindowStyle Normal
    }
    Write-Output -InputObject "Return object is $return"
    Return $return
}

New-Alias -Name Open-AdminHost -Value Open-AdminConsole -ErrorAction Ignore

New-Alias -Name Start-AdminConsole -Value Open-AdminConsole -ErrorAction Ignore

New-Alias -Name Start-AdminHost -Value Open-AdminConsole -ErrorAction Ignore

New-Alias -Name New-AdminConsole -Value Open-AdminConsole -ErrorAction Ignore

New-Alias -Name New-AdminHost -Value Open-AdminConsole -ErrorAction Ignore

New-Alias -Name sudo -Value Open-AdminConsole -ErrorAction Ignore
