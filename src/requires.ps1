#Requires -Version 5
Set-StrictMode -Off

if (($PSVersionTable.PSVersion.Major) -lt 5) {
    Write-Host @'
PowerShell 5 or later is required
Upgrade PowerShell: 'https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-windows?view=powershell-7.1'
'@ -ForegroundColor 'DarkRed'
    exit 1
}

if ([Environment]::OSVersion.Version.Major -lt 10) {
    Write-Host  'Upgrade to Windows 10+ before running this script' -ForegroundColor 'DarkRed'
    exit 2
}

if ((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ReleaseId -lt 1803) {
    Write-Host 'You need to run Windows Update and install Feature Updates to at least version 1803' -ForegroundColor 'DarkRed'
    exit 3
}

if (('Unrestricted', 'RemoteSigned') -notcontains (Get-ExecutionPolicy)) {
    Write-Host  @'
The execution policy on your machine is Restricted, but it must be opened up for this
installer with:
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
'@ -ForegroundColor 'DarkRed'
    exit 4
}

if (!(Get-Command 'wsl' -ErrorAction SilentlyContinue)) {
    Write-Host @"
You need Windows Subsystem for Linux setup before the rest of this script can run.
See https://docs.microsoft.com/en-us/windows/wsl/install-win10 for more information
or use the '$PSScriptRoot\files\wslctl-setup.ps1'
PowerShell script.
"@ -ForegroundColor 'DarkRed'
    exit 4
}
