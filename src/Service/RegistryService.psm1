
using module "..\Application\ServiceLocator.psm1"
using module "..\Application\AppConfig.psm1"
using module "..\Tools\FileUtils.psm1"
using module "..\Model\JsonHashtableFile.psm1"
using module "..\Model\Registry.psm1"


Class RegistryService
{

    [String] $Remote
    [String] $Endpoint
    [String] $Location
    [String] $File
    [JsonHashtableFile] $Buckets
    [System.Collections.Hashtable] $Registries

    RegistryService()
    {
        $Config = [AppConfig]([ServiceLocator]::getInstance().get('config'))
        $this.Location = [FileUtils]::joinPath($Config.appData, "Registry")
        $this.File = [FileUtils]::joinPath($Config.appData, "registry-buckets.json")

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
        if (-Not $this.Buckets)
        {
            $this.Buckets = [JsonHashtableFile]::new($this.File, @{})
            $this.Registries = @{}
            if ($this.Buckets.Count -ne 0 ){
                $this.Buckets.GetEnumerator() | ForEach-Object {
                    $this.Registries.Add(
                        $_.Key,
                        [Registry]::new($_.Key, $_.Value, [FileUtils]::joinPath($this.Location, $_.Key))
                    )
                }
            }
        }
    }

    [void] _assertAvailableRegistries(){
        if ($this.Registries.Count -eq 0 ){
            throw "No registry set"
        }
    }

    [void] add([String] $name, [String] $url)
    {
        $this._loadFile()
        if (-Not ($name -imatch '^[a-z][a-z0-9]{4,20}$'))
        {
            throw "Invalid registry name format (5 char min, 20 max, [a-z0-9]*)"
        }

        try { [System.Net.WebRequest]::Create($url) }
        catch { throw "Invalid registry url '$url'" }

        if ($this.Buckets.ContainsKey($name))
        {
            throw "Registry named '$name' already set"
        }
        $this.Buckets.Add($name, $url)
        $this.Registries.Add($name,  [Registry]::new($name, $url, [FileUtils]::joinPath($this.Location, $name))
        )
    }

    [void] remove([String] $name)
    {
        $this._loadFile()

        if (-Not $this.Buckets.ContainsKey($name))
        {
            throw "Bucket '$name' not set"
        }
        $this.Registries.$name.purge()
        $this.Buckets.Remove($name)
        $this.Registries.Remove($name)
    }

    [String[]] registryList()
    {
        $this._loadFile()
        $this._assertAvailableRegistries()

        $result = @()
        $result += $this.Buckets.GetEnumerator() | ForEach-Object {
                "{0,-21} - {1,1}" -f $_.Key, $_.Value
        } | Sort-Object

        return $result
    }

    [void] update()
    {
        $this._loadFile()
        $this._assertAvailableRegistries()

        $this.Registries.GetEnumerator() | ForEach-Object {
            ([Registry]$_.Value).update()
        }
    }


    [String[]] search([String] $pattern)
    {
        $this._loadFile()
        $this._assertAvailableRegistries()

        if ("*" -eq $pattern) { $pattern = "^.*$" }
        else { $pattern = "^.*$pattern.*$" }

        $result = @()
        if ($this.Registries.Count -ne 0 ){
            $result += $this.Registries.GetEnumerator() | ForEach-Object {
                $_.Value.search($pattern)
            } | Sort-Object
        }
        return $result
    }


    [String] pull([String] $distroName)
    {
        $this._loadFile()
        $this._assertAvailableRegistries()
        $foundRegistry = false

        foreach ($registryName in $this.Registries.Keys)
        {
            $registry = [Registry]$($this.Registries.Item($registryName))
            if ($registry.contains($distroName) )
            {
                $foundRegistry = $registry
                break;
            }
        }

        if (-not $foundRegistry )
        {
            throw "Distribution '$distroName' not found in registries - " +
            "Please use the 'update' command to refresh the registry."
        }

        $distroLocation = $foundRegistry.pull($distroName)

        return $distroLocation
    }


    [void] purge()
    {
        $this._loadFile()
        $this._assertAvailableRegistries()
        $this.Registries.GetEnumerator() | ForEach-Object {
            ([Registry]($_.Value)).purge()
        }
    }

    [void] commit()
    {
        $this._loadFile()
        $this.Buckets.commit()
    }
}