# Simple setup script to place a PowerShell module on a Windows instance that has never run PowerShell before
# File Name : copy-module.ps1
# Author    : Bryan Dady; @bcdady

# Get the name of this script's directory, as it's likely the name of the module to be installed
$dirName = Resolve-Path -Path $PSScriptRoot | Split-Path -Leaf;

# Test Admin permissions; if found, install module for all users. If NOT, install for current user only
if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] 'Administrator'))
{
    $moduleDestination = "$env:ProgramFiles\WindowsPowerShell\Modules";
    $installAllUsers = $true
} else {
    $moduleDestination = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules";
    $installAllUsers = $false
}

# Create a new directory for this module in the ProgramFiles PS Modules directory, so it can be shared by any/all PowerShell users on the host OS
New-Item -Path $moduleDestination -Name $dirName -ItemType Directory -Force

write-output  -InputObject "Copying module to $moduleDestination\$dirName\`n";

Get-ChildItem $PSScriptRoot -Recurse -Exclude 'copy-module.ps1','.git*','*.md' | 
Copy-Item -Destination $moduleDestination\$dirName ;

Write-Output -InputObject "`n # Congratulations! Module $dirName is now ready to be imported.`n To load the module, so you can start using it, run 'import-module -name $dirName -verbose'`n`n"
