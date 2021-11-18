# wslctl

The main goal of this project is to provide a single command `wslctl` to create, backup and manage
WSL (Windows Subsystem for Linux) instances on a windows 10 host.

It can deal with WSL1 and WSL2 instances (only if system is configured).

> There no exe building, only powershell scripts (OOP). Thus, everything is reviewable and auditable.


## Features

- [x] manage (set/get) default wsl version
- [x] halt wsl windows service (shutdown all instances)
- [x] create/remove/list wsl instances
- [x] default user creation on new instance with sudo capabilities (username/pwd configurable)
- [x] start/stop/status wsl instance (backgroud)
- [x] instance version convertion (v1 <-> v2)
- [x] remote execute commands/script
- [x] bash to wsl instance
- [x] build distribution from Dockerfile
- [x] custom configuration file
- [ ] rename instance
- [ ] clone instance

Registry Management

- [x] configurable endpoint (local or remote public url(read))
- [x] local cache of distributions (pull)
- [x] list/search of available distributions
- [x] distributions informations (size, date, description)
- [x] download integrity (sha256)
- [x] local cache cleanup

Backup Management

- [x] local backups informations (sha256, size, date, description, wsl name)
- [x] list/search of available local backups
- [x] remove backup by name
- [x] restore backup by name
- [x] restore confirmation when wsl instance already exists
- [ ] restore with another name


## Install

There are many options :

