# The following article was used to generate the algorithm in Powershell:

#     https://www.electricmonk.nl/docs/dependency_resolving_algorithm/dependency_resolving_algorithm.html

#     Each class file (determined by search in module structure which can be adapted as needed to target) is processed via the Powershell Abstract Syntax Tree and the following declarations are noted:
#         Strong type casting of variables, ie: [MyClass]$myVariable
#             If the type is not known to the runtime it is assumed to be required and neccessary within the module
#         Static property or method usage of a type, ie: $myVariable = [MyClass]::MyStaticProperty
#         New-Object declarations creating a TypeName by explicit parameter usage or by inferred parameter ordering.
#     As each file is processed, should any of the above be found the class is sent into another helper function which uses the AST to find the class file which exposes the Type.


Class ClassLoader {

    # Singleton
    static [ClassLoader] $Instance

    # List of cached items
    [System.Array]$Cached
    [ClassGraph]$Graph

    ClassLoader()
    {
        $this.Graph = [ClassGraph]::new( $(Split-Path -Parent -Path $PSScriptRoot) )
    }

    [System.Array] find([String] $Namespace)
    {
        return $this.find(@("$Namespace"))
    }

    [System.Array] find([System.Array] $Namespaces)
    {
        $filtered = @()

        # Namespaces dependencies filtered by already loaded
        $Namespaces  | ForEach-Object {
            if (-not $this.Graph.getClass($_).Loaded)
            {
                $this.Graph.getClassOrder($_) | ForEach-Object {
                    $class=$this.Graph.getClass($_)
                    if  (-not $class.Loaded)
                    {
                        $filtered += $class.Path
                    }
                }
            }
        }

        $filtered = $filtered | Select-Object -Unique
        if (-not $filtered){
            $filtered = @()
        }
        return $filtered
    }

    [void] finalize([String] $ClassPath)
    {
        if (-not $ClassPath){
            throw "The ClassePath parameter is empty"
        }
        write-host $ClassPath
        $classe=$this.Graph.getClassByPath($ClassPath)
        write-host "$ClassPath : $classe"
        #$classe.Loaded = $true
    }

    [System.Array] classOrder ([string] $Namespace)
    {
        return @(($this.Graph.getClassOrder($namespace) | ForEach-Object {
            $_.Path
        }))
    }

    [void] testCyclic([string] $Namespace)
    {
        # test for cyclic dependency
        $this.Graph.detectCyclicDependency($Namespace)
    }

    [void] toString ([string] $Namespace)
    {
        # test for cyclic dependency
        $this.testCyclic($Namespace)

        # draw out the dependencies
        $this.Graph.toString($namespace)
    }


    static [ClassLoader] getInstance()
    {
        if ($null -eq [ClassLoader]::Instance )
        {
            [ClassLoader]::Instance = [ClassLoader]::new()
        }

        return [ClassLoader]::Instance
    }

}


Class ClassModel {

    [String]$Path
    [String]$Name
    [String]$Namespace
    [bool]$Added = $false
    [bool]$Loaded = $false
    [System.Array]$DependentOn = @()
    [System.Array]$UsedBy = @()


    ClassModel([String] $ClassPath, [String] $RootPath)
    {
        $this.Path = $ClassPath
        $this.Name = [System.IO.Path]::GetFileNameWithoutExtension($ClassPath)
        $this.Namespace = [ClassModel]::classNamespace($ClassPath, $RootPath)
    }

    [System.Array] content()
    {
        return @(Get-Content -Path $this.Path -Force -Encoding UTF8)
    }

    [void] link([ClassModel] $Class)
    {
        if (-not ($Class.Namespace -eq "Application.ClassLoader" -or $this.Namespace -eq "Application.ClassLoader"))
        {
            # add dependency
            $deps = @($this.DependentOn | Select-Object -ExpandProperty Namespace)
            if ($deps -inotcontains $Class.Namespace) {
                $this.DependentOn += $Class
            }

            # add used by
            $used = @($Class.UsedBy | Select-Object -ExpandProperty Namespace)
            if ($used -inotcontains $this.Namespace) {
                $Class.UsedBy += $this
            }
        }
    }

    [System.Array] dependencies()
    {
        $dependencies = @()
        $visitor = @()

        # setup dependencies
        $this.DependentOn | ForEach-Object {
            $dependencies += @{
                Class = $_
                Links = @($this.Namespace)
            }
        }

        # find all dependencies and links
        for ($i = 0; $i -lt $dependencies.Length; $i++)
        {
            $class = $dependencies[$i].Class

            if ($visitor -inotcontains $class.Namespace)
            {
                foreach ($dep in $class.DependentOn) {
                    $dependencies += @{
                        Class = $dep
                        Links = ($dependencies[$i].Links + $class.Namespace)
                    }
                }

                $visitor += $class.Namespace
            }
        }

        return $dependencies
    }

    static [String] classNamespace([string] $ClassPath, [string] $RootPath)
    {
        $PartialPath = ($ClassPath.Replace($RootPath, [string]::Empty)).Trim('\/')
        $Parent = (Split-Path -Parent -Path $PartialPath)
        $File = [System.IO.Path]::GetFileNameWithoutExtension($PartialPath)

        if ([string]::IsNullOrWhiteSpace($Parent)) {
            $namepsace = ($File -replace '(\\|/)', '.')
        }
        else {
            $namepsace = ((Join-Path $Parent $File) -replace '(\\|/)', '.')
        }

        return $namepsace
    }

    static [System.Array] getClassModels([string] $RootPath)
    {
        return @((Get-ChildItem -Path $RootPath -Filter '*.ps1' -Recurse -Force).FullName | ForEach-Object {
            [ClassModel]::new( $_, $RootPath)
        })
    }
}




