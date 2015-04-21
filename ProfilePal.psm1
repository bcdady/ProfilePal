<#
.SYNOPSIS
    ProfilePal Module contains functions that help create and edit PowerShell profiles, as well as some other functions which can easily re-used across all PowerShell profiles
.DESCRIPTION
    ProfilePal.psm1 - Stores common functions for customizing PowerShell profiles for Console AND ISE Hosts
.NOTES
    File Name   : ProfilePal.psm1
    Author      : Bryan Dady
    Link Note   : Some functions originally inspired by zerrouki
    Thanks zerrouki for the inspiration! http://www.zerrouki.com/powershell-profile-example/
.LINK
    http://bryan.dady.us/profilepal/
    https://github.com/bcdady/profilepal
#>
#========================================
#Requires -Version 2.0

# Define script scope variables we might need later
[Boolean]$FrameTitleDefault;
[String]$defaultFrameTitle;

function Get-WindowTitle {
    # store default host window title
    if ($FrameTitleDefault) { $defaultFrameTitle = $Host.UI.RawUI.WindowTitle }
    $FrameTitleDefault = $true;
}

function Set-WindowTitle {
    # Customizes Host window title, to show version start date/time, and starting path.
    # With the path in the title, we can leave it out of the prompt; customized in another function within this module
    Get-WindowTitle
    $hosttime = (Get-ChildItem -Path $pshome\PowerShell.exe).creationtime;
    [String[]]$hostVersion = $Host.version;
    [String[]]$titlePWD    = Get-Location;
    $Host.UI.RawUI.WindowTitle = "PowerShell $hostVersion - $titlePWD [$hosttime]";
    $FrameTitleDefault = $false;
}

function Reset-WindowTitle {
    Write-Output -InputObject $defaultFrameTitle -Debug;
    Write-Output -InputObject "FrameTitle length: $($defaultFrameTitle.length)" -Debug;
    if ($defaultFrameTitle.length -gt 1) {
        $Host.UI.RawUI.WindowTitle = $defaultFrameTitle;
    }
#    [console]::Title=$defaultFrameTitle;
}

function prompt {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal] $identity

    $(  if ($PSDebugContext)
            { '[DEBUG] ' }

        elseif($principal.IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator'))
            { '[ADMIN] ' }

        else { '' }
    ) + 'PS .\' + $(if ($nestedpromptlevel -ge 1) { ' >> ' }) + '> '
}

function Open-AdminConsole {
    # Launch a new console window from the command line, with option -NoProfile support via parameter
    # Aliases added below
    Param( [Switch]$noprofile )

    # Check if UAC could be simplified
    if () {
    
    }

    if ($Variable:noprofile) {
        Start-Process -FilePath "$PSHOME\powershell.exe" -ArgumentList '-NoProfile' -Verb RunAs -WindowStyle Normal;
    } else {
        Start-Process -FilePath "$PSHOME\powershell.exe" -Verb RunAs -WindowStyle Normal;
    }
}

New-Alias -Name Open-AdminHost -Value Open-AdminConsole -ErrorAction Ignore;

New-Alias -Name Start-AdminConsole -Value Open-AdminConsole -ErrorAction Ignore;

New-Alias -Name Start-AdminHost -Value Open-AdminConsole -ErrorAction Ignore;

New-Alias -Name New-AdminConsole -Value Open-AdminConsole -ErrorAction Ignore;

New-Alias -Name New-AdminHost -Value Open-AdminConsole -ErrorAction Ignore;

New-Alias -Name Request-AdminConsole -Value Open-AdminConsole -ErrorAction Ignore;

New-Alias -Name Request-AdminHost -Value Open-AdminConsole -ErrorAction Ignore;

New-Alias -Name sudo -Value Open-AdminConsole -ErrorAction Ignore;

