
using module "..\Application\ServiceLocator.psm1"
using module "..\Application\AppConfig.psm1"


Class BucketService
{

    BucketService()
    {

    }

    [void] add([String] $name, [String] $url)
    {
        $config = [AppConfig]([ServiceLocator]::getInstance().get('config'))
        if (-Not $config.ContainsKey("buckets"))
        {
            $config.Add('buckets', @{})
        }
        if ($config.buckets.ContainsKey($name))
        {
            throw "Bucket named '$name' already set"
        }
        $config.buckets.Add($name, $url)
    }

    [void] remove([String] $name)
    {
        $config = [AppConfig]([ServiceLocator]::getInstance().get('config'))
        if (-Not $config.ContainsKey("buckets"))
        {
            throw "Bucket '$name' not set"
        }
        if (-Not $config.buckets.ContainsKey($name))
        {
            throw "Bucket '$name' not set"
        }
        $config.buckets.Remove($name)
    }

    [String[]] search([String] $pattern)
    {
        if ("*" -eq $pattern) { $pattern = "^.*$" }
        else { $pattern = "^.*$pattern.*$" }

        $config = [AppConfig]([ServiceLocator]::getInstance().get('config'))
        $result = @()
        if ($config.ContainsKey("buckets"))
        {
            $result += $config.buckets.GetEnumerator() | ForEach-Object {
                if ($_.Key -match ".*$pattern.*")
                {
                    "{0,-22} - {1,1}" -f $_.Key, $_.Value
                }
            } | Sort-Object
        }
        return $result
    }

    [void] commit()
    {
        $config = [AppConfig]([ServiceLocator]::getInstance().get('config'))
        $config.commit()
    }
}