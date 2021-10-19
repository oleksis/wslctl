
## ----------------------------------------------------------------------------
## Restore a wsl instance
## ----------------------------------------------------------------------------
function Restore-Wsl {
    [OutputType('bool')]
    Param( [string]$backupName, [bool]$forced)

    # Read backup properties
    $backupProperties = Get-JsonKeyValue $backupRegistryFile $backupName
    if ($null -eq $backupProperties) {
        Write-Host "Error: Backup '$backupName' does not exists" -ForegroundColor Red
        return $false
    }
    $wslName = $backupProperties.wslname
    $backupTgz = $backupProperties.archive
    $backupHash = $backupProperties.sha256

    Write-Host "Check archive file..."
    $backupTgzLocation = "$backupLocation/$backupTgz"
    if (-Not (Test-Path -Path $backupTgzLocation)) {
        Write-Host "Error: File not found '$backupTgzLocation'" -ForegroundColor Red
        return $false
    }

    Write-Host "Check archive integrity ($backupHash)..."
    $archiveHash = (Get-FileHash $backupTgzLocation -Algorithm SHA256).Hash.ToLower()
    if (-Not ($archiveHash -eq $backupHash)) {
        Write-Host "Error: Archive File integrity mismatch. Found '$archiveHash'" -ForegroundColor Red
        return $false
    }

    # Check if wsl instance exists and ask for confirmation if force parameter
    # is false
    if ((Test-WslInstanceIsCreated $wslName) -And (-Not $forced)) {
        Write-Host "*** WARNING ***" -ForegroundColor Yellow
        Write-Host "This action will replace the existing '$wslName' instance" -ForegroundColor Yellow
        Write-Host "with backup '$backupName'" -ForegroundColor Yellow
        While ($Selection -ne "Y" ) {
            $Selection = Read-Host "Proceed ? (Y/N)"
            Switch ($Selection) {
                Y { Write-Host "Continuing with validation" -ForegroundColor Green }
                N { Write-Host "Breaking out of script" -ForegroundColor Red; return $false ; }
                default { Write-Host "Only Y/N are Valid responses" }
            }
        }
    }

    # Remove existing instance
    if (Test-WslInstanceIsCreated $wslName) {
        Write-Host "Destroy existing '$wslName' instance..."
        if (-Not(Remove-WslInstance $wslName)) {
            return $false
        }
    }

    # Check target directory does not exists or is empty
    $wslNameLocation = "$wslLocation/$wslName"
    if (Test-Path -Path $wslNameLocation) {
        $directoryInfo = Get-ChildItem $wslNameLocation | Measure-Object
        if (-Not ($directoryInfo.count -eq 0)) {
            Write-Host "Error: Directory $wslNameLocation already in use" -ForegroundColor Red
            return $false
        }
    }

    # Instance creation
    Write-Host "Restore '$wslName' with $backupTgz..."
    if (Test-Path -Path $wslNameLocation) {
        New-Item -ItemType Directory -Force -Path $wslNameLocation | Out-Null
    }
    & $wsl --import $wslName $wslNameLocation $backupTgzLocation --version 2

    return $true
}