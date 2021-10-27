Class AbstractController
{
    AbstractController ()
    {
        $type = $this.GetType()

        if ($type -eq [AbstractController])
        {
            throw("Class $type must be inherited")
        }
    }

    [void] _assertArgument([System.String[]] $array, [int] $minLength)
    {
        $this._assertArgument($array, $minLength, $minLength)
    }

    [void] _assertArgument([System.String[]] $array, [int] $minLength, [int] $maxLength)
    {
        if ($maxLength -lt $minLength) { $maxLength = $minLength }
        if ($array.count -lt $minLength) { throw "too few arguments" }
        if ($array.count -gt $maxLength) { throw "too many arguments" }
    }

}

