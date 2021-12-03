using module "..\Model\JsonHashtableFile.psm1"
using module "..\Tools\FileUtils.psm1"


Class AppConfig : JsonHashtableFile
{

    AppConfig([String] $version) : base(
        [System.IO.Path]::ChangeExtension((Get-PSCallStack | Select-Object -Skip 1 -First 1 -ExpandProperty 'ScriptName'), "json"),
        @{})
    {
        $this.Add("version", $version)

        if (-Not $this.ContainsKey("appData"))
        {
            $this.Add("appData", [FileUtils]::joinPath($env:LOCALAPPDATA, "Wslctl") )
        }
        if (-Not $this.ContainsKey("registry"))
        {
            $this.Add("registry", '\\qu1-srsrns-share.seres.lan\delivery\wsl\images')
        }
    }
}
