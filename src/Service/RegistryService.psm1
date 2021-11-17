
using module "..\Application\ServiceLocator.psm1"
using module "..\Application\AppConfig.psm1"
using module "..\Tools\FileUtils.psm1"
using module "..\Model\JsonHashtableFile.psm1"


Class RegistryService
{

    [String] $Remote
    [String] $Endpoint
    [String] $Location
    [String] $File
    [JsonHashtableFile] $Hashtable

    RegistryService()
    {
        $Config = [AppConfig]([ServiceLocator]::getInstance().get('config'))

        # Remote porperties
        $this.Remote = $Config.Registry.Remote
        $this.Endpoint = $Config.Registry.Endpoint

        # Local Cache Properties
        $this.Location = $Config.Registry.Location
        $this.File = $Config.Registry.File

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

    [void] update()
    {
        $tempFile = [IO.Path]::GetTempFileName()

        # Update the cache registry file (in cache)
        if (-Not ([FileUtils]::copyWithProgress($this.Endpoint, $tempFile)))
        {
            if (Test-Path $tempFile -PathType leaf)
            {
                Remove-Item $tempFile
            }
            throw "Registry endpoint not reachable"
        }
        Move-Item -Path $tempFile -Destination $this.File -Force
    }


    [String[]] search([String] $pattern)
    {
        $this._loadFile()

        if ("*" -eq $pattern) { $pattern = "^.*$" }
        else { $pattern =  "^.*$pattern.*$"}

        $result = @()
        $result += $this.Hashtable.GetEnumerator() | ForEach-Object {
            if ($_.Key -match ".*$pattern.*")
            {
                "{0,-28} - {1,1} - {2,15} - {3,1}" -f $_.Key, $_.Value.date, `
                    $_.Value.size, $_.Value.message
            }
        } | Sort-Object
        return $result
    }


    [String] pull([String] $distroName)
    {
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
            if (-Not ([FileUtils]::copyWithProgress($distroEndpoint, $distroLocation)))
            {
                throw "Registry endpoint not reachable"
            }

            # Check integrity
            $distroLocationHash = [FileUtils]::sha256( $distroLocation )
            if (-Not ($distroLocationHash -eq $distroRealSha256))
            {
                Remove-Item -Path $distroLocation -Force -ErrorAction Ignore | Out-Null
                throw "Error: Archive File integrity mismatch. Found '$distroLocationHash' - " +
                "Removing  $distroLocation"
            }
        }
        return $distroLocation
    }


    [void] purge()
    {
        $this.Hashtable = $null
        Remove-Item -LiteralPath $this.Location -Force -Recurse -ErrorAction Ignore | Out-Null
    }
}