using module "..\Model\JsonHashtableFile.psm1"
using module "..\Tools\FileUtils.psm1"

Class AppConfig
{

    # Properties:
    [JsonHashtableFile] $Custom
    [System.Collections.Hashtable] $Backup
    [System.Collections.Hashtable] $Cache
    [System.Collections.Hashtable] $Registry
    [System.Collections.Hashtable] $Wsl
    [String] $Username
    [String] $Version

    # Constructor
    AppConfig([String] $version)
    {
        $this.Version = $version
        $this.Username = "$env:UserName"

        $this.initialize()
    }

    [void] initialize()
    {
        $this.Custom = [JsonHashtableFile]::new( $null, @{
                wsl      = 'c:\windows\system32\wsl.exe'
                registry = '\\qu1-srsrns-share.seres.lan\delivery\wsl\images'
                appData  = "$env:LOCALAPPDATA/Wslctl"
            })

        $this.Wsl = @{}
        $this.Wsl.Binary = $this.Custom.wsl
        $this.Wsl.Location = [FileUtils]::joinPath($this.Custom.appData, "Instances")
        $this.Wsl.DefaultUsername = $this.Username
        $this.Wsl.DefaultPassword = "ChangeMe"

        $this.Registry = @{}
        $this.Registry.Remote = $this.Custom.registry
        $this.Registry.Endpoint = [FileUtils]::joinUrl($this.Registry.Remote, "register.json")
        $this.Registry.Location = [FileUtils]::joinPath($this.Custom.appData, "Registry")
        $this.Registry.File = [FileUtils]::joinPath($this.Registry.Location, "register.json")


        $this.Backup = @{}
        $this.Backup.Location = [FileUtils]::joinPath($this.Custom.appData, "Backups")
        $this.Backup.File = [FileUtils]::joinPath($this.Backup.Location, "backups.json")

    }

    [void] commit()
    {
        $this.Custom.commit()
    }
}
