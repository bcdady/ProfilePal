﻿#!/usr/local/bin/powershell
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

function Get-WindowTitle {
    <#
        .SYNOPSIS
            Stores the default PowerShell host window title
        .DESCRIPTION
            Supports Set-WindowTitle and Reset-WindowTitle functions
    #>
    if ($FrameTitleDefault) {
        $defaultFrameTitle = $Host.UI.RawUI.WindowTitle 
    }
    $FrameTitleDefault = $true
}

function Set-WindowTitle {
    <#
        .SYNOPSIS
            Customizes Host window title, to show version, starting path, and start date/time. With the path in the title, we can leave it out of the prompt, to simplify and save console space.
        .DESCRIPTION
            For use in customizing PowerShell Host look and feel, in conjunction with a customized prompt function
        Customizes Host window title, to show version, starting path, and start date/time (in "UniversalSortableDateTimePattern using the format for universal time display" - per https://technet.microsoft.com/en-us/library/ee692801.aspx)
    #>
    Get-WindowTitle
    $hosttime = Get-Date (Get-Process -Id $PID).StartTime -Format u
    [String]$hostVersion = $($Host.version).tostring().substring(0,3) 
    [String]$titlePWD    = Get-Location
    $Host.UI.RawUI.WindowTitle = "$ShellId $PSEdition $hostVersion - $titlePWD [$hosttime]"
    $FrameTitleDefault = $false
}

New-Alias -Name Update-WindowTitle -Value Set-WindowTitle -ErrorAction Ignore
function Reset-WindowTitle {
    <#
        .SYNOPSIS
            Restores default PowerShell host window title, as captured by Get-WindowTitle
        .DESCRIPTION
            Provided to make it easy to reset the default window frame title, but presumes that Get-WindowTitle was previously run
    #>
    Write-Debug -InputObject $defaultFrameTitle 
    Write-Debug -InputObject "FrameTitle length: $($defaultFrameTitle.length)"
    if ($defaultFrameTitle.length -gt 1) {
        $Host.UI.RawUI.WindowTitle = $defaultFrameTitle
    }
}

function prompt {
    <#
        .SYNOPSIS
            Overrides the default prompt, to remove the pwd/path element from each line, and conditionally adds an indicator of the $host running with elevated permsisions ([ADMIN]).
        .DESCRIPTION
            From about_Prompts: "The Windows PowerShell prompt is determined by the built-in Prompt function. You can customize the prompt by creating your own Prompt function and saving it in your Windows PowerShell profile".

            See http://poshcode.org/3997 for more cool prompt customization ideas

    #>
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal] $identity

    $(  if ($PSDebugContext) {'[DEBUG] ' }
        elseif($principal.IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {'[ADMIN] '}
        else {''}
            ) + 'PS .\' + $(if ($nestedpromptlevel -ge 1) { ' >> ' }
    ) + '> '
}

