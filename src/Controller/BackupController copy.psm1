
using module "..\Application\ServiceLocator.psm1"
using module "..\Application\AppConfig.psm1"
using module "..\Application\AbstractController.psm1"
using module "..\Service\WslService.psm1"
using module "..\Tools\FileUtils.psm1"
using module "..\Tools\ExtendedConsole.psm1"
using module "..\Model\JsonHashtableFile.psm1"

Class BackupController : AbstractController
{

    [String] $Location
    [String] $File
    [String] $WslLocation
    [System.Collections.Hashtable] $Hashtable

    BackupController() : base()
    {
        $Config = [AppConfig][ServiceLocator]::getInstance().get('config')

        $this.Location = $Config.Backup.Location
        $this.File = $Config.Backup.File
        $this.WslLocation = $Config.Wsl.Location

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
        if (-Not $this.Hashtable)
        {
            $this.Hashtable = [JsonHashtableFile]::new($this.File, @{})
        }
    }

    [void] _commit()
    {
        $this.Hashtable.commit()
    }

    [String] _generateName([String] $wslName)
    {
        $this._loadFile()
        $backupPrePattern = "$wslName-bkp"
        $bkpNumber = 0
        $this.Hashtable.keys | Where-Object { $_ -like "$backupPrePattern.*" } | ForEach-Object {
            # remove wslname and backup string from key to get the number
            $bkpPreviousNumber = [int]($_.Split('.')[-1])
            if ($bkpPreviousNumber -ge $bkpNumber)
            {
                $bkpNumber = $bkpPreviousNumber + 1
            }
        }

        $bkpNumberStr = '{0:d2}' -f $bkpNumber
        $backupName = "$backupPrePattern.$bkpNumberStr"
        return $backupName
    }


    [void] create([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 2 )
        $wslName = $Arguments[0]
        $backupAnnotation = $Arguments[1]

        Write-Host "* Backup '$wslName'"

        Write-Host "Check instance exists ..."
        $wslService = [WslService][ServiceLocator]::getInstance().get('wsl-wrapper')
        if (-Not $wslService.exists($wslName))
        {
            throw "Instance '$wslName' does not exists"
        }

        Write-Host "Compute backup name ..."
        $backupName = $this._generateName($wslName)
        Write-Host "Backup name is: $backupName"

        Write-Host "Exporting wsl '$wslName' ..."
        $exportHashtable = $wslService.export( $wslName, $backupName )

        Write-Host "Fill extra archive informations ..."
        $exportHashtable.message = $backupAnnotation

        Write-Host "Move to backup directory..."
        $destination = [FileUtils]::joinPath($this.Location, $exportHashtable.archive)
        Move-Item -Path $exportHashtable.archive -Destination $destination -Force


        Write-Host "Register new backup ..."
        $this.Hashtable.Add($backupName, $exportHashtable)
        $this._commit()

        # Report
        Write-Host "$wslName backuped as $($exportHashtable.archive) (SHA256: $($exportHashtable.sha256))"
        Write-Host "* Backup complete"
    }


    [void] list([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 0)

        [ExtendedConsole]::WriteColor("Available Backups (recoverable):", "Yellow" )
        $this._loadFile()
        $this.Hashtable.GetEnumerator() | ForEach-Object {
            "{0,-28} - {1,1} - {2,15} - {3,1}" -f $_.Key, $_.Value.date, `
                $_.Value.size, $_.Value.message
        } | Sort-Object | ForEach-Object {
            # colorize output
            $fdistro, $infos = $_.Split(" ")
            $finfo = $infos -Join " "
            [ExtendedConsole]::WriteColor( @($fdistro, $finfo), @("Green", "White"))
        }
    }

    [void] search([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 1)
        $pattern = $Arguments[0]

        [ExtendedConsole]::WriteColor("Available backup from pattern '$pattern':", "Yellow" )
        $this._loadFile()
        $this.Hashtable.GetEnumerator() | ForEach-Object {
            if ($_.Key -match ".*$pattern.*")
            {
                "{0,-28} - {1,1} - {2,15} - {3,1}" -f $_.Key, $_.Value.date, `
                    $_.Value.size, $_.Value.message
            }
        } | Sort-Object | ForEach-Object {
            # colorize output
            $fdistro, $infos = $_.Split(" ")
            $finfo = $infos -Join " "
            [ExtendedConsole]::WriteColor( @($fdistro, $finfo), @("Green", "White"))
        }
    }


    [void] remove ([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 1)
        $backupName = $Arguments[0]

        $this._loadFile()

        # Check backup exists
        if (-not ($this.Hashtable.ContainsKey($backupName)) )
        {
            throw "Backup '$backupName' does not exists"
        }
        $backupTgz = $this.Hashtable.$backupName.archive
        $backupTgzFile = [FileUtils]::joinPath($this.Location, $backupTgz)

        if (Test-Path -Path $backupTgzFile)
        {
            Write-Host "Delete Archive $backupTgz..."
            Remove-Item -Path $backupTgzFile -Force -ErrorAction Ignore | Out-Null
        }

        Write-Host "Delete backup registry entry..."
        $this.Hashtable.Remove($backupName)
        $this._commit()

        Write-Host "* Backup '$backupName' removed"
    }

    [void] restore([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 1, 2)

        $backupName = $Arguments[0]
        $forced = $false
        if ($Arguments.count -eq 2)
        {
            if ($Arguments[1] -ne "--force")
            {
                throw 'invalid parameter'
            }
            $forced = $true
        }

        Write-Host "* Restore '$backupName'"

        Write-Host "Check backup integrity ..."
        $this._checkIntegrity($backupName)

        # Check if wsl instance exists and ask for confirmation if force parameter
        # is false
        $wslName = $this.Hashtable.$backupName.wslname
        $wslService = [WslService][ServiceLocator]::getInstance().get('wsl-wrapper')
        if (($wslService.exists($wslName)) -And (-Not $forced))
        {
            Write-Host "*** WARNING ***" -ForegroundColor Yellow
            Write-Host "This action will replace the existing '$wslName' instance" -ForegroundColor Yellow
            Write-Host "with backup '$backupName'" -ForegroundColor Yellow
            $Selection = ""
            While ($Selection -ne "Y" )
            {
                $Selection = Read-Host "Proceed ? (Y/N)"
                Switch ($Selection)
                {
                    Y { Write-Host "Continuing with validation" -ForegroundColor Green }
                    N { Write-Host "Breaking out of script" -ForegroundColor Red; exit 1 ; }
                    default { Write-Host "Only Y/N are Valid responses" }
                }
            }
        }

        # Remove existing instance
        if ($wslService.exists($wslName) )
        {
            Write-Host "Destroy existing '$wslName' instance..."
            if ( $wslService.remove($wslName) -ne 0)
            {
                throw "Can not destroy active $wslName"
            }
        }

        # Check target directory does not exists or is empty
        $wslNameLocation = [FileUtils]::joinPath($this.WslLocation, $wslName)
        if (Test-Path -Path $wslNameLocation)
        {
            $directoryInfo = Get-ChildItem $wslNameLocation | Measure-Object
            if (-Not ($directoryInfo.count -eq 0))
            {
                throw "Directory $wslNameLocation already in use"
            }
        }

        # Instance creation
        Write-Host "Restore '$wslName' with $backupName..."
        if (Test-Path -Path $wslNameLocation)
        {
            New-Item -ItemType Directory -Force -Path $wslNameLocation | Out-Null
        }

        $backupTgzLocation = [FileUtils]::joinPath($this.Location, $this.Hashtable.$backupName.archive)
        if ($wslService.import(
            $wslName,
            $wslNameLocation,
            $backupTgzLocation,
            $this.Hashtable.$backupName.wslversion
        ) -ne 0) {
            throw "Restoring $backupName failure"
        }

        Write-Host "* Restore complete"
    }

    [void] _checkIntegrity([String] $backupName)
    {
        $this._loadFile()
        if (-not ($this.Hashtable.ContainsKey($backupName)) )
        {
            throw "Archive '$backupName' does not exists"
        }
        $backupTgzLocation = [FileUtils]::joinPath($this.Location, $this.Hashtable.$backupName.archive)
        if (-Not (Test-Path -Path $backupTgzLocation))
        {
            throw "Archive File not found '$backupTgzLocation'"
        }
        $archiveHash = [FileUtils]::sha256($backupTgzLocation)
        if (-Not ($archiveHash -eq $this.hashtable.$backupName.sha256))
        {
            throw "Archive File integrity mismatch, found '$archiveHash'"
        }
    }

    [void] purge([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 0)
        $this.Hashtable = @{}
        Remove-Item -LiteralPath $this.Location -Force -Recurse -ErrorAction Ignore | Out-Null
        Write-Host "* Backup storage cleared"
    }
}
