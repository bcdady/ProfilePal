# Simple setup script to place a PowerShell module on a Windows instance that has never run PowerShell before
# File Name : copy-module.ps1
# Author    : Bryan Dady; @bcdady

# get the name of current directory, as it's likely the name of the module to be installed
$dirName = Resolve-Path -Path $pwd | Split-Path -Leaf;

# Create a new directory for this module in the ProgramFiles PS Modules directory, so it can be shared by any/all PowerShell users on the host OS
New-Item -Path "$env:ProgramFiles\WindowsPowerShell\Modules" -Name $dirName -ItemType Directory -Force

write-output  -InputObject "Copying module to $dirName\`n";

Get-ChildItem $pwd -Recurse -Exclude 'copy-module.ps1','.git*','readme.md' | 
Copy-Item -Destination $env:USERPROFILE\Documents\WindowsPowerShell\Modules\$dirName;

Write-Output -InputObject "`n # Congratulations! Module $dirName is now ready to be imported.`n To load the module, so you can start using it, run 'import-module -name $dirName -verbose'`n`n"
