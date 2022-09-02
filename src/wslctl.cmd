:: from scoop.sh
@echo off
setlocal enabledelayedexpansion
set args=%*
:: replace problem characters in arguments
set args=%args:"='%
set args=%args:(=`(%
set args=%args:)=`)%
set invalid="='
if !args! == !invalid! ( set args= )
powershell -noprofile -ex unrestricted "& '%~dp0\wslctl.ps1'  %args%;exit $lastexitcode"