- clone this repository (updatable via git tags)
- download a specific version from gitlab releases and extract to a directory of your choice (manualy updatable)
- **prefered**: install via scoop.sh (non admin) with my buckets ([mbl-35/scoop-srsrns](https://github.com/mbl-35/scoop-srsrns))

> Remember to add the resulting directory to your windows `%PATH%`

### Configuration

The tool has a default configuration set, but with a private registry endpoint location (mine).
You should at least change that value with the following command:

```bash
PS> wslctl registry set <registry-base-endpoint>
```

The custom configuration file is a json file named `wslctl.json` located next to the cmd file.

Supported configuration parameters :

| Name     | Description                       | Default Value                                           |
| ---      | ---                               | ---                                                     |
| wsl      | wsl binary location               |  "c:\\windows\\system32\\wsl.exe"                       |
| registry | remote or local registry endpoint | "\\\\qu1-srsrns-share.seres.lan\\delivery\\wsl\\images" |
| appData  | where to store everythings        | "`{$env:LOCALAPPDATA}`\\Wslctl"                         |


## Quick start

Get the registry URL and type folloging commands:

```powershell
# get metadata from registry:
PS> wslctl registry set <registry-base-endpoint>
PS> wslctl registry update
# optionnal
PS> wslctl version default 2
# create wsl instance
PS> wslctl create ubuntu-20.04
```

> You will have a fresh ubuntu focal install with your windows user name as default user

More commands to demonstrate the backup / restore functionalities :

```powershell
# connect to the previously created instance
PS> wslctl exec ubuntu-20.04
# Do Stuff
$ echo "toto"
toto
...
$ exit

# backup your instance
PS> wslctl backup ubuntu-20.04 "Saving my stuff"
backup name is ubuntu-20.04-bkp.00

# connect to the instance
PS> wslctl exec ubuntu-20.04
# Do something stupid ...
$ sudo rm -rf /etc
...
$ exit

# Restore the instance (removing actual broken instance)
PS> wslctl backup restore ubuntu-20.04-bkp.00 --force

```

## Usage

`wslctl` coul be used from windows shell prompt (powershell or cmd), but also from a wsl instance
(if the bash `$PATH` environment variable contains the `wslctl` directory).

Use the `--help` option to get the tool usage :
```bash
PS> wslctl --help
   wslctl COMMAND [ARG...]
   wslctl [ --help | --version ]
```

### Wsl managment commands
```bash
   create  <wsl_name> [<distro_name>] [|--v[1|2]]  Create a named wsl instance from distribution
   convert <wsl_name> <version>                     Concert instance to specified wsl version
   rm      <wsl_name>                               Remove a wsl instance by name
   exec    <wsl_name> [|<file.sh>|<cmd>]            Execute specified script|cmd on wsl instance by names
   ls                                               List all created wsl instance names
   start   <wsl_name>                               Start an instance by name
   stop    <wsl_name>                               Stop an instance by name
   status [<wsl_name>]                              List all or specified wsl Instance status
   halt                                             Shutdown all wsl instances
   version [|<wsl_name>|default [|<version>]]       Set/get default version or get  wsl instances version
   build   [<Wslfile>] [--tag=<distro_name>]        Build an instance (docker like)
```

### Wsl distribution registry commands
```bash
   registry set <remote_url>                        Set the remote registry (custom configuratio file)
   registry update                                  Update local distribution dictionary
   registry pull   <distro>                         Pull remote distribution to local registry
   registry purge                                   Remove all local registry content
   registry search <distro_pattern>                 Extract defined distributions from local registry
   registry ls                                      List local registry distributions
```

### Wsl backup managment commands
```bash
   backup create  <wsl_name> <message>              Create a new backup for the specified wsl instance
   backup rm      <backup_name>                     Remove a backup by name
   backup restore <backup_name> [--force]           Restore a wsl instance from backup
   backup search  <backup_pattern>                  Find a created backup with input as pattern
   backup ls                                        List all created backups
   backup purge                                     Remove all created backups
```

> Note: Because of `powershell` remove quotes from command line, we have to pay attention to the escape character sequence in arguments.
>  Here is an example :
>    ```powershell
>    PS> ./src/wslctl.ps1 backup create ubuntu-20.04 "focal backup"
>    ok
>    PS> powershell ./src/wslctl.ps1 backup create ubuntu-20.04 "focal backup"
>    ok
>    PS> powershell ./src/wslctl.ps1 backup create ubuntu-20.04 "'focal backup'"
>    Error: too few arguments
>    ```



## Usage example: Instance creation/removal/connection

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


## Usage Example: Remote Execution

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
hello from script file !
arg: arg1
arg: arg2

# Connect to wsl
PS1>  .\src\wslctl.cmd exec ubuntu-18.04
Connect to ubuntu-18.04 ...
me@host:/mnt/c/Users/me/home/github/wslctl$
```


# Registry

The registry is a remote or local repository to store retrivable distributions archives, and distributions metadatas.
There is no public registry repository (right now), because of probably sensitive informations stored in
customized entity (or business) resulting distributions.

For now, only one registry is allowed (otherwise, we have to manage more than a file to retrive distributions metadata).

The registry `endpoint` represents the registry base Url (ability to be in the local filesystem). Under that endpoint,
we have the metadata file definition (named `registry.json`), and all the downloadable distributions files.

`wslctl` manage a local cache of all downloaded file from the registry endpoint (stored in the `Registry` subdirectory
of the user configuration parameter `appData`).

## Registry Metadatas

Content of the `registry.json` file: a hashtable of named distribution associated with its properties.

Distributions properties :

| Field | Description | Example |
| --- | --- | --- |
| date     | Date of distribution production                           | 2021/09/04 14:09:00  |
| message  | Distribution description                                  | Official Archived Version",
| archive  | Name of the distribution archive in the registry endpoint | ubuntu-14.04.5-server-cloudimg-amd64-wsl.rootfs.tar.gz |
| sha256   | Archive integrity checksum (sha256)                       | 93ac63df1badf4642e0d6074ca3d31866b8fc2a7ed386460db0b915eaf447b94 |
| size     | Archive size (human readable format)                      | 230,10 MB |


## Endpoint Implementation Example

Lets see a private samba repository endpoint `\\share.domain.lan\wsl\registry`

- Remote Filesystem Structure

    ```bash
    smbuser@share.domain.lan:/samba-share/wsl/registry# ls -al
    total 5604064
    drwxr-x--- 2 smbuser smbuser       4096 oct.  13 18:27 .
    drwx------ 3 smbuser smbuser         20 juil. 26 11:39 ..
    -rw------- 1 smbuser smbuser  190632231 juin  11 07:53 ms-ubuntu-14.04.5.3-server-cloudimg-amd64-wsl-rootfs.tar.gz
    -rw------- 1 smbuser smbuser  236797902 juin  11 07:53 ms-ubuntu-16.04.2-server-cloudimg-amd64-wsl-rootfs.tar.gz
    -rw------- 1 smbuser smbuser  231179584 mai   22  2019 ms-ubuntu-18.04.2-server-cloudimg-amd64-wsl-rootfs.tar.gz
    -rw------- 1 smbuser smbuser  452534052 avril 23  2020 ms-ubuntu-20.04-server-cloudimg-amd64-wsl-rootfs.tar.gz
    -rw------- 1 smbuser smbuser       3508 oct.  13 19:43 register.json
    -rw------- 1 smbuser smbuser  241273494 oct.   4 14:09 ubuntu-14.04.5-server-cloudimg-amd64-wsl.rootfs.tar.gz
    -rw------- 1 smbuser smbuser  255534562 juin  11 10:18 ubuntu-16.04-server-cloudimg-amd64-wsl.rootfs.tar.gz
    -rw------- 1 smbuser smbuser  289440282 juin  11 10:18 ubuntu-18.04-server-cloudimg-amd64-wsl.rootfs.tar.gz
    -rw------- 1 smbuser smbuser  474855719 juin   9 09:20 ubuntu-20.04.2-server-cloudimg-amd64-wsl.rootfs.tar.gz
    ```

- **The corresponding `registry.json` file**

    ```json
    {
        "ubuntu-14.04.5":  {
            "date":     "2021/09/04 14:09:00",
            "message":  "Official Archived Version",
            "archive":  "ubuntu-14.04.5-server-cloudimg-amd64-wsl.rootfs.tar.gz",
            "sha256":   "93ac63df1badf4642e0d6074ca3d31866b8fc2a7ed386460db0b915eaf447b94",
            "size":     "230,10 MB"
        },
        "ubuntu-16.04":  {
            "date":     "2021/06/11 10:18:00",
            "message":  "Official Archived Version",
            "archive":  "ubuntu-16.04-server-cloudimg-amd64-wsl.rootfs.tar.gz",
            "sha256":   "d26d46f5460cbd7bcdbd2a0676831bcd25773ef2f2fdf270aafd34bba2d0db00",
            "size":     "243,70 MB"
        },
        "ubuntu-18.04":  {
            "date":     "2021/06/11 10:18:00",
            "message":  "Official Ubuntu Version",
            "archive":  "ubuntu-18.04-server-cloudimg-amd64-wsl.rootfs.tar.gz",
            "sha256":   "2f330a6c0f04de13cb209080c3011b4eb4ac7a73d49d308d4aefd737900f0598",
            "size":     "276,03 MB"
        },
        "ubuntu-20.04.2":  {
            "date":     "2021/06/09 09:20:00",
            "message":  "Official Ubuntu Version",
            "archive":  "ubuntu-20.04.2-server-cloudimg-amd64-wsl.rootfs.tar.gz",
            "sha256":   "2d746fff7776cc8b71fc820984b95ae9aad896fd6ae6e666ab523e2a596b2b45",
            "size":     "452,86 MB"
        },


        "ms-ubuntu-14.04.5":  {
            "date":     "2021/06/11 07:53:00",
            "message":  "Official Archived Version",
            "archive":  "ms-ubuntu-14.04.5.3-server-cloudimg-amd64-wsl-rootfs.tar.gz",
            "sha256":   "ff38b4c393260d1a282c0987005de5d2704d94979f247c90d548e85badcff673",
            "size":     "181,80 MB"
        },
        "ms-ubuntu-16.04.2":  {
            "date":     "2021/06/11 07:53:00",
            "message":  "Official Archived Version",
            "archive":  "ms-ubuntu-16.04.2-server-cloudimg-amd64-wsl-rootfs.tar.gz",
            "sha256":   "247314273c421a9c9ab11951ca4543ca2297d2fb557887a9a8948d1295794a91",
            "size":     "225,83 MB"
        },
        "ms-ubuntu-18.04.2":  {
            "date":     "2019/05/22 12:00:00",
            "message":  "Official Store Version Officielle",
            "archive":  "ms-ubuntu-18.04.2-server-cloudimg-amd64-wsl-rootfs.tar.gz",
            "sha256":   "7d220d798b75769d774358677b4cdb1ee556129f64005587dbe9ea8d50b38bd2",
            "size":     "220,47 MB"
        },
        "ms-ubuntu-20.04":  {
            "date":     "2020/04/23 12:00:00",
            "message":  "Official Store Version Officielle",
            "archive":  "ms-ubuntu-20.04-server-cloudimg-amd64-wsl-rootfs.tar.gz",
            "sha256":   "9d286bf63f963fbcea20ce6ffb56e8e81be8cd47e50d4aaeae717c18abe78066",
            "size":     "431,57 MB"
        }
    }
    ```

- Using that registry

    ```powershell
    # get metadata from registry:
    PS> wslctl registry set "\\share.domain.lan\wsl\registry"
    PS> wslctl registry update

    # list available distributions :
    PS> wslctl registry list
    Available distributions (installable):
    ms-ubuntu-14.04.5           - 2021/06/11 07:53:00 -       181,80 MB - Official Archived Version
    ms-ubuntu-16.04.2           - 2021/06/11 07:53:00 -       225,83 MB - Official Archived Version
    ms-ubuntu-18.04.2           - 2019/05/22 12:00:00 -       220,47 MB - Official Store Version Officielle
    ms-ubuntu-20.04             - 2020/04/23 12:00:00 -       431,57 MB - Official Store Version Officielle
    ubuntu-14.04.5              - 2021/09/04 14:09:00 -       230,10 MB - Official Archived Version
    ubuntu-16.04                - 2021/06/11 10:18:00 -       243,70 MB - Official Archived Version
    ubuntu-18.04                - 2021/06/11 10:18:00 -       276,03 MB - Official Ubuntu Version
    ubuntu-20.04.2              - 2021/06/09 09:20:00 -       452,86 MB - Official Ubuntu Version

    # create instance with available distribution
    PS> wslctl create ubuntu-20.04.2
    ```

# Backup / Restore

Once a wsl instance is created, we can save its state, and later restore it.


`wslctl` manage a local backup directory (stored in the `Backups` subdirectory of the user configuration parameter `appData`).
That directory has a backup metadata file named `backup.json`, storing all informations
(date, description, sha256, ...) of each realized backup, and all backup archives files in format
`{wsl-name}-bkp-{backup-index}-amd64-wsl-rootfs.tar.gz`.

## Backup Directory Example

Lets see a local user backup directory `%LOCALAPPDATA%\Wslctl\Backups`

```powershell
PS> dir C:\Users\me\AppData\Local\Wslctl\Backups

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----        27/10/2021     17:25           1161 backups.json
-a----        27/10/2021     09:06      241284793 ubuntu-14.04.5-bkp.00-amd64-wsl-rootfs.tar.gz
-a----        27/10/2021     17:24      241284381 ubuntu-14.04.5-bkp.01-amd64-wsl-rootfs.tar.gz
```


## Backup Metadatas

Content of the `backups.json` file: a hashtable of named distribution backuped, associated with its properties.

Distributions properties :

| Field | Description | Example |
| --- | --- | --- |
| date     | Date of backup production                                 | 2021/09/04 14:09:00  |
| message  | Backup description                                        | Retest oop |
| archive  | Name of the distribution archive in the registry endpoint | ubuntu-14.04.5-bkp.01-amd64-wsl-rootfs.tar.gz |
| sha256   | Archive integrity checksum (sha256)                       | df6ef87d8b449d039d49d94d9daa8b14ad34d23ce39f3d5e927b39d699a160ed |
| size     | Archive size (human readable format)                      | 230,10 MB |
| wslname | Instance name from wich the backup has been realized | ubuntu-14.04.5 |
| wslversion | Wsl version of the backuped instance | 2 |

The `backup list` command is based on that file :

```powershell
.\src\wslctl.cmd backup ls
Available Backups (recoverable):
ubuntu-14.04.5-bkp.00       - 2021/10/27 09:06:39 -       230,11 MB - test oop
ubuntu-14.04.5-bkp.01       - 2021/10/27 17:25:30 -       230,11 MB - Retest oop
```


# Building

Nothing pushed to registry nor backup.
> Only the wsl instance is created.

```powershell

# Create from Dockerfile set in directory (tag from dockerfile name)
> .\src\wslctl.cmd build .\tests\test.dockerfile
Building 'test' with .\tests\test.dockerfile
Parsing file ...
Warning: Unimplemented command 'expose' (ignored)
Warning: Unimplemented command 'expose' (ignored)
Warning: Unimplemented command 'cmd' (ignored)
From  : ubuntu:18.04
Tag   : test
...

# Create from directory (tag from directory name)
# used Dockerfile default name
> .\src\wslctl.cmd build .\tests
Building 'tests' with .\tests\Dockerfile
Parsing file ...
Warning: Unimplemented command 'expose' (ignored)
Warning: Unimplemented command 'expose' (ignored)
Warning: Unimplemented command 'cmd' (ignored)
From  : ubuntu:18.04
Tag   : tests
...


# Create wsl instance from specified Dockerfile and name it as specified tag name

> .\src\wslctl.cmd build .\tests\test.dockerfile --tag=ubuntu:18.04-mine --dry-run
DryRun - Building 'ubuntu:18.04-mine' with .\tests\test.dockerfile
Parsing file ...
Warning: Unimplemented command 'expose' (ignored)
Warning: Unimplemented command 'expose' (ignored)
Warning: Unimplemented command 'cmd' (ignored)
From  : ubuntu:18.04
Tag   : ubuntu:18.04-mine
...

# Using the --dry-run option (nothing created, just verbose what to do)
> .\src\wslctl.cmd build .\tests\test.dockerfile --tag=ubuntu:18.04-mine --dry-run
DryRun - Building 'ubuntu:18.04-mine' with .\tests\test.dockerfile
Parsing file ...
Warning: Unimplemented command 'expose' (ignored)
Warning: Unimplemented command 'expose' (ignored)
Warning: Unimplemented command 'cmd' (ignored)
From  : ubuntu:18.04
Tag   : ubuntu:18.04-mine

--------------Generated Script File --------------------
#!/usr/bin/env bash
# The script is generated from a Dockerfile via wslctl v1.0.5
# The Original DockerFile is from image : ubuntu:18.04
# Original DockerFile Maintainer: matsumotory

# -- Automatic change working directory:
cd /mnt/c/Users/me/home/github/wslctl/tests

# -- Converted commands:
apt-get -y update
apt-get -y install sudo openssh-server
apt-get -y install git
apt-get -y install curl
apt-get -y install rake
apt-get -y install ruby ruby-dev
apt-get -y install bison
apt-get -y install libcurl4-openssl-dev libssl-dev
apt-get -y install libhiredis-dev
apt-get -y install libmarkdown2-dev
apt-get -y install libcap-dev
apt-get -y install libcgroup-dev
apt-get -y install make
apt-get -y install libpcre3 libpcre3-dev
apt-get -y install libmysqlclient-dev
apt-get -y install gcc
cd /usr/local/src/ && git clone https://github.com/matsumotory/ngx_mruby.git
export NGINX_CONFIG_OPT_ENV="--with-http_stub_status_module --with-http_ssl_module --prefix=/usr/local/nginx --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module"
echo 'export NGINX_CONFIG_OPT_ENV="--with-http_stub_status_module --with-http_ssl_module --prefix=/usr/local/nginx --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module"'>> ~/.bashrc
cd /usr/local/src/ngx_mruby && sh build.sh && make install
--------------------------------------------------------
```



# Development Notes

### ScriptAnalyzer

In order to ba able to call `build.ps1` tasks, we need first import `InvokeBuild` powershell module as follow:
```powershell
PS> Install-Module -name InvokeBuild -Scope CurrentUser
PS> Invoke-Build -File ./.build.ps1 -Configuration 'Test'

# Correct with PSScriptAnalyser
PS> Get-Help Get-ScriptAnalyzerRule -ShowWindow
```

### Building wslctl Executable

> This does not work anymore... Just to remember
> Not be able to starts interactive bash with usage of Ps2exe. **So deliver ps1/pms1 scripts files only**
```Powershell
PS> Install-Module -Name ps2exe -Scope CurrentUser
PS> ps2exe wslctl.ps1
```

### Create a release

1. Add changes to `./CHANGELOG.md`.
1. Change the version in `./src/wslctl.ps1` (just change the `major.minor.build` part for variable `$version`).
1. Push to upstream: `git add . && git commit -m "commit message" && git push origin master`.
1. Run `$Version=(cmd /c powershell.exe .\src\wslctl.ps1 --version)` to retreive the binary version.
1. Create the tag with `git tag $Version`.
1. Push to upstream: `git push --tags origin master`.





