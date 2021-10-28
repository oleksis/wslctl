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

> Note: Because of `powershell` remove quotes from command line, replace problem characters in arguments as follow :
```powershell
PS> ./src/wslctl.ps1 backup create ubuntu-20.04 "focal backup"
ok
ps> powershell ./src/wslctl.ps1 backup create ubuntu-20.04 "focal backup"
ok
ps> powershell ./src/wslctl.ps1 backup create ubuntu-20.04 "'focal backup'"
Error: too few arguments
```

## Development

In order to ba able to call build.ps1 tasks, you need to import `InvokeBuild` powershell module:
```Powershell
Install-Module -name InvokeBuild -Scope CurrentUser
Invoke-Build -File ./.build.ps1 -Configuration 'Test'

# Correct with PSScriptAnalyser
Get-Help Get-ScriptAnalyzerRule -ShowWindow
```

#### Create a release

1. Add changes to `./CHANGELOG.md`.
1. Change the version in `./src/wslctl.ps1` (just change the `major.minor.build` part for variable `$version`).
1. Push to upstream: `git add . && git commit -m "commit message" && git push origin master`.
1. Run `$Version=(cmd /c powershell.exe .\src\wslctl.ps1 --version)` to retreive the binary version.
1. Create the tag with `git tag $Version`.
1. Push to upstream: `git push --tags origin master`.


#### Note Building Executable:
```Powershell
Install-Module -Name ps2exe -Scope CurrentUser
ps2exe wslctl.ps1
```
> Note: WSL2 is available from windows 10 release id 2009+ (build 19041+)
 to check:
    ```Powershell
   (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ReleaseId).ReleaseId => 2009#   Get-CimInstance Win32_OperatingSystem | Select -ExpandProperty buildnumber => 19041+
   ```

## NOTE
Not be able to starts interactive bash with sage of Ps2exe ...
So deliver ps1 script file only..


## Registry dictionary file
Example of `register.json` content :

```json
{
    "ubuntu-14.04-bps.0": {
        "date":     "20210621_095200",
        "message":  "Custom Alpha Version",
        "archive":  "ubuntu-14-04-bps.0-amd64-wsl.rootfs.tar.gz",
        "sha256":   "d2d1a2a3b54ebcf2786018d84f24c8235389d04ca739e1574caccb64d03db13e"
    },
    "ubuntu-20.04-bps.0": {
        "date":     "20210913_113900",
        "message":  "Custom  Alpha Version",
        "archive":  "ubuntu-20.04-bps.0-amd64-wsl.rootfs.tar.gz",
        "sha256":   "b3ef1cb0263898ae4c61771086b533038f7dbd4dbed00a9fc806bdec3a16a274"
    },
    "ubuntu-20.04-k8s.0": {
        "date":     "20210729_200900",
        "message":  "Custom  Alpha Version",
        "archive":  "ubuntu-20.04-k8s.0-amd64-wsl.rootfs.tar.gz",
        "sha256":   "2054a3bb735b7a614c174f564e7c573ba48b9e78261b65aa0a17dda92d851864"
    },

    "ubuntu-14.04.5":  {
        "date":     "20210904_140900",
        "message":  "Official Archived Version",
        "archive":  "ubuntu-14.04.5-server-cloudimg-amd64-wsl.rootfs.tar.gz",
        "sha256":   "93ac63df1badf4642e0d6074ca3d31866b8fc2a7ed386460db0b915eaf447b94"
    },
    "ubuntu-16.04":  {
        "date":     "20210611_101800",
        "message":  "Official Archived Version",
        "archive":  "ubuntu-16.04-server-cloudimg-amd64-wsl.rootfs.tar.gz",
        "sha256":   "d26d46f5460cbd7bcdbd2a0676831bcd25773ef2f2fdf270aafd34bba2d0db00"
    },
    "ubuntu-18.04":  {
        "date":     "20210611_101800",
        "message":  "Official Ubuntu Version",
        "archive":  "ubuntu-18.04-server-cloudimg-amd64-wsl.rootfs.tar.gz",
        "sha256":   "2f330a6c0f04de13cb209080c3011b4eb4ac7a73d49d308d4aefd737900f0598"
    },
    "ubuntu-20.04.2":  {
        "date":     "20210609_092000",
        "message":  "Official Ubuntu Version",
        "archive":  "ubuntu-20.04.2-server-cloudimg-amd64-wsl.rootfs.tar.gz",
        "sha256":   "2d746fff7776cc8b71fc820984b95ae9aad896fd6ae6e666ab523e2a596b2b45"
    },

    "ms-ubuntu-14.04.5":  {
        "date":     "20210611_075300",
        "message":  "Official Archived Version",
        "archive":  "ms-ubuntu-14.04.5.3-server-cloudimg-amd64-wsl-rootfs.tar.gz",
        "sha256":   "ff38b4c393260d1a282c0987005de5d2704d94979f247c90d548e85badcff673"
    },
    "ms-ubuntu-16.04.2":  {
        "date":     "20210611_075300",
        "message":  "Official Archived Version",
        "archive":  "ms-ubuntu-16.04.2-server-cloudimg-amd64-wsl-rootfs.tar.gz",
        "sha256":   "247314273c421a9c9ab11951ca4543ca2297d2fb557887a9a8948d1295794a91"
    },
    "ms-ubuntu-18.04.2":  {
        "date":     "20190522_120000",
        "message":  "Official Store Version Officielle",
        "archive":  "ms-ubuntu-18.04.2-server-cloudimg-amd64-wsl-rootfs.tar.gz",
        "sha256":   "7d220d798b75769d774358677b4cdb1ee556129f64005587dbe9ea8d50b38bd2"
    },
    "ms-ubuntu-20.04":  {
        "date":     "20200423_120000",
        "message":  "Official Store Version Officielle",
        "archive":  "ms-ubuntu-20.04-server-cloudimg-amd64-wsl-rootfs.tar.gz",
        "sha256":   "9d286bf63f963fbcea20ce6ffb56e8e81be8cd47e50d4aaeae717c18abe78066"
    }
}

```


