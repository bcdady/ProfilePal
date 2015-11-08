# Requires -Version 3.0
<#
    .SYNOPSIS
        ProfilePal Module contains functions that help create and edit PowerShell profiles, as well as some other functions which can easily be re-used across all PowerShell profiles
    .DESCRIPTION
        ProfilePal Module provides helpful functions for customizing PowerShell profiles, and includes a couple 'bonus' functions for making PowerShell a bit easier to work with. Intended to help new(er) PowerShell users more quickly discover the value of managing and customizing their own PowerShell Profile.
        Functions:
        Get-Profile     - Enumerates basic info of common PowerShell Profiles
        New-Profile     - Creates PowerShell Profiles, and customizes the console, with tips to get more familiar about managing one's own profile customizations and preferences
        Edit-Profile    - Opens a specified PowerShell profile in the PowerShell_ISE, for editing
        Suspend-Profile - Suspends an active PowerShell profile by renaming (appending) the filename. Helpful with testing or troubleshooting changes or potential conflicts between profiles. To reload a PowerShell session without the suspended profile, exit and restart the pertinent PowerShell host.
        Resume-Profile  - Resumes an suspended PowerShell profile, to be active in the next PowerShell session, by restoring a profile script file renamed by Suspend-Profile.
        Reset-Profile   - Simply reloads the current profile script (`. $Profile`), but 'reload' is not an approved PowerShell verb, so we call it Reset.

        Get-UserName    - Returns active user's account info in the format of DOMAIN\AccountName
        prompt          - Overrides the default prompt, removing the pwd/path element, and conditionally adds an [ADMIN] indicator, in place of the default Administrator string in the window title bar. Customizing prompt is explained in detail in the PowerShell help file about_Prompts (try `get-help about_Prompts`)
        Get-WindowTitle - Stores active $host window title, in support of Set-WindowTitle and Reset-WindowTitle functions
        Set-WindowTitle - Customizes PS $host window title, to show version, starting path, and start date/time
        Reset-WindowTitle - Restores default PowerShell host window title, as captured by Get-WindowTitle
        Start-RemoteDesktop - Launch a Windows Remote Desktop admin session to a specified computername, with either FullScreen, or sized window
        Open-AdminConsole - Launch a new console window from the command line, with elevated (admin) permissions
        Test-Port - Effectively a PowerShell native-alternative / replacement for telnet, for testing IP port(s) of a remote computer

    .NOTES
        File Name   : ProfilePal.psm1
        Author      : Bryan Dady
        Link Note   : Some functions originally inspired by zerrouki
        Thanks zerrouki for the inspiration! http://www.zerrouki.com/powershell-profile-example/
    .LINK
        http://bryan.dady.us/profilepal/
        https://github.com/bcdady/profilepal
#>

# Define script scope variables we might need later
[Boolean]$FrameTitleDefault
[String]$defaultFrameTitle

function Get-WindowTitle 
{
<#
    .SYNOPSIS
        Stores the default PowerShell host window title
    .DESCRIPTION
        Supports Set-WindowTitle and Reset-WindowTitle functions
#>
    if ($FrameTitleDefault) 
    {
        $defaultFrameTitle = $Host.UI.RawUI.WindowTitle 
    }
    $FrameTitleDefault = $true
}

