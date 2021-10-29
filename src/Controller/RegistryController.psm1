
using module "..\Application\ServiceLocator.psm1"
using module "..\Application\AppConfig.psm1"
using module "..\Application\AbstractController.psm1"
using module "..\Tools\ExtendedConsole.psm1"
using module "..\Service\RegistryService.psm1"


Class RegistryController : AbstractController
{

    [RegistryService] $registryService

    RegistryController() : base()
    {
        $this.registryService = [RegistryService]([ServiceLocator]::getInstance().get('registry'))
    }

    [void] update([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 0)
        $this.registryService.update()
        Write-Host "* Local registry updated"
    }

    [void] set([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 1)
        [ExtendedConsole]::WriteColor( "Setting Registry Remote Base Url", "Yellow")
        $remoteUrl = $Arguments[0]
        $config = [AppConfig]([ServiceLocator]::getInstance().get('config'))
        $config.Custom.registry = $remoteUrl
        $config.commit()
    }


    [void] list([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 0)

        [ExtendedConsole]::WriteColor( "Available distributions (installable):", "Yellow")

        $this.registryService.search("*") | ForEach-Object {
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

        [ExtendedConsole]::WriteColor( "Available distributions from pattern '$pattern':", "Yellow")
        $this.registryService.search($pattern) | ForEach-Object {
            # colorize output
            $fdistro, $infos = $_.Split(" ")
            $finfo = $infos -Join " "
            [ExtendedConsole]::WriteColor( @($fdistro, $finfo), @("Green", "White"))
        }
    }


    [void] pull([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 1)
        $distroName = $Arguments[0];

        Write-Host "Pulling distribution '$distroName' ..."
        $this.registryService.pull($distroName)
        Write-Host "* '$distroName' in local registry"

    }


    [void] purge([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 0)
        $this.registryService.purge()
        Write-Host "* Local registry cache cleared"
    }
}