function Get-Profile {
<#
.SYNOPSIS
Returns corresponding PowerShell profile name, path, and status (whether it's script file exists or not)
.DESCRIPTION
Can be passed a parameter for a profile by Name or Path, and returns a summary object
.EXAMPLE
PS C:\> Get-Profile -Name CurrentUserCurrentHost

.NOTES
NAME        :  Get-Profile
VERSION     :  2.0   
LAST UPDATED:  4/9/2015
AUTHOR      :  GLACIERBANCORP\bdady
.INPUTS
None
.OUTPUTS
Profile Object
#>
    [CmdletBinding()]
    Param (
        # Specifies which profile to check; if not specified, presumes default result from $PROFILE
        [Parameter(Mandatory=$false,
            Position=0,
            ValueFromPipeline=$false,
            ValueFromPipelineByPropertyName=$false,
            HelpMessage='Specify $PROFILE by Name, such as CurrenUserCurrentHost')]
        [string]
        $Name,

        # Specifies which profile to check; if not specified, presumes default result from $PROFILE
        [Parameter(Mandatory=$false,
            Position=0,
            ValueFromPipeline=$false,
            ValueFromPipelineByPropertyName=$false,
            HelpMessage='Specify $PROFILE by Name, such as CurrenUserCurrentHost')]
        [string]
        $Path
    )

    Write-Output 'Starting '+$PSCmdlet.MyInvocation.MyCommand.Name;

    # Enumerate and indicate which, if any, PowerShell profile scripts exist
    [hashtable]$hashProfiles = @{};
    $outputobj=New-Object -TypeName PSobject;

#     $PROFILE | Get-Member -MemberType NoteProperty | ForEach-Object { # 
    # Populate $hashProfiles
    $PROFILE | Get-Member -MemberType NoteProperty | ForEach { $hashProfiles[$PSItem.Name] = $Profile.$($PSItem.Name) }
    
    Write-Warning -Message $hashProfiles -Debug;

    ForEach-Object ($PSItem -in $hashProfiles) {
        $outputobj | Add-Member -MemberType NoteProperty -Name ProfileName -Value $PSItem.Name;
        $outputobj | Add-Member -MemberType NoteProperty -Name ProfilePath -Value $Profile.$($PSItem.Name);
        $ProfileDefined = Test-Path -Path $($Profile.$($PSItem.Name));
        $outputobj | Add-Member -MemberType NoteProperty -Name ProfileDefined -Value $ProfileDefined;
<#        write-output -InputObject "`nProfile Name: $($PSItem.Name)"
        write-output -InputObject "Profile Path: $($Profile.$($PSItem.Name))"
        write-output -InputObject "Exists: $(Test-Path -Path $($Profile.$($PSItem.Name)))"
#>
    }
    
    return $outputobj;

    Write-Output 'Exiting '+$PSCmdlet.MyInvocation.MyCommand.Name

}

function Edit-Profile {
<#
.Synopsis
   Open a PowerShell Profile script in the ISE editor
.DESCRIPTION
   Edit-Profile will attempt to open any existing PowerShell Profile scripts, and if none are found, will offer to invoke the New-Profile cmdlet to build one
   Both New-Profile and Edit-Profile can open any of the 4 contexts of PowerShell Profile scripts.
.PARAMETER ProfileName
    Accepts 'CurrentUserCurrentHost', 'CurrentUserAllHosts', 'AllUsersCurrentHost' or 'AllUsersAllHosts'
.EXAMPLE
   Edit-Profile
   Opens the default $profile script file, if it exists
.EXAMPLE
   Edit-Profile CurrentUserAllHosts
   Opens the specified CurrentUserAllHosts $profile script file, which applies to both Console and ISE hosts, for the current user
#>
    [CmdletBinding()]
    [OutputType([int])]
    Param (
        # Specifies which profile to edit; if not specified, ise presumes $profile means Microsoft.PowerShellISE_profile.ps1
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   HelpMessage='Specify the PowerShell Profile to modify. <optional>'
        )]
        [ValidateSet('AllUsersAllHosts','AllUsersCurrentHost','CurrentUserAllHosts','CurrentUserCurrentHost')]
        [String[]]
        $profileName
    )
    [String]$openProfile='';

    if ($profileName) {
        # check if the profile file exists
        write-output -InputObject "Testing existence of $($PROFILE.$profileName)";
        if (Test-Path -Path $PROFILE.$profileName) {
            # file exists, so we can pass it on to be opened
            $openProfile = $PROFILE.$profileName;
        } else {
            # Specified file doesn't exist. Fortunatley we also have a function to help with that
            New-Profile -profileName $profileName;
        }
    # otherwise, test for an existing profile, in order of most specific, to most general scope
    } elseif (Test-Path -Path $PROFILE.CurrentUserCurrentHost) {
        $openProfile = $PROFILE.CurrentUserCurrentHost;
    } elseif (Test-Path -Path $PROFILE.CurrentUserAllHosts) {
        $openProfile = $PROFILE.CurrentUserAllHosts;
    } elseif (Test-Path -Path $PROFILE.AllUsersCurrentHost) {
        $openProfile = $PROFILE.AllUsersCurrentHost;
    } elseif (Test-Path -Path $PROFILE.AllUsersAllHosts) {
        $openProfile = $PROFILE.AllUsersAllHosts;
    }

    # if a profile is specified, and found, then we open it.
    if ($openProfile) {
        & powershell_ise.exe -File $openProfile;
    } else {
        Write-Warning -Message 'Profile not found. Consider running New-Profile to create a ready-to-use profile script.';
    }

    return $openProfile;
}

