using module "..\Model\JsonHashtableFile.psm1"
using module "..\Tools\FileUtils.psm1"

Class AppConfig
{

    # Properties:
    [JsonHashtableFile] $UserConfig
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
        # get main script location and change extension
        $scriptPath = Get-PSCallStack | Select-Object -Skip 2 -First 1 -ExpandProperty 'ScriptName'
        $confPath = [System.IO.Path]::ChangeExtension($scriptPath, "json")

        $this.UserConfig = [JsonHashtableFile]::new( $confPath, @{})

        # Merge with defaults
        $mergeUserConfig =  @{
            wsl      = 'c:\windows\system32\wsl.exe'
            registry = '\\qu1-srsrns-share.seres.lan\delivery\wsl\images'
            appData  = [FileUtils]::joinPath($env:LOCALAPPDATA,"Wslctl")
        }
        $this.UserConfig.getenumerator() | ForEach-Object {
            if ($mergeUserConfig.ContainsKey($_.Key))
            {
                $mergeUserConfig.$($_.Key) = $_.Value
            }
        }

        # Final: configure services
        $this.Wsl = @{}
        $this.Wsl.Binary = $mergeUserConfig.wsl
        $this.Wsl.Location = [FileUtils]::joinPath($mergeUserConfig.appData, "Instances")
        $this.Wsl.DefaultUsername = $this.Username
        $this.Wsl.DefaultPassword = "ChangeMe"

        $this.Registry = @{}
        $this.Registry.Remote = $mergeUserConfig.registry
        $this.Registry.Endpoint = [FileUtils]::joinUrl($this.Registry.Remote, "register.json")
        $this.Registry.Location = [FileUtils]::joinPath($mergeUserConfig.appData, "Registry")
        $this.Registry.File = [FileUtils]::joinPath($this.Registry.Location, "register.json")


        $this.Backup = @{}
        $this.Backup.Location = [FileUtils]::joinPath($mergeUserConfig.appData, "Backups")
        $this.Backup.File = [FileUtils]::joinPath($this.Backup.Location, "backups.json")

    }

    [void] commit()
    {
        $this.UserConfig.commit()
    }
}
