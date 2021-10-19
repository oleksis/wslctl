###############################################################################
# Author: Seres
#
#  This is a PowerShell wrapper around the inbuilt WSL CLI.
#  It simplifies the calls to wsl, by just allowing you  to call commands with
#  a simple "wslctl" call.
#  Best used with the path to the script in your PATH.
#
#  Building Executable:
#    > Install-Module -Name ps2exe -Scope CurrentUser
#    > ps2exe wslctl.ps1
#
#
# Note: WSL2 is available from windows 10 release id 2009+ (build 19041+)
# to check:
#   (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ReleaseId).ReleaseId => 2009
#   Get-CimInstance Win32_OperatingSystem | Select -ExpandProperty buildnumber => 19041+
###############################################################################

#Auto-load scripts on PowerShell startup
Get-ChildItem "${PSScriptRoot}\**\*.ps1" | ForEach-Object{.$_} 

$version = "1.0.5"
$username = "$env:UserName"
$wsl = 'c:\windows\system32\wsl.exe'



# Registry Properties
$endpoint = '\\qu1-srsrns-share.seres.lan\delivery\wsl\images'
$registryEndpoint = "$endpoint\register.json"

# Local Properties
$installLocation = "$env:LOCALAPPDATA/Wslctl"      # Installation User Directory
$wslLocaltion = "$installLocation/Instances"    # Wsl instances location storage
$cacheLocation = "$installLocation/Cache"       # Cache Location (Storage of distribution packages)
$backupLocation = "$installLocation/Backups"    # Backups Location (Storage of distribution packages)

$cacheRegistryFile = "$cacheLocation/register.json"    # Local copy of reistry endpoint
$backupRegistryFile = "$backupLocation/backups.json"  # Local backup register


###############################################################################
##
##                                 MAIN
##
###############################################################################

# Patch ps2exe to keep un*x like syntax (issue #1)
# Warning: flag option only with one minus will be converted with 2 minus
if ( ($args | Where { $_ -is [bool] }) ) {
    $args = $args | Where {$_ -is [String]}                                 # Filter non string arguments
    $args = $args | ForEach-Object { $_ -replace "^-([^-].*)", "--`${1}" }  # Change -option to --option
    if ($args -is [string]) { $args = @( "$args" ) }                        # Assert args is array
}

$command = $args[0]
if ($null -eq $command -or [string]::IsNullOrEmpty($command.Trim())) {
    Write-Host 'No command supplied' -ForegroundColor Red
    exit 1
}

Install-WorkingEnvironment