function New-Profile {
<#
.Synopsis
   Create a new PowerShell profile script
.DESCRIPTION
   The PowerShell profile script can be created in any 1 of the 4 default contexts: AllUsersAllHosts, AllUsersCurrentHost, CurrentUserAllHosts, or the most common CurrentUserCurrentHost.
   If this function is called from within PowerShell ISE, the *CurrentHost* profiles will be created with the requisite PowerShellISE_profile prefix
   In order to create new AllUsers profile scripts, this function must be called with elevated (admin) priveleges, as the AllUsers profiles are created in 
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
    [CmdletBinding()]
    [OutputType([int])]
    Param (
        # Specifies which profile to edit; if not specified, ise presumes $profile means Microsoft.PowerShellISE_profile.ps1
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateSet('AllUsersAllHosts','AllUsersCurrentHost','CurrentUserAllHosts','CurrentUserCurrentHost')]
        [String[]]
        $profileName
    )

# pre-define new profile script content, which utilizes functions of this module
$profile_string_content = @"
# PowerShell `$Profile
# Created by New-Profile function of ProfilePal module

`$startingPath = `$pwd; # capture starting path so we can go back after other things below might move around

# -Optional- Specify custom font colors
# Uncomment the following if block to tweak the colors of your console; the 'if' statement is to make sure we leave the ISE host alone
<#
if (`$host.Name -eq 'ConsoleHost') {
    `$host.ui.rawui.backgroundcolor = 'gray';
    `$host.ui.rawui.foregroundcolor = 'darkblue'; # blue on gray work well in Console
    Clear-Host; # clear-host refreshes the background of the console host to the new color scheme
    Start-Sleep -Seconds 1; # wait a second for the clear command to refresh
    # write to consolehost a copy of the 'Logo' text displayed when one starts a typical powershell.exe session.
    # This is added in becuase we'd otherwise not see it, after customizing console colors, and then calling clear-host to refresh the console view
    Write-Output @!
Windows PowerShell
Copyright (C) 2013 Microsoft Corporation. All rights reserved.
!@

}
#>

Write-Output "`n`tLoading PowerShell `$Profile: $profileName`n";

# Load profile functions module; includes a customized prompt function
# In case you'd like to edit it, open ProfilePal.psm1 in ise, and review the function prompt {}
# for more info on prompt customization, you can run get-help about_Prompts
write-output ' # loading ProfilePal Module #'; import-module ProfilePal; # -Verbose;

# Here's an example of how convenient aliases can be added to your PS profile
New-Alias -Name rdp -Value Start-RemoteDesktop -ErrorAction Ignore; # Add  -ErrorAction Ignore, in case that alias is already defined

# In case any intermediaary scripts or module loads change our current directory, restore original path, before it's locked into the window title by Set-WindowTitle
Set-Location `$startingPath; 

# Call Set-WindowTitle function from ProfilePal module
Set-WindowTitle;

# Display execution policy; for convenience
write-output "`nCurrent PS execution policy is: "; Get-ExecutionPolicy;

write-output "`nTo view additional available modules, run: Get-Module -ListAvailable";
write-output "`nTo view cmdlets available in a given module, run: Get-Comand -Module <ModuleName>";

"@

    # If a $profile's not created yet, create the file
    if (!(Test-Path -Path $profile.$profileName))  {
        $new_profile = new-item -type file -path $profile.$profileName;
        # write the profile content into the new file
        Add-Content -Value $profile_string_content -Path $new_profile;
    } else {
        Write-Warning -Message "$($profile.$profileName) already exists";
    }

}

