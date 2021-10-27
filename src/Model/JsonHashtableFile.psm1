
Class JsonHashtableFile : System.Collections.Hashtable
{
    hidden [String] $File

    JsonHashtableFile([String] $path = $null, [System.Collections.Hashtable] $default = @{}) : base()
    {
        if ([System.String]::IsNullOrEmpty($path))
        {
            $lastScriptPath = Get-PSCallStack | Select-Object -Skip 1 -First 1 -ExpandProperty 'ScriptName'
            if (-not [System.String]::IsNullOrEmpty($lastScriptPath))
            {
                $this.File = "$lastScriptPath.json"
            }
            else
            {
                throw "Json file not specified"
            }
        }
        else
        {
            $this.File = $path
        }

        # Inject to this
        if (Test-Path -Path $this.File)
        {
            $content = Get-Content -Path $this.File -Raw -ErrorAction Stop
            try
            {
                # Join all lines into one string and parse the JSON content
                $jsonContent = ($content -join '') | ConvertFrom-Json

                # Extract all propeties from the json content
                $jsonNodes = $jsonContent | Get-Member -MemberType NoteProperty

                foreach ($jsonNode in $jsonNodes)
                {
                    $Key = $jsonNode.Name
                    $value = $jsonContent.$Key

                    if ($value -is [System.Management.Automation.PSCustomObject])
                    {
                        $this[$Key] = @{}

                        foreach ($property in $value.PSObject.Properties)
                        {
                            $this[$Key][$property.Name] = $property.Value
                        }
                    }
                    else
                    {
                        $this[$Key] = $value
                    }
                }

            }
            catch
            {
                throw "The JSON content was in an invalid format: $_"
            }
        }
        else
        {
            # set defaults
            $default.GetEnumerator() | ForEach-Object {
                $this[$_.key] = $_.value
            }
        }
    }

    [System.Collections.IDictionaryEnumerator] GetEnumerator()
    {
        $data = $this.Clone()
        $data.Remove('File')
        return $data.GetEnumerator()
    }

    [void] commit()
    {
        $this | ConvertTo-Json | Set-Content -Path $this.File
    }
}