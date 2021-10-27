
using module "..\Application\ServiceLocator.psm1"
using module "..\Application\AppConfig.psm1"
using module "..\Application\AbstractController.psm1"
using module "..\Tools\FileUtils.psm1"
using module "..\Tools\ExtendedConsole.psm1"
using module "..\Model\JsonHashtableFile.psm1"


Class RegistryController : AbstractController
{

    [String] $Remote
    [String] $Endpoint
    [String] $Location
    [String] $File
    [JsonHashtableFile] $Hashtable

    RegistryController() : base()
    {
        $Config = [AppConfig]([ServiceLocator]::getInstance().get('config'))

        # Remote porperties
        $this.Remote = $Config.Registry.Remote
        $this.Endpoint = $Config.Registry.Endpoint

        # Local Cache Properties
        $this.Location = $Config.Registry.Location
        $this.File =  $Config.Registry.File

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

    [void] update([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 0)

        # Update the cache registry file (in cache)
        if (-Not ([FileUtils]::copyWithProgress($this.Endpoint, $this.File)))
        {
            throw "Registry endpoint not reachable"
        }
        Write-Host "* Local registry updated"
    }



    [void] list([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 0)

        [ExtendedConsole]::WriteColor( "Available distributions (installable):", "Yellow")
        $this._loadFile()
        $this.Hashtable.GetEnumerator()  | ForEach-Object {
            # format and sort
            "{0,-28} - {1,1} - {2,15} - {3,1}" -f $_.Key, $_.Value.date, `
                $_.Value.size, $_.Value.message
        } | Sort-Object | ForEach-Object {
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

        $this._loadFile()
        if (-not ($this.Hashtable.ContainsKey($distroName)) )
        {
            throw "Distribution '$distroName' not found in registry - " +
                "Please use the 'update' command to refresh the registry."
        }
        $distroRealSha256 = $this.Hashtable.$distroName.sha256
        $distroPackage = $this.Hashtable.$distroName.archive

        $distroEndpoint = [FileUtils]::joinUrl($this.Remote, $distroPackage)
        $distroLocation = [FileUtils]::joinPath($this.Location, $distroPackage)

        # Check Distribution in cache or download it
        if (-Not (Test-Path -Path $distroLocation))
        {
            Write-Host "Dowload distribution '$distroName' ..."
            if (-Not ([FileUtils]::copyWithProgress($distroEndpoint, $distroLocation)))
            {
                throw "Registry endpoint not reachable"
            }

            # Check integrity
            Write-Host "Checking integrity ($distroRealSha256)..."
            $distroLocationHash = (Get-FileHash $distroLocation -Algorithm SHA256).Hash.ToLower()
            if (-Not ($distroLocationHash -eq $distroRealSha256))
            {
                Remove-Item -Path $distroLocation -Force -ErrorAction Ignore | Out-Null
                throw "Error: Archive File integrity mismatch. Found '$distroLocationHash' - " +
                "Removing  $distroLocation"
            }
        }
        else
        {
            Write-Host "Distribution '$distroName' already cached ..."
        }
    }

    [void] search([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 1)
        $pattern = $Arguments[0]

        [ExtendedConsole]::WriteColor( "Available distributions from pattern '$pattern':", "Yellow")
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

    [void] purge([Array] $Arguments)
    {
        $this._assertArgument( $Arguments, 0)
        $this.Hashtable = $null
        Remove-Item -LiteralPath $this.Location -Force -Recurse -ErrorAction Ignore | Out-Null
        Write-Host "* Local registry cache cleared"
    }
}