function Set-WindowTitle 
{
<#
    .SYNOPSIS
        Customizes Host window title, to show version, starting path, and start date/time. With the path in the title, we can leave it out of the prompt, to simplify and save console space.
    .DESCRIPTION
        For use in customizing PowerShell Host look and feel, in conjunction with a customized prompt function
       Customizes Host window title, to show version, starting path, and start date/time (in "UniversalSortableDateTimePattern using the format for universal time display" - per https://technet.microsoft.com/en-us/library/ee692801.aspx)
#>
    Get-WindowTitle
    $hosttime = Get-Date (Get-Process -Id $PID).StartTime -Format u
    [String[]]$hostVersion = $Host.version
    [String[]]$titlePWD    = Get-Location
    $Host.UI.RawUI.WindowTitle = "PowerShell $hostVersion - $titlePWD [$hosttime]"
    $FrameTitleDefault = $false
}

function Reset-WindowTitle 
{
<#
    .SYNOPSIS
        Restores default PowerShell host window title, as captured by Get-WindowTitle
    .DESCRIPTION
        Provided to make it easy to reset the default window frame title, but presumes that Get-WindowTitle was previously run
#>
    Write-Debug -InputObject $defaultFrameTitle 
    Write-Debug -InputObject "FrameTitle length: $($defaultFrameTitle.length)"
    if ($defaultFrameTitle.length -gt 1) 
    {
        $Host.UI.RawUI.WindowTitle = $defaultFrameTitle
    }
}

function prompt 
{
<#
    .SYNOPSIS
        Overrides the default prompt, to remove the pwd/path element from each line, and conditionally adds an indicator of the $host running with elevated permissions ([ADMIN]).
    .DESCRIPTION
        From about_Prompts: "The Windows PowerShell prompt is determined by the built-in Prompt function. You can customize the prompt by creating your own Prompt function and saving it in your Windows PowerShell profile".

        See http://poshcode.org/3997 for more cool prompt customization ideas

#>
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal] $identity

    $(  if ($PSDebugContext)
            {'[DEBUG] ' }
        elseif($principal.IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator'))
            {'[ADMIN] '}
        else 
        {''}
            ) + 'PS .\' + $(if ($nestedpromptlevel -ge 1) 
                { ' >> ' }
    ) + '> '
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
        New-AdminConsole
        New-AdminHost
        Request-AdminConsole
        Request-AdminHost
        sudo
#>
    # Aliases added below
    Param( [Switch]$noprofile )

    if ($Variable:noprofile) 
        { Start-Process -FilePath "$PSHOME\powershell.exe" -ArgumentList '-NoProfile' -Verb RunAs -WindowStyle Normal}
    else
        { Start-Process -FilePath "$PSHOME\powershell.exe" -Verb RunAs -WindowStyle Normal
    }
}

New-Alias -Name Open-AdminHost -Value Open-AdminConsole -ErrorAction Ignore

New-Alias -Name Start-AdminConsole -Value Open-AdminConsole -ErrorAction Ignore

New-Alias -Name Start-AdminHost -Value Open-AdminConsole -ErrorAction Ignore

New-Alias -Name New-AdminConsole -Value Open-AdminConsole -ErrorAction Ignore

New-Alias -Name New-AdminHost -Value Open-AdminConsole -ErrorAction Ignore

New-Alias -Name sudo -Value Open-AdminConsole -ErrorAction Ignore

