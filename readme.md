# ProfilePal

[Official Website](http://bryan.dady.us/profilepal)
    
ProfilePal is a free PowerShell module, made by [Bryan Dady](http://about.me/bryandady), to help set IT Pros up for early success with learning, mastering, and accelerating PowerShell.

The ProfilePal Module includes the following functions that are either designed to create new, instantly useful PowerShell profile scripts, or to help make managing existing PowerShell profiles easier. Basic descriptions are provided below, and get-help support is provided within each module as well, e.g. for additional description of parameters, and examples.

There are a few extra goodies thrown in, mostly thanks to the generous PowerShell profile tips previously provided by [Fabrice ZERROUKI](http://www.zerrouki.com/powershell-profile-example/)

## Functions
### Edit-Profile
Open a PowerShell Profile script in the ISE editor

Edit-Profile will attempt to open any existing PowerShell Profile scripts, and if none are found, will offer to invoke the New-Profile cmdlet to build one.

Edit-Profile, Get-Profile, and New-Profile can open any of the 4 contexts of PowerShell Profile scripts. For more information on profiles, run `get-help about_Profiles`

### Get-Profile
Returns profile name, script path, and status (whether it's script file exists or not), for the specified PowerShell profile. 

### New-Profile
Create a new PowerShell profile script

*This is the one that does the heavy lifting*

If not specified via parameter, New-Profile will create the CurrentUserCurrentHost profile. The newly created profile will include calls to functions defined within the ProfilePal module, such as `Set-WindowTitle`, and `prompt`. 

#### Aliases
Initialize-Profile

### prompt
Customizing prompt is explained in detail in the PowerShell help file about_Prompts (try `get-help about_Prompts`)

Since I find I rarely need to know my current path, I write the starting path and date / time to the Window Title, and then simplify the prompt to reflect the current directory:`PS .\>`

When the PS console is started with Administrative permissions (see also `Open-AdminConsole`), this function inserts an [ADMIN] indicator, to replace the default 'Administrator:' text which would otherwise be added to the Window Title: `PS [ADMIN] .\>`

### Reset-Profile
Simply reloads the current profile script (`. $Profile`), but 'reload' is not an approved PowerShell verb, so we call it Reset.

### Get-WindowTitle
Reads (once) and retains the default WindowTitle for the host, in a global variable. Supports Reset-WindowTitle.

### Reset-WindowTitle
Restores default PS $host window title

### Set-WindowTitle
Customizes PS $Host window title, to show PS version, starting path, and start date/time. With the path in the title, we can leave it out of the prompt; customized in prompt function within this module

### Start-RemoteDesktop
Whenever I work in an environment that doesn't (yet) have PSRemoting enabled, I like to have Remote Desktop ready to run, with some handy presets. I often add an alias to this of `rdp`

### Test-Port
Test-Port is effectively a PowerShell replacement for telnet, to support testing of a specified IP port of a remote computer. This comes in handy when working in an environment that disabled the Windows telnet client, in favor of security.

### Test-AdminPerms
Tests if the current user has Admin permissions, returning a simple boolean result

### Open-AdminConsole

Launches a new console window, with Admin permissions, thanks to the RunAs verb. This is commonly done by right-clicking the PowerShell icon, but this function makes it easy to achieve the same from the command line. I recently added -NoProfile support, so that the Administrative console / host can be started in a 'default' mode.

#### Aliases:
New-AdminConsole

New-AdminHost

Open-AdminHost

Request-AdminConsole

Request-AdminHost

Start-AdminConsole

Start-AdminHost
