#!/usr/local/bin/pwsh
#requires -Version 3
# Simple setup script to place a PowerShell module in a standard PS Module Path
# File Name : copy-module.ps1
# Author    : Bryan Dady; @bcdady
[CmdletBinding(SupportsShouldProcess)]
param ()

# Environmental info added when reviewed/revised to function on PS-Core on OSX
Write-Output -InputObject ''
Write-Output -InputObject ''
Write-Output -InputObject (' # {0} {1} {2} #' -f $ShellId, $PSVersionTable.PSVersion.toString(), $PSEdition)
# $PSHOME # "
Write-Output -InputObject ''

# Get the name of this script's directory, as it's likely the name of the module to be installed
$private:dirName = Resolve-Path -Path $PSScriptRoot | Split-Path -Leaf
Write-Verbose -Message ('$dirName is {0}' -f $private:dirName)

$private:ModulesPath = $null
$installAllUsers = $false
if (Get-Variable -Name myPSModulesPath -ValueOnly -ErrorAction Ignore) {
    Write-Verbose -Message ('$private:ModulesPath will be {0}' -f $myPSModulesPath)
    $private:ModulesPath = $myPSModulesPath 
} else {
    # Test Admin permissions; if found, install module for all users. If NOT, install for current user only
    if ($IsWindows) {
        if (($PSVersionTable.PSVersion.toString()) -le 5) {
            $PowerShellFolderName = 'WindowsPowerShell'
        } else {
            $PowerShellFolderName = 'PowerShell'
        }
         = 'PowerShell'
        Write-Verbose -Message ('Detected IsWindows: True. $PowerShellFolderName will be {0}' -f $PowerShellFolderName)
        if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
            [Security.Principal.WindowsBuiltInRole]'Administrator'))
        {
            $private:ModulesPath = Join-Path -Path $env:ProgramFiles -ChildPath ('{0}\Modules' -f $PowerShellFolderName)
            $installAllUsers = $true
        } else {
            $private:ModulesPath = Join-Path -Path "$env:USERPROFILE\Documents" -ChildPath ('{0}\Modules' -f $PowerShellFolderName)
        }
        Write-Verbose -Message ('$installAllUsers is {0}' -f $installAllUsers)
    } else {
        # confirm expected shared modules path exists
        if ('/usr/local/share/powershell/Modules' -in @($Env:PSModulePath -split ':')) {
            $private:ModulesPath = "~/.local/share/powershell/Modules/"
        } else {
            Write-Warning -InputObject 'Failed to determine appropriate module destination directory'
            exit
        }
    }
}

try {
    # Create a new directory for this module in the ProgramFiles PS Modules directory, so it can be shared by any/all PowerShell users on the host OS
    Write-Verbose -Message ('Creating destination directory: {0}\{1}' -f $private:ModulesPath, $private:dirName)
    New-Item -Path $private:ModulesPath -Name $private:dirName -ItemType Directory -Force -ErrorAction Ignore
}
catch {
    Write-Output -InputObject ''
    Write-Warning -Message ('Failed to create new destination directory: {0}\{1}' -f $private:ModulesPath, $private:dirName)
}

finally {
    $Error
    $Error.Clear()
}

$private:ModuleDestination = (Join-Path -Path $private:ModulesPath -ChildPath $private:dirName)

Write-Output -InputObject ''
Write-Output -InputObject ('Copying module from {0} to {1}' -f $PSScriptRoot, $private:ModuleDestination)

try {
    Get-ChildItem $PSScriptRoot -Recurse -Exclude 'copy-module.ps1','.git*','*.md','*.bak','*.old' | 
    Copy-Item -Destination $private:ModuleDestination -Force
}

catch {
    Write-Warning ('Fatal error: Unable to copy module to new destination directory: {0}' -f $private:ModuleDestination)
}

finally {
    $Error
    $Error.Clear()
}

# Confirm module manifest file is at expected path
try {
    if (Test-Path (Join-Path -Path $private:ModuleDestination -ChildPath "$private:dirName.psd1")) {
        Write-Output -InputObject ''
        Get-ChildItem -Path $private:ModuleDestination
        Write-Output -InputObject ''
        Write-Host -Object (' # Congratulations! Module {0} is now ready to be imported.' -f $private:dirName) -BackgroundColor Blue -ForegroundColor Green
        Write-Output -InputObject ('To load the module, so you can start using it, run ''import-module -name {0} -PassThru''' -f $private:dirName)
    }
}

catch {
    Write-Warning "Caution! Module $private:dirName was not found at it's new, expected path, and may not be ready to be imported.`n Review error messages, and then try again."
}