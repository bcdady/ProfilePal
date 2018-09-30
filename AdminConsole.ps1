
function Test-LocalAdmin {
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

function Open-AdminConsole {
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
  # Param( [Switch]$noprofile )
  [cmdletbinding()]
  param (
    [Parameter(Position=0)]
    [Alias('Automatic','Silent','NonInteractive')]
    [Switch]
    $NoProfile = $true,

    [Parameter(Mandatory=$true,HelpMessage='Specify the command to run',Position=1)]
    [Alias('script','ScriptBlock')]
    [Object]
    $Command
  )

  Write-Debug -Message ('$Variable: NoProfile : {0}' -f $NoProfile)
  Write-Debug -Message ('$Command is {0}' -f $Command)
    
  if ($Host.Version.Major -le 5) {
    $pwsh_path = Join-Path -Path $PSHOME -ChildPath 'powershell.exe'
  } else {
    $pwsh_path = Join-Path -Path $PSHOME -ChildPath 'pwsh'
  }

  Write-Verbose -Message ('$pwsh_path is {0}' -f $pwsh_path)
  
  if ($Variable:NoProfile) {
    # Add Command validation / safety checking
    $return = Start-Process -FilePath $pwsh_path -ArgumentList ('-NoProfile {0}' -f $Command) -Verb RunAs -WindowStyle Normal
  } else {
    $return = Start-Process -FilePath $pwsh_path -ArgumentList ('-Command & {{{0}}}' -f $Command) -Verb RunAs -WindowStyle Normal
  }
  Return $return
}

New-Alias -Name Open-AdminHost -Value Open-AdminConsole -ErrorAction Ignore

New-Alias -Name Start-AdminConsole -Value Open-AdminConsole -ErrorAction Ignore

New-Alias -Name Start-AdminHost -Value Open-AdminConsole -ErrorAction Ignore

New-Alias -Name New-AdminConsole -Value Open-AdminConsole -ErrorAction Ignore

New-Alias -Name New-AdminHost -Value Open-AdminConsole -ErrorAction Ignore

New-Alias -Name sudo -Value Open-AdminConsole -ErrorAction Ignore
