## ----------------------------------------------------------------------------
## Verify all installation environment
## ----------------------------------------------------------------------------
function Install-WorkingEnvironment {
    # Check install directories
    if (-Not (Test-Path -Path $cacheLocation)) {
        New-Item -ItemType Directory -Force -Path $cacheLocation | Out-Null
    }
    if (-Not (Test-Path -Path $wslLocaltion)) {
        New-Item -ItemType Directory -Force -Path $wslLocaltion | Out-Null
    }
    if (-Not (Test-Path -Path $backupLocation)) {
        New-Item -ItemType Directory -Force -Path $backupLocation | Out-Null
    }
}