function Get-Profile 
{
<#
    .SYNOPSIS
        Returns corresponding PowerShell profile name, path, and status (whether it's script file exists or not)
    .DESCRIPTION
        Can be passed a parameter for a profile by Name or Path, and returns a summary object
    .PARAMETER Name
        Accepts 'AllProfiles', 'CurrentUserCurrentHost', 'CurrentUserAllHosts', 'AllUsersCurrentHost' or 'AllUsersAllHosts'
    .EXAMPLE
        PS .\> Get-Profile

        Name                           Path                                                         Exists
        -----------                    -----------                                                  --------------
        CurrentUserCurrentHost         C:\Users\BDady\Documents\WindowsPowerSh...                   True

    .EXAMPLE
        PS .\> Get-Profile -Name AllUsersCurrentHost | Format-Table -AutoSize

        Name                Path                                                                        Exists
        -----------         -----------                                                                 --------------
        AllUsersCurrentHost C:\Windows\System32\WindowsPowerShell\v1.0\Microsoft.PowerShell_profile.ps1 False

    .NOTES
        NAME        :  Get-Profile
        LAST UPDATED:  4/27/2015
        AUTHOR      :  Bryan Dady
    .INPUTS
        None
    .OUTPUTS
        Profile Object
#>
    [CmdletBinding()]
    Param (
        # Specifies which profile to check; if not specified, presumes default result from $PROFILE
        [Parameter(Mandatory = $false,
                Position = 0,
                ValueFromPipeline = $false,
                ValueFromPipelineByPropertyName = $false,
        HelpMessage = 'Specify $PROFILE by Name, such as CurrenUserCurrentHost')]
        [ValidateSet('AllProfiles','CurrentUserCurrentHost', 'CurrentUserAllHosts', 'AllUsersCurrentHost', 'AllUsersAllHosts')]
        [string]
        $Name = 'AllProfiles'
    )

    # Define empty array to add profile return objects to
    [array]$outputobj = @()

    # Build a hashtable to easily enumerate PowerShell profile contexts / names and their scripts
    [hashtable]$hashProfiles = @{
        CurrentUserCurrentHost = $PROFILE.CurrentUserCurrentHost
        CurrentUserAllHosts    = $PROFILE.CurrentUserAllHosts
        AllUsersCurrentHost    = $PROFILE.AllUsersCurrentHost
        AllUsersAllHosts       = $PROFILE.AllUsersAllHosts
    }

    # Check if a $PROFILE script is found on the file system, for the profile specified by the Name parameter, then return details for that profile script
    Switch ($Name) {
        'AllProfiles' 
        {
            $hashProfiles.Keys | ForEach-Object -Process {
                if (Test-Path -Path $hashProfiles.$PSItem -ErrorAction SilentlyContinue)
                    { $ProfileExists = $true }
                else 
                    { $ProfileExists = $false
                }

                $properties = @{
                    'Name' = $PSItem
                    'Path' = $hashProfiles.$PSItem
                    'Exists' = $ProfileExists
                }
                $object = New-Object -TypeName PSObject -Property $properties

                # Add this resulting object to the array object to be returned by this function
                $outputobj += $object

                # cleanup properties variable
                Clear-Variable -Name properties
            }
        }
        Default 
        {
            if (Test-Path -Path $hashProfiles.$Name -ErrorAction SilentlyContinue)
                { $ProfileExists = $true }
            else 
                { $ProfileExists = $false
            }

            #'Optimize New-Object invocation, based on Don Jones' recommendation: https://technet.microsoft.com/en-us/magazine/hh750381.aspx
            $properties = @{
                'Name' = $Name
                'Path' = $hashProfiles.$Name
                'Exists' = $ProfileExists
            }
            $object = New-Object -TypeName PSObject -Property $properties

            # Add this resulting object to the array object to be returned by this function
            $outputobj = $object
        }
    }

    return $outputobj
}

function Edit-Profile 
{
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
        # Specifies which profile to edit; if not specified, ISE presumes $profile is CurrentUserCurrentHost
        [Parameter(Mandatory = $false,
                ValueFromPipelineByPropertyName = $true,
                Position = 0,
                HelpMessage = 'Specify the PowerShell Profile to modify. <optional>'
        )]
        [ValidateSet('AllUsersAllHosts','AllUsersCurrentHost','CurrentUserAllHosts','CurrentUserCurrentHost')]
        [String[]]
        $profileName
    )

    [String]$openProfile = ''

    if ($profileName) 
    {
        # check if the profile file exists
        Write-Debug -Message "Testing existence of $profileName profile: $($PROFILE.$profileName)"
        if (Test-Path -Path $PROFILE.$profileName) 
        {
            # file exists, so we can pass it on to be opened
            $openProfile = $PROFILE.$profileName
        }
        else 
        {
            # Specified file doesn't exist. Fortunately we also have a function to help with that
            Write-Output -InputObject "`n$profileName profile not found."
            Write-Output -InputObject 'Preparing to create a starter profile script, using the New-Profile function.'
            New-Profile -ProfileName $profileName
            # Check if the $profile exists, using the get-profile function
            if ((Get-Profile -Name "$profileName").Exists) 
            {
                $openProfile = $PROFILE.$profileName
            }
            else 
            {
                $openProfile = $null
            }
        }

        # otherwise, test for an existing profile, in order of most specific, to most general scope
    } elseif (Test-Path -Path $PROFILE.CurrentUserCurrentHost) 
    {
        $openProfile = $PROFILE.CurrentUserCurrentHost
    } elseif (Test-Path -Path $PROFILE.CurrentUserAllHosts) 
    {
        $openProfile = $PROFILE.CurrentUserAllHosts
    } elseif (Test-Path -Path $PROFILE.AllUsersCurrentHost) 
    {
        $openProfile = $PROFILE.AllUsersCurrentHost
    } elseif (Test-Path -Path $PROFILE.AllUsersAllHosts) 
    {
        $openProfile = $PROFILE.AllUsersAllHosts
    }

    # if a profile is specified, and found, then we open it.
    if ($openProfile) 
        { & powershell_ise.exe -File $openProfile }
    else 
        { Write-Warning -Message 'No existing PowerShell profile was found. Consider running New-Profile to create a ready-to-use profile script.'
    }
}

