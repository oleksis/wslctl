## ----------------------------------------------------------------------------
## Verify all installation environment
## ----------------------------------------------------------------------------
function Install-WorkingEnvironment {
    # Check install directories
    if (-Not (Test-Path -Path $cacheLocation)) {
        New-Item -ItemType Directory -Force -Path $cacheLocation | Out-Null
    }
    if (-Not (Test-Path -Path $wslLocation)) {
        New-Item -ItemType Directory -Force -Path $wslLocation | Out-Null
    }
    if (-Not (Test-Path -Path $backupLocation)) {
        New-Item -ItemType Directory -Force -Path $backupLocation | Out-Null
    }
}
