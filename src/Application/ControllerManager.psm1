
using module ".\ServiceLocator.psm1"
using module ".\AbstractController.psm1"
using module ".\ControllerResolver.psm1"

Class ControllerManager
{


    [ControllerResolver] $resolver

    ControllerManager ([System.Collections.Generic.List[AbstractController]] $controllers)
    {
        # Collect controller endpoints
        $this.resolver = [ControllerResolver]::new(
            $controllers,
            # Aliases
            @{
                rm = 'remove'
                ls = 'list'
            }
        )
    }

    [String[]] _getUnixArgumentListFromCommandLine ([String[]] $arguments)
    {
        if ($arguments -is [string]) # Assert Arguments is array
        {
            $arguments = @( $arguments )
        }

        # Patch ps2exe to keep un*x like syntax (issue #1)
        # Warning: flag option only with one minus will be converted with 2 minus
        if ( ($Arguments | Where-Object { $_ -is [bool] }) )
        {
            $arguments = $arguments | Where-Object { $_ -is [String] }                        # Filter non string arguments
            $arguments = $arguments | ForEach-Object { $_ -replace "^-([^-].*)", "--`${1}" }  # Change -option to --option
        }

        return $arguments
    }

    [void] run([String[]] $arguments)
    {
        try
        {
            # Get *nix like command line arguments
            $arguments = $this._getUnixArgumentListFromCommandLine($arguments)
            if (-not $arguments)
            {
                throw 'No command supplied'
            }

            $found = [Hashtable]$this.resolver.resolve($arguments)
            if (-not $found)
            {
                throw "unrecognized Command '$($arguments -Join " ")'"
            }

            # Call Controller Action
            $Controller = $found.controller
            $Action = $found.action
            $Controller.$Action($found.arguments)
        }
        catch
        {
            Write-Host "Error: $_" -ForegroundColor Red
            exit 1
        }
    }

}