function New-Profile 
{
<#
    .Synopsis
        Create a new PowerShell profile script
    .DESCRIPTION
        The PowerShell profile script can be created in any 1 of the 4 default contexts, and if not specified, defaults to the most common CurrentUserCurrentHost.
        If this function is called from within PowerShell ISE, the *CurrentHost* profiles will be created with the requisite PowerShellISE_profile prefix
        In order to create new AllUsers profile scripts, this function must be called with elevated (admin) privileges. 
    .PARAMETER ProfileName
        Accepts 'CurrentUserCurrentHost', 'CurrentUserAllHosts', 'AllUsersCurrentHost' or 'AllUsersAllHosts'
    .EXAMPLE
        PS .\> New-Profile

        Creates a new starter profile script for the context Current User / Current [PowerShell] Host

        Starter profile CurrentUserCurrentHost has been created. To review and/or modify (in the PowerShell ISE), try the Edit-Profile function.
        For example, run: Edit-Profile -profileName CurrentUserCurrentHost

        Directory: C:\Users\[username]\Documents\WindowsPowerShell


        Mode                LastWriteTime     Length Name
        ----                -------------     ------ ----
        -a---         4/27/2015  10:54 AM       2381 Microsoft.PowerShell_profile.ps1

    .EXAMPLE
        PS .\> New-Profile -profileName CurrentUserAllHosts

        Creates a new starter profile script for the context Current User / Current [PowerShell] Host

        Starter profile CurrentUserAllHosts has been created. To review and/or modify (in the PowerShell ISE), try the Edit-Profile function.
        For example, run: Edit-Profile -profileName CurrentUserAllHosts

        Directory: C:\Users\[username]\Documents\WindowsPowerShell

        Mode                LastWriteTime     Length Name
        ----                -------------     ------ ----
        -a---         4/27/2015  10:57 AM       2378 profile.ps1

#>
    [CmdletBinding()]
    [OutputType([int])]
    Param (
        # Specifies which profile to edit; if not specified, ISE presumes $profile is CurrentUserCurrentHost
        [Parameter(Mandatory = $false,
                ValueFromPipelineByPropertyName = $true,
        Position = 0)]
        [ValidateSet('AllUsersAllHosts','AllUsersCurrentHost','CurrentUserAllHosts','CurrentUserCurrentHost')]
        [String[]]
        $profileName = 'CurrentUserCurrentHost'
    )

    # Pre-define new profile script content, which will use functions of this module
    $profile_string_content = @"
# PowerShell `$Profile
# Created by New-Profile function of ProfilePal module

`$startingPath = `$pwd; # capture starting path so we can go back after other things below might move around

# -Optional- Specify custom font colors
# Uncomment the following if block to tweak the colors of your console; the 'if' statement is to make sure we leave the ISE host alone
# To Uncomment the following block, delete the `<#` from the next line as well as the matching `#`> a few lines down
<#
if (`$host.Name -eq 'ConsoleHost') {
    `$host.ui.rawui.backgroundcolor = 'gray';
    `$host.ui.rawui.foregroundcolor = 'darkblue'; # blue on gray work well in Console
    Clear-Host; # clear-host refreshes the background of the console host to the new color scheme
    Start-Sleep -Seconds 1; # wait a second for the clear command to refresh
    # write to consolehost a copy of the 'Logo' text displayed when one starts a typical powershell.exe session.
    # This is added in because we'd otherwise not see it, after customizing console colors, and then calling clear-host to refresh the console view
    Write-Output @'
Windows PowerShell [Customized by ProfilePal]
Copyright (C) 2013 Microsoft Corporation. All rights reserved.
'@

}
#>

Write-Output "``n``tLoading PowerShell ```$Profile`: $profileName``n";

# Load profile functions module; includes a customized prompt function
# In case you'd like to edit it, open ProfilePal.psm1 in ISE, and review the function prompt {}
# for more info on prompt customization, you can run get-help about_Prompts
write-output ' # loading ProfilePal Module #'; Import-Module -Name ProfilePal; # -Verbose;

# Do you like easter eggs?: & iex (New-Object Net.WebClient).DownloadString("http://bit.ly/e0Mw9w")

# Here's an example of how convenient aliases can be added to your PS profile
New-Alias -Name rdp -Value Start-RemoteDesktop -ErrorAction Ignore; # Add  -ErrorAction Ignore, in case that alias is already defined

# In case any intermediary scripts or module loads change our current directory, restore original path, before it's locked into the window title by Set-WindowTitle
Set-Location `$startingPath; 

# Call Set-WindowTitle function from ProfilePal module
Set-WindowTitle;

# Display execution policy; for convenience
write-output "``nCurrent PS execution policy is: "; Get-ExecutionPolicy;

write-output "``n ** To view additional available modules, run: Get-Module -ListAvailable";
write-output "``n ** To view cmdlets available in a given module, run: Get-Command -Module <ModuleName>`n";

"@

    Write-Debug -Message $profile_string_content

    # Check if the $profile exists, using the get-profile function
    if ((Get-Profile -Name "$profileName").Exists) 
    {
        Write-Warning -Message "$($PROFILE.$profileName) already exists"
    }
    else 
    {
        # Since a $profile's not created yet, create the file
        # check if we're attempting to create a system context profile
        if ($profileName -like 'AllUsers*') 
        {
            # then we need admin permissions
            if (Test-LocalAdmin) 
            {
                $new_profile = New-Item -type file -Path $PROFILE.$profileName
                # write the profile content into the new file
                Add-Content -Value $profile_string_content -Path $new_profile
            }
            else 
            {
                Write-Warning -Message 'Insufficient privileges to create an AllUsers profile script.'
                Write-Output -InputObject 'Please try again with an Admin console (see function Open-AdminConsole), or create a CurrentUser profile instead.'
            } # end Test-LocalAdmin
        }
        else 
        {
            $new_profile = New-Item -type file -Path $PROFILE.$profileName
            # write the profile content into the new file
            Add-Content -Value $profile_string_content -Path $new_profile
        } # end profileName
    } # end Get-Profile

    # Check / confirm that the $profile exists, using the get-profile function
    if ((Get-Profile -Name "$profileName").Exists) 
    {
        Write-Output -InputObject "`nStarter profile $profileName has been created."
        Write-Output -InputObject '    To review and/or modify (in the PowerShell ISE), try the Edit-Profile function.'
        Write-Output -InputObject "    For example, run: Edit-Profile -profileName $profileName"

        return $new_profile
    }
    else 
    {
        return $false
    }
} # end function

New-Alias -Name Initialize-Profile -Value New-Profile -ErrorAction:SilentlyContinue

function Reset-Profile 
{
<#
    .SYNOPSIS
        Reload the profile (`$PROFILE), by using dot-source invocation
    .DESCRIPTION
        Essentially an alias for PS .\>. $Profile
#>
    . $PROFILE
}

function Suspend-Profile 
{
<#
    .SYNOPSIS
        Suspend any active PowerShell profile scripts, by renaming (appending) the filename
        This can be reversed by the corresponding function Resume-Profile
    .DESCRIPTION
        Can be passed a parameter for a profile by Name or Path, and returns a summary object
    .PARAMETER Name
        Accepts 'AllProfiles', 'CurrentUserCurrentHost', 'CurrentUserAllHosts', 'AllUsersCurrentHost' or 'AllUsersAllHosts'
    .EXAMPLE
        PS .\> Suspend-Profile

        Name                           Path                                                         Exists
        -----------                    -----------                                                  --------------
        CurrentUserCurrentHost         C:\Users\BDady\Documents\WindowsPowerSh...                   True

    .EXAMPLE
        PS .\> Suspend-Profile -Name AllProfiles | Format-Table -AutoSize

        Name                Path                                                                        Exists
        -----------         -----------                                                                 --------------
        AllUsersCurrentHost C:\Windows\System32\WindowsPowerShell\v1.0\Microsoft.PowerShell_profile.ps1 False

    .NOTES
        NAME        :  Suspend-Profile
        LAST UPDATED:  7/27/2015
        AUTHOR      :  Bryan Dady

#>
    [CmdletBinding()]
    Param (
        # Specifies which profile to check; if not specified, presumes default result from $PROFILE
        [Parameter(Mandatory = $false,
                Position = 0,
                ValueFromPipeline = $false,
                ValueFromPipelineByPropertyName = $false,
        HelpMessage = 'Specify $PROFILE by Name, such as CurrenUserCurrentHost')]
        [ValidateSet('AllProfiles','CurrentUserCurrentHost', 'CurrentUserAllHosts', 'AllUsersCurrentHost', 'AllUsersAllHosts')]
        [string]
        $Name = 'CurrentUserCurrentHost'
    )

    # Define empty array to add profile return objects to
    [array]$outputobj = @()

    # Build a hashtable to easily enumerate PowerShell profile contexts / names and their scripts
    [hashtable]$hashProfiles = @{
        CurrentUserCurrentHost = $PROFILE.CurrentUserCurrentHost
        CurrentUserAllHosts    = $PROFILE.CurrentUserAllHosts
        AllUsersCurrentHost    = $PROFILE.AllUsersCurrentHost
        AllUsersAllHosts       = $PROFILE.AllUsersAllHosts
    }

    # Check if a $PROFILE script is found on the file system, for the profile specified by the Name parameter, then return details for that profile script
    Switch ($Name) {
        'AllProfiles' 
        {
            $hashProfiles.Keys | ForEach-Object -Process {
                if (Test-Path -Path $hashProfiles.$PSItem -ErrorAction SilentlyContinue)
                {
                    $ProfileExists = $true
                    $newPath = Rename-Item -Path $hashProfiles.$PSItem -NewName "$($hashProfiles.$PSItem)~" -Confirm -PassThru
                    Write-Verbose -Message "Assigned `$newPath to $($newPath)"
                }
                else 
                {
                    $ProfileExists = $false
                    $newPath = $null
                    Write-Debug -Message '$ProfileExists = $false; $newPath is $null'
                }

                $properties = @{
                    'Name' = $PSItem
                    'Path' = $newPath.FullName
                    'Exists' = $ProfileExists
                }
                $object = New-Object -TypeName PSObject -Property $properties

                # Add this resulting object to the array object to be returned by this function
                $outputobj += $object

                # cleanup properties variable
                Clear-Variable -Name properties
            }
        }
        Default 
        {
            if (Test-Path -Path $hashProfiles.$Name -ErrorAction SilentlyContinue)
            {
                $ProfileExists = $true
                $newPath = Rename-Item -Path $hashProfiles.$Name -NewName "$($hashProfiles.$Name)~" -Confirm -PassThru
                Write-Verbose -Message "Assigned `$newPath to $($newPath)"
            }
            else 
            {
                $ProfileExists = $false
                $newPath = $null
                Write-Debug -Message '$ProfileExists = $false; $newPath is $null'
            }

            #'Optimize New-Object invocation, based on Don Jones' recommendation: https://technet.microsoft.com/en-us/magazine/hh750381.aspx
            $properties = @{
                'Name' = $Name
                'Path' = $newPath.FullName
                'Exists' = $ProfileExists
            }
            $object = New-Object -TypeName PSObject -Property $properties

            # Add this resulting object to the array object to be returned by this function
            $outputobj = $object
        }
    }

    return $outputobj
}