Function Get-Profile {
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
        [Parameter(
            Position = 0,
            HelpMessage = 'Specify $PROFILE by Name, such as CurrenUserCurrentHost')]
        [ValidateSet('AllProfiles','CurrentUserCurrentHost', 'CurrentUserAllHosts', 'AllUsersCurrentHost', 'AllUsersAllHosts')]
        [string]
        $Name = 'AllProfiles'
    )

    # Define empty array to add profile return objects to
    [array]$returnCollection = @()

    # Build a hashtable to easily enumerate PowerShell profile contexts / names and their scripts
    [hashtable]$hashProfiles = @{
        CurrentUserCurrentHost = $PROFILE.CurrentUserCurrentHost
        CurrentUserAllHosts    = $PROFILE.CurrentUserAllHosts
        AllUsersCurrentHost    = $PROFILE.AllUsersCurrentHost
        AllUsersAllHosts       = $PROFILE.AllUsersAllHosts
    }

    # Check if a $PROFILE script is found on the file system, for the profile specified by the Name parameter, then return details for that profile script
    Switch ($Name) {
        'AllProfiles' {
            $hashProfiles.Keys | ForEach-Object -Process {
                if (Test-Path -Path $hashProfiles.$PSItem -ErrorAction SilentlyContinue) {
                    $ProfileExists = $true
                } else {
                    $ProfileExists = $false
                }

                $properties = @{
                    'Exists' = $ProfileExists
                    'Name'   = $PSItem
                    'Path'   = $hashProfiles.$PSItem
                }
                $object = New-Object -TypeName PSObject -Property $properties

                # Add this resulting object to the array object to be returned by this function
                $returnCollection += $object

                # cleanup properties variable
                Clear-Variable -Name properties
            }
        }
        Default {
            if (Test-Path -Path $hashProfiles.$Name -ErrorAction SilentlyContinue) {
                $ProfileExists = $true
            } else {
                $ProfileExists = $false
            }

            #'Optimize New-Object invocation, based on Don Jones' recommendation: https://technet.microsoft.com/en-us/magazine/hh750381.aspx
            $properties = @{
                'Name' = $Name
                'Path' = $hashProfiles.$Name
                'Exists' = $ProfileExists
            }
            $object = New-Object -TypeName PSObject -Property $properties

            # Add this resulting object to the array object to be returned by this function
            $returnCollection = $object
        }
    }

    return $returnCollection | Sort-Object -Property Name
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
        # Specifies which profile to edit; if not specified, ISE presumes $profile is CurrentUserCurrentHost
        [Parameter(
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            HelpMessage = 'Specify the PowerShell Profile to modify. <optional>'
        )]
        [ValidateSet('AllUsersAllHosts','AllUsersCurrentHost','CurrentUserAllHosts','CurrentUserCurrentHost')]
        [String]
        $profileName
    )

    [String]$openProfile = ''

    # check if the profile file exists
    if ($profileName) {
        Write-Debug -Message "Testing existence of $profileName profile: $($PROFILE.$profileName)"
        if (Test-Path -Path $PROFILE.$profileName) {
            # file exists, so we can pass it on to be opened
            $openProfile = $PROFILE.$profileName
        } else {
            # Specified file doesn't exist. Fortunately we also have a function to help with that
            Write-Output -InputObject "`n$profileName profile not found."
            Write-Output -InputObject 'Preparing to create a starter profile script, using the New-Profile function.'
            New-Profile -ProfileName $profileName
            # Check if the $profile exists, using the get-profile function
            if ((Get-Profile -Name "$profileName").Exists) {
                $openProfile = $PROFILE.$profileName
            } else {
                $openProfile = $null
            }
        }

    # otherwise, test for an existing profile, in order of most specific, to most general scope
    } elseif (Test-Path -Path $PROFILE.CurrentUserCurrentHost) {
        $openProfile = $PROFILE.CurrentUserCurrentHost
    } elseif (Test-Path -Path $PROFILE.CurrentUserAllHosts) {
        $openProfile = $PROFILE.CurrentUserAllHosts
    } elseif (Test-Path -Path $PROFILE.AllUsersCurrentHost) {
        $openProfile = $PROFILE.AllUsersCurrentHost
    } elseif (Test-Path -Path $PROFILE.AllUsersAllHosts) {
        $openProfile = $PROFILE.AllUsersAllHosts
    }

    # if a profile is specified, and found, then we open it.
    if ($openProfile) {
        # Enhance editor support: similar ot Edit-Module, open specified file(s), such as $PROFILE, via preferred/specified editor
        # if editor specified via .json, then confirm it's .exe is available
        # if not specified or not available, look for Get-PSEdit function/command (provided by Get-PSEdit script)
        # if all else fails, look for powershell_ise.exe, or finally notepad.exe
        if ([bool](get-command Get-PSEdit)) {
            # Confirm we can reference the powershell editor specified by the Get-PSEdit / Open-PSEdit functions / psedit alias
            Write-Verbose -Message 'Get-PSEdit' # "Testing availability of PSEdit alias"
            Get-PSEdit

            #$PSEdit = Test-Path -Path (Get-PSEdit)
            # if (Get-Alias -Name psedit -ErrorAction SilentlyContinue) {
            #     #$PSEdit = (Resolve-Path -Path (Get-PSEdit)).Path
            #     Write-Verbose -Message "`$PSEdit resolved to $PSEdit"
            # } else {
            if (-not (Test-Path -Path (Get-PSEdit))) {
                Write-Verbose -Message "Trying to identify best available editor via Assert-PSEdit function"
                try {
                    Assert-PSEdit
                }
                catch {
                    throw 'Encountered sever error determining editor (line 287)'
                }
            }
            Open-PSEdit $openProfile
        }

        if ([bool](Get-Variable -Name psISE -ErrorAction Ignore)) {
            Write-Verbose -Message "In ISE; proceeding to use built-in cmdlet psEdit"
            psEdit -filenames $openProfile
        } 
        if (-not (Test-Path -Path (Get-PSEdit))) {
            Write-Verbose -Message "Failed to locate a better editor, so defaulting to open with notepad"
            & notepad.exe -File $openProfile
        }
    } else {
        Write-Warning -Message 'No existing PowerShell profile was found. Consider running New-Profile to create a ready-to-use profile script.'
    }
}

