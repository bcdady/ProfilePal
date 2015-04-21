# Simple setup script to place a PowerShell module on a Windows instance that has never run PowerShell before
# File Name : copy-module.ps1
# Author    : Bryan Dady; @bcdady

if (Get-ExecutionPolicy -eq 'Undefined') {
    Write-Warning 'PowerShell ExecutionPolicy  is Undefined, and so this script won`'t run as intended.`nChange the policy to Unrestricted and/or run `'get-help about_Execution_Policies`' for more info.'
    
} else {

# get the name of current directory, as it's likely the name of the module to be installed
$dirName = Resolve-Path -Path $pwd | Split-Path -Leaf;

# mkdir a new directory for this module in the default user PS Modules directory; creating the rest of the path, if necesarry
New-Item -Path $env:USERPROFILE\Documents\WindowsPowerShell\Modules -Name $dirName -ItemType Directory -Force

# write-output  -InputObject "Created $env:USERPROFILE\Documents\WindowsPowerShell\Modules\$dirName";
write-output  -InputObject "Copying module to $dirName\";

Get-ChildItem $pwd -Recurse -Exclude 'copy-module.ps1','.git*','readme.md' | 
Copy-Item -Destination $env:USERPROFILE\Documents\WindowsPowerShell\Modules\$dirName;

Write-Output -InputObject "`n # Congratulations! Module $dirName is now ready to be imported.`n To load the module, so you can start using it, run 'import-module -name $dirName -verbose'`n`n"
}