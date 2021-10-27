
using module "..\Application\ServiceLocator.psm1"
using module "..\Application\AbstractController.psm1"
using module "..\Service\BackupService.psm1"
using module "..\Service\WslService.psm1"
using module "..\Tools\ExtendedConsole.psm1"



Class BackupController : AbstractController
{

    [BackupService] $backupService

    BackupController() : base()
    {
        $this.backupService = [BackupService][ServiceLocator]::getInstance().get('backup')
    }


    [void] create([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 2 )
        $wslName = $Arguments[0]
        $backupAnnotation = $Arguments[1]

        Write-Host "* Backup '$wslName' ..."
        $backupName = $this.backupService.create($wslName, $backupAnnotation)
        $backupProperties = $this.backupService.get($backupName)

        # Report
        Write-Host "$wslName backuped as $backupName "
        Write-Host "  archive $($backupProperties.archive)"
        Write-Host "  sha256: $($backupProperties.sha256)"
        Write-Host "* Backup complete"
    }


    [void] list([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 0)

        [ExtendedConsole]::WriteColor("Available Backups (recoverable):", "Yellow" )
        $this.backupService.search("*") | ForEach-Object {
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
        $this.backupService.search($pattern) | ForEach-Object {
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

        Write-Host "* Remove backup '$backupName'"
        $this.backupService.remove($backupName)
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

        # Check if wsl instance exists and ask for confirmation if force parameter
        # is false
        $backupProperties = $this.backupService.get($backupName)
        if (-Not $backupProperties)
        {
            throw "Backup name '$backupName' not found"
        }
        $wslName = $backupProperties.wslname
        $wslVersion = $backupProperties.wslversion
        $wslService = [WslService][ServiceLocator]::getInstance().get('wsl-wrapper')
        if (($wslService.exists($wslName)) -And (-Not $forced))
        {
            Write-Host "*** WARNING ***" -ForegroundColor Yellow
            Write-Host "This action will replace the existing '$wslName' instance" -ForegroundColor Yellow
            Write-Host "with backup '$backupName' (wsl-version: $wslVersion)" -ForegroundColor Yellow
            $Selection = ""
            While ($Selection -ne "Y" )
            {
                $Selection = Read-Host "Proceed ? (Y/N)"
                Switch ($Selection)
                {
                    Y { Write-Host "Continuing with validation" -ForegroundColor Green; $forced = $true; }
                    N { Write-Host "Breaking out of script" -ForegroundColor Red; exit 1 ; }
                    default { Write-Host "Only Y/N are Valid responses" }
                }
            }
        }

        $this.backupService.restore($backupName, $forced)
        Write-Host "* Restore complete"
    }

    [void] purge([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 0)
        $this.backupService.purge()
        Write-Host "* Backup storage cleared"
    }
}
