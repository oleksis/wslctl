# wslctl

wsl wrapper and cache manager 
When creating a new wsl instance, the defaut user has the same name as the windows session, 
and the default password is `ChangeMe` (to be changed after initialization with command `passwd`).
That user is in the `sudo` system group.

```bash
Usage:
   wslctl COMMAND [ARG...]
   wslctl [ --help | --version | --wsl-default-version [version_to_set]]

Wsl managment commands:
   create  <wsl_name> [<distro_name>] [--v1] Create a named wsl instance from distribution
   rm      <wsl_name>                        Remove a wsl instance by name
   exec    <wsl_name> [|<file.sh>|<cmd>]     Execute specified script|cmd on wsl instance by names
   ls                                        List all created wsl instance names
   start   <wsl_name>                        Start an instance by name
   stop    <wsl_name>                        Stop an instance by name
   status [<wsl_name>]                       List all or specified wsl Instance status
   halt                                      Shutdown all wsl instances

Wsl distribution registry commands:
   registry update                           Pull distribution registry (to cache)
   registry purge                            Remove all local registry content (from cache)
   registry search <distro_pattern>          Extract defined distributions from local registry
   registry ls                               List local registry distributions

Wsl backup managment commands:
   backup create  <wsl_name> [<message>]     Create a new backup for the specified wsl instance
   backup rm      <backup_name>              Remove a backup by name
   backup restore <backup_name> [--force]    Restore a wsl instance from backup
   backup ls                                 List all created backups
   backup purge                              Remove all created backups
```

## Development

In order to ba able to call build.ps1 tasks, you need to import `InvokeBuild` powershell module:
```Powershell
Install-Module -name InvokeBuild -Scope CurrentUser
Invoke-Build -File ./.build.ps1 -Configuration 'Test' 
```

#### Create a release

1. Add changes to `./CHANGELOG.md`.
1. Change the version in `./src/wslctl.ps1` (just change the `major.minor.build` part for variable `$version`).
1. Push to upstream: `git add . && git commit -m "commit message" && git push origin master`.
1. Run `$Version=(cmd /c powershell.exe .\src\wslctl.ps1 --version)` to retreive the binary version.
1. Create the tag with `git tag $Version`.
1. Push to upstream: `git push --tags origin master`.

## NOTE
Not be able to starts interactive bash with sage of Ps2exe ... 
So deliver ps1 script file only.. 