
using module ".\AbstractController.psm1"

Class ControllerResolver
{

    [System.Collections.Generic.Dictionary[String, AbstractController]] $controllers
    [System.Array] $commands
    [System.Collections.Hashtable] $aliases


    ControllerResolver([System.Collections.Generic.List[AbstractController]] $controllers, [System.Collections.Hashtable] $actionAliases)
    {
        $this.controllers = [System.Collections.Generic.Dictionary[String, AbstractController]]::new()
        $this.commands = @()
        $controllers.GetEnumerator() | ForEach-Object {
            $controllerName =  $_.GetType().Name.Replace("Controller", "").ToLower()

            $this.controllers.Add(
                $controllerName, $_
            )

            $this.commands += ($_ | Get-Member | Where-Object {
                ($_.MemberType -eq "Method") -and ($_.Name -cmatch "^(|__)[a-z]+$")
            } | ForEach-Object {
                ( $controllerName, $_.Name) -Join " "
            })
        }

        $this.aliases = $actionAliases
        $this.createActionAliases()

        # Sort commands
        $this.commands = $this.commands | Sort-Object -Descending { $_.length }
    }

    [void] createActionAliases()
    {
        $this.commands | ForEach-Object {
            $cmd = $_
            $this.aliases.GetEnumerator() | ForEach-Object {
                if ($cmd.EndsWith($_.value))
                {
                    $this.commands += $cmd.replace($_.value, $_.key)
                }
            }
        }
    }

    [String] resolveActionAliases ([String] $command)
    {
        $this.aliases.GetEnumerator() | ForEach-Object {
            if ($command.EndsWith($_.key))
            {
                $pattern = '^(\w+ )?{0}$' -f $_.key
                $replacement = '$1{0}' -f $_.value
                $command = $command -replace $pattern, $replacement
            }
        }
        return $command
    }

    [System.Collections.Hashtable] resolve([String[]] $cmdArray)
    {
        $recognizedCommand = $null

        $potencials = @( )
        $potencials += @("default", $cmdArray[0].Replace("--", "__")) -Join " "
        if ($cmdArray.count -gt 1)
        {
            $potencials += @($cmdArray[0], $cmdArray[1].Replace("--", "__")) -Join " "
        }

        $potencials | ForEach-Object {
            $unaliased = $this.resolveActionAliases($_)
            if ($this.commands.contains($unaliased))
            {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('UseDeclaredVarsMoreThanAssignments', '',
                    Justification = 'False positive: https://github.com/PowerShell/PSScriptAnalyzer/issues/1214')]
                $recognizedCommand = "$unaliased"
                Return
            }
        }
        if (-not $recognizedCommand) { return $null }

        $controllerName, $action = $recognizedCommand.Split(" ")[0, 1]

        $action = ( Get-Culture ).TextInfo.ToTitleCase(
            $action.Replace("-", " ")
        ).Replace(" ", "").Trim()

        $recognizedCommand = $recognizedCommand -replace "default ", ""
        $arguments = $cmdArray[($recognizedCommand.Split(" ").Length)..($cmdArray.Length)]

        $controller = $this.controllers.$controllerName
        return @{
            controller = $controller
            action     = $action
            arguments  = $arguments
        }
    }


}