Function New-Profile {
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
        [Parameter(
                ValueFromPipelineByPropertyName = $true,
        Position = 0)]
        [ValidateSet('AllUsersAllHosts','AllUsersCurrentHost','CurrentUserAllHosts','CurrentUserCurrentHost')]
        [String]
        $profileName = 'CurrentUserCurrentHost'
    )

    # Pre-define new profile script content, which will use functions of this module
    $profile_string_content = @"
# PowerShell `$Profile
# Created by New-Profile function of ProfilePal module

# capture starting path so we can go back after other things below might move around
`$startingPath = `$pwd

# -Optional- Specify custom font colors
# Uncomment the following if block to tweak the colors of your console; the 'if' statement is to make sure we leave the ISE host alone
# To Uncomment the following block, delete the `<#` from the next line as well as the matching `#`> a few lines down
<#
if (`$host.Name -eq 'ConsoleHost') {
    `$host.ui.rawui.backgroundcolor = 'gray'
    `$host.ui.rawui.foregroundcolor = 'darkblue'
    # clear-host refreshes the background of the console host to the new color scheme
    Clear-Host
    # Wait a second for the clear command to refresh
    Start-Sleep -Seconds 1
    # Write to consolehost a copy of the 'Logo' text displayed when one starts a typical powershell.exe session.
    # This is added in because we'd otherwise not see it, after customizing console colors, and then calling clear-host to refresh the console view
    Write-Output @'
Windows PowerShell [Customized by ProfilePal]
Copyright (C) 2013 Microsoft Corporation. All rights reserved.
'@

}
#>

Write-Output "``n``tLoading PowerShell ```$Profile`: $profileName``n"

# Load profile functions module; includes a customized prompt function
# In case you'd like to edit it, open ProfilePal.psm1 in ISE, and review the function prompt {}
# for more info on prompt customization, you can run get-help about_Prompts
write-output ' # loading ProfilePal Module #'
Import-Module -Name ProfilePal

# Do you like easter eggs?: & iex (New-Object Net.WebClient).DownloadString("http://bit.ly/e0Mw9w")

# Here's an example of how convenient aliases can be added to your PS profile
New-Alias -Name rdp -Value Start-RemoteDesktop -ErrorAction Ignore

# In case any intermediary scripts or module loads change our current directory, restore original path, before it's locked into the window title by Set-WindowTitle
Set-Location `$startingPath

# Call Set-WindowTitle function from ProfilePal module
Set-WindowTitle

# Display execution policy, for convenience
write-output "``nCurrent PS execution policy is: "
Get-ExecutionPolicy

write-output "``n ** To view additional available modules, run: Get-Module -ListAvailable"
write-output "``n ** To view cmdlets available in a given module, run: Get-Command -Module <ModuleName>`n"

"@

    Write-Debug -Message $profile_string_content

    # Check if the $profile exists, using the get-profile function
    if ((Get-Profile -Name "$profileName").Exists) {
        Write-Warning -Message "$($PROFILE.$profileName) already exists"
    } else {
        # Since a $profile's not created yet, create the file
        # check if we're attempting to create a system context profile
        if ($profileName -like 'AllUsers*') {
            # then we need admin permissions
            if (Test-LocalAdmin) {
                $new_profile = New-Item -type file -Path $PROFILE.$profileName
                # write the profile content into the new file
                Add-Content -Value $profile_string_content -Path $new_profile
            } else {
                Write-Warning -Message 'Insufficient privileges to create an AllUsers profile script.'
                Write-Output -InputObject 'Please try again with an Admin console (see function Open-AdminConsole), or create a CurrentUser profile instead.'
            } # end Test-LocalAdmin
        } else {
            $new_profile = New-Item -type file -Path $PROFILE.$profileName
            # write the profile content into the new file
            Add-Content -Value $profile_string_content -Path $new_profile
        } # end profileName
    } # end Get-Profile

    # Check / confirm that the $profile exists, using the get-profile function
    if ((Get-Profile -Name "$profileName").Exists) {
        Write-Output -InputObject "`nStarter profile $profileName has been created."
        Write-Output -InputObject '    To review and/or modify (in the PowerShell ISE), try the Edit-Profile function.'
        Write-Output -InputObject "    For example, run: Edit-Profile -profileName $profileName"

        return $new_profile
    } else {
        return $false
    }
} # end function

