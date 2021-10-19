
## ----------------------------------------------------------------------------
## Backup wsl instance
## ----------------------------------------------------------------------------
function Backup-Wsl {
    [OutputType('bool')]
    Param( [string]$wslName, [string]$backupAnnotation)
    $backupdate = Get-Date -Format "yyyy/MM/dd HH:mm:ss"

    # Check wslname instance already exists
    if (-Not (Test-WslInstanceIsCreated $wslName)) {
        Write-Host "Error: Instance '$wslName' does not exists" -ForegroundColor Red
        return $false
    }

    Write-Host "Compute backup name ..."
    #$backupName = "$wslName-$backupdate"
    # Read the next backup name for the specified wsl name instance
    $backupPrePattern = "$wslName-bkp"
    $bkpNumber = 0
    Get-JsonKeyList $backupRegistryFile | Where-Object { $_ -like "$backupPrePattern.*" } | ForEach-Object {
        # remove wslname and backup string from key to get the number
        $bkpPreviousNumber = [int]($_.Split('.')[-1])
        if ($bkpPreviousNumber -ge $bkpNumber) {
            $bkpNumber = $bkpPreviousNumber + 1
        }
    }
    $bkpNumberStr = '{0:d2}' -f $bkpNumber
    $backupName = "$backupPrePattern.$bkpNumberStr"
    Write-Host "Backup name is: $backupName"

    $backupTar = "$backupName-amd64-wsl-rootfs.tar"
    $backupTgz = "$backupTar.gz"

    # Stop if required
    if (Test-WslInstanceIsRunning $wslName) {
        Write-Host "Stop instance '$wslName'"
        & $wsl --terminate $wslName
    }
    # Export WSL
    Write-Host "Export wsl '$wslName' to $backupTar..."
    & $wsl --export $wslName $backupTar
    Write-Host "Compress $backupTar to $backupTgz..."
    & $wsl --distribution $wslName --exec gzip $backupTar
    Write-Host "Compute Backup Hash..."
    $backupHash = (Get-FileHash $backupTgz -Algorithm SHA256).Hash.ToLower()
    Write-Host "Compute File Size"
    $backupSize = (Get-HumanReadableFileSize -Path $backupTgz).Size
    Write-Host "Move to backup directory..."
    Move-Item -Path $backupTgz -Destination "$backupLocation/$backupTgz" -Force

    # Finally append backup to the register
    Set-JsonKeyValue $backupRegistryFile "$backupName" @{
        wslname = $wslName
        message = $backupAnnotation
        archive = $backupTgz
        sha256  = $backupHash
        size    = $backupSize
        date    = $backupdate
    }
    Write-Host "$wslName backuped as $backupTgz (SHA256: $backupHash)"
    return $true
}