
## ----------------------------------------------------------------------------
## Import wsl with cache management
## ----------------------------------------------------------------------------
function Import-Wsl {
    [OutputType('bool')]
    Param( [string]$wslName, [string]$distroName, [int]$wslVersion = 2)

    # Check wslname instance not already exists
    if (Test-WslInstanceIsCreated $wslName) {
        Write-Host "Error: Instance '$wslName' already exists" -ForegroundColor Red
        return $false
    }
    # Check target directory does not exists or is empty
    $wslNameLocation = "$wslLocaltion/$wslName"
    if (Test-Path -Path $wslNameLocation) {
        $directoryInfo = Get-ChildItem $wslNameLocation | Measure-Object
        if (-Not ($directoryInfo.count -eq 0)) {
            write-host "Error: Directory $wslNameLocation already in use" -ForegroundColor Red
            return $false
        }
    }
    # Get distroname definition
    $distroProperties = Get-JsonKeyValue $cacheRegistryFile $distroName
    if ($null -eq $distroProperties) {
        Write-Host "Error: Distribution '$distroName' not found in registry" -ForegroundColor Red
        Write-Host "  - Please use the 'update' command to refresh the registry."
        return $false
    }
    $distroRealSha256 = $distroProperties.sha256
    $distroPackage  = $distroProperties.archive
    $distroEndpoint = "$endpoint\$distroPackage"
    $distroLocation = "$cacheLocation\$distroPackage"

    # Distribution Cache Management:
    if (-Not (Test-Path -Path $distroLocation)) {
        Write-Host "Dowload distribution '$distroName' ..."
        if (-Not (Copy-File $distroEndpoint $distroLocation)) {
            Write-Host "Error: Registry endpoint not reachable" -ForegroundColor Red
            return $false
        }
        # Check integrity
        Write-Host "Checking integrity ($distroRealSha256)..." 
        $distroLocationHash = (Get-FileHash $distroLocation -Algorithm SHA256).Hash.ToLower()
        if (-Not ($distroLocationHash -eq $distroRealSha256)){
            Write-Host "Error: Archive File integrity mismatch. Found '$distroLocationHash'" -ForegroundColor Red
            Write-Host "       removing  $distroLocation" -ForegroundColor Red
            Remove-Item -Path $distroLocation -Force -ErrorAction Ignore | Out-Null
            return $false
        }
    }
    else {
        Write-Host "Distribution '$distroName' already cached ..."
    }

    # Instance creation
    Write-Host "Create wsl instance '$wslName'..."
    if (Test-Path -Path $wslNameLocation) {
        New-Item -ItemType Directory -Force -Path $wslNameLocation | Out-Null
    }
    & $wsl --import $wslName $wslNameLocation $distroLocation --version $wslVersion
    # Adjust Wsl Distro Name
    & $wsl --distribution $wslName sh -c "echo WSL_DISTRO_NAME=$wslName > /lib/init/wsl-distro-name.sh"
    return $true
}