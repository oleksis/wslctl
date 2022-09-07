
using module "..\Application\AppConfig.psm1"
using module "..\Application\ServiceLocator.psm1"
using module "..\Tools\FileUtils.psm1"
using module "..\Model\JsonHashtableFile.psm1"


Class WslService
{

    [String] $Binary
    [String] $Location
    [String] $File
    [String] $defaultUsename
    [String] $defaultPassword

    [JsonHashtableFile] $Instances


    WslService()
    {
        $Config = ([AppConfig][ServiceLocator]::getInstance().get('config'))

        $this.Binary = 'c:\windows\system32\wsl.exe'
        if ( $Config.ContainsKey("wsl")) { $this.Binary = $Config.wsl }
        $this.Location = [FileUtils]::joinPath($Config.appData, "Instances")
        $this.defaultUsename = "$env:UserName"
        $this.defaultPassword = "ChangeMe"

        $this.File = [FileUtils]::joinPath($Config.appData, "wsl-instances.json")
        $this._initialize()
    }

    [void] _initialize()
    {
        if (-Not (Test-Path -Path $this.Location))
        {
            New-Item -ItemType Directory -Force -Path $this.Location | Out-Null
        }
    }

    [void] _loadFile()
    {
        if (-Not $this.Instances)
        {
            $this.Instances = [JsonHashtableFile]::new($this.File, @{})
        }
    }

    [String] getLocation([String] $name)
    {
        return  [FileUtils]::joinPath($this.Location, $name)
    }


    [void] checkBeforeImport([String] $name) { $this.checkBeforeImport($name, $false) }
    [void] checkBeforeImport([String] $name, [Boolean] $forced)
    {
        if (($this.exists($name)) -And (-Not $forced))
        {
            throw "Instance '$name' already exists"
        }

        # Remove existing instance
        if ($this.exists($name) -and $this.remove($name) -ne 0)
        {
            throw "Can not destroy active $name"
        }

        # Check target directory does not exists or is empty
        $dir = $this.getLocation($name)
        if (Test-Path -Path $dir)
        {
            $directoryInfo = Get-ChildItem $dir | Measure-Object
            if (-Not ($directoryInfo.count -eq 0))
            {
                if (-not $forced)
                {
                    throw "Directory $dir already in use"
                }
                Remove-Item -LiteralPath $dir -Force -Recurse -ErrorAction Ignore | Out-Null

            }
        }

    }

    [Int32] import ([String] $name, [String] $from, [String] $archive) { return $this.import($name, $from, $archive, -1, $false) }
    [Int32] import ([String] $name, [String] $from, [String] $archive, [int] $version, [Boolean]$createDefaultUser)
    {
        if (($version -lt 1) -or ($version -gt 2))
        {
            $version = -1
        }
        if ($version -eq -1)
        {
            $version = $this.getDefaultVersion()
        }

        $dir = $this.getLocation($name)
        if (Test-Path -Path $dir)
        {
            New-Item -ItemType Directory -Force -Path $dir | Out-Null
        }

        & $this.Binary --import $name $dir $archive --version $version
        if ($LastExitCode -ne 0)
        {
            throw "Could not create '$name' instance"
        }

        # Adjust Wsl Distro Name
        & $this.Binary --distribution $name sh -c "mkdir -p /lib/init && echo WSL_DISTRO_NAME=$name > /lib/init/wsl-distro-name.sh"
        if ($LastExitCode -ne 0)
        {
            throw "Could not set '$name' /lib/init/wsl-distro-name.sh"
        }
        $returnCode = 0

        $this._loadFile()
        $this.Instances.Add($name, @{
                image    = $from
                creation = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
            })
        $this.Instances.commit()

        # copy val_ini script (suppose /usr/local/bin on all OS)
        $iniValPath = "$(Split-Path -Parent -Path $PSScriptRoot)/Resource/ini_val.sh"
        $this.copy($name, $iniValPath, "/usr/local/bin/ini_val")

        # Assert *nix file format
        $commandLine = @(
            "sed -i 's/\r//' /usr/local/bin/ini_val"
            "chmod +x /usr/local/bin/ini_val"
            )

        # create default user
        if ($createDefaultUser)
        {
            $commandLine += @(
                "/usr/sbin/addgroup --gid 1000 $($this.defaultUsename)"
                "/usr/sbin/adduser --quiet --disabled-password --gecos '' --uid 1000 --gid 1000 $($this.defaultUsename)"
                "/usr/sbin/usermod -aG sudo $($this.defaultUsename)"
                "userpass=`$(/usr/bin/openssl passwd -1 $($this.defaultPassword))"
                "/usr/sbin/usermod --password `$userpass $($this.defaultUsename)"
                "/usr/local/bin/ini_val /etc/wsl.conf user.default $($this.defaultUsename)"
            )
        }

        # set the wsl instance hostname
        $commandLine += "/usr/local/bin/ini_val /etc/wsl.conf network.hostname $($name)"
        $commandLineTxt = $commandLine -Join ";"
        Write-Verbose $commandLineTxt

        # execute all
        $returnCode = $this.exec($name, @( "$commandLineTxt" ))
        & $this.Binary --terminate $name
        return $returnCode
    }

    [System.Collections.Hashtable] export([String] $name, [String] $archiveName)
    {
        if ($this.isRunning($name))
        {
            Write-Host "Stop instance '$name'"
            $this.terminate($name)
        }

        $backupTar = "$archiveName-amd64-wsl-rootfs.tar"
        $backupTgz = "$backupTar.gz"

        # Export WSL
        & $this.Binary --export $name $backupTar
        & $this.Binary --distribution $name --exec gzip $backupTar

        $backupHash = [FileUtils]::sha256($backupTgz)
        $backupSize = [FileUtils]::getHumanReadableSize($backupTgz).Size
        $version = $this.version($name)

        $this._loadFile()
        $image = $null
        $creation = $null
        if ($this.Instances.ContainsKey($name))
        {
            $image = $this.Instances.$name.image
            $creation = $this.Instances.$name.creation
        }

        # Finally append backup to the register
        $backupdate = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
        return @{
            wslname    = $name
            image      = $image
            wslversion = $version
            archive    = $backupTgz
            sha256     = $backupHash
            size       = $backupSize
            date       = $backupdate
            creation   = $creation
        }
    }

    [int] convert([String] $name, [int]$version)
    {
        if ($this.isRunning($name))
        {
            Write-Host "Stop instance '$name'"
            $this.terminate($name)
        }

        &  $this.Binary  --set-version $name $version
        return $LastExitCode
    }

    [int32] start([String] $name)
    {
        # warning: wsl binary always returns 0 even if no distribution exists
        &  $this.Binary --distribution $name bash --login -c "nohup sleep 99999 </dev/null >/dev/null 2>&1 & sleep 1"
        return $LastExitCode
    }

    [Int32] terminate([String] $name)
    {
        & $this.Binary --terminate $name
        return $LastExitCode
    }

    [Int32] shutdown()
    {
        & $this.Binary --shutdown
        return $LastExitCode
    }


    [Boolean] isRunning([String] $name)
    {
        # Inexplicably, wsl --list --running produces UTF-16LE-encoded
        # ("Unicode"-encoded) output rather than respecting the
        # console's (OEM) code page.
        $prev = [Console]::OutputEncoding;
        [Console]::OutputEncoding = [System.Text.Encoding]::Unicode

        $isrunning = [bool](& $this.Binary --list --running |`
                Select-String -Pattern "^$name *"  -Quiet)

        [Console]::OutputEncoding = $prev
        return $isRunning
    }


    [Boolean] exists([String] $name)
    {
        # Inexplicably, wsl --list --running produces UTF-16LE-encoded
        # ("Unicode"-encoded) output rather than respecting the
        # console's (OEM) code page.
        $prev = [Console]::OutputEncoding;
        [Console]::OutputEncoding = [System.Text.Encoding]::Unicode

        $exists = [bool](& $this.Binary --list --verbose |`
                Select-String -Pattern " +$name +" -Quiet)

        [Console]::OutputEncoding = $prev
        return $exists
    }

    [Array] list()
    {
        # Inexplicably, wsl --list --running produces UTF-16LE-encoded
        # ("Unicode"-encoded) output rather than respecting the
        # console's (OEM) code page.
        $prev = [Console]::OutputEncoding;
        [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
        $result = @( (& $this.Binary --list | Select-Object -Skip 1) | Where-Object { $_ -ne "" } )
        [Console]::OutputEncoding = $prev
        $this._loadFile()

        $final = @()
        $final += $result.GetEnumerator() | ForEach-Object {
            $default = " "
            $name = $_
            $from = "-"
            $creation = "-"

            if ("$_" -match "^(?<name>[^ ]*) (?<default>.*)$")
            {
                $default = "*"
                $name = $matches['name'].Trim()
            }
            if ($this.Instances.ContainsKey($name))
            {
                $from = $this.Instances.$name.image
                $creation = $this.Instances.$name.creation
            }
            "{0,1} {1,-23}   {2,-20}   {3,1}" -f $default, $name, $creation, $from
        }
        return $final
    }

    [String] status([String] $name)
    {
        if (-Not $this.exists($name))
        {
            return "* $name is not a wsl instance"
        }
        return ( ($this.statusAll() | Select-String -Pattern " +$name +" | Out-String).Trim() -Split '[\*\s]+' |`
                Where-Object { $_ } )[1]
    }

    [int] version([String] $name)
    {
        if (-Not $this.exists($name))
        {
            return -1
        }
        return [int]( ($this.statusAll() | Select-String -Pattern " +$name +" | Out-String).Trim() -Split '[\*\s]+' |`
                Where-Object { $_ } )[2]

    }

    [String] getDefaultDistribution()
    {
        return (($this.statusAll() | Select-String -Pattern "\*" | Out-String).Trim()  -Split '[\*\s]+' |`
            Where-Object { $_ } )[0]
    }

    [String] setDefaultDistribution([String] $name)
    {
        if (-Not $this.exists($name))
        {
            return -1
        }

        & $this.Binary --set-default $name
        return $LastExitCode
    }

    [String[]] statusAll()
    {
        # Inexplicably, wsl --list --running produces UTF-16LE-encoded
        # ("Unicode"-encoded) output rather than respecting the
        # console's (OEM) code page.
        $prev = [Console]::OutputEncoding;
        [Console]::OutputEncoding = [System.Text.Encoding]::Unicode

        $result = (& $this.Binary --list --verbose | Select-Object -Skip 1) | Where-Object { $_ -ne "" }

        [Console]::OutputEncoding = $prev
        return [String[]]$result
    }


    [Int32] remove([String] $name)
    {
        if (-Not $this.exists($name))
        {
            throw "Instance '$name' not found"
        }

        & $this.Binary --unregister $name
        if ($LastExitCode -ne 0)
        {
            throw "Enable to remove '$name' instance"
        }
        $this._loadFile()
        if ($this.Instances.ContainsKey($name))
        {
            write-host "Remove '$name'"
            $this.Instances.Remove($name)
            $this.Instances.commit()
        }

        $dir = $this.getLocation([String] $name)
        Remove-Item -LiteralPath $dir -Force -Recurse -ErrorAction Ignore | Out-Null
        return $LastExitCode
    }

    [Int32] connect([string]$name)
    {
        return $this.exec($name, @("/bin/bash --login"))
    }

    [Int32] exec([string]$name, [string]$scriptPath, [array]$scriptArgs)
    {
        if (-Not ([IO.Path]::GetExtension($scriptPath) -eq '.sh'))
        {
            throw "Script has to be a shell file (extension '.sh')"
        }
        if (-not (Test-Path $scriptPath -PathType leaf))
        {
            throw "Script not found"
        }
        $winScriptFullPath = Resolve-Path -Path $scriptPath -ErrorAction Stop
        $wslScriptPath = $this.wslPath($winScriptFullPath)
        $scriptNoPath = Split-Path $scriptPath -Leaf
        $scriptTmpFile = "/tmp/$scriptNoPath"

        $commandLine = @(
            "cp $wslScriptPath $scriptTmpFile"
            "chmod +x $scriptTmpFile"
            "SCRIPT_WINPATH=$wslScriptPath $scriptTmpFile $scriptArgs"
            "return_code=`$?"
            "rm $scriptTmpFile"
            "exit `$return_code"
        ) -Join ";"
        return $this.exec($name, @( "$commandLine" ))
    }

    [Int32] exec([string]$name, [array]$commandline)
    {
        if ($null -eq $commandline ) { $commandline = @() }
        if (-Not $this.exists($name))
        {
            throw "Instance '$name' not found"
        }

        $processArgs = "--distribution $name -- $commandline"
        $process = Start-Process $this.Binary $processArgs -NoNewWindow -Wait -ErrorAction Stop -PassThru
        return $process.ExitCode
    }

    [int32] copy([string]$name, [string]$winSrcPath, [string]$wslDestPath)
    {
        # check file exists
        if (-not (Test-Path $winSrcPath -PathType leaf))
        {
            throw "File not found"
        }

        # resolve windows full path
        $winSrcFullPath = Resolve-Path -Path $winSrcPath -ErrorAction Stop
        # get same file accessible from wsl
        $wslSrcFullPath = $this.wslPath($winSrcFullPath)
        $commandLine = @(
            "cp $wslSrcFullPath $wslDestPath"
            "return_code=`$?"
            "exit `$return_code"
        ) -Join ";"
        return $this.exec($name, @( "$commandLine" ))
    }

    [String] wslPath([String] $winPath)
    {
        return & $this.Binary wslpath -u $winPath.Replace('\', '\\')
    }


    [String] winPath([String] $wslPath)
    {
        return & $this.Binary wslpath -w $wslPath.Replace('\', '\\')
    }


    [Int32] setDefaultVersion([int] $version)
    {
        if (($version -lt 1) -or ($version -gt 2))
        {
            throw "Invalid version number $version"
        }
        & $this.Binary --set-default-version $version
        return $LastExitCode
    }

    [String] getDefaultVersion()
    {
        # Get the default wsl version
        return Get-ItemPropertyValue `
            -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss `
            -Name DefaultVersion
    }
}