# Usage

## call exec

```powershell
# Call remote command
PS1> .\src\wslctl.cmd exec ubuntu-14.04.5 echo "toto tata"
Execute command 'echo toto tata' on ubuntu-14.04.5 ...
toto tata

 PS1> .\src\wslctl.cmd exec ubuntu-18.04 "echo tata; echo toto"
Execute command 'echo tata; echo toto' on ubuntu-18.04 ...
tata
toto

PS1>  .\src\wslctl.cmd exec ubuntu-18.04 "ls -lrt /tmp"
Execute command 'ls -lrt /tmp' on ubuntu-18.04 ...
total 141920
drwx------ 1 root     root         4096 Jul 31  2020 tmp5lkby6kk
drwx------ 1 root     root         4096 Sep 24  2020 pulse-CcctT9RwKSB1
drwx------ 1 root     root         4096 Dec 10  2020 tmp6g20k01_
...

PS1> .\src\wslctl.cmd exec ubuntu-18.04 ls -lrt /tmp
Execute command 'ls -lrt /tmp' on ubuntu-18.04 ...
total 141920
drwx------ 1 root     root         4096 Jul 31  2020 tmp5lkby6kk
drwx------ 1 root     root         4096 Sep 24  2020 pulse-CcctT9RwKSB1
drwx------ 1 root     root         4096 Dec 10  2020 tmp6g20k01_
...

# Call local script with args
PS1> .\src\wslctl.cmd exec ubuntu-18.04 .\tests\test-called-script.sh arg1 arg2
Execute test.sh on ubuntu-18.04 ...
SCRIPT_WINPATH=/mnt/c/Users/me/home/github/wslctl/tests/test-called-script.sh
toto from script file
arg: arg1
arg: arg2

# Connect to wsl
PS1>  .\src\wslctl.cmd exec ubuntu-18.04
Connect to ubuntu-18.04 ...
me@host:/mnt/c/Users/me/home/github/wslctl$
```

## Call instance creation/removal/connection

```powershell
# create wsl instance named 'my-ubuntu' with release 'ubuntu-18.04'
# default wsl version
PS1> .\src\wslctl.cmd create my-ubuntu ubuntu-18.04
* Import my-ubuntu
Check import requirements ...
Dowload distribution 'ubuntu-18.04' ...
Create wsl instance 'my-ubuntu' (wsl-version: 2)...
Adding group `me` (GID 1000) ...
Done.
* my-ubuntu created
  Could be started with command: wslctl start my-ubuntu

# remove it
PS1> .\src\wslctl.cmd rm my-ubuntu
*  my-ubuntu removed

# same creation with specific wsl version
PS1> .\src\wslctl.cmd create my-ubuntu ubuntu-18.04 --v1
* Import my-ubuntu
Check import requirements ...
Dowload distribution 'ubuntu-18.04' ...
Create wsl instance 'my-ubuntu' (wsl-version: 1)...
Adding group `me` (GID 1000) ...
Done.
* my-ubuntu created
  Could be started with command: wslctl start my-ubuntu

# connect to it
> .\src\wslctl.cmd exec my-ubuntu
Connect to my-ubuntu ...
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

me@host:/mnt/c/Users/me/home/github/wslctl$
```
