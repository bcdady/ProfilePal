#!/usr/local/bin/pwsh
# Simple setup script to place a PowerShell module in a standard PS Module Path
# File Name : copy-module.ps1
# Author    : Bryan Dady; @bcdady

# Environmental info added when reviewed/revised to function on PS-Core on OSX
Write-Output -InputObject (' # {0} {1} {2} #' -f $ShellId, $PSVersionTable.PSVersion.toString(), $PSEdition)
# $PSHOME # "

# Get the name of this script's directory, as it's likely the name of the module to be installed
$dirName = Resolve-Path -Path $PSScriptRoot | Split-Path -Leaf;

# Test Admin permissions; if found, install module for all users. If NOT, install for current user only
if ($IsWindows) {
    if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole]'Administrator'))
    {
    	$moduleDestination = "$env:ProgramFiles\WindowsPowerShell\Modules";
    	$installAllUsers = $true
    } else {
    	$moduleDestination = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules";
    	$installAllUsers = $false
    }
} else {
    # confirm expected shared modules path exists
    if ('/usr/local/share/powershell/Modules' -in @($Env:PSModulePath -split ':')) {
        $moduleDestination = '/usr/local/share/powershell/Modules'
    } else {
        Write-Warning -InputObject 'Failed to determine appropriate module destination directory'
        exit
    }
}

try {
    # Create a new directory for this module in the ProgramFiles PS Modules directory, so it can be shared by any/all PowerShell users on the host OS
    New-Item -Path $moduleDestination -Name $dirName -ItemType Directory -Force
}
catch {
    write-output -InputObject "`n"
    Write-Warning "Failed to create new destination directory: $moduleDestination\$dirName"
}

finally {
    $Error
    $Error.Clear()
}

write-output  -InputObject "`nCopying module from $PSScriptRoot to $moduleDestination\$dirName\`n";

try {
    Get-ChildItem $PSScriptRoot -Recurse -Exclude 'copy-module.ps1','.git*','*.md' | 
    Copy-Item -Destination $moduleDestination\$dirName ;
}

catch {
    Write-Warning "Fatal error: Unable to copy module to new destination directory: $moduleDestination\$dirName"
}

finally {
    $Error
    $Error.Clear()
}

# Confirm module manifest file is at expected path
try {
    if (Test-Path (Join-Path -Path $moduleDestination\$dirName -ChildPath "$dirName.psd1")) {
        write-host "`n";
        Write-Host -Object " # Congratulations! Module $dirName is now ready to be imported." -BackgroundColor Blue -ForegroundColor Green; 
        Write-Output -InputObject "To load the module, so you can start using it, run 'import-module -name $dirName -PassThru'`n`n";
    }
}

catch {
    Write-Warning "Caution! Module $dirName was not found at it's new, expected path, and may not be ready to be imported.`n Review error messages, and then try again`n`n"
}