New-Alias -Name Initialize-Profile -Value New-Profile -ErrorAction:SilentlyContinue

Function Reset-Profile {
    <#
        .SYNOPSIS
            Reload the profile (`$PROFILE), by using dot-source invocation
        .DESCRIPTION
            Essentially an alias for PS .\>. $Profile
    #>
    . $PROFILE
}

New-Alias -Name Reload-Profile -Value Reset-Profile -ErrorAction:SilentlyContinue

Function Suspend-Profile {
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
        [Parameter(Position = 0, ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Specify $PROFILE by Name, such as CurrenUserCurrentHost')]
        [ValidateSet('AllProfiles','CurrentUserCurrentHost', 'CurrentUserAllHosts', 'AllUsersCurrentHost', 'AllUsersAllHosts')]
        [string]
        $Name = 'CurrentUserCurrentHost'
    )

    # Define empty array to add profile return objects to
    [array]$returnCollection = @()

    # Build a hashtable to easily enumerate PowerShell profile contexts / names and their scripts
    [hashtable]$hashProfiles = @{
        CurrentUserCurrentHost = $PROFILE.CurrentUserCurrentHost
        CurrentUserAllHosts    = $PROFILE.CurrentUserAllHosts
        AllUsersCurrentHost    = $PROFILE.AllUsersCurrentHost
        AllUsersAllHosts       = $PROFILE.AllUsersAllHosts
    }

    $ProfileExists = $false
    $newPath = $null

    # Check if a $PROFILE script is found on the file system, for the profile specified by the Name parameter, then return details for that profile script
    Switch ($Name) {
        'AllProfiles' {
            try {
                Test-LocalAdmin

                Write-Output -InputObject 'Suspending All profiles (by renaming script files)'
                $hashProfiles.Keys | ForEach-Object -Process {
                    $ProfileExists = $false
                    $newPath = $null
                    if (Test-Path -Path $hashProfiles.$PSItem -ErrorAction SilentlyContinue) {
                        $ProfileExists = $true
                        $newPath = Rename-Item -Path $hashProfiles.$PSItem -NewName "$($hashProfiles.$PSItem)~" -Force
                        Write-Debug -Message "Assigned `$newPath to $($newPath)"
                    
                    } else {
                        Write-Debug -Message '$ProfileExists = $false; $newPath is $null'
                    }
                }
            }

            catch {
                Write-Warning -Message 'Insufficient privileges.'
                Write-Output -InputObject 'Please try again with an Admin console (see function Open-AdminConsole).'
            }

            finally {

                $properties = @{
                    'Exists' = $ProfileExists
                    'Name'   = $PSItem
                    'Path'   = $newPath.FullName
                }
                $object = New-Object -TypeName PSObject -Property $properties
            }

            # Add this resulting object to the array object to be returned by this function
            $returnCollection += $object

            # cleanup properties variable
            Clear-Variable -Name properties
        }
        
        'AllUsersCurrentHost' {
            try {
                Test-LocalAdmin
                Write-Output -InputObject "Suspending Profile $Name."

                Test-Path -Path $hashProfiles.$Name
                $ProfileExists = $true
                $newPath = Rename-Item -Path $hashProfiles.$Name -NewName "$($hashProfiles.$Name)~" -Force
                Write-Debug -Message "Assigned `$newPath to $($newPath)"
            }

            catch {
                Write-Warning -Message 'Insufficient privileges.'
                Write-Output -InputObject 'Please try again with an Admin console (see function Open-AdminConsole).'
            }

            finally {
                $properties = @{
                    'Exists' = $ProfileExists
                    'Name'   = $PSItem
                    'Path'   = $newPath.FullName
                }
                $object = New-Object -TypeName PSObject -Property $properties
            }

            # Add this resulting object to the array object to be returned by this function
            $returnCollection = $object
        
        }
        
        'AllUsersAllHosts' {
            try {
                Test-LocalAdmin
                Write-Output -InputObject "Suspending Profile $Name."

                Test-Path -Path $hashProfiles.$Name
                $ProfileExists = $true
                $newPath = Rename-Item -Path $hashProfiles.$Name -NewName "$($hashProfiles.$Name)~" -Force
                Write-Debug -Message "Assigned `$newPath to $($newPath)"
                
            }
        
            catch {
                Write-Warning -Message 'Insufficient privileges.'
                Write-Output -InputObject 'Please try again with an Admin console (see function Open-AdminConsole).'
            }

            finally {

                $properties = @{
                    'Exists' = $ProfileExists
                    'Name'   = $PSItem
                    'Path'   = $newPath.FullName
                }
                $object = New-Object -TypeName PSObject -Property $properties
            }

            # Add this resulting object to the array object to be returned by this function
            $returnCollection = $object
        }

        Default {
            try {
                Write-Output -InputObject "Suspending Profile $Name."

                Test-Path -Path $hashProfiles.$Name
                $ProfileExists = $true
                $newPath = Rename-Item -Path $hashProfiles.$Name -NewName "$($hashProfiles.$Name)~" -Force
                Write-Debug -Message "Assigned `$newPath to $($newPath)"
                
            }

            catch {
                Write-Warning -Message 'Insufficient privileges.'
                Write-Output -InputObject 'Please try again with an Admin console (see function Open-AdminConsole).'
            }

            finally {
                $properties = @{
                    'Exists' = $ProfileExists
                    'Name'   = $PSItem
                    'Path'   = $newPath.FullName
                }
                $object = New-Object -TypeName PSObject -Property $properties
            }

            # Add this resulting object to the array object to be returned by this function
            $returnCollection = $object
        }
    }

    Write-Output -InputObject 'Profile(s) suspended.'

    return $returnCollection | Sort-Object -Property Name | Format-Table -AutoSize
}

