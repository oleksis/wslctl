
## ----------------------------------------------------------------------------
# Normalize DockerFile Build style commands to hash array of commands
## ----------------------------------------------------------------------------
function ConvertFrom-WSLFile {
    [OutputType('array')]
    
    $instructions = "maintainer from user run add copy arg env expose cmd onbuild workdir entrypoint" -Split " "

    $commands=@()
    @($Input) | ForEach-Object {
        # ignore blank and comment lines
        if ($_ -match "^\s*$") { Return }
        if ($_ -match "^\s*#") { Return }

        $segments=$_ -Split " ",2
        if ($segments.length -lt 2 -Or -Not ($instructions -contains $segments[0].ToLower())) { 
            Write-Host "Warning: Unsupported command '$_' (ignored)" -ForegroundColor Yellow
            Return
        }

        $segments[0] = $segments[0].ToLower()
        switch ($segments[0].ToLower()) {
            { @("maintainer from user run add copy expose workdir" -Split " ") -contains $_ } {
                $commands += @{ $segments[0] = $segments[1] }
            }
            { @("entrypoint", "cmd") -contains $_ } {
                $commands += @{ $segments[0] = ($segments[1] | ConvertFrom-Json ) }
            }
            arg {
                $commands_args = $segments[1] -Split "=",2
                if ($commands_args.length -eq 2) { $commands += @{ "arg" = $commands_args } }
            }
            env {
                if ($segments[1] -match "^[a-zA-Z_].[a-zA-Z0-9_]+?=(`"|')[^`"']*?\1$" ){
                    $commands += @{ "env" = $segments[1] }
                    Return
                }
                
                $env_array = $segments[1] -Split " "
                $env_pattern = "^[a-zA-Z_].[a-zA-Z0-9_]+?=.+$"
                switch  ($env_array.length){
                    1 {
                        # env test=true
                        $commands += @{ "env" = $segments[1] }
                        Return
                    }
                    2 {
                        # env test=true
                        $invalid_members = $segments[1].Where({$_ -notmatch $env_pattern})
                        if ($invalid_members.length -eq 0) {
                            $commands += @{ "env" = $segments[1] }
                            Return
                        }
                        # env test true
                        $commands += @{ "env" = $env_array -Join  "=" }
                    }
                    Default {
                        # env test true OR
                        # env test=true key=value ... OR 
                        # env test this is the string of the test env value
                        $invalid_members = $env_array.Where({$_ -notmatch $env_pattern})
                        if ($invalid_members.length -eq 0){
                            # env test=true key=value ...
                            $commands += @{ "env" = $segments[1] }
                            Return
                        } 
                        # env test this is the string of the test env value
                        # => env test="this is the string of the test env value"
                        $env_key,$env_string=$env_array
                        $commands += @{ "env" = (@($env_key, ('"'+( $env_string -Join " " )+'"')) -Join "=") }
                    }
                }
            }
        }
    }
    return $commands
}



## ----------------------------------------------------------------------------
# Hash array of Wslfile commands to bash interpretable array commands
## ----------------------------------------------------------------------------
function ConvertTo-WSLBashCommands {
    [OutputType('string')]
    param ( [string]$WorkingDirectory )
    
    $pwdInWsl =  ConvertTo-WslPath $WorkingDirectory
    $bash=@(
        "#!/usr/bin/env bash",
        "# The script is generated from a Dockerfile via wslctl v$VERSION "
        )
    $bashEndOfHeader=@(
        "`n# -- Automatic change working directory:",
        "cd $pwdInWsl",
        "`n# -- Converted commands:"
        )

    @($Input) | ForEach-Object {
        $key=$_.keys[0]
        $values = $_.values
        switch ($key) {
            "from" { $bash += "# The Original Wslfile is from image : $values" }
            "maintainer" { $bash += "# Original Wslfile Maintainer: $values" }
            "run"  { $bash += $bashEndOfHeader + "$values" ; $bashEndOfHeader=@() }
            "arg"  { $bash += $bashEndOfHeader + $values -Join "=" ; $bashEndOfHeader=@() }
            "env"  { $bash += $bashEndOfHeader + "export $values" + "echo 'export $values'>> ~/.bashrc" ; $bashEndOfHeader=@() }
            "user" { $bash += $bashEndOfHeader + "su - $values" ; $bashEndOfHeader=@() }
            "copy" { $bash += $bashEndOfHeader + "cp $values" ; $bashEndOfHeader=@() } 
            Default { Write-Host "Warning: Unimplemented command '$_' (ignored)" -ForegroundColor Yellow }
        }
    }
    $bash
}