New-Alias -Name Initialize-Profile -Value New-Profile -ErrorAction:SilentlyContinue;

function Reset-Profile {
    # reload the profile, by using dot-source invokation
    . $Profile
}

function Test-AdminPerms {
# Test if you have Admin Permissions; returns simple boolean result
([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole] 'Administrator')
}

function Start-RemoteDesktop {
<#
    .SYNOPSIS
        Launch a Windows Remote Desktop admin session to a specified computername, with either FullScreen, or sized window
    .DESCRIPTION
        Start-RemoteDesktop calls the mstsc.exe process installed on the local instance of Windows.
        By default, Start-RemoteDesktop specifies the optional arguments of /admin, and /fullscreen.
        Start-RemoteDesktop also provides a -ScreenSize parameter, which supports optional window resolution specifications of 1440 x 1050, 1280 x 1024, and 1024 x 768.
        I first made this because I was tired of my last mstsc session hanging on to my last resolution (which would change between when I was docked at my desk, or working from the smaller laptop screen); so this could always 'force' /fullscreen.
    .PARAMETER ComputerName
        Specifies the DNS name or IP address of the computer / server to connect to.
    .PARAMETER ScreenSize
        Specifies the window resolution. If not specified, defaults to Full Screen.
    .PARAMETER Control
        Optionall specifies if the remote session should function in Admin, RestrictedAdmin, or Control mode [default in this function].
    .PARAMETER FullScreen
        Unambiguously specifies that the RDP window open to full screen size.
    .PARAMETER PipelineVariable
        Accepts property ComputerName.
    .EXAMPLE
        PS C:\> Start-RemoteDesktop remotehost
        Invokes mstsc.exe /v:remotehost /control
    .EXAMPLE
        PS C:\> Start-RemoteDesktop -ComputerName <IP Address> -ScreenSize 1280x1024 -Control RestrictedAdmin
        Invokes mstsc.exe /v:<IP Address> /RestrictedAdmin /w:1280 /h:1024
    .NOTES
        NAME        :  Start-RemoteDesktop
        VERSION     :  1.7   
        LAST UPDATED:  4/4/2015
        AUTHOR      :  Bryan Dady; @bcdady; http://bryan.dady.us
    .INPUTS
        ComputerName
    .OUTPUTS
        None
#>
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty]
        [String[]]
        $ComputerName,

        [Parameter(Position=1)]
        [ValidateSet('FullAdmin','RestrictedAdmin')]
        [Switch]
        $Control,

        [Switch]
        $FullScreen,

        [ValidateSet('FullScreen','1440x1050','1280x1024','1024x768')]
        [String[]]
        $ScreenSize = 'FullScreen'
    )
    Write-Output 'Starting '+$PSCmdlet.MyInvocation.MyCommand.Name

    if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {
        Write-Output "Confirmed network availability of ComputerName $ComputerName";
    } else {
        Write-Output "Unable to confirm network availability of ComputerName $ComputerName [Test-Connection failed]" -Debug;
        break;
    }

    switch ($Control) {
        'FullAdmin'  { $Control = '/admin' }
        'RestrictedAdmin'  { $Control = '/RestrictedAdmin'}
        Default      { $Control = '/Control'}
    }

    if ($FullScreen) { $Resolution = '/fullscreen' }
    else {
        switch ($ScreenSize) {
            'FullScreen' { $Resolution = '/fullscreen' }
            '1440x1050'  { $Resolution = '/w:1440 /h:1050'}
            '1280x1024'  { $Resolution = '/w:1280 /h:1024'}
            '1024x768'   { $Resolution = '/w:1024 /h:768'}
            Default      { $Resolution = '/fullscreen' }
        }
    }

    Write-Output "Start-Process -FilePath mstsc.exe -ArgumentList ""/v:$ComputerName $Control $Resolution""" -Debug; 
    
    Start-Process -FilePath mstsc.exe -ArgumentList "/v:$ComputerName $Control $Resolution"; 

    Write-Output 'Exiting '+$PSCmdlet.MyInvocation.MyCommand.Name;
}

