
## ----------------------------------------------------------------------------
## Transform a windows path to a wsl access path
## ----------------------------------------------------------------------------
function ConvertTo-WslPath {
    [OutputType('string')]
    Param([Parameter(Mandatory = $true)][string]$path)
    wsl 'wslpath' -u $path.Replace('\', '\\');
}


## ----------------------------------------------------------------------------
## Check if a named wsl instance is Running
## ----------------------------------------------------------------------------
function Test-WslInstanceIsRunning {
    [OutputType('bool')]
    Param( [Parameter(Mandatory = $true)][string]$wslName )
    # Inexplicably, wsl --list --running produces UTF-16LE-encoded ("Unicode"-encoded) output
    # rather than respecting the console's (OEM) code page.
    $prev = [Console]::OutputEncoding; [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
    $isrunning = [bool](& $wsl --list --running | Select-String -Pattern "^$wslName *"  -quiet)
    [Console]::OutputEncoding = $prev
    if ($isRunning) { return $true; } else { return $false; }
}

## ----------------------------------------------------------------------------
## Check if a named wsl instance has been created
## ----------------------------------------------------------------------------
function Test-WslInstanceIsCreated {
    [OutputType('bool')]
    Param( [Parameter(Mandatory = $true, ValueFromPipeline = $true)][string]$wslName )
    # Inexplicably, wsl --list --running produces UTF-16LE-encoded ("Unicode"-encoded) output
    # rather than respecting the console's (OEM) code page.
    $prev = [Console]::OutputEncoding; [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
    $exists = [bool](& $wsl --list --verbose | Select-String -Pattern " +$wslName +" -quiet)
    [Console]::OutputEncoding = $prev
    if ($exists) { return $true; } else { return $false; }
}


## ----------------------------------------------------------------------------
## Array of installed distributions
## ----------------------------------------------------------------------------
function Get-WslInstances {
    [OutputType('array')]
    # Inexplicably, wsl --list --running produces UTF-16LE-encoded ("Unicode"-encoded) output
    # rather than respecting the console's (OEM) code page.
    $prev = [Console]::OutputEncoding; [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
    $result = (& $wsl --list | Select-Object -Skip 1) | Where-Object { $_ -ne "" }
    [Console]::OutputEncoding = $prev
    return $result
}


## ----------------------------------------------------------------------------
## Array of installed distribution with status
## ----------------------------------------------------------------------------
function Get-WslInstancesWithStatus {
    [OutputType('array')]
    # Inexplicably, wsl --list --running produces UTF-16LE-encoded ("Unicode"-encoded) output
    # rather than respecting the console's (OEM) code page.
    $prev = [Console]::OutputEncoding; [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
    $result = (& $wsl --list --verbose | Select-Object -Skip 1) | Where-Object { $_ -ne "" }
    [Console]::OutputEncoding = $prev
    return $result
}

## ----------------------------------------------------------------------------
## Get wsl instance status
## ----------------------------------------------------------------------------
function Get-WslInstanceStatus {
    #[OutputType('string')]
    Param( [Parameter(Mandatory = $true, ValueFromPipeline = $true)][string]$wslName )
    if (-Not (Test-WslInstanceIsCreated $wslName)) {
        return "* $wslName is not a wsl instance"
    }
    else {
        return ((Get-WslInstancesWithStatus | Select-String -Pattern " +$wslName +" | Out-String).Trim() -Split '[\*\s]+'  | Where-Object {$_})[1]
    }
}


## ----------------------------------------------------------------------------
## Remove a named wsl instance
## ----------------------------------------------------------------------------
function Remove-WslInstance {
    [OutputType('bool')]
    Param( [Parameter(Mandatory = $true, ValueFromPipeline = $true)][string]$wslName )
    if (-Not (Test-WslInstanceIsCreated $wslName)) {
        Write-Host "Error: Instance '$wslName' not found" -ForegroundColor Red
        return $false;
    }
    & $wsl --unregister $wslName
    if ($?) { return $true; } else { return $false; }
}

## ----------------------------------------------------------------------------
## Setup wsl instance default user
## ----------------------------------------------------------------------------
function Initialize-WslInstanceDefaultUser {
    [OutputType('bool')]
    Param( [Parameter(Mandatory = $true, ValueFromPipeline = $true)][string]$wslName )
    if (-Not (Test-WslInstanceIsCreated $wslName)) {
        Write-Host "Error: Instance '$wslName' not found" -ForegroundColor Red
        return $false;
    }
    & $wsl --distribution $wslName --exec /usr/sbin/addgroup --gid 1000 $username
    & $wsl --distribution $wslName --exec /usr/sbin/adduser --quiet --disabled-password --gecos `` --uid 1000 --gid 1000 $username
    & $wsl --distribution $wslName --exec /usr/sbin/usermod -aG sudo $username
    & $wsl --distribution $wslName --% /usr/sbin/usermod --password $(/usr/bin/openssl passwd -crypt ChangeMe) $(/usr/bin/id -nu 1000)
    & $wsl --distribution $wslName --% /usr/bin/printf '\n[user]\ndefault=%s\n' $(/usr/bin/id -nu 1000) >> /etc/wsl.conf
    & $wsl --terminate $wslName
    return $true;
}
