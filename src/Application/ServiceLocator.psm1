Class ServiceLocator
{
    # Singleton
    static [ServiceLocator] $instance

    # Properties
    [System.Collections.Hashtable] $Services = @{}

    [Object] get([String] $name)
    {
        if ( $this.Services.ContainsKey($name) )
        {
            return ( $this.Services.$name )
        }
        return $null
    }

    [void] add([String] $name, [Object] $service)
    {
        $this.Services.$name= $service
    }

    static [ServiceLocator] getInstance()
    {
        if ($null -eq [ServiceLocator]::instance )
        {
            [ServiceLocator]::instance = [ServiceLocator]::new()
        }

        return [ServiceLocator]::instance
    }
}


