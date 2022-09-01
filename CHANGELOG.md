v2.1.6 (working):
* [EVOL] Custom custom module refresh on each execution (dynamic manage module names cache)
* [EVOL] Add editor config

v2.1.5:
* [ISSUE#8] logout on wsl required Ctrl+C to exit
* [ISSUE#14] check cached archive uptodate by computing with registry referenced hash (eg latest tag)
* [BUG] typo Dowload -> Download

v2.1.4:
* [EVOL] allow to have remote archive file defined in registries

v2.1.3:
* [BUG] display error with instance list when only one (string array)

v2.1.2:
* [EVOL] ability to create from archive file (for wslctl)
* [ISSUE#12] setting default distribution

v2.1.1:
* [EVOL] download does not return boolean

v2.1.0:
* [EVOL] add creation date and image to wsl list
* [EVOL] create switch distrib and name from cli
* [EVOL] remove message"Could be started with command xxx" because external distributions support
* [BUG] error when directory not exists for wsl-distro-name.sh
* [EVOL] registry manage multi repositories
* [EVOL] dispatch configuration to services
* [EVOL] appconfig inherit from jsonHashtableFile
* [BUILD] Copy should set recusive #9

v2.0.5:
* [EVOL] add file size to backup create report
* [BUG] registry update broke registry file #6
* [BUG] Dockerfile parser misinterpret arg command #7