function Resume-Profile 
{
<#
    .SYNOPSIS
        Resumes any previously suspended PowerShell profile scripts, by restoring the expected filename

    .DESCRIPTION
        Can be passed a parameter for a profile by Name or Path, and returns a summary object
    .PARAMETER Name
        Accepts 'AllProfiles', 'CurrentUserCurrentHost', 'CurrentUserAllHosts', 'AllUsersCurrentHost' or 'AllUsersAllHosts'
    .EXAMPLE
        PS .\> Resume-Profile

        Name                           Path                                                         Exists
        -----------                    -----------                                                  --------------
        CurrentUserCurrentHost         C:\Users\BDady\Documents\WindowsPowerSh...                   True

    .EXAMPLE
        PS .\> Resume-Profile -Name AllProfiles | Format-Table -AutoSize

        Name                Path                                                                        Exists
        -----------         -----------                                                                 --------------
        AllUsersCurrentHost C:\Windows\System32\WindowsPowerShell\v1.0\Microsoft.PowerShell_profile.ps1 False

    .NOTES
        NAME        :  Resume-Profile
        LAST UPDATED:  7/27/2015
        AUTHOR      :  Bryan Dady

#>
    [CmdletBinding()]
    Param (
        # Specifies which profile to check; if not specified, presumes default result from $PROFILE
        [Parameter(Mandatory = $false,
                Position = 0,
                ValueFromPipeline = $false,
                ValueFromPipelineByPropertyName = $false,
        HelpMessage = 'Specify $PROFILE by Name, such as CurrenUserCurrentHost')]
        [ValidateSet('AllProfiles','CurrentUserCurrentHost', 'CurrentUserAllHosts', 'AllUsersCurrentHost', 'AllUsersAllHosts')]
        [string]
        $Name = 'CurrentUserCurrentHost'
    )

    # Define empty array to add profile return objects to
    [array]$outputobj = @()

    # Build a hashtable to easily enumerate PowerShell profile contexts / names and their scripts
    [hashtable]$hashProfiles = @{
        CurrentUserCurrentHost = $PROFILE.CurrentUserCurrentHost
        CurrentUserAllHosts    = $PROFILE.CurrentUserAllHosts
        AllUsersCurrentHost    = $PROFILE.AllUsersCurrentHost
        AllUsersAllHosts       = $PROFILE.AllUsersAllHosts
    }

    # Check if a $PROFILE script is found on the file system, for the profile specified by the Name parameter, then return details for that profile script
    Switch ($Name) {
        'AllProfiles' 
        {
            $hashProfiles.Keys | ForEach-Object -Process {
                if (Test-Path -Path "$($hashProfiles.$PSItem)~" -ErrorAction SilentlyContinue)
                {
                    $ProfileExists = $true
                    $newPath = Rename-Item -Path "$($hashProfiles.$PSItem)~" -NewName $hashProfiles.$PSItem -Confirm -PassThru
                    Write-Verbose -Message "Assigned `$newPath to $($newPath)"
                }
                else 
                {
                    $ProfileExists = $false
                    $newPath = $null
                    Write-Debug -Message '$ProfileExists = $false; $newPath is $null'
                }

                $properties = @{
                    'Name' = $PSItem
                    'Path' = $newPath.FullName
                    'Exists' = $ProfileExists
                }
                $object = New-Object -TypeName PSObject -Property $properties

                # Add this resulting object to the array object to be returned by this function
                $outputobj += $object

                # cleanup properties variable
                Clear-Variable -Name properties
            }
        }
        Default 
        {
            if (Test-Path -Path "$($hashProfiles.$Name)~" -ErrorAction SilentlyContinue)
            {
                $ProfileExists = $true
                $newPath = Rename-Item -Path "$($hashProfiles.$Name)~" -NewName $hashProfiles.$Name -Confirm -PassThru
                Write-Debug -Message "Assigned `$newPath to $($newPath)"
            }
            else 
            {
                $ProfileExists = $false
                $newPath = $null
                Write-Debug -Message '$ProfileExists = $false; $newPath is $null'
            }

            #'Optimize New-Object invocation, based on Don Jones' recommendation: https://technet.microsoft.com/en-us/magazine/hh750381.aspx
            $properties = @{
                'Name' = $Name
                'Path' = $newPath.FullName
                'Exists' = $ProfileExists
            }
            $object = New-Object -TypeName PSObject -Property $properties

            # Add this resulting object to the array object to be returned by this function
            $outputobj = $object
        }
    }

    return $outputobj
}

