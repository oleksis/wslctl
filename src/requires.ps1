#Requires -Version 5
Set-StrictMode -Off

if (($PSVersionTable.PSVersion.Major) -lt 5) {
    Write-Host @'
PowerShell 5 or later is required
Upgrade PowerShell: 'https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-windows?view=powershell-7.1'
'@ -ForegroundColor 'DarkRed'
    exit 1
}
