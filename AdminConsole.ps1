
Function Test-LocalAdmin {
    <#
        .SYNOPSIS
            Test if you have Admin Permissions; returns simple boolean result
        .DESCRIPTION
            ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
            [Security.Principal.WindowsBuiltInRole] 'Administrator')
    #>
    if ((Get-Variable -Name IsAdmin -ErrorAction Ignore) -eq $true) {
        Return $IsAdmin
    } else {
      if ((Get-Variable -Name IsWindows -ErrorAction Ignore) -eq $true) {
        Return ([security.principal.windowsprincipal] [security.principal.windowsidentity]::GetCurrent()).isinrole([Security.Principal.WindowsBuiltInRole] 'Administrator')
      }
    }
} # end function Test-LocalAdmin

Function Open-AdminConsole {
 	[cmdletbinding()]
 	param (
		[Parameter(Position=0)]
		[Alias('Interactive')]
		[Switch]
		$LoadProfile,
		[Parameter(Position=1)]
        [Alias('cmdlet','function','script','ScriptBlock')]
		[Object]
		$Command
	)

    if ($Global:PSEdition -eq 'Core') {
        $Shell = 'pwsh.exe'
    } else {
        $Shell = 'powershell.exe'
    }
    $ShellPath = Join-Path -Path $PSHOME -ChildPath $Shell

    Write-Verbose -Message ('$ShellPath is {0}' -f $ShellPath)

    Write-Debug -Message ('$Variable:LoadProfile is {0}' -f $Variable:LoadProfile)
    Write-Debug -Message ('$Command is {0}' -f $Command)
    # Can't add Command handling until including some kind of validation / safety checking
    # if ($Variable:Command)

    if ($Variable:LoadProfile) {
        # Add Command validation / safety checking
        $return = Start-Process -FilePath "$ShellPath" -ArgumentList ('-LoadProfile {0}' -f $Command) -Verb RunAs -WindowStyle Normal
    } else {
        $return = Start-Process -FilePath "$ShellPath" -ArgumentList ('-Command & {{{0}}}' -f $Command) -Verb RunAs -WindowStyle Normal
    }
    Return $return
    <#
        .SYNOPSIS
            Launch a new console window from the command line, with optional -LoadProfile support
        .DESCRIPTION
            Simplifies opening a PowerShell console host, with Administrative permissions, by enabling the same result from the keyboard, instead of having to grab the mouse to Right-Click and select 'Run as Administrator'
            The following aliases are also provided:
            Open-AdminHost
            Start-AdminConsole
            Start-AdminHost
            New-AdminConsole
            New-AdminHost
            Request-AdminConsole
            Request-AdminHost
            sudo
    #>
}

New-Alias -Name New-AdminConsole -Value Open-AdminConsole -ErrorAction Ignore
New-Alias -Name New-AdminHost -Value Open-AdminConsole -ErrorAction Ignore
New-Alias -Name Open-AdminHost -Value Open-AdminConsole -ErrorAction Ignore
New-Alias -Name Start-AdminConsole -Value Open-AdminConsole -ErrorAction Ignore
New-Alias -Name Start-AdminHost -Value Open-AdminConsole -ErrorAction Ignore
New-Alias -Name sudo -Value Open-AdminConsole -ErrorAction Ignore
