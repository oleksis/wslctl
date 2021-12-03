
using module "..\Application\ServiceLocator.psm1"
using module "..\Application\AppConfig.psm1"
using module "..\Application\AbstractController.psm1"
using module "..\Service\RegistryService.psm1"
using module "..\Service\BuilderService.psm1"
using module "..\Service\WslService.psm1"
using module "..\Tools\FileUtils.psm1"
using module "..\Tools\ExtendedConsole.psm1"


Class DefaultController : AbstractController
{

    DefaultController() : base()
    {
    }

    [void] create([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 0, 3 )

        $wslService = [WslService][ServiceLocator]::getInstance().get('wsl-wrapper')
        $registryService = [RegistryService][ServiceLocator]::getInstance().get('registry')

        $wslName = $null
        $distroName = $null
        $wslVersion = $wslService.getDefaultVersion()
        $createUser = $true

        # Parse Arguments
        foreach ($element in $Arguments)
        {
            switch ($element)
            {
                --no-user { $createUser = $false }
                --v1 { $wslVersion = 1 }
                --v2 { $wslVersion = 2 }
                Default
                {
                    if ( $null -eq $wslName ) { $wslName = $element }
                    elseif ( $null -eq $distroName ) { $distroName = $element }
                    else { throw "Invalid parameter" }
                }
            }
        }
        if ( $null -eq $distroName) { $distroName = $wslName }

        Write-Host "* Import $wslName"

        Write-Host "Check import requirements ..."
        $wslService.checkBeforeImport($wslName)

        Write-Host "Dowload distribution '$distroName' ..."
        $archive = $registryService.pull($distroName)

        Write-Host "Create wsl instance '$wslName' (wsl-version: $wslVersion)..."
        $wslService.import(
            $wslName,
            $archive,
            $wslVersion,
            $createUser
        )

        Write-Host "* $wslName created"
        Write-Host "  Could be started with command: wslctl start $wslName"
    }


    [void] status([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 0, 1 )
        $wslService = [WslService][ServiceLocator]::getInstance().get('wsl-wrapper')

        if ($Arguments.count -eq 0)
        {
            # List all wsl instance status
            # Remove wsl List header and display own
            Write-Host "Wsl instances status:" -ForegroundColor Yellow
            $wslService.statusAll() | ForEach-Object {
                "$_" -match "^(?<default>[*| ]*)(?<distro>[^ ]*)(?<infos>.*)$"
                #write-host $matches
                [ExtendedConsole]::WriteColor( @(
                        $matches['default'],
                        $matches['distro'],
                        $matches['infos']),
                    @("White", "Green", "White"))
            }
        }
        else
        {
            # List status for specific wsl instance
            $wslName = $Arguments[0]
            if (-Not $wslService.exists($wslName))
            {
                throw "No instance named '$wslName' found"
            }
            [ExtendedConsole]::WriteColor($wslService.status($wslName), "White")
        }
    }

    [void] start([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 1)

        $wslName = $Arguments[0]
        $wslService = [WslService][ServiceLocator]::getInstance().get('wsl-wrapper')

        if (-Not $wslService.exists($wslName))
        {
            throw "No instance named '$wslName' found"
        }

        if ($wslService.start($wslName) -eq 0)
        {
            Write-Host "*  $wslName started"
        }
    }

    [void] stop([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 1 )

        $wslName = $Arguments[0]
        $wslService = [WslService][ServiceLocator]::getInstance().get('wsl-wrapper')

        if (-Not $wslService.exists($wslName))
        {
            throw "No instance named '$wslName' found"
        }

        if ($wslService.terminate($wslName) -eq 0)
        {
            Write-Host "*  $wslName stopped"
        }
    }

    [void] remove ([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 1 )

        $wslName = $Arguments[0]
        $wslService = [WslService][ServiceLocator]::getInstance().get('wsl-wrapper')

        if (-Not $wslService.exists($wslName))
        {
            throw "No instance named '$wslName' found"
        }

        if ($wslService.remove($wslName) -eq 0)
        {
            Write-Host "*  $wslName removed"
        }
    }

    [void] list ([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 0)

        Write-Host "Wsl instances:" -ForegroundColor Yellow
        $wslService = [WslService][ServiceLocator]::getInstance().get('wsl-wrapper')
        $wslService.list() | ForEach-Object {
            ((" " * 2), $_ ) -Join ""
        } | Sort-Object | ForEach-Object {
            [ExtendedConsole]::WriteColor( $_, "White")
        }
    }

    [void] exec ([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 1, 50)

        ([string]$wslName, [array]$commandline) = $Arguments
        if ($null -eq $commandline ) { $commandline = @() }
        $wslService = [WslService][ServiceLocator]::getInstance().get('wsl-wrapper')

        if ($Arguments.Count -eq 1)
        {
            # No commands: connect to distribution
            Write-Host "Connect to $wslName ..." -ForegroundColor Yellow
            $wslService.connect($wslName)
            return
        }

        # Script file execution
        if (Test-Path $commandline[0] -PathType leaf)
        {
            ([string]$script, [array]$scriptArgs) = $commandline
            $scriptNoPath = Split-Path $script -Leaf
            Write-Host "Execute $scriptNoPath on $wslName ..." -ForegroundColor Yellow
            if ($wslService.exec($wslName, $script, $scriptArgs) -ne 0)
            {
                throw "Command result with errors"
            }
            return
        }

        # Inline Script execution
        Write-Host "Execute command '$commandline' on $wslName ..." -ForegroundColor Yellow
        if ($wslService.exec($wslName, $commandline) -ne 0)
        {
            throw "Command result with errors"
        }
    }

    [void] build ([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 0, 4)

        $dryRun = $false
        # Default file name in directory
        $wslFilePath = (Get-Location).Path
        $tag = $null
        $tagTxt = $dryRunTxt = ""
        # Parse arguments
        for ($index = 0; $index -lt $Arguments.length; $index++)
        {
            switch -regex ($Arguments[$index])
            {
                --dry-run
                {
                    $dryRun = $true
                    $dryRunTxt = "DryRun - "
                }

                '--tag=[^ ]+'
                {
                    $tag = ($Arguments[$index] -Split ("="))[1]
                    #$index++
                    $tagTxt = " '$tag' with"
                }
                Default
                {
                    if ($Arguments[$index].StartsWith("--"))
                    {
                        throw "Invalid option $($Arguments[$index])"
                    }
                    $wslFilePath = $Arguments[$index]
                }
            }
        }

        Write-Host "$($dryRunTxt)Building$($tagTxt) $wslFilePath" -ForegroundColor Yellow
        $builder = [BuilderService][ServiceLocator]::getInstance().get('builder')
        $builder.build($wslFilePath, $tag, $dryRun)
        Write-Host "* Wsl built"
    }


    [void] halt ([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 0)

        $wslService = [WslService][ServiceLocator]::getInstance().get('wsl-wrapper')
        $wslService.shutdown()
        Write-Host "* Wsl halted"
    }



    [void] version([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 1, 2)
        $wslService = [WslService][ServiceLocator]::getInstance().get('wsl-wrapper')

        if ($Arguments.count -eq 1)
        {
            # default : display wsl default version
            # not default: display wsl name instance version
            if ('default' -eq $Arguments[0])
            {
                Write-Host $wslService.getDefaultVersion()
            }
            else
            {
                $wslName = $Arguments[0]
                if (-Not $wslService.exists($wslName))
                {
                    throw "No instance named '$wslName' found"
                }
                Write-Host $wslService.version($wslName)
            }
        }
        else
        {
            # args: default + wslversion to set
            $wslDefaultVersion = $Arguments[1]
            if ( $wslService.setDefaultVersion($wslDefaultVersion) -ne 0)
            {
                throw "Enable to set wsl default version to $wslDefaultVersion"
            }
            Write-Host "* wsl default version set to $wslDefaultVersion"
        }


    }

    [void] convert ([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 2)
        $wslService = [WslService][ServiceLocator]::getInstance().get('wsl-wrapper')

        $wslName = $Arguments[0]
        $versionToSet = [int32]$Arguments[1]

        Write-Host "Convert '$wslName' to version $versionToSet"
        Write-Host "Checking instance exists ..."
        if (-Not $wslService.exists($wslName))
        {
            throw "No instance named '$wslName' found"
        }

        $actualVersion = $wslService.version($wslName)
        Write-Host "Checking instance version ..."
        if ($actualVersion -eq $versionToSet)
        {
            Write-Host "* wsl inscance '$wslName' already set with version $versionToSet"
            return
        }

        Write-Host "Converting '$wslName' from version $actualVersion to $versionToSet ..."
        if ($wslService.convert($wslName, $versionToSet) -ne 0)
        {
            throw "Enable to convert instance '$wslName' to version $versionToSet ..."
        }
        Write-Host "* wsl instance '$wslName' converted to $versionToSet"
    }

    [void] __version([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 0)
        # display software version
        $version = ([AppConfig][ServiceLocator]::getInstance().get('config')).version
        [ExtendedConsole]::WriteColor($version)
    }

    [void] __help([Array] $Arguments)
    {
        $this.help($Arguments)
    }

    [void] help([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 0)

        $titleColor = "Yellow"
        $highlightColor = "Green"
        $foregroundColor = "White"

        [ExtendedConsole]::WriteColor()
        [ExtendedConsole]::WriteColor("Usage:", $titleColor)
        [ExtendedConsole]::WriteColor("   wslctl COMMAND [ARG...]", $foregroundColor)
        [ExtendedConsole]::WriteColor("   wslctl [ --help | --version ]", $foregroundColor)

        # Wsl management
        [ExtendedConsole]::WriteColor()
        [ExtendedConsole]::WriteColor("Wsl managment commands:", $titleColor)
        @(
            @("   create  <wsl_name> [<distro_name>] [|--v[1|2]]  ", "Create a named wsl instance from distribution"),
            @("   convert <wsl_name> <version>                     ", "Concert instance to specified wsl version"),
            @("   rm      <wsl_name>                               ", "Remove a wsl instance by name"),
            @("   exec    <wsl_name> [|<file.sh>|<cmd>]            ", "Execute specified script|cmd on wsl instance by names"),
            @("   ls                                               ", "List all created wsl instance names"),
            @("   start   <wsl_name>                               ", "Start an instance by name"),
            @("   stop    <wsl_name>                               ", "Stop an instance by name"),
            @("   status [<wsl_name>]                              ", "List all or specified wsl Instance status"),
            @("   halt                                             ", "Shutdown all wsl instances"),
            @("   version [|<wsl_name>|default [|<version>]]       ", "Set/get default version or get  wsl instances version"),
            @("   build   [<Wslfile>] [--tag=<distro_name>]        ", "Build an instance (docker like)")
        ) | ForEach-Object { [ExtendedConsole]::WriteColor($_, @($highlightColor, $foregroundColor)) }


        # wsl distributions registry management
        [ExtendedConsole]::WriteColor()
        [ExtendedConsole]::WriteColor("Wsl distribution registry commands:", $titleColor)
        @(
            @("   registry set <remote_url>                        ", "Set the remote registry (custom configuratio file)"),
            @("   registry update                                  ", "Update local distribution dictionary"),
            @("   registry pull   <distro>                         ", "Pull remote distribution to local registry"),
            @("   registry purge                                   ", "Remove all local registry content"),
            @("   registry search <distro_pattern>                 ", "Extract defined distributions from local registry"),
            @("   registry ls                                      ", "List local registry distributions")
        ) | ForEach-Object { [ExtendedConsole]::WriteColor($_, @($highlightColor, $foregroundColor)) }


        # Wsl backup management
        [ExtendedConsole]::WriteColor()
        [ExtendedConsole]::WriteColor("Wsl backup managment commands:", $titleColor)
        @(
            @("   backup create  <wsl_name> <message>              ", "Create a new backup for the specified wsl instance"),
            @("   backup rm      <backup_name>                     ", "Remove a backup by name"),
            @("   backup restore <backup_name> [--force]           ", "Restore a wsl instance from backup"),
            @("   backup search  <backup_pattern>                  ", "Find a created backup with input as pattern"),
            @("   backup ls                                        ", "List all created backups"),
            @("   backup purge                                     ", "Remove all created backups")
        ) | ForEach-Object { [ExtendedConsole]::WriteColor($_, @($highlightColor, $foregroundColor)) }

        [ExtendedConsole]::WriteColor()

    }

}