Class ClassGraph {

    [System.Collections.Hashtable] $Classes = @{}

    ClassGraph([string] $RootPath)
    {
        # append class and test path
        #$RootPath = (Join-Path (Resolve-Path $RootPath) 'Classes')
        $RootPath = (Resolve-Path $RootPath)
        if (!(Test-Path $RootPath)) {
            throw "The Classes directory path does not exist: $($RootPath)"
        }

        # get all classes, and build graph
        [ClassModel]::getClassModels($RootPath) | ForEach-Object {
            $this.Classes[$_.Name] = $_
        }

        # regex for using
        $regex = '\[(?<name>\w+)\]'

        # now, get all class dependencies
        foreach ($class in $this.Classes.Values) {
            # get file content
            $content = $class.content()

            # get all classes being used
            $usedClasses = @($content -imatch $regex)

            # if there are no dependencies, move along
            if ($usedClasses.Length -eq 0) {
                continue
            }

            # loop through each class, adding dependencies and used by
            foreach ($dep in $usedClasses) {
                $dep -imatch $regex | Out-Null
                $className = $Matches['name']

                # skip if class isn't custom
                if (!$this.Classes.ContainsKey($className)) {
                    continue
                }

                # skip if it is a self reference
                if ($className -ieq $class.Name) {
                    continue
                }

                # add dependency
                $this.Classes[$class.Name].link($this.Classes[$className])
            }
        }
    }

    [ClassModel] getClassByPath([String] $ClassPath)
    {
        return ($this.Classes.Values | Where-Object {
                    $_.Path -ieq $ClassPath
                } | Select-Object -First 1)
    }

    [ClassModel] getClass([String] $Namespace)
    {
        return ($this.Classes.Values | Where-Object {
                    $_.Namespace -ieq $Namespace
                } | Select-Object -First 1)
    }

    [System.Array] getClassOrder([String] $Namespace)
    {
        $order = @()

        if (-not [string]::IsNullOrWhiteSpace($Namespace))
        {
            $this.Classes.Values | Where-Object {
                $_.Namespace -ieq $Namespace
            } | ForEach-Object {
                $order += $this._recurseClassDependencies($_, 0)
            }

        } else {

            do {
                # get first class where all dependencies are added
                $class = ($this.Classes.Values | Where-Object {
                    !$_.Added -and (($_.DependentOn.Length -eq 0) -or @($_.DependentOn | Where-Object { !$_.Added }).Length -eq 0)
                } | Select-Object -First 1)

                # add the class
                Write-Verbose "Adding class: $($class.Namespace)"
                $order += $class

                # flag as added
                $class.Added = $true

            } while (@($this.Classes.Values | Where-Object { !$_.Added }).Length -gt 0 )
        }

        return $order
    }



    [void] detectCyclicDependency ([string] $Namespace)
    {
        $this.Classes.Values | Where-Object {
            [string]::IsNullOrWhiteSpace($Namespace) -or $_.Namespace -ieq $Namespace
        } | ForEach-Object {
            $class = $_

            # get all dependencies for the current class
            $dep = ($class.dependencies() | Where-Object { $_.Class.Namespace -ieq $class.Namespace })

            # if the list contains this class, error
            if ($null -ne $dep) {
                $message = $this._formatCyclicErrorMessage($dep.Links + $class.Namespace)
                throw "Cyclic dependency found on class '$($class.Path)':`n`n- - - - - - -`n$($message)`n- - - - - - -"
            }
        }
    }

    [void] toString([string] $Namespace)
    {
        $this.Classes.Values | Where-Object {
            [string]::IsNullOrWhiteSpace($Namespace) -or $_.Namespace -ieq $Namespace
        } | ForEach-Object {
            Write-PSClassDependencyTree -Class $_ -Level 0
            Write-Host ([string]::Empty)
        }
    }

    [void] _recurseClassDependencyTree([ClassModel] $Class, [int] $Level)
    {
        $prefix = "$('   ' * $Level)| ->"
        Write-Host "$($prefix) $($Class.Namespace)"

        if ($Class.DependentOn.Length -eq 0) {
            return
        }

        $Class.DependentOn | ForEach-Object {
            $this._recurseClassDependencyTree($_, ($Level + 1))
        }
    }

    [System.Array] _recurseClassDependencies ([ClassModel] $Class, [int] $Level)
    {
         $order = @()

        if ($Class.DependentOn.Length -ne 0) {
            $Class.DependentOn | ForEach-Object {
                $this._recurseClassDependencies($_, ($Level + 1)) | ForEach-Object {
                    if (-not $order.contains($_))
                    {
                        $order += $_
                    }
                }
            }
        }

        $order += "$($Class.Namespace)"
        return $order
    }

    [string] _formatCyclicErrorMessage([string[]] $Links)
    {
        # get middle length
        $length = [int](($Links | Measure-Object -Property Length -Minimum).Minimum * 0.5) - 1
        $space = [string]::new(' ', $length)

        # build the separator
        $separator = "`n$($space)$(@('|', 'V') -join "`n$($space)")`n"

        # build and return the sting
        return ($Links -join $separator)
    }

}
