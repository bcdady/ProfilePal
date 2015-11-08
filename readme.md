# ProfilePal

[Official Website](http://bryan.dady.us/profilepal)
    
ProfilePal is a free PowerShell module, made by [Bryan Dady](http://about.me/bryandady), to help set IT Pros up for early success with learning, mastering, and accelerating PowerShell.

ProfilePal module provides helpful functions for creating and customizing PowerShell profiles, and includes a couple 'bonus' functions for making PowerShell a bit easier to work with; intended to help new(er) PowerShell users more quickly discover the value of managing and customizing their own PowerShell Profile.

There are a few extra goodies thrown in, mostly thanks to the generous PowerShell profile tips previously provided by [Fabrice ZERROUKI](http://www.zerrouki.com/powershell-profile-example/)

## Profile Script Functions
### Get-Profile
Returns profile name, script path, and status (whether it's script file exists or not), for all, or for a specified PowerShell profile. 

### New-Profile
Creates a new PowerShell profile script, which customizes the console, and includes functions and tips to get more familiar about managing one's own profile customization and preferences.

*This is the one that does the heavy lifting*

If not specified via parameter, New-Profile will create the CurrentUserCurrentHost profile. The newly created profile will include calls to functions defined within the ProfilePal module, such as `Set-WindowTitle`, and `prompt`. 

#### Alias
Initialize-Profile

### Edit-Profile
Opens a specified PowerShell profile in the PowerShell_ISE, for editing
Edit-Profile will attempt to open any existing PowerShell Profile scripts, and if none are found, will offer to invoke the New-Profile cmdlet to build one.

Edit-Profile, Get-Profile, and New-Profile can open any of the 4 default contexts of PowerShell profile scripts. For more information on profiles, run `get-help about_Profiles`

### Suspend-Profile
Suspends an active PowerShell profile by renaming (appending) the profile script filename. This can be helpful with testing or troubleshooting changes or potential conflicts between profiles. To reload a PowerShell session without the suspended profile, exit and restart the pertinent PowerShell host.

### Resume-Profile
Resumes an suspended PowerShell profile, to be active in the next PowerShell session, by restoring a profile script file renamed by Suspend-Profile.

### Reset-Profile
Simply reloads the current profile script (`. $Profile`), but 'reload' is not an approved PowerShell verb, so we call it Reset.

### Get-UserName
Returns active user's account name in the format of DOMAIN\AccountName

#### Alias: whoami

## PowerShell Host Customization Functions

### prompt
Overrides the default prompt, removing the pwd/path element, and conditionally adds an [ADMIN] indicator, in place of the default Administrator string in the window title bar. Customizing prompt is explained in detail in the PowerShell help file about_Prompts (try `get-help about_Prompts`)

Since I find I rarely need to know my current path, I write the starting path and date / time to the Window Title, and then simplify the prompt to reflect the current directory:`PS .\>`

When the PowerShell console is started with Administrative permissions (see also `Open-AdminConsole`), this function inserts an [ADMIN] indicator, to replace the default 'Administrator:' text which would otherwise be added to the Window Title: `PS [ADMIN] .\>`

### Get-WindowTitle
Stores the PowerShell host window title, in support of Set-WindowTitle and Reset-WindowTitle functions

### Set-WindowTitle
Customizes PowerShell host window title, to show PowerShell version, starting path, and start date/time. With the path in the title, we can leave it out of the prompt; customized in prompt function within this module.

### Reset-WindowTitle
Restores default PowerShell host window title, as captured by Get-WindowTitle

## Bonus Functions:
### Start-RemoteDesktop
Launch a Windows Remote Desktop admin session to a specified computername, with either FullScreen, or sized window. Whenever I work in an environment that doesn't (yet) have PSRemoting enabled, I like to have Remote Desktop ready to run, with some handy presets. I often add an alias to this function, named `rdp`, in my own profile  

### Test-Port
Effectively a PowerShell-native alternative / replacement for telnet, to test IP port(s) of a remote computer. This comes in handy when working in an environment that disabled the Windows telnet client, in favor of security.

#### Alias: telnet

### Test-LocalAdmin
Test if the current host process is running with elevated, local admin, permissions; returns simple Boolean result.

### Open-AdminConsole
Launch a new console window, with Admin permissions, thanks to the RunAs verb. This is commonly done by right-clicking the PowerShell icon, but this function makes it easy to achieve the same from the command line. There is a 
-NoProfile parameter, so that the Administrative console / host can be started in a clean / 'default' mode.

#### Aliases: New-AdminConsole, New-AdminHost, Open-AdminHost, Start-AdminConsole, Start-AdminHost, sudo