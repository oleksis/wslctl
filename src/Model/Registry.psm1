
using module "..\Application\ServiceLocator.psm1"
using module "..\Tools\FileUtils.psm1"
using module "..\Tools\Downloader.psm1"
using module "..\Model\JsonHashtableFile.psm1"


Class Registry
{

    [String] $Name
    [String] $Remote
    [String] $Endpoint
    [String] $Location
    [String] $File
    [JsonHashtableFile] $Distributions

    Registry([String] $name, [String] $remoteUrl, [String]$cacheDir)
    {
        $this.Name = $name
        $this.Location = $cacheDir
        $this.File = [FileUtils]::joinPath($this.Location, "register.json")

         # Remote properties
        $this.Remote = $remoteUrl;
        $this.Endpoint = [FileUtils]::joinUrl($this.Remote, "register.json")

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
        if (-Not $this.Distributions)
        {
            $this.Distributions = [JsonHashtableFile]::new($this.File, @{})
        }
    }

    [void] update()
    {
        $tempFile = [IO.Path]::GetTempFileName()

        # Update the cache registry file (in cache)
        if (-Not ([Downloader]::download($this.Endpoint, $tempFile)))
        {
            if (Test-Path $tempFile -PathType leaf)
            {
                Remove-Item $tempFile
            }
            throw "Registry '$($this.Name)' endpoint not reachable"
        }
        Move-Item -Path $tempFile -Destination $this.File -Force
    }


    [String[]] search([String] $pattern)
    {
        $this._loadFile()

        if ("*" -eq $pattern) { $pattern = "^.*$" }
        else { $pattern =  "^.*$pattern.*$"}

        $result = @()
        if ($this.Distributions.Count -ne 0){
            $result += $this.Distributions.GetEnumerator() | ForEach-Object {
                if ($_.Key -match ".*$pattern.*")
                {
                    "{0,-28} {1,-12}   {2,1}   {3,10}   {4,1}" -f $_.Key, ("["+$this.name+"]"), $_.Value.date, `
                        $_.Value.size, $_.Value.description
                }
            } | Sort-Object
        }
        return $result
    }


    [boolean] contains([String] $distroName)
    {
        $this._loadFile()
        return $this.Distributions.ContainsKey($distroName)
    }


    [String] pull([String] $distroName)
    {
        $this._loadFile()
        if (-not ($this.Distributions.ContainsKey($distroName)) )
        {
            throw "Distribution '$distroName' not found in this registry - " +
            "Please use the 'update' command to refresh the registry."
        }
        $distroRealSha256 = $this.Distributions.$distroName.sha256
        $distroPackage = $this.Distributions.$distroName.archive
        $distroPackageExtension = "tar.gz", "tar", "tgz" | Where-Object {$distroPackage -Like "*.$_" }
        if ($distroPackageExtension.length -eq 0)
        {
            throw "Registry archive reference format not supported for '$distroName'"
        }

        if ($distroPackage.ToLower().StartsWith("http://") -or $distroPackage.ToLower().StartsWith("https://")) {
            $distroEndpoint = $distroPackage
            # compute distroPackage url hash (prevent file name longer than 256)
            $enc   = [system.Text.Encoding]::UTF8
            $sha1 = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider
            $hash = ([String]$sha1.ComputeHash($enc.GetBytes($distroPackage))) -replace '\s',''

            $distroLocation = [FileUtils]::joinPath($this.Location, "$hash.$distroPackageExtension")
            write-host "$distroLocation"
        } else {
            # Registry relative Path
            $distroEndpoint = [FileUtils]::joinUrl($this.Remote, $distroPackage)
            $distroLocation = [FileUtils]::joinPath($this.Location, $distroPackage)
        }

        # Check Distribution cached uptodate with the registry defined hash for that distribution
        if (Test-Path -Path $distroLocation)
        {
            $distroLocationHash = [FileUtils]::sha256( $distroLocation )
            if (-Not ($distroLocationHash -eq $distroRealSha256))
            {
                Remove-Item -Path $distroLocation -Force -ErrorAction Ignore | Out-Null
            }
        }

        # Check Distribution in cache or download it
        if (-Not (Test-Path -Path $distroLocation))
        {
            # assert directory exists (distro package could have sub directories)
            $distroLocationParent = Split-Path $distroLocation -parent
            New-Item -ItemType Directory -Force -Path $distroLocationParent | Out-Null
            $tempFile = [IO.Path]::GetTempFileName()

            if (-Not ([Downloader]::download($distroEndpoint, $tempFile)))
            {
                throw "Registry endpoint not reachable"
            }

            # Check integrity
            $distroLocationHash = [FileUtils]::sha256( $tempFile )
            if (-Not ($distroLocationHash -eq $distroRealSha256))
            {
                Remove-Item -Path $tempFile -Force -ErrorAction Ignore | Out-Null
                throw "Error: Archive File integrity mismatch. Found '$distroLocationHash' - " +
                "Removing  $distroLocation"
            }
            Move-Item -Path $tempFile -Destination $distroLocation
        }
        return $distroLocation
    }


    [void] purge()
    {
        $this.Distributions = $null
        Remove-Item -LiteralPath $this.Location -Force -Recurse -ErrorAction Ignore | Out-Null
    }
}