function Test-Port {
<#
.SYNOPSIS
Test-Port is effectively a PowerShell replacement for telnet, to support testing of a specified IP port of a remote computer
.DESCRIPTION
Test-Port enables testing for any answer or open indication from a remote network port.
.PARAMETER Target
DNS name or IP address of a remote computer or network device to test response from.
.PARAMETER Port
IP port number to test on the TARGET.
.PARAMETER Timeout
Time-to-live (TTL) parameter for how long to wait for a response from the TARGET PORT.
.EXAMPLE
PS C:\> Test-Port RemoteHost 9997
Tests if the remote host is open on the default Splunk port.
.NOTES
NAME        :  Test-Port
VERSION     :  1.1   
LAST UPDATED:  4/4/2015
AUTHOR      :  GLACIERBANCORP\BDady
.INPUTS
None
.OUTPUTS
None
#>
    [cmdletbinding()]
    param(
        [parameter(mandatory=$true,
            position=0)]
        [String[]]$Target,

        [parameter(mandatory=$true,
            position=1)]
            [ValidateRange(1,50000)]
        [int32]$Port=80,

        [int32]$Timeout=2000
    )
    $outputobj=New-Object -TypeName PSobject;
    $outputobj | Add-Member -MemberType NoteProperty -Name TargetHostName -Value $Target;
    if(Test-Connection -ComputerName $Target -Count 2) {
        $outputobj | Add-Member -MemberType NoteProperty -Name TargetHostStatus -Value 'ONLINE';
    } else {
        $outputobj | Add-Member -MemberType NoteProperty -Name TargetHostStatus -Value 'OFFLINE';
    } 
    $outputobj | Add-Member -MemberType NoteProperty -Name PortNumber -Value $Port;
    $Socket=New-Object System.Net.Sockets.TCPClient;
    $Connection=$Socket.BeginConnect($Target,$Port,$null,$null);
    $Connection.AsyncWaitHandle.WaitOne($timeout,$false) | Out-Null;
    if($Socket.Connected -eq $true) {$outputobj | Add-Member -MemberType NoteProperty -Name ConnectionStatus -Value 'Success';
    } else {
        $outputobj | Add-Member -MemberType NoteProperty -Name ConnectionStatus -Value 'Failed';
    }
    $Socket.Close | Out-Null;
    $outputobj | Select-Object TargetHostName, TargetHostStatus, PortNumber, Connectionstatus | Format-Table -AutoSize;
}

New-Alias -Name telnet -Value Test-Port -ErrorAction Ignore;
 
function Get-UserName {
<#
.SYNOPSIS
    Get-UserName returns user's account info in the format of DOMAIN\AccountName
.DESCRIPTION
    [System.Security.Principal.WindowsIdentity]::GetCurrent().Name;
.EXAMPLE
    PS C:\> Get-UserName;
    Returns DomainName\UserName
.EXAMPLE
    PS C:\> whoami
    Linux friendly alias invokes Get-UserName
.NOTES
    NAME        :  Get-UserName
    VERSION     :  1.1   
    LAST UPDATED:  3/4/2015
#>

[System.Security.Principal.WindowsIdentity]::GetCurrent().Name;
}

New-Alias -Name whoami -Value Get-UserName -ErrorAction Ignore;

Export-ModuleMember -function * -alias *