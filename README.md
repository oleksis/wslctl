# wslctl
wsl wrapper and cache manager 



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