# Switch Statement on input Command
switch ($command) {

    # -- WSL managment commands -----------------------------------------------

    create {
        # Instanciate new wsl instance
        Assert-ArgumentCount $args 2 5
        $wslName = $null
        $distroName = $null
        $wslVersion = 2
        $createUser = $true

        $null, $args = $args
        foreach ($element in $args) {
            switch ($element) {
                --no-user { $createUser = $false }
                --v1      { $wslVersion = 1 }
                Default {
                    if ( $null -eq $wslName ) { $wslName = $element }
                    elseif ( $null -eq $distroName ) { $distroName = $element }
                    else {
                        Write-Host "Error: Invalid parameter" -ForegroundColor Red
                        exit 1
                    }
                }
            }
        }

        if ( $null -eq $distroName) { $distroName = $wslName }

        Write-Host "* Import $wslName"
        if (-Not (Import-Wsl $wslName $distroName $wslVersion)) { exit 1 }

        # Create default wsl user
        if ($createUser) {
            Write-Host "* Create default wsl user"
            if (-Not (Initialize-WslInstanceDefaultUser $wslName )) { exit 1 }
        }

        # Restart instance
        Write-Host "* $wslName created"
        Write-Host "  Could be started with command: wslctl start $wslName"
    }

    { @("rm", "remove") -contains $_ } {
        # Remove the specified wsl instance
        Assert-ArgumentCount $args 2
        $wslName = $args[1]
        if (Remove-WslInstance $wslName) {
            Write-Host "*  $wslName removed"
        }
    }

    { @("ls", "list") -contains $_ } {
        # List all wsl installed
        Assert-ArgumentCount $args 1
        Write-Host "Wsl instances:" -ForegroundColor Yellow
        Get-WslInstances | ForEach-Object { (" " * 2) + $_ } | Sort-Object
    }

    start {
        # Starts wsl instance by starting a long bash background process in it
        Assert-ArgumentCount $args 2
        $wslName = $args[1]
        & $wsl --distribution $wslName bash -c "nohup sleep 99999 </dev/null >/dev/null 2>&1 & sleep 1"
        if ($?) { Write-Host "*  $wslName started" ; }
    }

    stop {
        # Stop wsl instances
        Assert-ArgumentCount $args 2
        $wslName = $args[1]
        & $wsl --terminate $wslName
        if ($?) { Write-Host "*  $wslName stopped" }
    }

    status {
        Assert-ArgumentCount $args 1 2
        if ($args.count -eq 1) {
            # List all wsl instance status
            # Remove wsl List header and display own
            Write-Host "Wsl instances status:" -ForegroundColor Yellow
            Get-WslInstancesWithStatus
        }
        else {
            # List status for specific wsl instance
            $wslName = $args[1]
            Get-WslInstanceStatus $wslName
        }
    }

    build {
        # build [<Wslfile path>] [<--dry-run>]
        Assert-ArgumentCount $args 1 3

        $dryRun=$false
        $wslFile = "./Wslfile" # Default file name in directory
        for ($index = 1; $index -lt $args.length; $index++){
            switch ($args[$index]){
                --dry-run { $dryRun = $true }
                Default   { $wslFile = $args[$index] }
            }
        }   
        if (-Not (Test-Path $wslFile -PathType leaf)){
            Write-Host "Error: Invalid parameter $wslFile not found" -ForegroundColor Red
            exit 1
        }
        $wslFullPath = Resolve-Path -Path $wslFile -ErrorAction Stop
        # target wsl distro is parent directory name
        $wslFileDirectory = (get-item $wslFullPath).Directory
        
        
        # Translate WSLfile to Bash commands
        $normalizedCommandHash = Get-Content $wslFullPath | ConvertFrom-WSLFile
        $fromDistroName = $normalizedCommandHash.from
        $wslTargetDistroName = $wslFileDirectory.Name
        if (-Not $fromDistroName){
            Write-Host "Error: Invalid file: no FROM property found" -ForegroundColor Red
            exit 1
        }
        $bashArray = $normalizedCommandHash | ConvertTo-WSLBashCommands -WorkingDirectory $wslFileDirectory
        
        if ($dryRun) { 
            Write-Host "Base Distro name  : $fromDistroName" 
            Write-Host "Target Distro name: $wslTargetDistroName" 
            Write-Host 
            Write-Host "--------------Generated Script File --------------------"
            ($bashArray -Join "`n") 
            Write-Host "--------------------------------------------------------"
            exit
        }
        
        # Create Temp file with proper extension and set its content
        $tempBashWinFile = Get-ChildItem ([IO.Path]::GetTempFileName()) | `
            Rename-Item -NewName { [IO.Path]::ChangeExtension($_, ".sh") } -PassThru
        ($bashArray -Join "`n") | Set-Content $tempBashWinFile

        # Create target distribution name and execute script file
        self create $wslname $fromDistroName --no-user
        self exec $wslname $tempBashWinFile
        $exitCode = $LastExitCode
        exit $exitCode
    }

    exec {
        # exec <instance> [|<file.sh>|<remote_cmd_with_args>]
        Assert-ArgumentCount $args 2 50

        ($null, [string]$wslName, [array]$commandline) = $args
        if ($null -eq $commandline ) { $commandline=@() }

        
        # Check wslname instance already exists
        if (-Not (Test-WslInstanceIsCreated $wslName)) {
            Write-Host "Error: Instance '$wslName' does not exists" -ForegroundColor Red
            exit 1
        }

        if (-not($commandline)){
            # No commands: connect to distribution
            Write-Host "Connect to $wslName ..." -ForegroundColor Yellow
            & $wsl --distribution $wslName
            exit $LastExitCode
        } 

        # Command passed 
        # Check local script:Resolv windows full path to the script
        try { $winScriptFullPath = Resolve-Path -Path $commandline[0] -ErrorAction Stop }
        catch {}
        
        if ($winScriptFullPath){

            # Check script extension
            if (-Not ([IO.Path]::GetExtension($winScriptFullPath) -eq '.sh')) {
                Write-Host "Error: script has to be a shell file (.sh)" -ForegroundColor Red
                exit 1
            }
            ([string]$script, [array]$scriptArgs) = $commandline
            $scriptInWslPath = ConvertTo-WslPath $winScriptFullPath
            $scriptNoPath = Split-Path $script -leaf
            $scriptTmpFile = "/tmp/$scriptNoPath"
            # Copy script file to instance and pass original script path in SCRIPT_WINPATH env variable
            # Call remote script with args
            Write-Host "Execute $scriptNoPath on $wslName ..." -ForegroundColor Yellow
            & $wsl --distribution $wslName --exec cp $scriptInWslPath $scriptTmpFile
            & $wsl --distribution $wslName --exec chmod +x $scriptTmpFile
            & $wsl --distribution $wslName -- SCRIPT_WINPATH=$scriptInWslPath $scriptTmpFile $scriptArgs
            $exitCode = $LastExitCode
            & $wsl --distribution $wslName --exec rm $scriptTmpFile
            exit $exitCode
        } 
        # Standard command to send 
        Write-Host "Execute command '$commandline' on $wslName ..." -ForegroundColor Yellow
        & $wsl --distribution $wslName -- SCRIPT_WINPATH= $commandline
        exit $LastExitCode
    }

    halt {
        # stop all wsl instances
        Assert-ArgumentCount $args 1
        & $wsl --shutdown
        Write-Host "* Wsl halted"
    }


    # -- Wsl distribution registry commands ---------------------------------

    registry {
        Assert-ArgumentCount $args 2 3
        $subCommand = $args[1]

        switch ($subCommand) {

            update {
                # Update the cache registry file (in cache)
                Assert-ArgumentCount $args 2
                if (-Not (Copy-File $registryEndpoint $cacheRegistryFile)) {
                    Write-Host "Error: Registry endpoint not reachable" -ForegroundColor Red
                    exit 1
                }
                Write-Host "* Local registry updated"
            }

            purge {
                # remove the cache directory
                Assert-ArgumentCount $args 2
                Remove-Item -LiteralPath $cacheLocation -Force -Recurse -ErrorAction Ignore | Out-Null
                Write-Host "* Local registry cache cleared"
            }

            search {
                # Search available distribution by regexp
                Assert-ArgumentCount $args 3
                $pattern = $args[2]
                Write-Host "Available distributions from pattern '$pattern':" -ForegroundColor Yellow
                (Convert-JsonToHashtable $cacheRegistryFile).GetEnumerator() | ForEach-Object { 
                    if ($_.Key -match ".*$pattern.*") {
                        "{0,-28} - {1,1} - {2,15} - {3,1}" -f  $_.Key,$_.Value.date,$_.Value.size,$_.Value.message
                    }
                } | Sort
            }

            { @("ls", "list") -contains $_ } {
                # List register keys
                Assert-ArgumentCount $args 2
                Write-Host "Available Distributions (installable):" -ForegroundColor Yellow
                (Convert-JsonToHashtable $cacheRegistryFile).GetEnumerator() |  ForEach-Object {
                    "{0,-28} - {1,1} - {2,15} - {3,1}" -f  $_.Key,$_.Value.date,$_.Value.size,$_.Value.message
                } | Sort
            }

            Default {
                Write-Host "Error: Command '$command $subCommand' is not defined" -ForegroundColor Red
                exit 1
            }
        }
    }


    # -- Wsl backup management commands ---------------------------------------

    backup {
        Assert-ArgumentCount $args 2 4
        $subCommand = $args[1]

        switch ($subCommand) {
            create {
                # Backup a existing wsl instance
                Assert-ArgumentCount $args 4
                $wslName = $args[2]
                $backupAnnotation = $args[3]

                Write-Host "* Backup '$wslName'"
                if (-Not (Backup-Wsl $wslName "$backupAnnotation")) { exit 1 }
                Write-Host "* Backup complete"
            }

            restore {
                # Restore a previously backuped wsl instance
                Assert-ArgumentCount $args 3 4
                $backupName = $args[2]
                $forced = $false
                if ($args.count -eq 4) {
                    if ($args[3] -ne "--force") {
                        Write-Host 'Error: invalid parameter' -ForegroundColor Red
                        exit 1
                    }
                    $forced = $true
                }
                Write-Host "* Restore '$backupName'"
                if (-Not (Restore-Wsl $backupName $forced)) { exit 1 }
                Write-Host "* Restore complete"
            }

            purge {
                # Remove the backup directory
                Assert-ArgumentCount $args 2
                Remove-Item -LiteralPath $backupLocation -Force -Recurse -ErrorAction Ignore | Out-Null
                Write-Host "* Backup storage cleared"
            }

            { @("rm", "remove") -contains $_ } {
                # Remove a backup by name
                Assert-ArgumentCount $args 3
                $backupName = $args[2]

                $backupProperties = Get-JsonKeyValue $backupRegistryFile $backupName
                if ($null -eq $backupProperties) {
                    Write-Host "Error: Backup '$backupName' does not exists" -ForegroundColor Red
                    return $false
                }
                $backupTgz = $backupProperties.archive
                $backupTgzFile = "$backupLocation/$backupTgz"
                if (Test-Path -Path $backupTgzFile) {
                    Write-Host "Delete Archive $backupTgz..."
                    Remove-Item -Path $backupTgzFile -Force -ErrorAction Ignore | Out-Null
                }
                Write-Host "Delete backup registry entry..."
                Remove-JsonKey $backupRegistryFile $backupName
                Write-Host "* Backup '$backupName' removed"
            }

            search {
                # Search available backup by regexp
                Assert-ArgumentCount $args 3
                $pattern = $args[2]
                Write-Host "Available backup from pattern '$pattern':" -ForegroundColor Yellow
                (Convert-JsonToHashtable $backupRegistryFile).GetEnumerator() | ForEach-Object { 
                    if ($_.Key -match ".*$pattern.*") {
                        "{0,-28} - {1,1} - {2,15} - {3,1}" -f  $_.Key,$_.Value.date,$_.Value.size,$_.Value.message
                    }
                } | Sort
            }

            { @("ls", "list") -contains $_ } {
                # List backup resister keys
                Assert-ArgumentCount $args 2
                Write-Host "Available Backups (recoverable):" -ForegroundColor Yellow
                (Convert-JsonToHashtable $backupRegistryFile).GetEnumerator() |  ForEach-Object {
                    "{0,-28} - {1,1} - {2,15} - {3,1}" -f  $_.Key,$_.Value.date,$_.Value.size,$_.Value.message
                } | Sort
            }

            Default {
                Write-Host "Error: Command '$command $subCommand' is not defined" -ForegroundColor Red
                exit 1
            }
        }
    }


    # -- Others commands ------------------------------------------------------

    { @("--version", "version") -contains $_ } { Write-Host "$version" }

    { @("--help", "help") -contains $_ } { Show-Help }

    { @("--wsl-default-version", "wsl-default-version") -contains $_ } {
        Assert-ArgumentCount $args 1 2
        if ($args.count -eq 1) {
            # Get the default wsl version
            Get-ItemPropertyValue -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss -Name DefaultVersion
        }
        else {
            # List status for specific wsl instance
            $wslDefaultVersion = $args[1]
            & $wsl --set-default-version $wslDefaultVersion
        }
    }

    # -- Undefined commands ---------------------------------------------------
    Default {
        Write-Host "Error: Command '$command' is not defined" -ForegroundColor Red
        exit 1
    }
}
