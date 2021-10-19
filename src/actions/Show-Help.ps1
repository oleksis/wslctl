
## ----------------------------------------------------------------------------
## Display Help informations
## ----------------------------------------------------------------------------
function Show-Help {
    Write-Host
    Write-Host  "Usage:" -ForegroundColor Yellow
    Write-Host "   wslctl COMMAND [ARG...]"
    Write-Host "   wslctl [ --help | --version | --wsl-default-version [version_to_set]]"
    Write-Host
    # Wsl management
    Write-Host "Wsl managment commands:"  -ForegroundColor Yellow
    Write-Color -Text "   create  <wsl_name> [<distro_name>] [--v1] ", "Create a named wsl instance from distribution" -Color Green, White
    Write-Color -Text "   rm      <wsl_name>                        ", "Remove a wsl instance by name" -Color Green, White
    Write-Color -Text "   exec    <wsl_name> [|<file.sh>|<cmd>]     ", "Execute specified script|cmd on wsl instance by names" -Color Green, White
    Write-Color -Text "   ls                                        ", "List all created wsl instance names" -Color Green, White
    Write-Color -Text "   start   <wsl_name>                        ", "Start an instance by name" -Color Green, White
    Write-Color -Text "   stop    <wsl_name>                        ", "Stop an instance by name" -Color Green, White
    Write-Color -Text "   status [<wsl_name>]                       ", "List all or specified wsl Instance status" -Color Green, White
    Write-Color -Text "   halt                                      ", "Shutdown all wsl instances" -Color Green, White
    Write-Color -Text "   build  [<Wslfile>] [--dry-run]            ", "Build an instance (docker like)" -Color Green, White
    Write-Host

    # wsl distributions registry management
    Write-Host "Wsl distribution registry commands:"  -ForegroundColor Yellow
    Write-Color -Text "   registry update                           ", "Pull distribution registry (to cache)" -Color Green, White
    Write-Color -Text "   registry purge                            ", "Remove all local registry content (from cache)" -Color Green, White
    Write-Color -Text "   registry search <distro_pattern>          ", "Extract defined distributions from local registry" -Color Green, White
    Write-Color -Text "   registry ls                               ", "List local registry distributions" -Color Green, White
    Write-Host

    # Wsl backup management
    Write-Host "Wsl backup managment commands:"  -ForegroundColor Yellow
    Write-Color -Text "   backup create  <wsl_name> <message>       ", "Create a new backup for the specified wsl instance" -Color Green, White
    Write-Color -Text "   backup rm      <backup_name>              ", "Remove a backup by name" -Color Green, White
    Write-Color -Text "   backup restore <backup_name> [--force]    ", "Restore a wsl instance from backup" -Color Green, White
    Write-Color -Text "   backup search  <backup_pattern>           ", "Find a created backup with input as pattern" -Color Green, White
    Write-Color -Text "   backup ls                                 ", "List all created backups" -Color Green, White
    Write-Color -Text "   backup purge                              ", "Remove all created backups" -Color Green, White
    Write-Host
}