function global:Test-LocalAdmin 
{
<#
    .SYNOPSIS
        Test if you have Admin Permissions; returns simple boolean result
    .DESCRIPTION
        ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole] 'Administrator')
#>
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] 'Administrator')
}

function Start-RemoteDesktop 
{
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
        Optional specifies if the remote session should function in Admin, RestrictedAdmin, or Control mode [default in this function].
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
        [Parameter(Mandatory = $true,
                ValueFromPipelineByPropertyName = $true,
        Position = 0)]
        [ValidateNotNullOrEmpty]
        [String[]]
        $ComputerName,

        [Parameter(Position = 1)]
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

    if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) 
    {
        Write-Output -InputObject "Confirmed network availability of ComputerName $ComputerName"
    }
    else 
    {
        Write-Output -InputObject "Unable to confirm network availability of ComputerName $ComputerName [Test-Connection failed]"
        break
    }

    switch ($Control) {
        'FullAdmin'  
        {
            $Control = '/admin' 
        }
        'RestrictedAdmin'  
        {
            $Control = '/RestrictedAdmin'
        }
        Default      
        {
            $Control = '/Control'
        }
    }

    if ($FullScreen) 
    {
        $Resolution = '/fullscreen' 
    }
    else 
    {
        switch ($ScreenSize) {
            'FullScreen' 
            {
                $Resolution = '/fullscreen' 
            }
            '1440x1050'  
            {
                $Resolution = '/w:1440 /h:1050'
            }
            '1280x1024'  
            {
                $Resolution = '/w:1280 /h:1024'
            }
            '1024x768'   
            {
                $Resolution = '/w:1024 /h:768'
            }
            Default      
            {
                $Resolution = '/fullscreen' 
            }
        }
    }

    Write-Debug -Message "Start-Process -FilePath mstsc.exe -ArgumentList ""/v:$ComputerName $Control $Resolution""" 
    
    Start-Process -FilePath mstsc.exe -ArgumentList "/v:$ComputerName $Control $Resolution" 

    Write-Output 'Exiting '+$PSCmdlet.MyInvocation.MyCommand.Name
}

