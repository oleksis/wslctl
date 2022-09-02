#Requires -Version 5
Set-StrictMode -Off

if (($PSVersionTable.PSVersion.Major) -lt 5) {
    Write-Host @'
PowerShell 5 or later is required
Upgrade PowerShell: 'https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-windows?view=powershell-7.1'
'@ -ForegroundColor 'DarkRed'
    exit 1
}

$srcdir = "$(Split-Path -Parent -Path $PSScriptRoot)/src"

# Wrapper to cleanup custom modules from PowerShell session cache
# Could not be integrated with wslctl-boostrap because it's using 'use module'
# directive which need to be first instructions of file
# NOTE: the main application is now in wslctl-bootstrap.ps1 file
#
# @see: https://stackoverflow.com/questions/67027886/reload-the-powershell-module-every-time-the-script-is-executing
# @see: https://github.com/PowerShell/PowerShell/issues/7654
# @see: https://github.com/PowerShell/PowerShell/issues/2505
$moduleFile = "$srcdir/modules.json"
if (Test-Path -Path $moduleFile -PathType Leaf){
    $myModules = @((Get-Content -Raw $moduleFile | ConvertFrom-Json))
} else {
    $myModules=@((Get-ChildItem -Path "$srcdir" -Filter '*.psm1' -Recurse -Force |
        ForEach-Object -Process {[System.IO.Path]::GetFileNameWithoutExtension($_) }
    ))
    ConvertTo-Json -InputObject $myModules | Out-File -FilePath $moduleFile
}

# remove custom known Modules:
Get-Module | ForEach-Object {
    if ($myModules.contains($_.Name)){
        Write-Verbose "removing: $_.Name"
        try { Remove-Module $_.Name -Force } catch {;}
    }
}

# Note: Github disabled TLS 1.0 support on 2018-02-23. Need to enable TLS 1.2
#       for all communication with api.github.com
# TODO: Optimize-SecurityProtocol

# Setup proxy globally
# TODO: setup_proxy

# include main application
. "$srcdir/bootstrap.ps1" @Args
