
using module "..\Application\ServiceLocator.psm1"
using module "..\Application\AppConfig.psm1"
using module "..\Application\AbstractController.psm1"
using module "..\Service\WslService.psm1"
using module "..\Tools\FileUtils.psm1"
using module "..\Tools\ExtendedConsole.psm1"
using module "..\Model\JsonHashtableFile.psm1"

Class BackupService
{

    [String] $Location
    [String] $File
    [System.Collections.Hashtable] $Hashtable

    BackupService()
    {
        $Config = [AppConfig][ServiceLocator]::getInstance().get('config')

        $this.Location = [FileUtils]::joinPath($Config.appData, "Backups")
        $this.File = [FileUtils]::joinPath($this.Location, "backups.json")

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


    [String] create([String] $wslName, [String] $backupAnnotation)
    {
        $wslService = [WslService][ServiceLocator]::getInstance().get('wsl-wrapper')
        if (-Not $wslService.exists($wslName))
        {
            throw "Instance '$wslName' does not exists"
        }

        $backupName = $this._generateName($wslName)
        $exportHashtable = $wslService.export( $wslName, $backupName )
        $exportHashtable.description = $backupAnnotation
        $destination = [FileUtils]::joinPath($this.Location, $exportHashtable.archive)
        Move-Item -Path $exportHashtable.archive -Destination $destination -Force


        $this.Hashtable.Add($backupName, $exportHashtable)
        $this._commit()

        return $backupName
    }

    [System.Collections.Hashtable] get([String] $backupName)
    {
        $this._loadFile()
        if (-not ($this.Hashtable.ContainsKey($backupName)) )
        {
            return $null
        }
        return $this.Hashtable.$BackupName
    }

    [String[]] search([String] $pattern)
    {
        $this._loadFile()

        if ("*" -eq $pattern) { $pattern = "^.*$" }
        else { $pattern = "^.*$pattern.*$" }

        $result = @()
        $result += $this.Hashtable.GetEnumerator() | ForEach-Object {
            if ($_.Key -match ".*$pattern.*")
            {
                "{0,-28} - {1,1} - {2,15} - {3,1}" -f $_.Key, $_.Value.date, `
                    $_.Value.size, $_.Value.description
            }
        } | Sort-Object
        return $result
    }


    [void] remove ([String] $backupName)
    {

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
            Remove-Item -Path $backupTgzFile -Force -ErrorAction Ignore | Out-Null
        }

        $this.Hashtable.Remove($backupName)
        $this._commit()
    }


    [void] restore([String] $backupName) { $this.restore($backupName, $false) }
    [void] restore([String] $backupName, [Boolean] $forced)
    {
        $this._checkIntegrity($backupName)

        $wslName = $this.Hashtable.$backupName.wslname
        $backupTgzLocation = [FileUtils]::joinPath($this.Location, $this.Hashtable.$backupName.archive)

        $wslService = [WslService][ServiceLocator]::getInstance().get('wsl-wrapper')
        $wslService.checkBeforeImport($wslName, $forced)

        if ($wslService.import(
                $wslName,
                $this.Hashtable.$backupName.image,
                $backupTgzLocation,
                $this.Hashtable.$backupName.wslversion,
                $false
            ) -ne 0)
        {
            throw "Restoring $backupName failure"
        }
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

    [void] purge()
    {
        $this.Hashtable = @{}
        Remove-Item -LiteralPath $this.Location -Force -Recurse -ErrorAction Ignore | Out-Null
    }
}