function Test-Port 
{
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
        AUTHOR      :  Bryan Dady
    .INPUTS
        None
    .OUTPUTS
        None
#>
    [cmdletbinding()]
    param(
        [parameter(mandatory = $true,
        position = 0)]
        [String[]]$Target,

        [parameter(mandatory = $true,
        position = 1)]
        [ValidateRange(1,50000)]
        [int32]$Port = 80,

        [int32]$Timeout = 2000
    )
    $outputobj = New-Object -TypeName PSobject
    $outputobj | Add-Member -MemberType NoteProperty -Name TargetHostName -Value $Target
    if(Test-Connection -ComputerName $Target -Count 2) 
    {
        $outputobj | Add-Member -MemberType NoteProperty -Name TargetHostStatus -Value 'ONLINE'
    } else 
    {
        $outputobj | Add-Member -MemberType NoteProperty -Name TargetHostStatus -Value 'OFFLINE'
    } 
    $outputobj | Add-Member -MemberType NoteProperty -Name PortNumber -Value $Port
    $Socket = New-Object -TypeName System.Net.Sockets.TCPClient
    $Connection = $Socket.BeginConnect($Target,$Port,$null,$null)
    $null = $Connection.AsyncWaitHandle.WaitOne($Timeout,$false)
    if($Socket.Connected -eq $true) 
    {
        $outputobj | Add-Member -MemberType NoteProperty -Name ConnectionStatus -Value 'Success'
    } else 
    {
        $outputobj | Add-Member -MemberType NoteProperty -Name ConnectionStatus -Value 'Failed'
    }
    $null = $Socket.Close
    $outputobj |
    Select-Object -Property TargetHostName, TargetHostStatus, PortNumber, Connectionstatus |
    Format-Table -AutoSize
}

New-Alias -Name telnet -Value Test-Port -ErrorAction Ignore
 
function Get-UserName 
{
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

    [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
}

New-Alias -Name whoami -Value Get-UserName -ErrorAction Ignore

Export-ModuleMember -Function * -Alias *