Function Resume-Profile {
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
        [Parameter(
            Position = 0,
            HelpMessage = 'Specify $PROFILE by Name, such as CurrentUserCurrentHost'
        )]
        [ValidateSet('AllProfiles','CurrentUserCurrentHost', 'CurrentUserAllHosts', 'AllUsersCurrentHost', 'AllUsersAllHosts')]
        [string]
        $Name = 'CurrentUserCurrentHost'
    )

    # Define empty array to add profile return objects to
    [array]$returnCollection = @()

    # Build a hashtable to easily enumerate PowerShell profile contexts / names and their scripts
    [hashtable]$hashProfiles = @{
        CurrentUserCurrentHost = $PROFILE.CurrentUserCurrentHost
        CurrentUserAllHosts    = $PROFILE.CurrentUserAllHosts
        AllUsersCurrentHost    = $PROFILE.AllUsersCurrentHost
        AllUsersAllHosts       = $PROFILE.AllUsersAllHosts
    }

    # Check if a $PROFILE script is found on the file system, for the profile specified by the Name parameter, then return details for that profile script
    Switch ($Name) {
        'AllProfiles' {
            Write-Output -InputObject 'Resuming All profiles'
            
            $hashProfiles.Keys | ForEach-Object -Process {
                if (Test-Path -Path "$($hashProfiles.$PSItem)~" -ErrorAction SilentlyContinue) {
                    $ProfileExists = $true
                    $newPath = Rename-Item -Path "$($hashProfiles.$PSItem)~" -NewName $hashProfiles.$PSItem -Force
                    Write-Debug -Message "Resuming (restoring) profile $Name"
                } else {
                    $ProfileExists = $false
                    $newPath = $null
                    Write-Debug -Message '$ProfileExists = $false; $newPath is $null'
                }

                $properties = @{
                    'Exists' = $ProfileExists
                    'Name'   = $PSItem
                    'Path'   = $newPath.FullName
                }
                $object = New-Object -TypeName PSObject -Property $properties

                 # Add this resulting object to the array object to be returned by this function
                $returnCollection += $object

                # cleanup properties variable
                Clear-Variable -Name properties
            }
        }
        Default {
            if (Test-Path -Path "$($hashProfiles.$Name)~" -ErrorAction SilentlyContinue) {
                Write-Output -InputObject "Suspending Profile $Name."
                $ProfileExists = $true
                $newPath = Rename-Item -Path "$($hashProfiles.$Name)~" -NewName $hashProfiles.$Name -Force
                Write-Debug -Message "Assigned `$newPath to $($newPath)"
            } else {
                $ProfileExists = $false
                $newPath = $null
                Write-Debug -Message '$ProfileExists = $false; $newPath is $null'
            }

            #'Optimize New-Object invocation, based on Don Jones' recommendation: https://technet.microsoft.com/en-us/magazine/hh750381.aspx
            $properties = @{
                'Exists' = $ProfileExists
                'Name' = $Name
                'Path' = $newPath.FullName
            }
            $object = New-Object -TypeName PSObject -Property $properties

            # Add this resulting object to the array object to be returned by this function
            $returnCollection = $object
        }
    }

    Write-Output -InputObject 'Profile(s) suspended.'

    return $returnCollection | Sort-Object -Property Name
}
